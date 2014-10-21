use v6;
use Test;

plan 9;

# the boundary between run time and compile time is hard to implement right.
# Some of those tests might look trivial, but nearly all of them are based
# on things that at one point or another failed in even rather advanced
# compilers.

{
    is (BEGIN { "foo" }), "foo", 'Can use BEGIN <block> as an expression';
    is (BEGIN  "foo" ), "foo", 'Can use BEGIN <expr> as an expression';
}

{
    my $my;
    BEGIN { $my = 'foo' }
    is $my, 'foo', 'can set outer lexical from a BEGIN block';
}

#?rakudo skip 'cannot assing to non-container'
{
    our $our;
    BEGIN { $our = 'foo' }
    is $our, 'foo', 'can set outer package var from a BEGIN block';
}

{
    sub my-uc($x) { $x.uc };
    my ($my-uc, $setting-uc);
    BEGIN { $my-uc      = my-uc 'Ab' }
    BEGIN { $setting-uc =    uc 'Cd' }
    is $my-uc,      'AB', 'can call subs from an outer scope in BEGIN';
    is $setting-uc, 'CD', 'can call subs from the setting in BEGIN';

}

{
    class SomeClass { };
    my $var;
    BEGIN { $var = SomeClass };
    isa_ok $var, SomeClass, 'use a class at BEGIN time';
}

{
    my $code;
    BEGIN { $code = sub { 'returnvalue' } }
    is $code(), 'returnvalue', 'Can execute an anonymous sub return from BEGIN';
}

{
    my $tracker = '';
    try {
        eval q[
            BEGIN { $tracker = "begin" }
            $tracker = "run";
            # syntax error (two terms in a row):
            1 1
        ];
    }
    is $tracker, 'begin',
        'BEGIN block was executed before a parse error happened later in the file';

}
