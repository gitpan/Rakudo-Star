use v6;

use Test;

plan 9;

# L<S32::Str/Str/ucfirst>

is tc("hello world"), "Hello world", "simple";
is tc(""),            "",            "empty string";
is tc("üüüü"),        "Üüüü",        "umlaut";
is tc("óóóó"),        "Óóóó",        "accented chars";
#?pugs todo
is tc('ßß'),          'Ssß',         'sharp s => Ss';
#?pugs todo
is tc('ǉ'),           'ǈ',           'lj => Lj (in one character)';
is 'abc'.tc,          'Abc',         'method form of title case';
#?rakudo todo 'leaving the rest alone'
is 'aBcD'.tc,         'ABcD',        'tc only modifies first character';
is "\x1044E\x10427".tc, "\x10426\x10427", 'tc works on codepoints greater than 0xffff';


# vim: ft=perl6
