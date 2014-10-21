use v6;
use Test;
plan 7;

is &infix:<+>(3, 8), 11, 'Can refer to &infix:<+>';
is  infix:<+>(3, 8), 11, 'Can refer to  infix:<+>';

is &infix:<->(3, 8), -5, 'Can refer to &infix:<->';
is  infix:<->(3, 8), -5, 'Can refer to  infix:<->';

#?pugs skip 'Order::Increase'
is &infix:<cmp>(3, 4), Order::Increase, 'Can refer to &infix:<cmp>';

#?niecza todo
#?pugs 2 skip 'no compatiable multi ok'
ok ~&infix:<+> ~~ /infix/, 'String value of &infix:<+> contains "infix"';
#?niecza todo
ok ~&infix:<+> ~~ /\+/, 'String value of &infix:<+> contains "+"';
