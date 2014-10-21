use Perl6::Grammar;
use Perl6::Actions;
use Perl6::Compiler;

class Perl6::DebugHooks {
    has %!hooks;
    has $!suspended;
    
    method set_hook($name, $callback) {
        $*W.add_object($callback);
        %!hooks{$name} := $callback;
    }
    
    method has_hook($name) {
        !$!suspended && nqp::existskey(%!hooks, $name)
    }
    
    method get_hook($name) {
        %!hooks{$name}
    }
    
    method suspend() {
        $!suspended := 1
    }
    
    method unsuspend() {
        $!suspended := 0
    }
}

sub ps_qast() {
    QAST::Op.new(
        :op('callmethod'), :name('new'),
        QAST::WVal.new( :value($*W.find_symbol(['PseudoStash'])) )
    )
}

grammar Perl6::HookRegexGrammar is Perl6::RegexGrammar {
    method nibbler() {
        my $*RX_TOP_LEVEL_NIBBLER := 0;
        unless %*RX<DEBUGGER_SEEN> {
            %*RX<DEBUGGER_SEEN> := 1;
            $*RX_TOP_LEVEL_NIBBLER := 1;
        }
        Perl6::RegexGrammar.HOW.find_method(Perl6::RegexGrammar, 'nibbler')(self)
    }
}

class Perl6::HookRegexActions is Perl6::RegexActions {
    method nibbler($/) {
        if $*RX_TOP_LEVEL_NIBBLER && $*DEBUG_HOOKS.has_hook('regex_region') {
            my $file := pir::find_caller_lex__Ps('$?FILES') // '<unknown>';
            $*DEBUG_HOOKS.get_hook('regex_region')($file, $/.from, $/.to);
        }
        Perl6::RegexActions.nibbler($/);
    }
    
    method quantified_atom($/) {
        Perl6::RegexActions.quantified_atom($/);
        my $qa := $/.ast;
        if $qa && $*DEBUG_HOOKS.has_hook('regex_atom') {
            $/.'!make'(QAST::Regex.new(
                :rxtype('concat'),
                QAST::Regex.new(
                    :rxtype('qastnode'),
                    :subtype('declarative'),
                    QAST::Op.new(
                        :op('call'),
                        QAST::WVal.new( :value($*DEBUG_HOOKS.get_hook('regex_atom')) ),
                        $*W.add_string_constant(pir::find_caller_lex__ps('$?FILES') // '<unknown>'),
                        ps_qast(),
                        $*W.add_numeric_constant('Int', $/.from),
                        $*W.add_numeric_constant('Int', $/.to)
                    )
                ),
                $qa
            ));
        }
    }
}

class Perl6::HookActions is Perl6::Actions {
    my %uninteresting := nqp::hash(
        'package_declarator', 1,
        'routine_declarator', 1,
        'multi_declarator', 1,
        'type_declarator', 1,
        'regex_declarator', 1,
        'statement_prefix', 1
    );
    sub interesting_expr($e) {
        my $accept := 1;
        for $e.hash {
            if %uninteresting{$_.key} {
                $accept := 0;
                last;
            }
            if $_.key eq 'scope_declarator' && $_.value<sym> eq 'has' {
                $accept := 0;
                last;
            }
            if $_.key eq 'circumfix' && $e<circumfix><pblock> {
                $accept := 0;
                last;
            }
        }
        $accept
    }
    
    method statement($/) {
        Perl6::Actions.statement($/);
        if $*ST_DEPTH <= 1 && $<EXPR> && interesting_expr($<EXPR>) {
            my $stmt := $/.ast;
            my $pot_hash := nqp::istype($stmt, QAST::Op) &&
                ($stmt.name eq '&infix:<,>' || $stmt.name eq '&infix:<=>>');
            my $nil := nqp::istype($stmt, QAST::Var) && $stmt.name eq 'Nil';
            if !$pot_hash && !$nil && $*DEBUG_HOOKS.has_hook('statement_simple') {
                $/.'!make'(QAST::Stmts.new(
                    QAST::Op.new(
                        :op('call'),
                        QAST::WVal.new( :value($*DEBUG_HOOKS.get_hook('statement_simple')) ),
                        $*W.add_string_constant(pir::find_caller_lex__ps('$?FILES') // '<unknown>'),
                        ps_qast(),
                        $*W.add_numeric_constant('Int', $/.from),
                        $*W.add_numeric_constant('Int', $/.to)
                    ),
                    $stmt
                ));
            }
        }
    }
    
    method statement_control:sym<if>($/) {
        if $*DEBUG_HOOKS.has_hook('statement_cond') {
            my $from := $<sym>.from;
            for $<xblock> {
                my $ast := $_.ast;
                $ast[0] := QAST::Stmts.new(
                    QAST::Op.new(
                        :op('call'),
                        QAST::WVal.new( :value($*DEBUG_HOOKS.get_hook('statement_cond')) ),
                        $*W.add_string_constant(pir::find_caller_lex__ps('$?FILES') // '<unknown>'),
                        ps_qast(),
                        $*W.add_string_constant('if'),
                        $*W.add_numeric_constant('Int', $from),
                        $*W.add_numeric_constant('Int', $_<pblock>.from - 1)
                    ),
                    $ast[0]
                );
                $from := $_<pblock>.to + 1;
            }
        }
        Perl6::Actions.statement_control:sym<if>($/);
    }
    
    sub simple_xblock_hook($/) {
        if $*DEBUG_HOOKS.has_hook('statement_cond') {
            my $stmt := $/.ast;
            $stmt[0] := QAST::Stmts.new(
                QAST::Op.new(
                    :op('call'),
                    QAST::WVal.new( :value($*DEBUG_HOOKS.get_hook('statement_cond')) ),
                    $*W.add_string_constant(pir::find_caller_lex__ps('$?FILES') // '<unknown>'),
                    ps_qast(),
                    $*W.add_string_constant(~$<sym>),
                    $*W.add_numeric_constant('Int', $<sym>.from),
                    $*W.add_numeric_constant('Int', $<xblock><pblock>.from - 1)
                ),
                $stmt[0]
            );
        }
    }
    
    method statement_control:sym<unless>($/) {
        Perl6::Actions.statement_control:sym<unless>($/);
        simple_xblock_hook($/);
    }
    
    method statement_control:sym<while>($/) {
        Perl6::Actions.statement_control:sym<while>($/);
        simple_xblock_hook($/);
    }
    
    method statement_control:sym<repeat>($/) {
        Perl6::Actions.statement_control:sym<repeat>($/);
        if $*DEBUG_HOOKS.has_hook('statement_cond') {
            my $stmt := $/.ast;
            $stmt[0] := QAST::Stmts.new(
                QAST::Op.new(
                    :op('call'),
                    QAST::WVal.new( :value($*DEBUG_HOOKS.get_hook('statement_cond')) ),
                    $*W.add_string_constant(pir::find_caller_lex__ps('$?FILES') // '<unknown>'),
                    ps_qast(),
                    $*W.add_string_constant(~$<wu>),
                    $*W.add_numeric_constant('Int', $<wu>.from),
                    $*W.add_numeric_constant('Int', $<xblock>
                        ?? $<xblock><pblock>.from - 1
                        !! $/.to)
                ),
                $stmt[0]
            );
        }
    }
    
    method statement_control:sym<loop>($/) {
        if $*DEBUG_HOOKS.has_hook('statement_cond') {
            for <e1 e2 e3> -> $expr {
                if $/{$expr} -> $m {
                    $m[0].'!make'(QAST::Stmts.new(
                        QAST::Op.new(
                            :op('call'),
                            QAST::WVal.new( :value($*DEBUG_HOOKS.get_hook('statement_cond')) ),
                            $*W.add_string_constant(pir::find_caller_lex__ps('$?FILES') // '<unknown>'),
                            ps_qast(),
                            $*W.add_string_constant('loop'),
                            $*W.add_numeric_constant('Int', widen_expr_from($m[0])),
                            $*W.add_numeric_constant('Int', widen_expr_to($m[0]))
                        ),
                        $m[0].ast
                    ));
                }
            }
        }
        Perl6::Actions.statement_control:sym<loop>($/);
    }
    
    sub widen_expr_from($e) {
        my $from := $e.from;
        for @($e) {
            if $_.from < $from {
                $from := $_.from;
            }
        }
        $from
    }
    
    sub widen_expr_to($e) {
        my $to := $e.to;
        for @($e) {
            if $_.to > $to {
                $to := $_.to;
            }
        }
        $to
    }
    
    method statement_control:sym<for>($/) {
        Perl6::Actions.statement_control:sym<for>($/);
        simple_xblock_hook($/);
    }
    
    method statement_control:sym<given>($/) {
        Perl6::Actions.statement_control:sym<given>($/);
        simple_xblock_hook($/);
    }
    
    method statement_control:sym<when>($/) {
        Perl6::Actions.statement_control:sym<when>($/);
        simple_xblock_hook($/);
    }
    
    method statement_control:sym<require>($/) {
        Perl6::Actions.statement_control:sym<require>($/);
        if $*DEBUG_HOOKS.has_hook('statement_simple') {
            $/.'!make'(QAST::Stmts.new(
                QAST::Op.new(
                    :op('call'),
                    QAST::WVal.new( :value($*DEBUG_HOOKS.get_hook('statement_simple')) ),
                    $*W.add_string_constant(pir::find_caller_lex__ps('$?FILES') // '<unknown>'),
                    ps_qast(),
                    $*W.add_numeric_constant('Int', $/.from),
                    $*W.add_numeric_constant('Int', $/.to)
                ),
                $/.ast
            ));
        }
    }
}

class Perl6::HookGrammar is Perl6::Grammar {
    my %seen_files;
    
    method statementlist() {
        my $file := pir::find_caller_lex__Ps('$?FILES') // '<unknown>';
        unless nqp::existskey(%*SEEN_FILES, $file) {
            if $*DEBUG_HOOKS.has_hook('new_file') {
                # First time we've seen this file; register it.
                $*DEBUG_HOOKS.get_hook('new_file')($file, self.MATCH.orig);
                
                # Also fiddle the %*LANG for the appropriate actions.
                %*LANG<Regex>         := Perl6::HookRegexGrammar;
                %*LANG<Regex-actions> := Perl6::HookRegexActions;
                %*LANG<MAIN>          := Perl6::HookGrammar;
                %*LANG<MAIN-actions>  := Perl6::HookActions;
            }
            %*SEEN_FILES{$file} := 1;
        }
        my $cur_st_depth := $*ST_DEPTH;
        {
            my $*ST_DEPTH := $cur_st_depth + 1;
            Perl6::Grammar.HOW.find_method(Perl6::Grammar, 'statementlist')(self)
        }
    }
    
    method comp_unit() {
        my $*ST_DEPTH := 0;
        my %*SEEN_FILES;
        Perl6::Grammar.HOW.find_method(Perl6::Grammar, 'comp_unit')(self)
    }
    
    method blockoid() {
        my $*ST_DEPTH := 0;
        Perl6::Grammar.HOW.find_method(Perl6::Grammar, 'blockoid')(self)
    }
    
    method semilist() {
        my $cur_st_depth := $*ST_DEPTH;
        {
            my $*ST_DEPTH := $cur_st_depth + 1;
            Perl6::Grammar.HOW.find_method(Perl6::Grammar, 'semilist')(self)
        }
    }
}

sub hll-config($config) {
    $config<name>           := 'rakudo';
    $config<version>        := '';
    $config<release-number> := '';
    $config<codename>       := '';
    $config<build-date>     := '2012-08-05T16:57:45Z';
}

sub MAIN(@ARGS) {
    # Initialize dynops.
    pir::rakudo_dynop_setup__v();

    # Bump up Parrot's recursion limit
    pir::getinterp__P().recursion_limit(100000);

    # Create and configure compiler object.
    my $comp := Perl6::Compiler.new();
    $comp.language('perl6');
    $comp.parsegrammar(Perl6::HookGrammar);
    $comp.parseactions(Perl6::HookActions);
    $comp.addstage('syntaxcheck', :before<past>);
    $comp.addstage('optimize', :before<post>);
    hll-config($comp.config);
    my $COMPILER_CONFIG := $comp.config;
    
    # Add extra command line options.
    my @clo := $comp.commandline_options();
    @clo.push('setting=s');
    @clo.push('c');
    @clo.push('I=s');
    @clo.push('M=s');

    # Set up module loading trace
    my @*MODULES := [];
    
    # Set up END block list, which we'll run at exit.
    my @*END_PHASERS := [];
    
    # Force loading of the debugger module.
    my $pname := @ARGS.shift();
    @ARGS.unshift('-Ilib');
    @ARGS.unshift('-MDebugger::UI::CommandLine');
    @ARGS.unshift($pname);
    
    # Set up debug hooks object.
    my $*DEBUG_HOOKS := Perl6::DebugHooks.new();

    # Enter the compiler.
    $comp.command_line(@ARGS, :encoding('utf8'), :transcode('ascii iso-8859-1'));
    
    # Run any END blocks before exiting.
    for @*END_PHASERS { $_() }
}
