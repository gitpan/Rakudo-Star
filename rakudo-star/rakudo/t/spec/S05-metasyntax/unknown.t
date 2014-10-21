use v6;
use Test;

plan 11;

# L<S05/Simplified lexical parsing of patterns/not all non-identifier glyphs are currently meaningful as metasyntax>

# testing unknown metasyntax handling

eval_dies_ok('"aa!" ~~ /!/', '"!" is not valid metasyntax');
lives_ok({"aa!" ~~ /\!/}, 'escaped "!" is valid');
lives_ok({"aa!" ~~ /'!'/}, 'quoted "!" is valid');

eval_dies_ok('"aa!" ~~ /\a/', 'escaped "a" is not valid metasyntax');
lives_ok({"aa!" ~~ /a/}, '"a" is valid');
lives_ok({"aa!" ~~ /'a'/}, 'quoted "a" is valid');

# used to be a pugs bug

{
    my rule foo { \{ };
    ok '{'  ~~ /<foo>/, '\\{ in a rule (+)';
    ok '!' !~~ /<foo>/, '\\{ in a rule (-)';
}

# RT #74832
{
    dies_ok {eval('/ a+ + /')}, 'Cannot parse regex a+ +';
    #?rakudo todo 'RT 74832'
    #?niecza todo
    ok "$!" ~~ /:i quantif/, 'error message mentions quantif{y,ier}';
}

# RT 77110
{
    try { eval '$_ = "0"; s/-/1/;' };
    ok "$!" ~~ /'Unrecognized regex metacharacter -'/,
        'unescaped "-" is not valid regular expression metasyntax';
}

# vim: ft=perl6
