use v6;
use Test;
plan 7;

# test relation between attributes and inheritance

class A {
    has $.a;
}

class B is A {
    method accessor {
        return $.a
    }
}

my $o;
lives_ok {$o = B.new(a => 'blubb') }, 'Can initialize inherited attribute';
is $o.accessor, 'blubb',              'accessor can use inherited attribute';

class Artie61500 {
    has $!p = 61500;
}
#?pugs todo
eval_dies_ok 'class Artay61500 is Artie61500 { method bomb { return $!p } }',
    'Compile error for subclass to access private attribute of parent';

class Parent {
    has $!priv = 23;
    method get { $!priv };
    has $.public is rw;
    method report() { $!public }
}

class Child is Parent {
    has $!priv = 42;
    has $.public is rw;
}

#?pugs todo
is Child.new().Parent::get(), 23,
   'private attributes do not leak from child to parent class (1)';

#?pugs todo
is Child.new().get(), 23,
   'private attributes do not leak from child to parent class (2)';

my $child = Child.new();
$child.public = 5;
#?pugs todo
nok $child.report.defined,
    'If parent and child have an attribute of the same name, they do not share storage location';

# RT #61500
#?pugs todo
{
    eval_dies_ok 'class A { has $!foo = 7 }; class B is A { method x { say $!foo } }; B.new.x', 'rt 61500';
}

# vim: ft=perl6
