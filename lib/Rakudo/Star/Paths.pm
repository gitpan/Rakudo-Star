package Rakudo::Star::Paths;

use strict;
use warnings FATAL => 'all';
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

sub base_path {
  catdir(dirname(__FILE__), 'Install')
}

sub bin_path {
  my $class = shift;
  catdir($class->base_path, 'bin');
}

sub env_PATH {
  my $class = shift;
  'export PATH='.join(':', $class->bin_path, $ENV{PATH}?$ENV{PATH}:())."\n";
}

sub import {
  if ($0 eq '-') {
    print shift->env_PATH;
    exit 0;
  }
}

=head1 NAME

Rakudo::Star::Paths - find your rakudo install

=head1 SYNOPSIS

  bash$ perl -MRakudo::Star::Paths
  export PATH=/path/to/rakudo/star/bin:...

  bash$ eval $(perl -MRakudo::Star::Paths)
  # PATH env var is now set

  bash$ perl -MRakudo::Star::Paths -e 'print Rakudo::Star::Paths->bin_path'
  /path/to/rakudo/star/bin

=head1 COPYRIGHT

See L<Rakudo::Star/COPYRIGHT>

=head1 LICENSE

See L<Rakudo::Star/LICENSE>

=cut

1;
