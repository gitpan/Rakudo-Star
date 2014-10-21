use v6;
use Test;

plan 12;

# L<S14/Traits/>
{
    role description {
        has $.description is rw;
    }

    multi trait_mod:<is>(Routine $code, description,  $arg) {
        $code does description($arg)
    }
    multi trait_mod:<is>(Routine $code, description) {
        $code does description('missing description!')
    }
    multi trait_mod:<is>(Routine $code, Str :$described!) {
        $code does description($described);
    }
    multi trait_mod:<is>(Routine $code, Bool :$described!) {
        $code does description("missing description!");
    }


    sub answer() is description('computes the answer') { 42 }
    sub faildoc() is description { "fail" }
    is answer(), 42, 'can call sub that has had a trait applied to it by role name with arg';
    is &answer.description, 'computes the answer',  'description role applied and set with argument';
    is faildoc(), "fail", 'can call sub that has had a trait applied to it by role name without arg';
    is &faildoc.description, 'missing description!', 'description role applied without argument';

    sub cheezburger is described("tasty") { "nom" }
    sub lolcat is described { "undescribable" }

    is cheezburger(), "nom", 'can call sub that has had a trait applied to it by named param with arg';
    is &cheezburger.description, 'tasty',  'named trait handler applied other role set with argument';
    is lolcat(), "undescribable", 'can call sub that has had a trait applied to it by named param without arg';
    is &lolcat.description, 'missing description!', 'named trait handler applied other role without argument';
}

{
    my $recorder = '';
    multi trait_mod:<is>(Routine $c, :$woowoo!) {
        $c.wrap: sub {
            $recorder ~= 'wrap';
        }
    }
    sub foo is woowoo { };
    lives_ok &foo, 'Can call subroutine that was wrapped by a trait';
    #?rakudo todo 'trait mod / .wrap interaction'
    is $recorder, 'wrap', 'and the wrapper has been called once';
}

# RT 112664
{
    multi trait_mod:<is>($m, :$a!) {
	multi y(|$) { my $x = $m }
	$m.wrap(&y)
    }
    sub rt112664 is a {}

    lives_ok { rt112664 },
    '[BUG] multi without proto gets wrong lexical lookup chain (RT 112664)';
}

# RT 74092
{
    try { eval 'sub yulia is krassivaya { }' };
    ok "$!" ~~ /'trait_mod:<is>'/,
        'declaration of a sub with an unknown trait mentions trait_mod:<is> in dispatch error';
}

done();

# vim: ft=perl6
