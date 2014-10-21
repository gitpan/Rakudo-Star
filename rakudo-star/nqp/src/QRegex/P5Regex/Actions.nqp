class QRegex::P5Regex::Actions is HLL::Actions {
    method TOP($/) {
        make buildsub($<nibbler>.ast);
    }

    method nibbler($/) { make $<termaltseq>.ast }

    method termaltseq($/) {
        my $qast := $<termish>[0].ast;
        if +$<termish> > 1 {
            $qast := QAST::Regex.new( :rxtype<altseq>, :node($/) );
            for $<termish> { $qast.push($_.ast); }
        }
        make $qast;
    }

    method termish($/) {
        my $qast := QAST::Regex.new( :rxtype<concat>, :node($/) );
        my $lastlit := 0;
        for $<noun> {
            my $ast := $_.ast;
            if $ast {
                if $lastlit && $ast.rxtype eq 'literal'
                        && !QAST::Node.ACCEPTS($ast[0]) {
                    $lastlit[0] := $lastlit[0] ~ $ast[0];
                }
                else {
                    $qast.push($_.ast);
                    $lastlit := $ast.rxtype eq 'literal' 
                                && !QAST::Node.ACCEPTS($ast[0])
                                  ?? $ast !! 0;
                }
            }
        }
        make $qast;
    }

    method quantified_atom($/) {
        my $qast := $<atom>.ast;
        if $<quantifier> {
            my $ast := $<quantifier>[0].ast;
            $ast.unshift($qast);
            $qast := $ast;
        }
        $qast.backtrack('r') if $qast && !$qast.backtrack && %*RX<r>;
        make $qast;
    }

    method atom($/) {
        if $<metachar> {
            make $<metachar>.ast;
        }
        elsif $<esc> {
            my $qast := QAST::Regex.new( ~$<esc>, :rxtype<literal>, :node($/));
            make $qast;
        }
        else {
            my $qast := QAST::Regex.new( ~$/, :rxtype<literal>, :node($/));
            $qast.subtype('ignorecase') if %*RX<i>;
            make $qast;
        }
    }
    
    method p5metachar:sym<bs>($/) {
        make $<backslash>.ast;
    }
    
    method p5metachar:sym<.>($/) {
        make QAST::Regex.new( :rxtype<cclass>, :subtype<.>, :node($/) );
    }

    method p5metachar:sym<^>($/) {
        make QAST::Regex.new( :rxtype<anchor>, :subtype<bos>, :node($/) );
    }

    method p5metachar:sym<$>($/) {
        make QAST::Regex.new(
            :rxtype('concat'),
            QAST::Regex.new(
                :rxtype('quant'), :min(0), :max(1),
                QAST::Regex.new( :rxtype('literal'), "\n" )
            ),
            QAST::Regex.new( :rxtype<anchor>, :subtype<eos>, :node($/) )
        );
    }
    
    method p5metachar:sym<[ ]>($/) {
        make $<cclass>.ast;
    }
    
    method cclass($/) {
        my $str := '';
        my $qast;
        my @alts;
        for $<charspec> {
            if $_[1] {
                my $node;
                my $lhs;
                my $rhs;
                if $_[0]<backslash> {
                    $node := $_[0]<backslash>.ast;
                    $/.CURSOR.panic("Illegal range endpoint in regex: " ~ ~$_)
                        if $node.rxtype ne 'literal' && $node.rxtype ne 'enumcharlist'
                            || $node.negate || nqp::chars($node[0]) != 1;
                    $lhs := $node[0];
                }
                else {
                    $lhs := ~$_[0][0];
                }
                if $_[1][0]<backslash> {
                    $node := $_[1][0]<backslash>.ast;
                    $/.CURSOR.panic("Illegal range endpoint in regex: " ~ ~$_)
                        if $node.rxtype ne 'literal' && $node.rxtype ne 'enumcharlist'
                            || $node.negate || nqp::chars($node[0]) != 1;
                    $rhs := $node[0];
                }
                else {
                    $rhs := ~$_[1][0][0];
                }
                my $ord0 := nqp::ord($lhs);
                my $ord1 := nqp::ord($rhs);
                $/.CURSOR.panic("Illegal reversed character range in regex: " ~ ~$_)
                    if $ord0 > $ord1;
                $str := nqp::concat($str, nqp::chr($ord0++)) while $ord0 <= $ord1;
            }
            elsif $_[0]<backslash> {
                my $bs := $_[0]<backslash>.ast;
                $bs.negate(!$bs.negate) if $<sign> eq '^';
                @alts.push($bs);
            }
            else { $str := $str ~ ~$_[0]; }
        }
        @alts.push(QAST::Regex.new( $str, :rxtype<enumcharlist>, :node($/), :negate( $<sign> eq '^' ) ))
            if nqp::chars($str);
        $qast := +@alts == 1 ?? @alts[0] !!
            $<sign> eq '^' ??
                QAST::Regex.new( :rxtype<concat>, :node($/),
                    QAST::Regex.new( :rxtype<conj>, :subtype<zerowidth>, |@alts ), 
                    QAST::Regex.new( :rxtype<cclass>, :subtype<.> ) ) !!
                QAST::Regex.new( :rxtype<altseq>, |@alts );
        make $qast;
    }
    
    method p5backslash:sym<s>($/) {
        make QAST::Regex.new(:rxtype<cclass>, '.CCLASS_WHITESPACE', 
                             :subtype($<sym> eq 'n' ?? 'nl' !! ~$<sym>),
                             :negate($<sym> le 'Z'), :node($/));
    }

    method p5backslash:sym<b>($/) {
        make QAST::Regex.new(:rxtype<subrule>, :subtype<method>,
                             :node($/), PAST::Node.new('wb'), 
                             :negate($<sym> eq 'B'), :name('') );
    }
    
    method p5backslash:sym<misc>($/) {
        my $qast := QAST::Regex.new( ~$/ , :rxtype('literal'), :node($/) );
        make $qast;
    }
    
    method p5quantifier:sym<*>($/) {
        my $qast := QAST::Regex.new( :rxtype<quant>, :min(0), :max(-1), :node($/) );
        make quantmod($qast, $<quantmod>);
    }

    method p5quantifier:sym<+>($/) {
        my $qast := QAST::Regex.new( :rxtype<quant>, :min(1), :max(-1), :node($/) );
        make quantmod($qast, $<quantmod>);
    }

    method p5quantifier:sym<?>($/) {
        my $qast := QAST::Regex.new( :rxtype<quant>, :min(0), :max(1), :node($/) );
        make quantmod($qast, ~$<quantmod>);
    }
    
    method p5quantifier:sym<{ }>($/) {
        my $qast;
        $qast := QAST::Regex.new( :rxtype<quant>, :min(+$<start>), :node($/) );
        if $<end>      { $qast.max(+$<end>[0]); }
        elsif $<comma> { $qast.max(-1); }
        else           { $qast.max($qast.min); }
        make quantmod($qast, $<quantmod>);
    }
    
    sub quantmod($ast, $mod) {
        if    $mod eq '?' { $ast.backtrack('f') }
        elsif $mod eq '+' { $ast.backtrack('g') }
        $ast;
    }


    # XXX Below here copied from p6regex; needs review

    method metachar:sym<ws>($/) {
        my $qast := %*RX<s>
                    ?? QAST::Regex.new(PAST::Node.new('ws'), :rxtype<ws>, :subtype<method>, :node($/))
                    !! 0;
        make $qast;
    }

    method metachar:sym<[ ]>($/) {
        make $<nibbler>.ast;
    }

    method metachar:sym<( )>($/) {
        my $subpast := PAST::Node.new(buildsub($<nibbler>.ast, :anon(1)));
        my $qast := QAST::Regex.new( $subpast, $<nibbler>.ast, :rxtype('subrule'),
                                     :subtype('capture'), :node($/) );
        make $qast;
    }

    method metachar:sym<'>($/) {
        my $quote := $<quote_EXPR>.ast;
        if PAST::Val.ACCEPTS($quote) { $quote := $quote.value; }
        if QAST::SVal.ACCEPTS($quote) { $quote := $quote.value; }
        my $qast := QAST::Regex.new( $quote, :rxtype<literal>, :node($/) );
        $qast.subtype('ignorecase') if %*RX<i>;
        make $qast;
    }

    method metachar:sym<">($/) {
        my $quote := $<quote_EXPR>.ast;
        if PAST::Val.ACCEPTS($quote) { $quote := $quote.value; }
        if QAST::SVal.ACCEPTS($quote) { $quote := $quote.value; }
        my $qast := QAST::Regex.new( $quote, :rxtype<literal>, :node($/) );
        $qast.subtype('ignorecase') if %*RX<i>;
        make $qast;
    }

    method metachar:sym<lwb>($/) {
        make QAST::Regex.new( :rxtype<anchor>, :subtype<lwb>, :node($/) );
    }

    method metachar:sym<rwb>($/) {
        make QAST::Regex.new( :rxtype<anchor>, :subtype<rwb>, :node($/) );
    }

    method metachar:sym<from>($/) {
        make QAST::Regex.new( :rxtype<subrule>, :subtype<capture>,
            :backtrack<r>,
            :name<$!from>, PAST::Node.new('!LITERAL', ''), :node($/) );
    }

    method metachar:sym<to>($/) {
        make QAST::Regex.new( :rxtype<subrule>, :subtype<capture>,
            :backtrack<r>,
            :name<$!to>, PAST::Node.new('!LITERAL', ''), :node($/) );
    }

    method metachar:sym<assert>($/) {
        make $<assertion>.ast;
    }

    method metachar:sym<var>($/) {
        my $qast;
        my $name := $<pos> ?? +$<pos> !! ~$<name>;
        if $<quantified_atom> {
            $qast := $<quantified_atom>[0].ast;
            if $qast.rxtype eq 'quant' && $qast[0].rxtype eq 'subrule' {
                self.subrule_alias($qast[0], $name);
            }
            elsif $qast.rxtype eq 'subrule' { 
                self.subrule_alias($qast, $name); 
            }
            else {
                $qast := QAST::Regex.new( $qast, :name($name), 
                                          :rxtype<subcapture>, :node($/) );
            }
        }
        else {
            $qast := QAST::Regex.new( PAST::Node.new('!BACKREF', $name),
                         :rxtype<subrule>, :subtype<method>, :node($/));
        }
        make $qast;
    }

    method backslash:sym<e>($/) {
        my $qast := QAST::Regex.new( "\c[27]", :rxtype('enumcharlist'),
                        :negate($<sym> eq 'E'), :node($/) );
        make $qast;
    }

    method backslash:sym<f>($/) {
        my $qast := QAST::Regex.new( "\c[12]", :rxtype('enumcharlist'),
                        :negate($<sym> eq 'F'), :node($/) );
        make $qast;
    }

    method backslash:sym<h>($/) {
        my $qast := QAST::Regex.new( "\x[09,20,a0,1680,180e,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,200a,202f,205f,3000]", :rxtype('enumcharlist'),
                        :negate($<sym> eq 'H'), :node($/) );
        make $qast;
    }

    method backslash:sym<r>($/) {
        my $qast := QAST::Regex.new( "\r", :rxtype('enumcharlist'),
                        :negate($<sym> eq 'R'), :node($/) );
        make $qast;
    }

    method backslash:sym<t>($/) {
        my $qast := QAST::Regex.new( "\t", :rxtype('enumcharlist'),
                        :negate($<sym> eq 'T'), :node($/) );
        make $qast;
    }

    method backslash:sym<v>($/) {
        my $qast := QAST::Regex.new( "\x[0a,0b,0c,0d,85,2028,2029]",
                        :rxtype('enumcharlist'),
                        :negate($<sym> eq 'V'), :node($/) );
        make $qast;
    }

    method backslash:sym<o>($/) {
        my $octlit :=
            HLL::Actions.ints_to_string( $<octint> || $<octints><octint> );
        make $<sym> eq 'O'
             ?? QAST::Regex.new( $octlit, :rxtype('enumcharlist'),
                                  :negate(1), :node($/) )
             !! QAST::Regex.new( $octlit, :rxtype('literal'), :node($/) );
    }

    method backslash:sym<x>($/) {
        my $hexlit :=
            HLL::Actions.ints_to_string( $<hexint> || $<hexints><hexint> );
        make $<sym> eq 'X'
             ?? QAST::Regex.new( $hexlit, :rxtype('enumcharlist'),
                                  :negate(1), :node($/) )
             !! QAST::Regex.new( $hexlit, :rxtype('literal'), :node($/) );
    }

    method backslash:sym<c>($/) {
        make QAST::Regex.new( $<charspec>.ast, :rxtype('literal'), :node($/) );
    }

    method assertion:sym<?>($/) {
        my $qast;
        if $<assertion> {
            $qast := $<assertion>.ast;
            $qast.subtype('zerowidth');
        }
        else {
            $qast := QAST::Regex.new( :rxtype<anchor>, :subtype<pass>, :node($/) );
        }
        make $qast;
    }

    method assertion:sym<!>($/) {
        my $qast;
        if $<assertion> {
            $qast := $<assertion>.ast;
            $qast.negate( !$qast.negate );
            $qast.subtype('zerowidth');
        }
        else {
            $qast := QAST::Regex.new( :rxtype<anchor>, :subtype<fail>, :node($/) );
        }
        make $qast;
    }

    method assertion:sym<method>($/) {
        my $qast := $<assertion>.ast;
        $qast.subtype('method');
        $qast.name('');
        make $qast;
    }

    method assertion:sym<name>($/) {
        my $name := ~$<longname>;
        my $qast;
        if $<assertion> {
            $qast := $<assertion>[0].ast;
            self.subrule_alias($qast, $name);
        }
        elsif $name eq 'sym' {
            my $loc := nqp::index(%*RX<name>, ':sym<');
            $loc := nqp::index(%*RX<name>, ':sym«')
                if $loc < 0;
            my $rxname := pir::chopn__Ssi(nqp::substr(%*RX<name>, $loc + 5), 1);
            $qast := QAST::Regex.new(:name('sym'), :rxtype<subcapture>, :node($/),
                QAST::Regex.new(:rxtype<literal>, $rxname, :node($/)));
        }
        else {
            $qast := QAST::Regex.new(:rxtype<subrule>, :subtype<capture>,
                                     :node($/), PAST::Node.new($name), 
                                     :name($name) );
            if $<arglist> {
                for $<arglist>[0].ast.list { $qast[0].push( $_ ) }
            }
            elsif $<nibbler> {
                $name eq 'after' ??
                    $qast[0].push(buildsub(self.flip_ast($<nibbler>[0].ast), :anon(1))) !!
                    $qast[0].push(buildsub($<nibbler>[0].ast, :anon(1)));
            }
        }
        make $qast;
    }
    
    method arg($/) {
        make $<quote_EXPR> ?? $<quote_EXPR>.ast !! +$<val>;
    }

    method arglist($/) {
        my $past := PAST::Op.new( :pasttype('list') );
        for $<arg> { $past.push( $_.ast ); }
        make $past;
    }

    method mod_internal($/) {
        my $n := $<n>[0] gt '' ?? +$<n>[0] !! 1;
        %*RX{ ~$<mod_ident><sym> } := $n;
        make 0;
    }

    our sub buildsub($qast, $block = PAST::Block.new(:blocktype<method>), :$anon) {
        my $blockid := $block.subid;
        my $hashpast := PAST::Op.new( :pasttype<hash> );
        for capnames($qast, 0) {
            if $_.key gt '' { 
                $hashpast.push($_.key); 
                $hashpast.push(
                    nqp::iscclass(pir::const::CCLASS_NUMERIC, $_.key, 0) + ($_.value > 1) * 2); 
            }
        }
        my $initpast := PAST::Stmts.new();
        my $capblock := PAST::Block.new( :hll<nqp>, :namespace(['Sub']), :lexical(0),
                                         :name($blockid ~ '_caps'),  $hashpast );
        $initpast.push(PAST::Stmt.new($capblock));

        my $nfapast := QRegex::NFA.new.addnode($qast).past;
        if $nfapast {
            my $nfablock := PAST::Block.new( 
                                :hll<nqp>, :namespace(['Sub']), :lexical(0),
                                :name($blockid ~ '_nfa'), $nfapast);
            $initpast.push(PAST::Stmt.new($nfablock));
        }
        alt_nfas($qast, $blockid, $initpast);

        unless $block.symbol('$¢') {
            $initpast.push(PAST::Var.new(:name<$¢>, :scope<lexical>, :isdecl(1)));
            $block.symbol('$¢', :scope<lexical>);
        }

        $block<orig_qast> := $qast;
        
        $qast := QAST::Regex.new( :rxtype<concat>,
                     QAST::Regex.new( :rxtype<scan> ),
                     $qast,
                     ($anon ??
                          QAST::Regex.new( :rxtype<pass> ) !!
                          QAST::Regex.new( :rxtype<pass>, :name(%*RX<name>) )));
        $block.push($initpast);
        $block.push(PAST::QAST.new($qast));
        $block;
    }
    
    our sub qbuildsub($qast, $block = QAST::Block.new(), :$anon, :$addself) {
        my $blockid := $block.cuid;
        my $hashpast := QAST::Op.new( :op<hash> );
        for capnames($qast, 0) {
            if $_.key gt '' { 
                $hashpast.push(QAST::SVal.new( :value($_.key) )); 
                $hashpast.push(QAST::IVal.new( :value(
                    nqp::iscclass(pir::const::CCLASS_NUMERIC, $_.key, 0) + ($_.value > 1) * 2) )); 
            }
        }
        my $initpast := QAST::Stmts.new();
        if $addself {
            $initpast.push(QAST::Var.new( :name('self'), :scope('local'), :decl('param') ));
        }
        my $capblock := QAST::BlockMemo.new( :name($blockid ~ '_caps'),  $hashpast );
        $initpast.push(QAST::Stmt.new($capblock));

        my $nfapast := QRegex::NFA.new.addnode($qast).qast;
        if $nfapast {
            my $nfablock := QAST::BlockMemo.new( :name($blockid ~ '_nfa'), $nfapast);
            $initpast.push(QAST::Stmt.new($nfablock));
        }
        qalt_nfas($qast, $blockid, $initpast);

        unless $block.symbol('$¢') {
            $initpast.push(QAST::Var.new(:name<$¢>, :scope<lexical>, :decl('var')));
            $block.symbol('$¢', :scope<lexical>);
        }

        $block<orig_qast> := $qast;
        
        $qast := QAST::Regex.new( :rxtype<concat>,
                     QAST::Regex.new( :rxtype<scan> ),
                     $qast,
                     ($anon ??
                          QAST::Regex.new( :rxtype<pass> ) !!
                          QAST::Regex.new( :rxtype<pass>, :name(%*RX<name>) )));
        $block.push($initpast);
        $block.push($qast);
        $block;
    }

    sub capnames($ast, $count) {
        my %capnames;
        my $rxtype := $ast.rxtype;
        if $rxtype eq 'concat' {
            for $ast.list {
                my %x := capnames($_, $count);
                for %x { %capnames{$_.key} := +%capnames{$_.key} + $_.value; }
                $count := %x{''};
            } 
        }
        elsif $rxtype eq 'altseq' || $rxtype eq 'alt' {
            my $max := $count;
            for $ast.list {
                my %x := capnames($_, $count);
                for %x {
                    %capnames{$_.key} := +%capnames{$_.key} < 2 && %x{$_.key} == 1 ?? 1 !! 2;
                }
                $max := %x{''} if %x{''} > $max;
            }
            $count := $max;
        }
        elsif $rxtype eq 'subrule' && $ast.subtype eq 'capture' {
            my $name := $ast.name;
            if $name eq '' { $name := $count; $ast.name($name); }
            my @names := nqp::split('=', $name);
            for @names {
                if $_ eq '0' || $_ > 0 { $count := $_ + 1; }
                %capnames{$_} := 1;
            }
        }
        elsif $rxtype eq 'subcapture' {
            for nqp::split(' ', $ast.name) {
                if $_ eq '0' || $_ > 0 { $count := $_ + 1; }
                %capnames{$_} := 1;
            }
            my %x := capnames($ast[0], $count);
            for %x { %capnames{$_.key} := +%capnames{$_.key} + %x{$_.key} }
            $count := %x{''};
        }
        elsif $rxtype eq 'quant' {
            my %astcap := capnames($ast[0], $count);
            for %astcap { %capnames{$_} := 2 }
            $count := %astcap{''};
        }
        %capnames{''} := $count;
        nqp::deletekey(%capnames, '$!from');
        nqp::deletekey(%capnames, '$!to');
        %capnames;
    }
    
    sub alt_nfas($ast, $subid, $initpast) {
        my $rxtype := $ast.rxtype;
        if $rxtype eq 'alt' {
            my $nfapast := PAST::Op.new( :pasttype('list') );
            $ast.name(PAST::Node.unique('alt_nfa_') ~ '_' ~ ~nqp::time_n());
            for $ast.list {
                alt_nfas($_, $subid, $initpast);
                $nfapast.push(QRegex::NFA.new.addnode($_).past(:non_empty));
            }
            my $nfablock := PAST::Block.new(
                                :hll<nqp>, :namespace(['Sub']), :lexical(0),
                                :name($subid ~ '_' ~ $ast.name), $nfapast);
            $initpast.push(PAST::Stmt.new($nfablock));
        }
        elsif $rxtype eq 'subcapture' || $rxtype eq 'quant' {
            alt_nfas($ast[0], $subid, $initpast)
        }
        elsif $rxtype eq 'concat' || $rxtype eq 'altseq' || $rxtype eq 'conj' || $rxtype eq 'conjseq' {
            for $ast.list { alt_nfas($_, $subid, $initpast) }
        }
    }
    
    sub qalt_nfas($ast, $subid, $initpast) {
        my $rxtype := $ast.rxtype;
        if $rxtype eq 'alt' {
            my $nfapast := QAST::Op.new( :op('list') );
            $ast.name(QAST::Node.unique('alt_nfa_') ~ '_' ~ ~nqp::time_n());
            for $ast.list {
                qalt_nfas($_, $subid, $initpast);
                $nfapast.push(QRegex::NFA.new.addnode($_).qast(:non_empty));
            }
            my $nfablock := QAST::BlockMemo.new( :name($subid ~ '_' ~ $ast.name), $nfapast);
            $initpast.push(QAST::Stmt.new($nfablock));
        }
        elsif $rxtype eq 'subcapture' || $rxtype eq 'quant' {
            qalt_nfas($ast[0], $subid, $initpast)
        }
        elsif $rxtype eq 'concat' || $rxtype eq 'altseq' || $rxtype eq 'conj' || $rxtype eq 'conjseq' {
            for $ast.list { qalt_nfas($_, $subid, $initpast) }
        }
    }

    method subrule_alias($ast, $name) {
        if $ast.name gt '' { $ast.name( $name ~ '=' ~ $ast.name ); }
        else { $ast.name($name); }
        $ast.subtype('capture');
    }

    method flip_ast($qast) {
        return $qast unless nqp::istype($qast, QAST::Regex);
        if $qast.rxtype eq 'literal' {
            $qast[0] := $qast[0].reverse();
        }
        elsif $qast.rxtype eq 'concat' {
            my @tmp;
            while +@($qast) { @tmp.push(@($qast).shift) }
            while @tmp      { @($qast).push(self.flip_ast(@tmp.pop)) }
        }
        elsif $qast.rxtype eq 'pastnode' {
            # Don't go exploring these
        }
        else {
            for @($qast) { self.flip_ast($_) }
        }
        $qast
    }
}
