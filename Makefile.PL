use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'Rakudo-Star',
  VERSION_FROM => 'lib/Rakudo/Star.pm',
  AUTHOR => 'mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>',
);

sub MY::postamble { <<'END' }

INSTALLRAKUDO=$(INSTALLSITEARCH)/Rakudo/Star/Install

all :: rakudo
	touch blib/arch/auto/Rakudo-Star/force-arch

rakudo-star/Makefile :
	cd rakudo-star; $(PERL) Configure.pl --gen-parrot --prefix=$(INSTALLRAKUDO)

rakudo : rakudo-star/Makefile
	cd rakudo-star; mkdir -p rakudo/blib/Perl6 rakudo/blib/QPerl6; make all

install :: rakudoinstall

rakudoinstall :
	cd rakudo-star; make install
END
