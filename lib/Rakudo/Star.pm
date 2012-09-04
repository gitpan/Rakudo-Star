package Rakudo::Star;

our $VERSION = '2012.08_000';

$VERSION = eval $VERSION;

1;

=head1 NAME

Rakudo::Star - install Rakudo Star from CPAN

=head1 SYNOPSIS

This module is here as a version container - see L<Rakudo::Star::Paths>
for documentation of how to find the install.

=head1 DESCRIPTION

Basically, this module convinces MakeMaker to build a bundled version of
<http://rakudo.org>'s "Star" release, then provides a way to find it on
disk.

Note that since parrot is not relocatable, the rakudo install is not
relocatable - so putting it in a L<local::lib> dir and then C<mv>-ing that
directory is not going to work yet. Sorry.

=head1 AUTHORS OF RAKUDO

See L<http://rakudo.org> for the Rakudo project. The following author,
copyright and license information applies only to the L<Rakudo::Star>
installation code.

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet, because nobody's broken it yet. I'm sure they will shortly.

=head1 COPYRIGHT

Copyright (c) 2012 the L<Rakudo::Star> L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself; for the licensing of rakudo, please see L<http://rakudo.org>

=cut
