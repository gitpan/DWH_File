package DWH_File::ID_Mill;

use warnings;
use strict;
use vars qw( @ISA $VERSION );

@ISA = qw(  );
$VERSION = 0.01;

sub new {
    my ( $this, $kernel, $key ) = @_;
    length $key == 3 or die "ID_Mill keys must be three chars";
    my $class = ref $this || $this;
    my $current = $kernel->fetch( $key );
    $current ||= 0;
    my $self = { current => $current,
                 kernel => $kernel,
                 key => $key,
                };
    bless $self, $class;
    return $self;
}

sub next {
    $_[ 0 ]->{ current }++;
    return $_[ 0 ]->{ current };
}

sub save {
    my ( $self ) = @_;
    $self->{ kernel }->store( $self->{ key }, $self->{ current } );
}

1;

__END__

=head1 NAME

DWH_File::ID_Mill - 

=head1 SYNOPSIS

DWH_File::ID_Mill is part of the DWH_File distribution. For user-oriented
documentation, see DWH_File documentation (perldoc DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: ID_Mill.pm,v $
    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

