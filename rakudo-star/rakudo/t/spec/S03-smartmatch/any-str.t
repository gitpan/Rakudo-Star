use v6;
use Test;
plan 5;

#L<S03/Smart matching/Any Str string equality>
{
    ok(!("foo" !~~ "foo"),  "!(foo ne foo)");
    ok(("bar" !~~ "foo"),   "bar ne foo)");
    ok  (4 ~~ '4'),         'string equality';
    ok !(4 !~~ '4'),        'negated string equality';
    #?rakudo skip 'smartmatching Mu against Str'
    #?niecza skip 'Mu as argument'
    #?pugs todo 'Mu'
    ok  (Mu ~~ ''),         'Mu ~~ ""';
}

done;

# vim: ft=perl6
