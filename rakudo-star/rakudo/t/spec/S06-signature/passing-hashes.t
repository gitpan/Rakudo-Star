use v6;

# L<S06/Parameters and arguments>
# TODO: better smart-linking

use Test;
plan 3;

sub sanity {
    my %sane = 'a'..'d' Z 1..4;
    isa_ok(%sane, Hash, '%sane is a Hash');
}

sub insanity (%baloney) {
    isa_ok(%baloney, Hash, '%baloney is a Hash');
}

# sanity 0
my %h = 'a'..'d' Z 1..4;
isa_ok(%h.WHAT, Hash, '%h is a Hash');

#sanity 1;
sanity;

# Hash passed to a sub used to become a List in pugs
insanity %h;


# vim: ft=perl6
