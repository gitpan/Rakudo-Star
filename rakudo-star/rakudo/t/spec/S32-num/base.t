use v6;
use Test;

plan 12;

is  0.base(8),  '0',        '0.base(something)';
# RT #112872
is  0.base(2),  '0',        '0.base(2)';
is 42.base(10), '42',       '42.base(10)';
is 42.base(16), '2A',       '42.base(16)';
is 42.base(2) , '101010',   '42.base(2)';
is 35.base(36), 'Z',        '35.base(36)';
is 36.base(36), '10',       '36.base(36)';
is (-12).base(16), '-C',    '(-12).base(16)';

# RT 112900
#?niecza 4 skip "Rat.base NYI"
is (1/10000000000).base(3),
   '0.0000000000000000000010',   # is the trailing zero correct?
   '(1/10000000000).base(3) (RT 112900)';
is (3.25).base(16), '3.4',  '(3.25).base(16)';
is (10.5).base(2), '1010.1', '(10.5).base(2)';
is (-3.5).base(16), '-3.8', '(-3.5).base(16)';
#TODO more non-integer tests?
