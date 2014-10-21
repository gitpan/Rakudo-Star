use v6;

use Test;

# old: L<A12/"Declaration of Methods" /methods do not set the topic now/>
# (This is an an "update" section.)
# not mentioned explicitly in S12, but still true.

plan 2;

class Foo {
    method no_topic     { .echo }
    method topic ($_: ) { .echo }
    method echo         { "echo"  }
}

{
    my Foo $foo .= new;
    #?pugs todo 'outdated semantics'
    dies_ok { $foo.no_topic() }, '$_ is not set in methods...';
}

{
    my Foo $foo .= new;
    is $foo.topic(), "echo", '...unless $_ the invocant name is specified to be "$_"';
}

# vim: ft=perl6
