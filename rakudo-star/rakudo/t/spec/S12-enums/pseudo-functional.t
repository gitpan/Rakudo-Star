use v6;
use Test;

plan 11;

# L<S12/Anonymous Mixin Roles using C<but> or C<does>/enumeration supplies the type name as a coercion>

enum day (:Sun(1), 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');

is day(Tue), day(3), 'day(Tue) same as day(3)';

{
    my $today_tue = 'Today' but day(Tue);
    my $today_3   = 'Today' but day(3);

    is $today_tue, $today_3, 'day(Tue) same as day(3) in variables';
}

my $x = 'Today' but day(Tue);

ok $x.day ~~ day,  'day(Tue).day is a day';
ok $x.day == Tue,  'day(Tue) == Tue';
lives_ok { day($x) }, 'day($x) lives';
ok $x.Tue,         'day(Tue).Tue';

ok $x.day != Wed, 'day(Tue) != Wed';

nok $x.does(Wed), '! day(Tue).does(Wed)';
nok $x.Wed,       '! day(Tue).does(Wed)';
nok 8.does(day),  '8 is not a day';
nok 8 ~~ day,     '8 does not match day';

# vim: ft=perl6
