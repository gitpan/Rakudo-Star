use v6;
use MONKEY_TYPING;

use Test;
BEGIN { @*INC.push('t/spec/packages/') };
use Test::Util;
plan 38;

# old: L<S05/Return values from matches/"A match always returns a Match object" >
# L<S05/Match objects/"A match always returns a " >
{
  my $match = 'abd' ~~ m/ (a) (b) c || (\w) b d /;
  #?niecza todo 'match returns match object'
  isa_ok( $match, 'Match', 'Match object returned');
  #?niecza todo 'match returns match object'
  isa_ok( $/, 'Match', 'Match object assigned to $/');
  ok( $/ === $match, 'Same match objects');
}

# old: L<S05/Return values from matches/"The array elements of a C<Match> object are referred to" >
# L<S05/Accessing captured subpatterns/"The array elements of a " >
{
  'abd' ~~ m/ (a) (b) c || (\w) b d /;
  ok( $/[0] eq 'a', 'positional capture accessible');
  ok( @($/).[0] eq 'a', 'array context - correct number of positional captures');
  ok( @($/).elems == 1, 'array context - correct number of positional captures');
  ok( $/.list.elems == 1, 'the .list methods returns a list object');
}

# old: L<S05/Return values from matches/"When used as a hash, a C<Match> object" >
# L<S05/Match objects/"When used as a hash" >
{
  'abd' ~~ m/ <alpha> <alpha> c || <alpha> b d /;
  ok( $/<alpha> eq 'a', 'named capture accessible');
  ok( %($/).keys == 1, 'hash context - correct number of named captures');
  ok( %($/).<alpha> eq 'a', 'hash context - named capture accessible');
  ok( $/.hash.keys[0] eq 'alpha', 'the .hash method returns a hash object');
}

# RT 62530
#?rakudo skip 'augment'
#?niecza skip 'rule declaration outside of grammar'
{
  augment class Match { method keys () {return %(self).keys }; };
  rule a {H};
  "Hello" ~~ /<a>/;
  is $/.keys, 'a', 'get rule result';
  my $x = $/;
  is $x.keys, 'a', 'match copy should be same as match';
}

# RT #64946
{
    my regex o { o };
    "foo" ~~ /f<o=&o>+/;

    is ~$<o>, 'o o', 'match list stringifies like a normal list';
    ok $<o> ~~ Positional, '... and it is Positional';
    # I don't know what difference 'isa' makes, but it does.
    # Note that calling .WHAT (as in the original ticket) does not have
    # the same effect.
    is ~$<o>, 'o o', 'match list stringifies like a normal list AFTER "isa"';
}

# RT #64952
{
    'ab' ~~ /(.)+/;
    is $/[0][0], 'a', 'match element [0][0] from /(.)+/';
    is $/[0][1], 'b', 'match element [0][1] from /(.)+/';

    my @match = @( 'ab' ~~ /(.)+/ );
    #?rakudo 2 todo 'nom regression'
    is @match[0][0], 'a', 'match element [0][0] from /(.)+/ coerced';
    is @match[0][1], 'b', 'match element [0][1] from /(.)+/ coerced';
}

# RT #64948
{
    ok %( 'foo' ~~ /<alpha> oo/ ).exists('alpha'),
       'Match coerced to Hash says match exists';
}

# This is similar to a test in S05-interpolation/regex-in-variable.t
#?niecza todo 'match with non-existent capture does not match'
nok 'aa' ~~ /(.)$1/, 'match with non-existent capture does not match';
#?rakudo todo 'RT 70007'
#?niecza todo 'eek'
is_run( q{'aa' ~~ /(.)$1/},
        {
            status => 0,
            out    => '',
            err    => rx/undef/,
        },
        'match with non-existent capture emits a warning' );

# RT #66252
{
    $_ = 'RT 66252';
    m/(R.)/;
    #?niecza todo 'Match object in $/ after match in void context'
    isa_ok $/, 'Match', 'Match object in $/ after match in void context';
    is $/, 'RT', 'Matched as intended in void context';
}

# RT #70003
{
    'abc' ~~ /a/;
    is ($/.orig).rindex('a'), 0, 'rindex() works on $/.orig';
    is ($/.orig).rindex('a', 2), 0, 'rindex() works on $/.orig';
}

# RT #71362
#?rakudo skip 'binding to $/'
{
    $/ := 'foobar';
    is $0, 'foobar', '$0 works like $/[0], even for non-Match objects';
    nok $1.defined, '$1 is not defined';
}

# RT #72956
#?niecza skip 'Unsupported use of $/ variable as input record separator'
{
    $/ = Any;
    lives_ok { $0 },
        '$0 accessible when $/ is undefined';
    ok $0 === Any,
        '$0 is Any when $/ is undefined';
    nok $0.defined, '$0 is undefined';
}

# RT #77160
{
    ok 'abc' ~~ /(.)+/, 'regex sanity';
    my $x = 0;
    $x++ for $/.list;
    #?rakudo todo 'nom regression'
    is $x, 1, '$/.list does not flatten quantified subcaptures';

    ok 'abc' ~~ /(.)**2 (.)/, 'regex sanity';
    $x = 0;
    $x++ for $/.list;
    #?rakudo todo 'nom regression'
    is $x, 2, '$/.list does not flattens subcaptures';
}

# RT 74180
{
    my $s;
    try { $s = eval '"foo" ~~ /(foo)/; "$0a"' };
    ok not $!, 'alphabetic characters can follow digits in $0 variable in interpolation';
    is $s, 'fooa', 'alphabetic characters follows $0 interpolated value';
}

done;

# vim: ft=perl6
