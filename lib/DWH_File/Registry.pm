package DWH_File::Registry;

use warnings;
use strict;
use vars qw( @ISA $VERSION $instance );

BEGIN { $instance = '' }

@ISA = qw(  );
$VERSION = 0.01;

sub new {
    my ( $class ) = @_;
    $instance and die "Singleton constraint violated in DWH_File::Registry";
    my $self = { hi_tag => 0 };
    bless $self, $class;
    return $self;
}

sub instance { $instance ||= $_[ 0 ]->new }

sub retrieve {
    if ( exists $_[ 0 ]->{ $_[ 1 ] } and ref $_[ 0 ]->{ $_[ 1 ] } ) {
        return $_[ 0 ]->{ $_[ 1 ] };
    }
    else { return undef }
}

sub register {
    my ( $self, $registrand ) = @_;
    my $tag;
    if ( $tag = $registrand->fetch( 'tag' ) ) {
        $tag > $self->{ hi_tag } and $self->{ hi_tag } = $tag;
    }
    else {
        $tag = ++( $self->{ hi_tag } );
        $registrand->store( 'tag', $tag );
    }
    $self->{ $tag } and die "Duplicate registration on tag '$tag'";
    $self->{ $tag } = $registrand;
    return $tag;
}

1;

__END__

=head1 NAME

DWH_File::Registry - 

=head1 SYNOPSIS

DWH_File::Registry is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: Registry.pm,v $
    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

