package DWH_File::Tie::Hash;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

use DWH_File::Subscript;
use DWH_File::Tie::Subscripted;
use DWH_File::Tie::Hash::Node;

@ISA = qw( DWH_File::Tie::Subscripted );
$VERSION = 0.01;

sub TIEHASH {
    my $this = shift;
    my $self = $this->perform_tie( @_ );
    #$self->{ cache } = DWH_File::Cache->new;
}

sub DELETE {
    my ( $self, $key ) = @_;
    my $subscript = DWH_File::Subscript->from_input( $self, $key );
    my $node = $self->get_node( $subscript ) or return undef;
    my ( $p_node, $s_node, $p_sub, $s_sub );
    if ( defined $node->{ pred } ) {
	$p_sub = DWH_File::Subscript->from_input( $self, $node->{ pred } );
	$p_node = $self->get_node( $p_sub );
    }
    if ( defined $node->{ succ } ) {
	$s_sub = DWH_File::Subscript->from_input( $self, $node->{ succ } );
	$s_node = $self->get_node( $s_sub );
    }
    my $value = $node->{ value };
    $node->set_value( undef );
    $self->{ kernel }->delete( $subscript );
    if ( not $p_node ) {
	if ( not $s_node ) { $self->{ first } = undef } # first, last, only
	else {
            # first
	    $self->{ first } = $s_sub->actual;
	    $s_node->{ pred } = undef;
	    $self->{ kernel }->store( $s_sub, $s_node );
	}
	# make lazy
	$self->{ kernel }->save_custom_grounding( $self );
    }
    else {
	if ( not $s_node ) {
            # last
	    $p_node->{ succ } = undef;
	    $self->{ kernel }->store( $p_sub, $p_node );
	}
	else {
            # general (mid)
	    $p_node->{ succ } = $s_sub->actual;
	    $self->{ kernel }->store( $p_sub, $p_node );
	    $s_node->{ pred } = $p_sub->actual;
	    $self->{ kernel }->store( $s_sub, $s_node );
	}
    }
    return $value;
}

sub CLEAR {
    my ( $self ) = @_;
    my $k = $self->{ first };
    while ( defined $k ) {
	my $sub = DWH_File::Subscript->from_input( $self, $k );
	my $node = $self->get_node( $sub );
	$k = $node->{ succ };
	$node->set_value( undef );
	$self->{ kernel }->delete( $sub );
    }
    $self->{ first } = undef;
    $self->{ kernel }->save_custom_grounding( $self );
}

sub FIRSTKEY { $_[ 0 ]->{ first } }

sub NEXTKEY {
    my $subscript = DWH_File::Subscript->from_input( @_[ 0, 1 ] );
    my $node = $_[ 0 ]->get_node( $subscript ) or return undef;
    return $node->{ succ };
}

sub tie_reference {
    $_[ 2 ] ||= {};
    my ( $this, $kernel, $ref, $blessing, $id, $tail ) = @_;
    my $class = ref $this || $this;
    $blessing ||= ref $ref;
    my $instance = tie %$ref, 'DWH_File::Tie::Hash', $kernel, $ref, $id, $tail;
    if ( $blessing ne 'HASH' ) { bless $ref, $blessing }
    bless $instance, $class;
    return $instance;
}

sub wake_up_call {
    my ( $self, $tail ) = @_;
    unless ( defined $tail ) { die "Tail anomaly" }
    my ( $signal, $first ) = unpack "a a*", $tail;
    if ( $signal eq '>' ) { $self->{ first } = $first }
    elsif ( $signal eq '<' ) { $self->{ first } = undef }
    else { die "Unknown signal byte: '$signal'" }
}

sub sign_in_first_time {
    my ( $self ) = @_;
    while ( my ( $k, $v ) = each %{ $self->{ content } } ) {
	$self->STORE( $k, $v );
    }
}

sub node_class { 'DWH_File::Tie::Hash::Node' }

sub handle_new_node {
    my ( $self, $node, $subscript ) = @_;
    $node->set_successor( $self->FIRSTKEY );
    $self->set_first_key( $subscript->actual );
}

sub set_first_key {
    my ( $self, $key ) = @_;
    my $first = $self->FIRSTKEY;
    if ( defined $first ) {
        my $subscript = DWH_File::Subscript->from_input( $self, $first );
        my $node = $self->get_node( $subscript );
        $node->set_predecessor( $key );
	# make lazy
	$self->{ kernel }->store( $subscript, $node );
    }
    $self->{ first } = $key;
    # make lazy
    $self->{ kernel }->save_custom_grounding( $self );
}

sub custom_grounding {
    my $k = $_[ 0 ]->FIRSTKEY;
    if ( defined $k ) { return ">$k" }
    else { return '<' }
}

1;

__END__

=head1 NAME

DWH_File::Tie::Hash - 

=head1 SYNOPSIS

DWH_File::Tie::Hash is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Hash.pm,v $
    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

