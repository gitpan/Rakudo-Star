use URI::Escape;
class Perl6::Documentable {
    has Str $.kind;     # type, language doc, routine, operator
    has Str $.subkind;  # class/role/enum, sub/method, prefix/infix/...

    has Str $.name;
    has     $.pod;
    has Bool $.pod-is-complete;

    # the Documentable that this one was extracted from, if any
    has $.origin;

    method human-kind() {   # SCNR
        $.kind eq 'operator'
            ?? "$.subkind operator"
            !! $.kind eq 'language'
            ?? 'language documentation'
            !! $.subkind // $.kind;
    }

    method filename() {
        $.kind eq 'operator'
            ?? "html/language/operators.html"
            !! "html/$.kind/$.name.html"
            ;
    }
    method url() {
        $.kind eq 'operator'
            ?? "/language/operators#$.subkind%20" ~ uri_escape($.name)
            !! "/$.kind/$.name"
            ;
    }
}
