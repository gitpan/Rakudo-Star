use v6;

use Test;

plan 44;

=begin description

This test tests the C<pick> builtin. See S32::Containers#pick.

Previous discussions about pick.

L<"http://groups.google.com/group/perl.perl6.language/tree/browse_frm/thread/24e369fba3ed626e/4e893cad1016ed94?rnum=1&_done=%2Fgroup%2Fperl.perl6.language%2Fbrowse_frm%2Fthread%2F24e369fba3ed626e%2F6e6a2aad1dcc879d%3F#doc_2ed48e2376511fe3">

=end description

# L<S32::Containers/List/=item pick>

my @array = <a b c d>;
#?pugs skip "autothread"
ok ?(@array.pick eq any <a b c d>), "pick works on arrays";
#?niecza skip '().pick === Nil'
#?pugs skip 'Nil'
ok ().pick === Nil, '.pick on the empty list is Nil';

my @arr = <z z z>;

ok ~(@arr.pick(2)) eq 'z z',   'method pick with $num < +@values';
ok ~(@arr.pick(4)) eq 'z z z', 'method pick with $num > +@values';

#?pugs 2 skip 'NYI'
is pick(2, @arr), <z z>, 'sub pick with $num < +@values, implicit no-replace';
is pick(4, @arr), <z z z>, 'sub pick with $num > +@values';

#?pugs skip '.Str'
is (<a b c d>.pick(*).sort).Str, 'a b c d', 'pick(*) returns all the items in the array (but maybe not in order)';

{
  my @items = <1 2 3 4>;
  my @shuffled_items_10;
  push @shuffled_items_10, @items.pick(*) for ^10;
  isnt(@shuffled_items_10, @items xx 10,
       'pick(*) returned the items of the array in a random order');
}

#?pugs skip "autothreading"
{
    # Test that List.pick doesn't flatten array refs
    ok ?([[1, 2], [3, 4]].pick.join('|') eq any('1|2', '3|4')), '[[1,2],[3,4]].pick does not flatten';
    ok ?(~([[1, 2], [3, 4]].pick(*)) eq '1 2 3 4' | '3 4 1 2'), '[[1,2],[3,4]].pick(*) does not flatten';
}

{
    ok <5 5>.pick() == 5,
       '.pick() returns something can be used as single scalar';
}

#?pugs skip 'pick not defined: VNum Infinity'
{
    my @a = 1..100;
    my @b = pick(*, @a);
    is @b.elems, 100, "pick(*, @a) returns the correct number of elements";
    is ~@b.sort, ~(1..100), "pick(*, @a) returns the correct elements";
    is ~@b.grep(Int).elems, 100, "pick(*, @a) returns Ints (if @a is Ints)";
}

{
    my @a = 1..100;

    isa_ok @a.pick, Int, "picking a single element from an array of Ints produces an Int";
    #?pugs todo
    ok @a.pick ~~ 1..100, "picking a single element from an array of Ints produces one of them";

    #?pugs todo
    isa_ok @a.pick(1), Int, "picking 1 from an array of Ints produces an Int";
    #?pugs todo
    ok @a.pick(1) ~~ 1..100, "picking 1 from an array of Ints produces one of them";

    my @c = @a.pick(2);
    isa_ok @c[0], Int, "picking 2 from an array of Ints produces an Int...";
    isa_ok @c[1], Int, "... and an Int";
    #?pugs todo
    ok (@c[0] ~~ 1..100) && (@c[1] ~~ 1..100), "picking 2 from an array of Ints produces two of them";
    ok @c[0] != @c[1], "picking 2 from an array of Ints produces two distinct results";

    #?pugs 2 skip "NYI"
    is @a.pick("25").elems, 25, ".pick works Str arguments";
    is pick("25", @a).elems, 25, "pick works Str arguments";
}

#?pugs skip "NYI"
{
    #?rakudo todo 'error on pick :replace'
    dies_ok({ [1,2,3].pick(4, :replace) }, 'error on deprecated :replace');
}

# enums + pick
#?pugs skip "NYI"
{
    is Bool.pick(*).grep(Bool).elems, 2, 'Bool.pick works';

    enum A <b c d>;
    is A.pick(*).grep(A).elems, 3, 'RandomEnum.pick works';
}

# ranges + pick
{
    my %seen;
    %seen{$_} = 1 for (1..100).pick(50);
    is %seen.keys.elems, 50, 'Range.pick produces uniq elems';
    ok (so 1 <= all(%seen.keys) <= 100), '... and all the elements are in range';
}

{
    my %seen;
    %seen{$_} = 1 for (1..300).pick(50);
    is %seen.keys.elems, 50, 'Range.pick produces uniq elems';
    ok (so 1 <= all(%seen.keys) <= 300), '... and all the elements are in range';
}

{
    my %seen;
    %seen{$_} = 1 for (1..50).pick(*);
    is %seen.keys.elems, 50, 'Range.pick produces uniq elems';
    ok (so 1 <= all(%seen.keys) <= 50), '... and all the elements are in range';
}

{
    ok 1 <= (1..50).pick <= 50, 'Range.pick() works';
}

{
    my %seen;
    %seen{$_} = 1 for (1..1_000_000).pick(50);
    is %seen.keys.elems, 50, 'Range.pick produces uniq elems';
    ok (so 1 <= all(%seen.keys) <= 1_000_000), '... and all the elements are in range';
}

{
    my %seen;
    %seen{$_} = 1 for (1^..1_000_000).pick(50);
    is %seen.keys.elems, 50, 'Range.pick produces uniq elems (lower exclusive)';
    ok (so 1 < all(%seen.keys) <= 1_000_000), '... and all the elements are in range';
}

{
    my %seen;
    %seen{$_} = 1 for (1..^1_000_000).pick(50);
    is %seen.keys.elems, 50, 'Range.pick produces uniq elems (upper exclusive)';
    ok (so 1 <= all(%seen.keys) < 1_000_000), '... and all the elements are in range';
}

{
    my %seen;
    %seen{$_} = 1 for (1^..^1_000_000).pick(50);
    is %seen.keys.elems, 50, 'Range.pick produces uniq elems (both exclusive)';
    ok (so 1 < all(%seen.keys) < 1_000_000), '... and all the elements are in range';
}

is (1..^2).pick, 1, 'pick on 1-elem range';

#?pugs todo
ok ('a'..'z').pick ~~ /\w/, 'Range.pick on non-Int range';

# vim: ft=perl6
