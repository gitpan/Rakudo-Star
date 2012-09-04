use strict;
use warnings FATAL => 'all';
use Test::More qw(no_plan);

chdir('rakudo-star/rakudo');

sub run_test {
  my ($file) = @_;
  cmp_ok(system($^X, 't/harness', $file), '==', 0, "${file} passed");
}

run_test($_) for <t/00-parrot/*.t>;

run_test($_) for <t/01-rakudo/*.t>;
