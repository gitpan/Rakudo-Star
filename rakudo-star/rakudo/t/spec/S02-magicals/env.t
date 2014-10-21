use v6;

# Tests for magic variables

use Test;
BEGIN @*INC.push: 't/spec/packages/';
use Test::Util;
# L<S28/Named variables>
plan 14;

if $*OS eq "browser" {
  skip_rest "Programs running in browsers don't have access to regular IO.";
  exit;
}

=begin desc

= DESCRIPTION

Tests for %*ENV

Tests that C<%*ENV> can be read and written to and that
child processes see the modified C<%*ENV>.

=end desc

# It must not be empty at startup.
ok +%*ENV.keys, '%*ENV has keys';

# %*ENV should be able to get copied into another variable.
my %vars = %*ENV;
is +%vars.keys, +%*ENV.keys, '%*ENV was successfully copied into another variable';

# XXX: Should modifying %vars affect the environment? I don't think so, but, of
# course, feel free to change the following test if I'm wrong.
%vars<PATH> = "42";
ok %*ENV<PATH> ne "42",
  'modifying a copy of %*ENV didn\'t affect the environment';

# Similarily, I don't think creating a new entry in %vars should affect the
# environment:
diag '%*ENV<PUGS_ROCKS>=' ~ (%*ENV<PUGS_ROCKS> // "");
ok !defined(%*ENV<PUGS_ROCKS>), "there's no env variable 'PUGS_ROCKS'";
%vars<PUGS_ROCKS> = "42";
diag '%*ENV<PUGS_ROCKS>=' ~ (%*ENV<PUGS_ROCKS> // "");
ok !defined(%*ENV<PUGS_ROCKS>), "there's still no env variable 'PUGS_ROCKS'";

my ($redir,$squo) = (">", "'");

# RT #77906 - can we modify the ENV?
my $expected = 'Hello from subprocess';
%*ENV<PUGS_ROCKS> = $expected;
# Note that the "?" preceding the "(" is necessary, because we need a Bool,
# not a junction of Bools.
is %*ENV<PUGS_ROCKS>, $expected,'%*ENV is rw';

%*ENV.delete('PUGS_ROCKS');
ok(!%*ENV.exists('PUGS_ROCKS'), 'We can remove keys from %*ENV');

ok !%*ENV.exists("does_not_exist"), "exists() returns false on a not defined env var";

# %ENV must not be imported by default
#?pugs todo 'bug'
eval_dies_ok("%ENV", '%ENV not visible by default');

# following doesn't parse yet
#?rakudo skip 'import keyword'
#?niecza skip 'Action method statement_control:import not yet implemented'
{
    # It must be importable
    import PROCESS <%ENV>;
    ok +%ENV.keys, 'imported %ENV has keys';
}

# Importation must be lexical
#?pugs todo 'bug'
{
    try { eval "%ENV" };
    ok $!.defined, '%ENV not visible by after lexical import scope';
    1;
}

# RT #78256
{
    nok %*ENV<NOSUCHENVVAR>.defined, 'non-existing vars are undefined';
    nok %*ENV.exists('NOSUCHENVVAR'), 'non-existing vars do not exist';

}

#?niecza skip "Cannot call is_run; none of these signatures match"
{
    %*ENV<abc> = 'def';
    is_run 'print %*ENV<abc>',
    {
        status  => 0,
        out     => 'def',
        err     => '',
    },
    'ENV members persist to child processes';
}

# vim: ft=perl6
