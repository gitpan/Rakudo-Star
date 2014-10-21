use v6;
use Test;

plan 9;

#L<S06/Operator overloading>

# Define operator, check it works.
sub infix:<wtf>($a, $b) { $a ~ "WTF" ~ $b };
is 'OMG' wtf 'BBQ', 'OMGWTFBBQ', 'basic sanity';

# Assignment meta-op.
my $a = 'OMG';
$a wtf= 'BBQ';
is $a, 'OMGWTFBBQ', 'assignment meta-op';

# Reduce meta-op.
is ([wtf] <OMG BBQ PONIES>), 'OMGWTFBBQWTFPONIES', 'reduce meta-op generated';

# Reverse meta-op.
is 'BBQ' Rwtf 'OMG', 'OMGWTFBBQ', 'reverse meta-op generated';

# Cross meta-op.
is ~('OMG','BBQ' Xwtf 'OMG','BBQ'), 'OMGWTFOMG OMGWTFBBQ BBQWTFOMG BBQWTFBBQ',
    'cross meta-op generated';

# Hyper meta-op (todo: unicode variants, check variants apply correct constraints)
is ~(('OMG','BBQ') >>wtf<< ('BBQ','OMG')), 'OMGWTFBBQ BBQWTFOMG', '>>...<< hyper generated';
is ~(('OMG','BBQ') <<wtf<< ('BBQ','OMG')), 'OMGWTFBBQ BBQWTFOMG', '<<...<< hyper generated';
is ~(('OMG','BBQ') >>wtf>> ('BBQ','OMG')), 'OMGWTFBBQ BBQWTFOMG', '>>...>> hyper generated';
is ~(('OMG','BBQ') <<wtf>> ('BBQ','OMG')), 'OMGWTFBBQ BBQWTFOMG', '<<...>> hyper generated';

# vim: ft=perl6
