package DWH_File::Tie::Hash::Node;

use warnings;
use strict;
use vars qw( @ISA $VERSION );
use overload
    '""' => \&to_string,
    fallback => 1;

use DWH_File::Slot;

@ISA = qw( DWH_File::Slot );
$VERSION = 0.01;

sub new {
    my ( $this ) = @_;
    my $class = ref( $this ) || $this;
    my $self = { pred => undef,
                 succ => undef,
                };
    bless $self, $class;
    return $self;
}

sub from_stored {
    my ( $this, $kernel, $data ) = @_;
    my $self = $this->new;
    my ( $pred_len, $succ_len ) = unpack "ll", $data;
    my $pl = $pred_len > 0 ? $pred_len : 0;
    my $sl = $succ_len > 0 ? $succ_len : 0;
    my ( $ignore, $pred_key, $succ_key, $value_string ) =
        unpack "a8 a$pl a$sl a*", $data;
    $pred_len > 0 and $self->{ pred } = $pred_key;
    $succ_len > 0 and $self->{ succ } = $succ_key;
    $self->{ value } = DWH_File::Value::Factory->from_stored( $kernel,
							      $value_string );
    return $self;
}

sub to_string {
    my ( $pred_key, $succ_key ) = @{ $_[ 0 ] }{ qw( pred succ) };
    my ( $pl, $sl );
    if ( defined $pred_key ) { $pl = length( $pred_key ) }
    else {
	$pl = -1;
	$pred_key = '';
    }
    if ( defined $succ_key ) { $sl = length( $succ_key ) }
    else {
	$sl = -1;
	$succ_key = '';
    }
    my $res = pack( "ll", $pl, $sl ) .
        $pred_key . $succ_key . $_[ 0 ]->{ value };
    return $res;
}

sub set_successor { $_[ 0 ]->{ succ } = $_[ 1 ] }

sub set_predecessor { $_[ 0 ]->{ pred } = $_[ 1 ] }

1;

__END__

=head1 NAME

DWH_File::Tie::Hash::Node - 

=head1 SYNOPSIS

DWH_File::Tie::Hash::Node is part of the DWH_File distribution.
For user-oriented documentation, see DWH_File documentation
(perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Node.pm,v $
    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

