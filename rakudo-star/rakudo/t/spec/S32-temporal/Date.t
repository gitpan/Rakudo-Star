use v6;
use Test;

# L<S32::Temporal/C<Date>>

plan 58;

# construction
{
    lives_ok { Date.new('2010-01-01') }, 'Date.new("2010-01-01")';
    lives_ok { Date.new(2010, 1, 1) }, 'List constructor';
    lives_ok { Date.new(:year(2010), :month(1), :day(1)) }, 'named arguments';
    lives_ok { Date.today }, 'Date.today';
    lives_ok { 
        my $dt = DateTime.new(:year(2010),:month(06), :day(04));   #OK octal
        Date.new($dt); 
    }, 'Date.new from DateTime';

    dies_ok { Date.new('malformed') }, 'obviously malformed string';
    dies_ok { Date.new('2010-00-23') }, 'dies on zero-based months';
    dies_ok { Date.new('2010-13-23') }, 'dies on month 13';
    dies_ok { Date.new('2010-01-00') }, 'dies on zero-based days';
    dies_ok { Date.new('2010-01-32') }, 'dies on day of month 32';
    dies_ok { Date.new('1999-02-29') }, 'dies on 29 February 1999';
    dies_ok { Date.new('1900-02-29') }, 'dies on 29 February 1900';
    lives_ok { Date.new('2000-02-29') }, '...but not 29 February 2000';

    isa_ok Date.new(2010, 01, 01), Date, 'Date.new() returns a Date';  #OK octal

    my $date = Date.new('1999-01-29');
    dies_ok { $date.clone(month => 2) }, 'dies on 29 February 1999 (Date.clone)';
    lives_ok { $date.clone(:month(2), :year(2000)) }, '..but not 29 February 2000 (Date.clone)';
}

# stringification
is ~Date.new(:year(2010), :month(3), :day(5)), '2010-03-05',
    'normal Date strinfies sanely';

# accessors

{
    my $d;

    ok ($d = Date.new('2000-02-28')), 'creation' or die "Something's very wrong";
    is $d.year, 2000,    'year';
    is $d.month,   2,    'month';
    is $d.day,    28,    'day';

    is $d.day-of-week,             1, 'Day of week';

    #is $d.is-leap-year,      Bool::True, 'leap year';
    is $d.days-in-month,          29, 'days in month';
}

# arithmetics

sub d($x) { Date.new($x); }
{
    is d('2010-04-12').succ, '2010-04-13', 'simple .succ';
    is d('2010-04-12').pred, '2010-04-11', 'simple .pred';

    is d('2000-02-28').succ, '2000-02-29', '.succ with leap year (1)';
    is d('2000-02-28').pred, '2000-02-27', '.pred with leap year (1)';

    is d('2000-02-29').succ, '2000-03-01', '.succ with leap year (2)';
    is d('2000-02-29').pred, '2000-02-28', '.pred with leap year (2)';
    is d('2000-03-01').pred, '2000-02-29', '.pred with leap year (3)';
}

# arithmetic operators
{
    is d('2000-02-28') + 7,  '2000-03-06', '+7';
    is d('2000-03-06') - 14, '2000-02-21', '-14';

    is d('2000-02-28') - d('2000-02-21'), 7, 'Difference of two dates';

    is d('2000-02-21') + 0, d('2000-02-21'), '+0';
    is d('2000-02-21') + -3, d('2000-02-21') - 3, '+ -3 == - 3';

    my ($a, $b, $c);
    # $a < $b < $c;
    $a = d('1963-07-02');
    $b = d('1964-02-01');
    $c = d('1964-02-02');

    ok  $a == $a, '== (+)';
    nok $a == $b, '== (-)';

    ok  $a != $c, '!= (+)';
    nok $a != $a, '!= (-)';

    ok  $b <= $b, '<= (+)';
    ok  $b <= $c, '<= (+)';
    nok $b <= $a, '<= (-)';

    nok $a <  $a, '<  (-)';
    ok  $a <  $b, '<  (+)';
    nok $b <  $a, '<  (-)';

    ok  $a >= $a, '>= (+)';
    ok  $b >= $a, '>= (+)';
    nok $b >= $c, '>= (-)';

    nok $a >  $a, '> (-)';
    ok  $b >  $a, '> (+)';
    nok $a >  $b, '> (-)';

    is $a cmp $a, Order::Same,     'cmp ( 0)';
    is $a cmp $b, Order::Increase, 'cmp (-1)';
    is $c cmp $a, Order::Decrease, 'cmp (+1)';


    is $a <=> $a, Order::Same,     '<=> ( 0)';
    is $a <=> $b, Order::Increase, '<=> (-1)';
    is $c <=> $a, Order::Decrease, '<=> (+1)';
}

ok d('2011-01-14') ~~ d('2011-01-14'), 'Can smartch Date objects';

done;
