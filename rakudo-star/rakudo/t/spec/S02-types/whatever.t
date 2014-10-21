use v6;
use Test;

plan 80;

# L<S02/The Whatever Object/"The * character as a standalone term captures the notion of">
# L<S02/Native types/"If any native type is explicitly initialized to">

{
    my $x = *;
    isa_ok $x, Whatever, 'can assign * to a variable and isa works';

    my Whatever $y;
    ok $y.WHAT === Whatever, 'can type variables with Whatever';

    ok *.WHAT === Whatever, '*.WHAT does not autocurry';
}

# L<S02/Currying of Unary and Binary Operators/"Most of the built-in numeric operators">

my $x = *-1;
lives_ok { $x.WHAT }, '(*-1).WHAT lives';
ok $x ~~ Code, '*-1 is some form of Code';
isa_ok $x, WhateverCode, '*-1 is a WhateverCode object';
is $x.(5), 4, 'and we can execute that Code';

ok *.abs ~~ Code, '*.abs is of type Code';
isa_ok *.abs, WhateverCode, '... WhateverCode, more specifically';

isa_ok 1..*, Range, '1..* is a Range, not a Code';
#?niecza skip 'Cannot use value like WhateverCode as a number'
isa_ok 1..*-1, WhateverCode, '1..*-1 is a WhateverCode';
#?niecza skip 'Unable to resolve method postcircumfix:<( )> in class Range'
isa_ok (1..*-1)(10), Range, '(1..*-1)(10) is a Range';

{
    my @a = map *.abs, 1, -2, 3, -4;
    is @a, [1,2,3,4], '*.meth created closure works';
}

{
    # check that it also works with Enums - used to be a Rakudo bug
    # RT #63880
    enum A <b c>;
    isa_ok (b < *), Code, 'Enums and Whatever star interact OK';
}

# check that more complex expressions work:

{
    my $code = *.uc eq 'FOO';
    ok $code ~~ Callable, '"*.uc eq $str" produces a Callable object';
    ok $code("foo"), 'and it works (+)';
    ok !$code("bar"), 'and it works (-)';
}

# RT #64566
#?niecza skip 'hangs'
{
    my @a = 1 .. 4;
    is @a[1..*], 2..4, '@a[1..*] skips first element, stops at last';
    is @a, 1..4, 'array is unmodified after reference to [1..*]';
    # RT #61844
    is (0, 1)[*-1..*], 1, '*-1..* lives and clips to range of Parcel';
}

# RT #68894
{
    my @a = <a b>;
    my $t = join '', map { @a[$_ % *] }, ^5;
    is $t, 'ababa', '$_ % * works';
}

{
    my $x = +*;
    isa_ok $x, Code, '+* is of type Code';

    # following is what we expect +* to do
    my @list = <1 10 2 3>;
    is sort(-> $key {+$key}, @list), [1,2,3,10], '-> $key {+$key} generates closure to numify';

    # and here are two actual applications of +*
    is sort($x, @list), [1,2,3,10], '+* generates closure to numify';
    is @list.sort($x), [1,2,3,10], '+* generates closure to numify';

    # test that  +* works in a slice
    my @x1;
    for 1..4 {
        @x1[+*] = $_;
    }
    is @x1.join('|'), '1|2|3|4', '+* in hash slice (RT 67450)';
}

# L<S02/Currying of Unary and Binary Operators/are internally curried into closures of one or two
# arguments>
{
    my $c = * * *;
    ok $c ~~ Code, '* * * generated a closure';
    is $c(-3, -5), 15, '... that takes two arguments';
}

{
    my $c = * * * + *;
    ok $c ~~ Code, '* * * + * generated a closure';
    is $c(2, 2, 2), 6,  '... that works';
    is $c(-3, -3, -3), 6, '... that respects precdence';
    is $c(0, -10, 3), 3, 'that can work with three different arguments';
}

{
    my $c = * + * * *;
    ok $c ~~ Code, '* + * * * generated a closure';
    is $c(2, 2, 2), 6,  '... that works';
    is $c(-3, -3, -3), 6, '... that respects precdence';
    is $c(3, 0, -10), 3, 'that can work with three different arguments';
}

#?niecza skip 'hangs'
is (0,0,0,0,0,0) >>+>> ((1,2) xx *), <1 2 1 2 1 2>, 'xx * works';

{
    is (1, Mu, 2, 3).grep(*.defined), <1 2 3>, '*.defined works in grep';

    my $rt68714 = *.defined;
    ok $rt68714 ~~ Code, '*.defined generates a closure';
    ok $rt68714(68714), '*.defined works (true)';
    ok not $rt68714(Any), '*.defined works (false)';
}

# L<S02/The Whatever Object/skip first two elements>
{
    # TODO: find out if this allowed for item assignment, or for list
    # assignment only
    #?rakudo todo '* as dummy'
    eval_lives_ok ' * = 5 ', 'can dummy-asign to *';

    my $x;
    (*, *, $x) = 1, 2, 3, 4, 5;
    is $x, 3, 'Can skip lvalues and replace them by Whatever';
}


# L<S02/Currying of Unary and Binary Operators/This rewrite happens after variables are looked up
# in their lexical scope>

{
    my $x = 3;
    {
        is (* + (my $x = 5)).(8), 13,
            'can use a declaration in Whatever-curried expression';
        is $x, 5, 'and it did not get promoted into its own scope';
    }
}

# L<S02/The C<.assuming> Method/This is only for operators that are not
# Whatever-aware.>
{
    multi sub infix:<quack>($x, $y) { "$x|$y" };
    isa_ok * quack 5, Code,
        '* works on LHS of user-defined operator (type)';
    isa_ok 5 quack *, Code,
        '* works on RHS of user-defined operator (type)';
    isa_ok * quack *, Code,
        '* works on both sides of user-defined operator (type)';
    is (* quack 5).(3), '3|5',
        '* works on LHS of user-defined operator (result)';
    is (7 quack *).(3), '7|3',
        '* works on RHS of user-defined operator (result)';
    is (* quack *).('a', 'b'), 'a|b',
        '* works on both sides of user-defined operator (result)';
    is ((* quack *) quack *).(1, 2, 3), '1|2|3',
        'also with three *';
    is ((* quack *) quack 'a').(2, 3), '2|3|a',
        'also if the last is not a *, but a normal value';
}

# Ensure that in *.foo(blah()), blah() is not called until we invoke the closure.
{
    my $called = 0;
    sub oh_noes() { $called = 1; 4 }
    my $x = *.substr(oh_noes());
    is $called, 0, 'in *.foo(oh_noes()), oh_noes() not called when making closure';
    ok $x ~~ Callable, 'and we get a Callable as expected';
    is $x('lovelorn'), 'lorn', 'does get called when invoked';
    is $called, 1, 'does get called when invoked';
}

# chains of methods
{
    my $x = *.uc.flip;
    ok $x ~~ Callable, 'we get a Callable from chained methods with *';
    is $x('dog'), 'GOD', 'we call both methods';
}

# chains of operators, RT #71846
{
    is (0, 1, 2, 3).grep(!(* % 2)).join('|'),
        '0|2', 'prefix:<!> Whatever-curries correctly';
}

# RT #69362
{
    my $x = *.uc;
    my $y = * + 3;
    ok $x.signature, 'Whatever-curried method calls have a signature';
    ok $y.signature, 'Whatever-curried operators have a signature';

}

# RT #73162
eval_lives_ok '{*.{}}()', '{*.{}}() lives';

# RT #80256
{
    my $f = * !< 3;
    isa_ok $f, Code, 'Whatever-currying !< (1)';
    nok $f(2), 'Whatever-currying !< (2)';
    ok $f(3), 'Whatever-currying !< (3)';
    ok $f(4), 'Whatever-currying !< (4)';
}

#?rakudo skip 'currying plus meta ops'
{
    my $f = 5 R- *;
    isa_ok $f, Code, 'Whatever-currying with R- (1)';
    is $f(7), 2, 'Whatever-currying with R- (2)';
    is $f(0), -5, 'Whatever-currying with R- (3)';

    dies_ok { &infix:<+>(*, 42) }, '&infix:<+>(*, 42) doesn\'t make a closure';
    #?niecza skip 'Undeclared routine'
    dies_ok { &infix:<R+>(*, 42) }, '&infix:<+>(*, 42) doesn\'t make a closure';
}

# RT 79166
{
    my $rt79166 = *;
    isa_ok $rt79166, Whatever, 'assignment of whatever still works';
    $rt79166 = 'RT 79166';
    is $rt79166, 'RT 79166', 'assignment to variable with whatever in it';
}

# RT #81448
{
    sub f($x) { $x x 2 };
    is *.&f.('a'), 'aa', '*.&sub curries';
}

# RT #77000
{
    isa_ok *[0], WhateverCode, '*[0] curries';
    is *[0]([1, 2, 3]), 1, '... it works';
}

# RT #102466

{
    my $chained = 1 < * < 3;
     ok $chained(2), 'Chained comparison (1)';
    #?rakudo 2 todo 'RT 102466'
    nok $chained(1), 'Chained comparison (2)';
    nok $chained(3), 'Chained comparison (3)';
}

# vim: ft=perl6
