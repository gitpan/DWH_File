package DWH_File::Kernel;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

use AnyDBM_File;
use UNIVERSAL;

use DWH_File::ID_Mill;
use DWH_File::Cache;
#use DWH_File::Log;
use DWH_File::Registry;
use DWH_File::ClassPool;
use DWH_File::Value::Factory;

@ISA = qw( );
$VERSION = 0.01;

sub new {
    my $this = shift;
    my $file = $_[ 0 ];
    my $class = ref $this || $this;
    my $dbm = tie my %dummy, 'AnyDBM_File', @_;
    my $self = { dbm => $dbm,
                 cache => DWH_File::Cache->new,
                 garbage => {},
                 #logger =>DWH_File::Log->new( $file ),
                };
    bless $self, $class;
    $self->{ id_mill } = DWH_File::ID_Mill->new( $self, 'idl' );
    $self->{ id_mill }{ current } ||= 0;
    my $registry = DWH_File::Registry->instance;
    $self->{ tag } = $registry->register( $self );
    $self->{ registry } = $registry;
    $self->{ class_pool } = DWH_File::ClassPool->new( $self, 'idc' );
    my $worker_id = $dbm->FETCH( 'idb' );
    if ( defined $worker_id ) {
	$self->{ work } = $self->activate_by_id( $worker_id );
    }
    else {
        $self->{ work } = DWH_File::Value::Factory->from_input( $self, {},
						       'DWH_File::Work' );
        $self->store( 'idb', $self->{ work }{ id } );
    }
    return $self;
}

sub store {
    $_[ 0 ]->{ dbm }->STORE( @_[ 1, 2 ] );
    $_[ 0 ]->{ logger } and $_[ 0 ]->{ logger }->log_store( @_[ 1, 2 ] );
}

sub fetch {
    return $_[ 0 ]->{ dbm }->FETCH( $_[ 1 ] );
}

sub delete {
    $_[ 0 ]->{ dbm }->DELETE( $_[ 1 ] );
    $_[ 0 ]->{ logger } and $_[ 0 ]->{ logger }->log_delete( $_[ 1 ] );
}

sub next_id {
    return $_[ 0 ]->{ id_mill }->next;
}

sub save_state {
    $_[ 0 ]->{ id_mill }->save;
    $_[ 0 ]->{ class_pool }->save;
}

sub class_id {
    $_[ 0 ]->{ class_pool }->class_id( $_[ 1 ] );
}

sub reference_string {
    pack "aSL", '^', $_[ 0 ]->{ tag }, $_[ 1 ]->{ id };
}

sub activate_reference {
    my ( $self, $stored ) = @_;
    my ( $head, $tag, $id ) =
	unpack "aSL", $stored;
    $head eq '^' or return undef;
    if ( $tag != $self->{ tag } ) {
        return $self->{ registry }->retrieve( $tag )->
                                    activate_reference( $stored );
    }
    else { return $self->activate_by_id( $id ) }
}

sub activate_by_id {
    my ( $self, $id ) = @_;
    my $val_obj;
    unless ( $val_obj = $self->{ cache }->retrieve( $id ) ) {
	my $ground = $self->fetch( pack "L", $id );
	my ( $class_id, $blessing_id, $refcount, $tail )
	    = unpack "SSLa*", $ground;
        my $ref;
        my $class = $self->{ class_pool }->retrieve( $class_id );
        my $blessing = $self->{ class_pool }->retrieve( $blessing_id );
        $class or die "Invalid class id: '$class_id'";
        $val_obj = $class->tie_reference( $self, $ref, $blessing, $id, $tail );
    }
    return $val_obj;
}

sub ground_reference {
    my ( $self, $value_obj ) = @_;
    unless ( ref $value_obj and
             $value_obj->isa( 'DWH_File::Value' ) and
             $value_obj->isa( 'DWH_File::Reference' ) ) {
        die "ground_reference() called for inapproproate object";
    }
    my $ground = pack "SSLa*", $self->class_id( $value_obj ),
                               $self->class_id( $value_obj->actual_value ),
                               0, # refcount
                               $value_obj->custom_grounding;
    $self->store( pack( "L", $value_obj->{ id } ), $ground );
}

sub save_custom_grounding {
    my ( $self, $value_obj ) = @_;
    unless ( ref $value_obj and
             $value_obj->isa( 'DWH_File::Value' ) and
             $value_obj->isa( 'DWH_File::Reference' ) ) {
	die "save_custom_grounding() called for inapproproate object";
    }
    my $id = $value_obj->{ id };
    defined $id or return;
    my $idstring = pack "L", $id;
    my $ground = $self->fetch( $idstring ) or return;
    my ( $pre ) = unpack "a8", $ground;
    $pre or return;
    $self->store( $idstring, pack "a8a*", $pre,
                  $value_obj->custom_grounding );
}

sub unground {
    my ( $self, $value_obj ) = @_;
    unless ( ref $value_obj and
             $value_obj->isa( 'DWH_File::Value' ) and
             $value_obj->isa( 'DWH_File::Reference' ) ) {
        die "unground() called for inapproproate object";
    }
    $self->delete( pack( "L", $value_obj->{ id } ) );
}

sub bump_refcount {
    my ( $self, $id ) = @_;
    my $idstring = pack "L", $id;
    my ( $pre, $refcount, $post ) = unpack "a4La*", $self->fetch( $idstring );
    $refcount++;
    $self->store( $idstring, pack( "a4La*", $pre, $refcount, $post ) );
    delete $self->{ garbage }{ $id };
}

sub cut_refcount {
    my ( $self, $id ) = @_;
    my $idstring = pack "L", $id;
    my ( $pre, $refcount, $post ) = unpack "a4La*",
                                           $self->fetch( $idstring );
    $refcount--;
    $self->store( $idstring, pack "a4La*", $pre, $refcount, $post );
    if ( $refcount == 0 ) { $self->{ garbage }{ $id } = 1 }
    elsif ( $refcount < 0 ) { die "Negative refcount exception! [$id]" }
}

sub tieing {
    $_[ 0 ]->{ cache }->encache( $_[ 1 ] );
}

sub did_tie {
}

sub purge_garbage {
    while ( my @goids = keys %{ $_[ 0 ]->{ garbage } } ) {
        for my $goid ( @goids ) {
            my $goner = $_[ 0 ]->activate_by_id( $goid );
            if ( $goner and
                 UNIVERSAL::isa( $goner, 'DWH_File::Reference' ) ) {
                 $goner->vanish;
                 delete $_[ 0 ]->{ garbage }{ $goid };
            }
            else { warn "Garbage anomaly: $goid ~ $goner" }
        }
    }
}

1;

__END__

=head1 NAME

DWH_File::Kernel - 

=head1 SYNOPSIS

DWH_File::Kernel is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Kernel.pm,v $
    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

