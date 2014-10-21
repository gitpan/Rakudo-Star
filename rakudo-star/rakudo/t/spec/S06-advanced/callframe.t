use v6;
use Test;

plan 6;

# this test file contains tests for line numbers, among other things
# so it's extremely important not to randomly insert or delete lines.


my $baseline = 10;

isa_ok callframe(), CallFrame, 'callframe() returns a CallFrame';

sub f() {
    is callframe().line, $baseline + 5, 'callframe().line';
    ok callframe().file ~~ /« callframe »/, '.file';

    #?rakudo skip '.inline'
    nok callframe().inline, 'explicitly entered block (.inline)';

    # Note:  According to S02, these should probably fail unless
    # $x is marked 'is dynamic'.  We allow it for now since there's
    # still some uncertainty in the spec in S06, though.
    is callframe(1).my.<$x>, 42, 'can access outer lexicals via .my';
    callframe(1).my.<$x> = 23;
}

my $x = 42;

f();

is $x, 23, '$x successfully modified';

done();

# vim: ft=perl6
