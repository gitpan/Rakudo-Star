use v6;
use Test;
plan 16;

# L<S29/Context/"=item eval">

=begin pod

Tests for the eval() builtin

=end pod

# eval should evaluate the code in the lexical scope of eval's caller
{
    sub make_eval_closure {
        my $a = 5;   #OK not used
        return sub ($s) {
            eval $s 
        };
    };
    is(make_eval_closure().('$a'), 5, 'eval runs code in the proper lexical scope');
}

is(eval('5'), 5, 'simple eval works and returns the value');
my $foo = 1234;
is(eval('$foo'), $foo, 'simple eval using variable defined outside');

# traps die?
#?pugs todo
dies_ok {eval('die; 1')}, "eval does not trap die";

#?pugs todo
dies_ok {eval '1 1)'}, "eval throws on syntax error";

#?pugs todo
dies_ok {eval 'use Poison; 1'}, "eval dies on fatal use";

# L<S04/Exception handlers/Perl 6's eval function only evaluates strings, not blocks.>
#?pugs todo
dies_ok({eval {; 42} }, 'block eval is gone');

# RT #63978, eval didn't work in methods
{
    class EvalTester1 {
        method e($s) { eval $s };
    }
    is EvalTester1.e('5'),       5, 'eval works inside class methods';
    is EvalTester1.new.e('5'),   5, 'eval works inside instance methods';
}

{
    my $x = 5;
    class EvalTester2 {
        method e($s) { eval "$s + \$x" };
    }
    is EvalTester2.e('1'),       6, 
       'eval works inside class methods, with outer lexicals';
    is EvalTester2.new.e('1'),   6, 
       'eval works inside instance methods, with outer lexicals';
}

#?rakudo skip 'eval(Buf)'
#?niecza skip 'Unable to resolve method encode in class Str'
#?pugs skip 'encode'
is eval("'møp'".encode('UTF-8')), 'møp', 'eval(Buf)';

{
    #?rakudo skip 'eval coerce to string'
    is eval(88), 88, 'eval of non-string works';

    my $number = 2;
    #?rakudo skip 'eval coerce to string'
    is eval($number), $number, 'eval of non-string variable works';
}

# RT #77646
{
    my $x = 0;
    eval '$x++' for 1..4;
    is $x, 4, 'can execute the same eval multiple times, without surrounding block';

}

# RT 112472
#?niecza todo "No :lang argument yet..."
#?pugs skip 'Cannot cast from VUndef to VCode'
{
    try eval(:lang<rt112472>, '1');
    ok "$!" ~~ / 'rt112472' /, 'eval in bogus language mentions the language';
}

# vim: ft=perl6
