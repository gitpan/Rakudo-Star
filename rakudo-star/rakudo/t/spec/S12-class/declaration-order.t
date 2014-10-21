use v6;

use Test;

plan 2;


=begin pod

A class can only derive already declared classes.

=end pod

# L<S12/Classes/"bare class names must be predeclared">

# need eval_lives_ok here because class declarations happen at compile time
eval_lives_ok ' class A {}; class B is A {}; ', "base before derived: lives";
eval_dies_ok ' class D is C {}; class C {}; ', "derived before base: dies";

# vim: ft=perl6
