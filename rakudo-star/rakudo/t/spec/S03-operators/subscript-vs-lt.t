use v6;

use Test;

=begin pod

  Infix comparison operators L<S03/"Changes to Perl 5 operators"/"stealth postfix">

=end pod


plan 4;

# infix less-than requires whitespace; otherwise it's interpreted as
# a <...> hash subscript

eval_lives_ok "1 <2", "infix less-than (<) requires whitespace before.";
eval_lives_ok  "1 < 2" , "infix less-than (<) requires whitespace before.";
#?rakudo 2 todo 'parsing'
#?pugs 2 todo 'parsing'
eval_dies_ok("1< 2", "infix less-than (<) requires whitespace before, so this is a parse error.");
eval_dies_ok("1<2", "infix less-than (<) requires whitespace before, so this is a parse error.");

# vim: ft=perl6
