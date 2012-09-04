#! perl
# Copyright (C) 2010, Parrot Foundation.
use strict;
use warnings;
use HTML::Entities;

=head1 NAME

tools/dev/find_hacks.pl - Generates a TracWiki formatted list of 'hack'
comments in Parrot source.

=head1 SYNOPSIS

  $ perl tools/dev/find_hacks.pl

=head1 DESCRIPTION

This script greps through all text files in the directory that it's run in, and
looks for all instances of the word 'hack' in the source. It then outputs a
TracWiki formatted page that can be copied and pasted into Trac directly, complete
with links to the relevant source file on github.

If run with a non-clean source tree, generated files have a chance of matching, so
this tool is best run after a `make realclean'.

=cut

# Open our grep stream and then print a header.
open(my $hacks, '-|', 'grep -rIn hack .') || die "Could not grep! $!\n";
print '= Parrot HACK List =' . "\n\n";

while(<$hacks>) {
    if(/^.\/(.+?):([0-9]+):(.*hack.*)$/i) {
        # Save the regex data.
        my $filename = $1, my $linenum = $2, my $context = $3;

        # Make sure we're not triggering for 'hacker', though.
        next if $context =~ /hacker/;
        # And this script should not trigger.
        next if $filename =~ /find_hacks.pl$/;

        # Process context for HTML, then do some stuff to it too.
        $context = encode_entities($context);
        $context =~ s/hack/<strong><font color="red">hack<\/font><\/strong>/ig;

        # See if we have an incomplete multi-line comment.
        my $begin = $context =~ /\/\*/ && !($context =~ /\*\//);
        my $end = $context =~ /\*\// && !($context =~ /\/\*/);

        # Print out the main line data.
        print "  * [https://github.com/parrot/parrot/blob/master/$filename#L$linenum $filename:$linenum][[br]]\n{{{\n#!html\n";
        print "<div class='wikipage' style='font-family: Consolas,Lucida Console,DejaVu Sans Mono,Bitstream Vera Sans Mono,monospace;'>";
        if($begin) {
            # First print out the beginning
            $context =~ s/ /&nbsp;/g;
            print $context . "<br>\n";

            # Open the file and just slurp the entirety.
            open(my $SOURCEFILE, '<', $filename) or die $!;
            my $terminator = $/; undef $/;
            my $sourcefile = <$SOURCEFILE>;
            $/ = $terminator;

            # Split based on newline and then keep printing until we get an end.
            my @lines = split(/$terminator/, $sourcefile);
            my $someline = $linenum;
            do {
                $lines[$someline] = encode_entities($lines[$someline]);
                $lines[$someline] =~ s/ /&nbsp;/g;
                print $lines[$someline] . "<br>\n";
            } while !($lines[$someline++] =~ /\*\//);

            close $SOURCEFILE;
        }
        elsif($end) {
            # Open the file and read fully.
            open(my $SOURCEFILE, '<', $filename) or die $!;
            my $terminator = $/; undef $/;
            my $sourcefile = <$SOURCEFILE>;
            $/ = $terminator;

            # Go back until we found the beginning of the comment.
            my @lines = split(/$terminator/, $sourcefile);
            my $someline = $linenum;
            while (!($lines[--$someline] =~ /\/\*/)) { }

            # And print from there to just before our line.
            for(; $someline < ($linenum - 1); $someline++) {
                $lines[$someline] = encode_entities($lines[$someline]);
                $lines[$someline] =~ s/ /&nbsp;/g;
                print $lines[$someline] . "<br>\n";
            }

            # Print out the last line.
            print $context . "<br>\n";

            close $SOURCEFILE;
        }
        else {
            $context =~ s/^\s+//;
            $context =~ s/\s+$//;
            print $context . "<br>\n";
        }

        print "</div>\n}}}\n\n";
    }
}

# Print a footer.
print '{{{
#!comment
Automatically generated by tools/dev/find_hacks.pl
}}}';

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
