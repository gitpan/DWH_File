package DWH_File::ClassPool;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

@ISA = qw(  );
$VERSION = 0.01;

sub new {
    my ( $this, $kernel, $key ) = @_;
    my $class = ref $this || $this;
    my $base_id = $kernel->fetch( 'cpi' );
    unless ( defined $base_id ) {
        $base_id = $kernel->next_id;
        $kernel->store( 'cpi', $base_id );
    }
    my $self = { base_id => $base_id,
                 id_mill => DWH_File::ID_Mill->new( $kernel, 'idc' ),
                 kernel => $kernel,
                };
    $self->{ id_mill }{ current } ||= 0;
    bless $self, $class;
    return $self;
}

sub save {
    $_[ 0 ]->{ id_mill }->save;
}

sub retrieve {
    $_[ 0 ]->{ kernel }->fetch( pack "S", $_[ 1 ] );
}

sub class_id {
    my ( $self, $that ) = @_;
    my $the_class = ref $that || $that;
    my $base = pack "L", $self->{ base_id };
    my $class_p = $self->{ kernel }->fetch( "$base$the_class" );
    my $class_id;
    if ( defined $class_p ) { $class_id = unpack "S", $class_p }
    else {
        $class_id = $self->{ id_mill }->next;
        $class_p = pack "S", $class_id;
        $self->{ kernel }->store( $class_p, $the_class );
        $self->{ kernel }->store( "$base$the_class", $class_p );
    }
    return $class_id;
}

1;

__END__

=head1 NAME

DWH_File::ClassPool - 

=head1 SYNOPSIS

DWH_File::ClassPool is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: ClassPool.pm,v $
    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

