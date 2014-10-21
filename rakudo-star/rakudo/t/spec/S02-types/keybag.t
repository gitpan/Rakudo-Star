use v6;
use Test;

plan 141;

# L<S02/Mutable types/KeyHash of UInt>

# A KeyBag is a KeyHash of UInt, i.e. the values are positive Int

sub showkv($x) {
    $x.keys.sort.map({ $^k ~ ':' ~ $x{$k} }).join(' ')
}

# L<S02/Immutable types/'the bag listop'>

{
    my $b = KeyBag.new("a", "foo", "a", "a", "a", "a", "b", "foo");
    isa_ok $b, KeyBag, 'we got a KeyBag';
    is showkv($b), 'a:5 b:1 foo:2', '...with the right elements';

    is $b<a>, 5, 'Single-key subscript (existing element)';
    isa_ok $b<a>, Int, 'Single-key subscript yields an Int';
    is $b<santa>, 0, 'Single-key subscript (nonexistent element)';
    isa_ok $b<santa>, Int, 'Single-key subscript yields an Int (nonexistent element)';
    ok $b.exists('a'), '.exists with existing element';
    nok $b.exists('santa'), '.exists with nonexistent element';

    is $b.values.elems, 3, "Values returns the correct number of values";
    is ([+] $b.values), 8, "Values returns the correct sum";
    ok ?$b, "Bool returns True if there is something in the KeyBag";
    nok ?KeyBag.new(), "Bool returns False if there is nothing in the KeyBag";
    
    my $hash;
    lives_ok { $hash = $b.hash }, ".hash doesn't die";
    isa_ok $hash, Hash, "...and it returned a Hash";
    is showkv($hash), 'a:5 b:1 foo:2', '...with the right elements';

    dies_ok { $b.keys = <c d> }, "Can't assign to .keys";
    dies_ok { $b.values = 3, 4 }, "Can't assign to .values";

    is ~$b<a b>, "5 1", 'Multiple-element access';
    is ~$b<a santa b easterbunny>, "5 0 1 0", 'Multiple-element access (with nonexistent elements)';

    is $b.elems, 8, '.elems gives sum of values';
    is +$b, 8, '+$bag gives sum of values';

    lives_ok { $b<a> = 42 }, "Can assign to an existing element";
    is $b<a>, 42, "... and assignment takes effect";
    lives_ok { $b<brady> = 12 }, "Can assign to a new element";
    is $b<brady>, 12, "... and assignment takes effect";
    lives_ok { $b<spiderman> = 0 }, "Can assign zero to a nonexistent element";
    nok $b.exists("spiderman"), "... and that didn't create the element";
    lives_ok { $b<brady> = 0 }, "Can assign zero to a existing element";
    nok $b.exists("brady"), "... and it goes away";
    
    lives_ok { $b<a>++ }, "Can ++ an existing element";
    is $b<a>, 43, "... and the increment happens";
    lives_ok { $b<carter>++ }, "Can ++ a new element";
    is $b<carter>, 1, "... and the element is created";
    lives_ok { $b<a>-- }, "Can -- an existing element";
    is $b<a>, 42, "... and the decrement happens";
    lives_ok { $b<carter>-- }, "Can -- an element with value 1";
    nok $b.exists("carter"), "... and it goes away";
    lives_ok { $b<farve>-- }, "Can -- an element that doesn't exist";
    nok $b.exists("farve"), "... and everything is still okay";
}

#?rakudo skip ':exists and :delete NYI'
{
    my $s = KeyBag.new(<a a b foo>);
    is $s<a>:exists, True, ':exists with existing element';
    is $s<santa>:exists, False, ':exists with nonexistent element';
    is $s<a>:delete, 2, ':delete works on KeyBag';
    is showkv($s), 'b:1 foo:1', '...and actually deletes';
}

{
    my $b = KeyBag.new('a', False, 2, 'a', False, False);
    my @ks = $b.keys;
    #?niecza 2 todo
    #?rakudo 2 todo ''
    is @ks.grep(Int)[0], 2, 'Int keys are left as Ints';
    is @ks.grep(* eqv False).elems, 1, 'Bool keys are left as Bools';
    is @ks.grep(Str)[0], 'a', 'And Str keys are permitted in the same set';
    is $b{2, 'a', False}.sort.join(' '), '1 2 3', 'All keys have the right values';
}

#?niecza skip "Unmatched key in Hash.LISTSTORE"
{
    my %h = bag <a b o p a p o o>;
    ok %h ~~ Hash, 'A hash to which a Bag has been assigned remains a hash';
    is showkv(%h), 'a:2 b:1 o:3 p:2', '...with the right elements';
}

{
    my $b = KeyBag.new(<a b o p a p o o>);
    isa_ok $b, KeyBag, '&KeyBag.new given an array of strings produces a KeyBag';
    is showkv($b), 'a:2 b:1 o:3 p:2', '...with the right elements';
}

{
    my $b = KeyBag.new([ foo => 10, bar => 17, baz => 42, santa => 0 ]);
    isa_ok $b, KeyBag, '&KeyBag.new given an array of pairs produces a KeyBag';
    is showkv($b), 'bar:17 baz:42 foo:10', '... with the right elements';
}

{
    my $b = KeyBag.new({ foo => 10, bar => 17, baz => 42, santa => 0 }.hash);
    isa_ok $b, KeyBag, '&KeyBag.new given a Hash produces a KeyBag';
    is showkv($b), 'bar:17 baz:42 foo:10', '... with the right elements';
}

{
    my $b = KeyBag.new({ foo => 10, bar => 17, baz => 42, santa => 0 });
    isa_ok $b, KeyBag, '&KeyBag.new given a Hash produces a KeyBag';
    is showkv($b), 'bar:17 baz:42 foo:10', '... with the right elements';
}

{
    my $b = KeyBag.new(set <foo bar foo bar baz foo>);
    isa_ok $b, KeyBag, '&KeyBag.new given a Set produces a KeyBag';
    is showkv($b), 'bar:1 baz:1 foo:1', '... with the right elements';
}

{
    my $b = KeyBag.new(KeySet.new(set <foo bar foo bar baz foo>));
    isa_ok $b, KeyBag, '&KeyBag.new given a KeySet produces a KeyBag';
    is showkv($b), 'bar:1 baz:1 foo:1', '... with the right elements';
}

{
    my $b = KeyBag.new(bag set <foo bar foo bar baz foo>);
    isa_ok $b, KeyBag, '&KeyBag.new given a Bag produces a KeyBag';
    is showkv($b), 'bar:1 baz:1 foo:1', '... with the right elements';
}

{
    my $b = KeyBag.new(set <foo bar foo bar baz foo>);
    $b<bar> += 2;
    my $c = KeyBag.new($b);
    isa_ok $c, KeyBag, '&KeyBag.new given a KeyBag produces a KeyBag';
    is showkv($c), 'bar:3 baz:1 foo:1', '... with the right elements';
    $c<manning> = 10;
    is showkv($c), 'bar:3 baz:1 foo:1 manning:10', 'Creating a new element works';
    is showkv($b), 'bar:3 baz:1 foo:1', '... and does not affect the original KeyBag';
}

{
    my $b = KeyBag.new({ foo => 10, bar => 1, baz => 2});

    # .list is just the keys, as per TimToady: 
    # http://irclog.perlgeek.de/perl6/2012-02-07#i_5112706
    isa_ok $b.list.elems, 3, ".list returns 3 things";
    is $b.list.grep(Str).elems, 3, "... all of which are Str";

    isa_ok $b.pairs.elems, 3, ".pairs returns 3 things";
    is $b.pairs.grep(Pair).elems, 3, "... all of which are Pairs";
    is $b.pairs.grep({ .key ~~ Str }).elems, 3, "... the keys of which are Strs";
    is $b.pairs.grep({ .value ~~ Int }).elems, 3, "... and the values of which are Ints";

    is $b.iterator.grep(Pair).elems, 3, ".iterator yields three Pairs";
    is $b.iterator.grep({ .key ~~ Str }).elems, 3, "... the keys of which are Strs";
    is $b.iterator.grep({True}).elems, 3, "... and nothing else";
}

{
    my $b = KeyBag.new({ foo => 10000000000, bar => 17, baz => 42 });
    my $s;
    my $c;
    lives_ok { $s = $b.perl }, ".perl lives";
    isa_ok $s, Str, "... and produces a string";
    ok $s.chars < 1000, "... of reasonable length";
    lives_ok { $c = eval $s }, ".perl.eval lives";
    isa_ok $c, KeyBag, "... and produces a KeyBag";
    is showkv($c), showkv($b), "... and it has the correct values";
}

{
    my $b = KeyBag.new({ foo => 2, bar => 3, baz => 1 });
    my $s;
    lives_ok { $s = $b.Str }, ".Str lives";
    isa_ok $s, Str, "... and produces a string";
    #?rakudo todo 'KeyBag stringification'
    is $s.split(" ").sort.join(" "), "bar bar bar baz foo foo", "... which only contains bar baz and foo with the proper counts and separated by spaces";
}

{
    my $b = KeyBag.new({ foo => 10000000000, bar => 17, baz => 42 });
    my $s;
    lives_ok { $s = $b.gist }, ".gist lives";
    isa_ok $s, Str, "... and produces a string";
    ok $s.chars < 1000, "... of reasonable length";
    ok $s ~~ /foo/, "... which mentions foo";
    ok $s ~~ /bar/, "... which mentions bar";
    ok $s ~~ /baz/, "... which mentions baz";
}

# L<S02/Names and Variables/'C<%x> may be bound to'>

{
    my %b := KeyBag.new("a", "b", "c", "b");
    isa_ok %b, KeyBag, 'A KeyBag bound to a %var is a KeyBag';
    is showkv(%b), 'a:1 b:2 c:1', '...with the right elements';

    is %b<b>, 2, 'Single-key subscript (existing element)';
    is %b<santa>, 0, 'Single-key subscript (nonexistent element)';

    lives_ok { %b<a> = 4 }, "Assign to an element";
    is %b<a>, 4, "... and gets the correct value";
}

# L<S32::Containers/KeyBag/roll>

{
    my $b = KeyBag.new("a", "b", "b");

    my $a = $b.roll;
    ok $a eq "a" || $a eq "b", "We got one of the two choices";

    my @a = $b.roll(2);
    is +@a, 2, '.roll(2) returns the right number of items';
    is @a.grep(* eq 'a').elems + @a.grep(* eq 'b').elems, 2, '.roll(2) returned "a"s and "b"s';

    @a = $b.roll: 100;
    is +@a, 100, '.roll(100) returns 100 items';
    ok 2 < @a.grep(* eq 'a') < 75, '.roll(100) (1)';
    ok @a.grep(* eq 'a') + 2 < @a.grep(* eq 'b'), '.roll(100) (2)';
}

{
    my $b = KeyBag.new({"a" => 100000000000, "b" => 1});

    my $a = $b.roll;
    ok $a eq "a" || $a eq "b", "We got one of the two choices (and this was pretty quick, we hope!)";

    my @a = $b.roll: 100;
    is +@a, 100, '.roll(100) returns 100 items';
    ok @a.grep(* eq 'a') > 97, '.roll(100) (1)';
    ok @a.grep(* eq 'b') < 3, '.roll(100) (2)';
}

# L<S32::Containers/KeyBag/pick>

{
    my $b = KeyBag.new("a", "b", "b");

    my $a = $b.pick;
    ok $a eq "a" || $a eq "b", "We got one of the two choices";

    my @a = $b.pick(2);
    is +@a, 2, '.pick(2) returns the right number of items';
    ok @a.grep(* eq 'a').elems <= 1, '.pick(2) returned at most one "a"';
    is @a.grep(* eq 'b').elems, 2 - @a.grep(* eq 'a').elems, '.pick(2) and the rest are "b"';

    @a = $b.pick: *;
    is +@a, 3, '.pick(*) returns the right number of items';
    is @a.grep(* eq 'a').elems, 1, '.pick(*) (1)';
    is @a.grep(* eq 'b').elems, 2, '.pick(*) (2)';
}

{
    my $b = KeyBag.new({"a" => 100000000000, "b" => 1});

    my $a = $b.pick;
    ok $a eq "a" || $a eq "b", "We got one of the two choices (and this was pretty quick, we hope!)";

    my @a = $b.pick: 100;
    is +@a, 100, '.pick(100) returns 100 items';
    ok @a.grep(* eq 'a') > 98, '.pick(100) (1)';
    ok @a.grep(* eq 'b') < 2, '.pick(100) (2)';
}

#?niecza skip "Trait name not available on variables"
{
    my %h is KeyBag = a => 1, b => 0, c => 2;
    #?rakudo todo 'todo'
    nok %h.exists( 'b' ), '"b", initialized to zero, does not exist';
    #?rakudo todo 'todo'
    is +%h.keys, 2, 'Inititalization worked';
    is %h.elems, 3, '.elems works';
    #?rakudo todo 'todo'
    isa_ok %h<nonexisting>, Int, '%h<nonexisting> is an Int';
    #?rakudo todo 'todo'
    is %h<nonexisting>, 0, '%h<nonexisting> is 0';
}

#?niecza skip "Trait name not available on variables"
{
    my %h is KeyBag = a => 1, b => 0, c => 2;

    lives_ok { %h<c> = 0 }, 'can set an item to 0';
    #?rakudo todo 'todo'
    nok %h.exists( 'c' ), '"c", set to zero, does not exist';
    #?rakudo todo 'todo'
    is %h.elems, 1, 'one item left';
    #?rakudo todo 'todo'
    is %h.keys, ('a'), '... and the right one is gone';

    lives_ok { %h<c>++ }, 'can add (++) an item that was removed';
    #?rakudo todo 'todo'
    is %h.keys.sort, <a c>, '++ on an item reinstates it';
}

#?niecza skip "Trait name not available on variables"
{
    my %h is KeyBag = a => 1, c => 1;

    lives_ok { %h<c>++ }, 'can "add" (++) an existing item';
    is %h<c>, 2, '++ on an existing item increments the counter';
    is %h.keys.sort, <a c>, '++ on an existing item does not add a key';

    lives_ok { %h<a>-- }, 'can remove an item with decrement (--)';
    #?rakudo todo 'todo'
    is %h.keys, ('c'), 'decrement (--) removes items';
    #?rakudo todo 'todo'
    nok %h.exists( 'a' ), 'item is gone according to .exists too';
    is %h<a>, 0, 'removed item is zero';

    lives_ok { %h<a>-- }, 'remove a missing item lives';
    #?rakudo todo 'todo'
    is %h.keys, ('c'), 'removing missing item does not change contents';
    #?rakudo todo 'todo'
    is %h<a>, 0, 'item removed again is still zero';
}

#?niecza skip "Trait name not available on variables"
{
    my %h is KeyBag;
    lives_ok { %h = bag <a b c d c b> }, 'Assigning a Bag to a KeyBag';
    is %h.keys.sort.map({ $^k ~ ':' ~ %h{$k} }).join(' '),
        'a:1 b:2 c:2 d:1', '... works as expected';
}

# vim: ft=perl6
