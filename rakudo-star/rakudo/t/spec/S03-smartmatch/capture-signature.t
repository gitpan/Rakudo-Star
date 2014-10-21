use v6;

use Test;

plan 4;

sub t1(%h) {
    given %h {
        when :(Int :$a) { "pivo" }
        when :(Str :$a) { "slivovica" }
    }
}
my %h = a => 42;
is t1(%h), "pivo", "signature smart-match against hash works (1)";
%h<a> = "moja draha";
is t1(%h), "slivovica", "signature smart-match against hash works (1)";


sub t2(@a) {
    given @a {
        when :($a)     { "godis" }
        when :($a, $b) { "om nom nom" }
    }
}
is t2([1]), "godis", "signature smart-match against array works (1)";
is t2([1,2]), "om nom nom", "signature smart-match against array works (2)";


done;

# vim: ft=perl6
