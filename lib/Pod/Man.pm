# Pod::Roff -- Convert POD data to formatted *roff input.
# $Id$
#
# Copyright 1999 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# This module is intended to be a replacement for pod2man, and attempts to
# match its output except for some specific circumstances where other
# decisions seemed to produce better output.  It uses Pod::Parser and is
# designed to be very easy to subclass.

############################################################################
# Modules and declarations
############################################################################

package Pod::Roff;

require 5.004;

use Carp qw(carp croak);
use Pod::Select ();

use strict;
use subs qw(makespace);
use vars qw(@ISA %ESCAPES $PREAMBLE $VERSION);

@ISA = qw(Pod::Select);

($VERSION = (split (' ', q$Revision$ ))[1]) =~ s/\.(\d)$/.0$1/;


############################################################################
# Preamble and *roff output tables
############################################################################

# The following is the static preamble which starts all *roff output we
# generate.  It's completely static except for the font to use as a
# fixed-width font, which is designed by @CFONT@.  $PREAMBLE should
# therefore be run through s/\@CFONT\@/<font>/g before output.
$PREAMBLE = <<'----END OF PREAMBLE----';
.de Sh \" Subsection heading
.br
.if t .Sp
.ne 5
.PP
\fB\\$1\fR
.PP
..
.de Sp \" Vertical space (when we can't use .PP)
.if t .sp .5v
.if n .sp
..
.de Ip \" List item
.br
.ie \\n(.$>=3 .ne \\$3
.el .ne 3
.IP "\\$1" \\$2
..
.de Vb \" Begin verbatim text
.ft @CFONT@
.nf
.ne \\$1
..
.de Ve \" End verbatim text
.ft R

.fi
..
.\" Set up some character translations and predefined strings.  \*(-- will
.\" give an unbreakable dash, \*(PI will give pi, \*(L" will give a left
.\" double quote, and \*(R" will give a right double quote.  | will give a
.\" real vertical bar.  \*(C+ will give a nicer C++.  Capital omega is used
.\" to do unbreakable dashes and therefore won't be available.  \*(C` and
.\" \*(C' expand to `' in nroff, nothing in troff, for use with C<>
.tr \(*W-|\(bv\*(Tr
.ds C+ C\v'-.1v'\h'-1p'\s-2+\h'-1p'+\s0\v'.1v'\h'-1p'
.ie n \{\
.    ds -- \(*W-
.    ds PI pi
.    if (\n(.H=4u)&(1m=24u) .ds -- \(*W\h'-12u'\(*W\h'-12u'-\" diablo 10 pitch
.    if (\n(.H=4u)&(1m=20u) .ds -- \(*W\h'-12u'\(*W\h'-8u'-\"  diablo 12 pitch
.    ds L" ""
.    ds R" ""
.    ds C` `
.    ds C' '
'br\}
.el\{\
.    ds -- \(em\|
.    ds PI \(*p
.    ds L" ``
.    ds R" ''
'br\}
.\"
.\" If the F register is turned on, we'll generate index entries on stderr
.\" for titles (.TH), headers (.SH), subsections (.Sh), items (.Ip), and
.\" index entries marked with X<> in POD.  Of course, you'll have to process
.\" the output yourself in some meaningful fashion.
.if \nF \{\
.    de IX
.    tm Index:\\$1\t\\n%\t"\\$2"
.    .
.    nr % 0
.    rr F
.\}
.\"
.\" For nroff, turn off justification.  Always turn off hyphenation; it
.\" makes way too many mistakes in technical documents.
.hy 0
.if n .na
.\"
.\" Accent mark definitions (@(#)ms.acc 1.5 88/02/08 SMI; from UCB 4.2).
.\" Fear.  Run.  Save yourself.  No user-serviceable parts.
.bd B 3
.    \" fudge factors for nroff and troff
.if n \{\
.    ds #H 0
.    ds #V .8m
.    ds #F .3m
.    ds #[ \f1
.    ds #] \fP
.\}
.if t \{\
.    ds #H ((1u-(\\\\n(.fu%2u))*.13m)
.    ds #V .6m
.    ds #F 0
.    ds #[ \&
.    ds #] \&
.\}
.    \" simple accents for nroff and troff
.if n \{\
.    ds ' \&
.    ds ` \&
.    ds ^ \&
.    ds , \&
.    ds ~ ~
.    ds /
.\}
.if t \{\
.    ds ' \\k:\h'-(\\n(.wu*8/10-\*(#H)'\'\h"|\\n:u"
.    ds ` \\k:\h'-(\\n(.wu*8/10-\*(#H)'\`\h'|\\n:u'
.    ds ^ \\k:\h'-(\\n(.wu*10/11-\*(#H)'^\h'|\\n:u'
.    ds , \\k:\h'-(\\n(.wu*8/10)',\h'|\\n:u'
.    ds ~ \\k:\h'-(\\n(.wu-\*(#H-.1m)'~\h'|\\n:u'
.    ds / \\k:\h'-(\\n(.wu*8/10-\*(#H)'\z\(sl\h'|\\n:u'
.\}
.    \" troff and (daisy-wheel) nroff accents
.ds : \\k:\h'-(\\n(.wu*8/10-\*(#H+.1m+\*(#F)'\v'-\*(#V'\z.\h'.2m+\*(#F'.\h'|\\n:u'\v'\*(#V'
.ds 8 \h'\*(#H'\(*b\h'-\*(#H'
.ds o \\k:\h'-(\\n(.wu+\w'\(de'u-\*(#H)/2u'\v'-.3n'\*(#[\z\(de\v'.3n'\h'|\\n:u'\*(#]
.ds d- \h'\*(#H'\(pd\h'-\w'~'u'\v'-.25m'\f2\(hy\fP\v'.25m'\h'-\*(#H'
.ds D- D\\k:\h'-\w'D'u'\v'-.11m'\z\(hy\v'.11m'\h'|\\n:u'
.ds th \*(#[\v'.3m'\s+1I\s-1\v'-.3m'\h'-(\w'I'u*2/3)'\s-1o\s+1\*(#]
.ds Th \*(#[\s+2I\s-2\h'-\w'I'u*3/5'\v'-.3m'o\v'.3m'\*(#]
.ds ae a\h'-(\w'a'u*4/10)'e
.ds Ae A\h'-(\w'A'u*4/10)'E
.    \" corrections for vroff
.if v .ds ~ \\k:\h'-(\\n(.wu*9/10-\*(#H)'\s-2\u~\d\s+2\h'|\\n:u'
.if v .ds ^ \\k:\h'-(\\n(.wu*10/11-\*(#H)'\v'-.4m'^\v'.4m'\h'|\\n:u'
.    \" for low resolution devices (crt and lpr)
.if \n(.H>23 .if \n(.V>19 \
\{\
.    ds : e
.    ds 8 ss
.    ds o a
.    ds d- d\h'-1'\(ga
.    ds D- D\h'-1'\(hy
.    ds th \o'bp'
.    ds Th \o'LP'
.    ds ae ae
.    ds Ae AE
.\}
.rm #[ #] #H #V #F C
----END OF PREAMBLE----
#`# for cperl-mode
                                   
# This table is taken nearly verbatim from Tom Christiansen's pod2man.  It
# assumes that the standard preamble has already been printed, since that's
# what defines all of the accent marks.  Note that some of these are quoted
# with double quotes since they contain embedded single quotes, so use \\
# uniformly for backslash for readability.
%ESCAPES = (
    'amp'       =>    '&',      # ampersand
    'lt'        =>    '<',      # left chevron, less-than
    'gt'        =>    '>',      # right chevron, greater-than
    'quot'      =>    '"',      # double quote

    'Aacute'    =>    "A\\*'",  # capital A, acute accent
    'aacute'    =>    "a\\*'",  # small a, acute accent
    'Acirc'     =>    'A\\*^',  # capital A, circumflex accent
    'acirc'     =>    'a\\*^',  # small a, circumflex accent
    'AElig'     =>    '\*(AE',  # capital AE diphthong (ligature)
    'aelig'     =>    '\*(ae',  # small ae diphthong (ligature)
    'Agrave'    =>    "A\\*`",  # capital A, grave accent
    'agrave'    =>    "A\\*`",  # small a, grave accent
    'Aring'     =>    'A\\*o',  # capital A, ring
    'aring'     =>    'a\\*o',  # small a, ring
    'Atilde'    =>    'A\\*~',  # capital A, tilde
    'atilde'    =>    'a\\*~',  # small a, tilde
    'Auml'      =>    'A\\*:',  # capital A, dieresis or umlaut mark
    'auml'      =>    'a\\*:',  # small a, dieresis or umlaut mark
    'Ccedil'    =>    'C\\*,',  # capital C, cedilla
    'ccedil'    =>    'c\\*,',  # small c, cedilla
    'Eacute'    =>    "E\\*'",  # capital E, acute accent
    'eacute'    =>    "e\\*'",  # small e, acute accent
    'Ecirc'     =>    'E\\*^',  # capital E, circumflex accent
    'ecirc'     =>    'e\\*^',  # small e, circumflex accent
    'Egrave'    =>    'E\\*`',  # capital E, grave accent
    'egrave'    =>    'e\\*`',  # small e, grave accent
    'ETH'       =>    '\\*(D-', # capital Eth, Icelandic
    'eth'       =>    '\\*(d-', # small eth, Icelandic
    'Euml'      =>    'E\\*:',  # capital E, dieresis or umlaut mark
    'euml'      =>    'e\\*:',  # small e, dieresis or umlaut mark
    'Iacute'    =>    "I\\*'",  # capital I, acute accent
    'iacute'    =>    "i\\*'",  # small i, acute accent
    'Icirc'     =>    'I\\*^',  # capital I, circumflex accent
    'icirc'     =>    'i\\*^',  # small i, circumflex accent
    'Igrave'    =>    'I\\*`',  # capital I, grave accent
    'igrave'    =>    'i\\*`',  # small i, grave accent
    'Iuml'      =>    'I\\*:',  # capital I, dieresis or umlaut mark
    'iuml'      =>    'i\\*:',  # small i, dieresis or umlaut mark
    'Ntilde'    =>    'N\*~',   # capital N, tilde
    'ntilde'    =>    'n\*~',   # small n, tilde
    'Oacute'    =>    "O\\*'",  # capital O, acute accent
    'oacute'    =>    "o\\*'",  # small o, acute accent
    'Ocirc'     =>    'O\\*^',  # capital O, circumflex accent
    'ocirc'     =>    'o\\*^',  # small o, circumflex accent
    'Ograve'    =>    'O\\*`',  # capital O, grave accent
    'ograve'    =>    'o\\*`',  # small o, grave accent
    'Oslash'    =>    'O\\*/',  # capital O, slash
    'oslash'    =>    'o\\*/',  # small o, slash
    'Otilde'    =>    'O\\*~',  # capital O, tilde
    'otilde'    =>    'o\\*~',  # small o, tilde
    'Ouml'      =>    'O\\*:',  # capital O, dieresis or umlaut mark
    'ouml'      =>    'o\\*:',  # small o, dieresis or umlaut mark
    'szlig'     =>    '\*8',    # small sharp s, German (sz ligature)
    'THORN'     =>    '\\*(Th', # capital THORN, Icelandic
    'thorn'     =>    '\\*(th', # small thorn, Icelandic
    'Uacute'    =>    "U\\*'",  # capital U, acute accent
    'uacute'    =>    "u\\*'",  # small u, acute accent
    'Ucirc'     =>    'U\\*^',  # capital U, circumflex accent
    'ucirc'     =>    'u\\*^',  # small u, circumflex accent
    'Ugrave'    =>    'U\\*`',  # capital U, grave accent
    'ugrave'    =>    'u\\*`',  # small u, grave accent
    'Uuml'      =>    'U\\*:',  # capital U, dieresis or umlaut mark
    'uuml'      =>    'u\\*:',  # small u, dieresis or umlaut mark
    'Yacute'    =>    "Y\\*'",  # capital Y, acute accent
    'yacute'    =>    "y\\*'",  # small y, acute accent
    'yuml'      =>    'y\\*:',  # small y, dieresis or umlaut mark

# The following are strictly internal.  Don't use them in POD source; other
# translators won't know about them or could do completely different things
# with them.

    '_bullet'   =>    '\\(bu',  # bullet
    '_cplus'    =>    '\\*(C+', # C++
    '_emdash'   =>    '\\*(--', # em-dash
    '_pi'       =>    '\\*(PI', # pi
    '_space'    =>    '\\ ',    # nonbreaking space, used by S<>
    '_thsp'     =>    '\\|',    # thin space
    '_zero'     =>    '\\&',    # zero-width character

    '_c'        =>    '\\*(C`', # start of a C<> block
    '_endc'     =>    "\\*(C'", # end of a C<> block

    '_lquote'   =>    '\\*(L"', # left double quote
    '_rquote'   =>    '\\*(R"', # right double quote

    '_sm'       =>    '\\s-1',  # small text
    '_endsm'    =>    '\\s0',   # normal sized text
);


############################################################################
# Static helper functions
############################################################################

# Given a command and a single argument that may or may not contain double
# quotes, handle double-quote formatting for it.  If there are no double
# quotes, just return the command followed by the argument in double quotes.
# If there are double quotes, use an if statement to test for nroff, and for
# nroff output the command followed by the argument in double quotes with
# embedded double quotes doubled.  For other formatters, remap paired double
# quotes to `` and ''.
sub switchquotes {
    my $command = shift;
    local $_ = shift;
    my $extra = shift;
    s/\\\*\([LR]\"/\"/g;
    if (/\"/) {
        s/\"/\"\"/g;
        my $troff = $_;
        $troff =~ s/\"\"([^\"]*)\"\"/\`\`$1\'\'/g;
        s/\"/\"\"/g if $extra;
        $troff =~ s/\"/\"\"/g if $extra;
        $_ = qq("$_") . ($extra ? " $extra" : '');
        $troff = qq("$troff") . ($extra ? " $extra" : '');
        return ".if n $command $_\n.el $command $troff\n";
    } else {
        $_ = qq("$_") . ($extra ? " $extra" : '');
        return "$command $_\n";
    }
}

# Translate a font string into an escape.
sub toescape { (length ($_[0]) > 1 ? '\f(' : '\f') . $_[0] }

                    
############################################################################
# Initialization
############################################################################

# Initialize the object.  Here, we also process any additional options
# passed to the constructor or set up defaults if none were given.  center
# is the centered title, release is the version number, and date is the date
# for the documentation.  Note that we can't know what file name we're
# processing due to the architecture of Pod::Parser, so that *has* to either
# be passed to the constructor or set separately with Pod::Roff::name().
sub initialize {
    my $self = shift;

    # Figure out the fixed-width font.  If user-supplied, make sure that
    # they are the right length.
    for (qw/fixed fixedbold fixeditalic fixedbolditalic/) {
        if (defined $$self{$_}) {
            if (length ($$self{$_}) < 1 || length ($$self{$_}) > 2) {
                croak "roff font should be 1 or 2 chars, not `$$self{$_}'";
            }
        } else {
            $$self{$_} = '';
        }
    }

    # Set the default fonts.  We can't be sure what fixed bold-italic is
    # going to be called, so default to just bold.
    $$self{fixed}           ||= 'CW';
    $$self{fixedbold}       ||= 'CB';
    $$self{fixeditalic}     ||= 'CI';
    $$self{fixedbolditalic} ||= 'CB';

    # Set up a table of font escapes.  First number is fixed-width, second
    # is bold, third is italic.
    $$self{FONTS} = { '000' => '\fR', '001' => '\fI',
                      '010' => '\fB', '011' => '\f(BI',
                      '100' => toescape ($$self{fixed}),
                      '101' => toescape ($$self{fixeditalic}),
                      '110' => toescape ($$self{fixedbold}),
                      '111' => toescape ($$self{fixedbolditalic})};

    # Modification date header.
    if (!defined $$self{date}) {
        my ($day, $month, $year) = (localtime)[3,4,5];
        $month++;
        $year += 1900;
        $$self{date} = join ('-', $year, $month, $day);
    }

    # Extra stuff for page titles.
    $$self{center} = 'User Contributed Perl Documentation'
        unless defined $$self{center};
    $$self{indent}  = 4 unless defined $$self{indent};

    # We used to try first to get the version number from a local binary,
    # but we shouldn't need that any more.  Get the version from the running
    # Perl.
    if (!defined $$self{release}) {
        my ($version, $patch) = ($] =~ /^(.{5})(\d{2})?/);
        $$self{release}  = "perl $version";
        $$self{release} .= ", patch $patch" if $patch;
    }

    # Double quotes in things that will be quoted.
    for (qw/center date release/) { $$self{$_} =~ s/\"/\"\"/g }

    $$self{INDENT}  = 0;        # Current indentation level.
    $$self{INDENTS} = [];       # Stack of indentations.
    $$self{INDEX}   = [];       # Index keys waiting to be printed.

    $self->SUPER::initialize;
}

# For each document we process, output the preamble first.  Note that the
# fixed width font is a global default; once we interpolate it into the
# PREAMBLE, it ain't ever changing.  Maybe fix this later.
sub begin_pod {
    my $self = shift;

    # Try to figure out the name and section from the file name.
    my $section = $$self{section} || 1;
    my $name = $$self{name};
    if (!defined $name) {
        $name = $self->input_file;
        $name =~ s/\.p(od|[lm])$//i;
        if ($section =~ /^1/) {
            require File::Basename;
            $name = uc File::Basename::basename ($name);
        } else {
            # Lose everything up to the first of
            #     */lib/*perl*      standard or site_perl module
            #     */*perl*/lib      from -D prefix=/opt/perl
            #     */*perl*/         random module hierarchy
            # which works.  Should be fixed to use File::Spec.
            for ($name) {
                s%//+%/%g;
                if (     s%^.*?/lib/[^/]*perl[^/]*/%%i
                      or s%^.*?/[^/]*perl[^/]*/(?:lib/)?%%i) {
                    s%^site(_perl)?/%%;       # site and site_perl
                    s%^(.*-$^O|$^O-.*)/%%o;   # arch
                    s%^\d+\.\d+%%;            # version
                }
                s%/%::%g;
            }
        }
    }

    # Now, print out the preamble and the title.
    $PREAMBLE =~ s/\@CFONT\@/$$self{fixed}/;
    chomp $PREAMBLE;
    print { $self->output_handle } <<"----END OF HEADER----";
.\\" Automatically generated by Pod::Roff version $VERSION
.\\" @{[ scalar localtime ]}
.\\"
.\\" Standard preamble:
.\\" ======================================================================
$PREAMBLE
.\\" ======================================================================
.\\"
.IX Title "$name $section"
.TH $name $section "$$self{release}" "$$self{date}" "$$self{center}"
.UC
----END OF HEADER----
#"# for cperl-mode

    # Initialize a few per-file variables.
    $$self{INDENT} = 0;
    $$self{NEEDSPACE} = 0;
}


############################################################################
# Core overrides
############################################################################

# Called for each command paragraph.  Gets the command, the associated
# paragraph, the line number, and a Pod::Paragraph object.  Just dispatches
# the command to a method named the same as the command.  =cut is handled
# internally by Pod::Parser.
sub command {
    my $self = shift;
    my $command = shift;
    return if $command eq 'pod';
    return if ($$self{EXCLUDE} && $command ne 'end');
    $command = 'cmd_' . $command;
    $self->$command (@_);
}

# Called for a verbatim paragraph.  Gets the paragraph, the line number, and
# a Pod::Paragraph object.  Rofficate backslashes, untabify, put a
# zero-width character at the beginning of each line to protect against
# commands, and wrap in .Vb/.Ve.
sub verbatim {
    my $self = shift;
    return if $$self{EXCLUDE};
    local $_ = shift;
    return if /^\s+$/;
    s/\s+$/\n/;
    my $lines = tr/\n/\n/;
    my $indent;
    1 while s/^(.*?)(\t+)/$1 . ' ' x (length ($2) * 8 - length ($1) % 8)/me;
    s/\\/\\e/g;
    s/^(\s*\S)/'\&' . $1/gme;
    $self->makespace if $$self{NEEDSPACE};
    $self->output (".Vb $lines\n$_.Ve\n");
    $$self{NEEDSPACE} = 0;
}

# Called for a regular text block.  Gets the paragraph, the line number, and
# a Pod::Paragraph object.  Perform interpolation and output the results.
sub textblock {
    my $self = shift;
    return if $$self{EXCLUDE};
    $self->output ($_[0]), return if $$self{VERBATIM};

    # Perform a little magic to collapse multiple L<> references.  We'll
    # just rewrite the whole thing into actual text at this part, bypassing
    # the whole internal sequence parsing thing.
    s{
        (L<                     # A link of the form L</something>.
              /
              (
                  [:\w]+        # The item has to be a simple word...
                  (\(\))?       # ...or simple function.
              )
          >
          (
              ,?\s+(and\s+)?    # Allow lots of them, conjuncted.
              L<  
                  /
                  ( [:\w]+ ( \(\) )? )
              >
          )+
        )
    } {
        local $_ = $1;
        s{ L< / ([^>]+ ) } {$1}g;
        my @items = split /(?:,?\s+(?:and\s+)?)/;
        my $string = "the ";
        my $i;
        for ($i = 0; $i < @items; $i++) {
            $string .= $items[$i];
            $string .= ", " if @items > 2 && $i != $#items;
            $string .= " and " if ($i == $#items - 1);
        }
        $string .= " entries elsewhere in this document";
        $string;
    }gex;

    # Parse the tree and output it.  collapse does guesswork and then
    # starts at the bottom and calls interior_sequence on each sequence.
    local $_ = $self->parse_text ({ -expand_ptree => 'collapse' }, @_);
    $_ = join ('', $_->children);
    s/\s+$/\n/;
    $self->makespace if $$self{NEEDSPACE};
    $self->output ($self->unescape ($_));
    $self->outindex;
    $$self{NEEDSPACE} = 1;
}

# Called for an interior sequence.  Gets the command, argument, and a
# Pod::InteriorSequence object and is expected to return the resulting text.
# Leave E<> alone and unchanged in the output; we fix those as the very last
# thing that we do before we output the paragraph.
sub interior_sequence {
    my $self = shift;
    my $command = shift;
    local $_ = shift;

    # Handle special sequences.
    if ($command eq 'E') { return "E<$_>"    }
    if ($command eq 'Z') { return 'E<_zero>' }

    # For all the other sequences, empty content produces no output.
    return if $_ eq '';

    # Handle formatting sequences.
    if ($command eq 'B') { return 'E<_FS_B>' . $_ . 'E<_FE_B>' }
    if ($command eq 'F') { return 'E<_FS_I>' . $_ . 'E<_FE_I>' }
    if ($command eq 'I') { return 'E<_FS_I>' . $_ . 'E<_FE_I>' }
    if ($command eq 'C') {
        return 'E<_FS_F>E<_c>' . $_ . 'E<_endc>E<_FE_F>';
    }

    # Whitespace protection replaces whitespace with E<_space>.
    if ($command eq 'S') { s/\s+/E<_space>/g; return $_ }

    # Handle links.
    if ($command eq 'L') { return $self->buildlink ($_) }

    # For indexes, add to the list for the current paragraph.
    if ($command eq 'X') { push (@{ $$self{INDEX} }, $_); return }

    # Anything else is unknown.
    carp "Unknown sequence $command<$_>";
}


############################################################################
# Command paragraphs
############################################################################

# All command paragraphs take the paragraph and the line number.

# First level heading.  We can't output .IX in the NAME section due to a bug
# in some versions of catman, so don't output a .IX for that section.  .SH
# already uses small caps, so remove any E<> sequences that would cause
# them.
sub cmd_head1 {
    my $self = shift;
    $_ = $self->parse_text ({ -expand_ptree => 'collapse' }, @_);
    $_ = join ('', $_->children);
    s/\s+$//;
    s/E<_(?:end)?sm>//g;
    $self->output (switchquotes ('.SH', $self->unescape ($_)));
    $self->outindex (($_ eq 'NAME') ? () : ('Header', $_));
    $$self{NEEDSPACE} = 0;
}

# Second level heading.
sub cmd_head2 {
    my $self = shift;
    $_ = $self->parse_text ({ -expand_ptree => 'collapse' }, @_);
    $_ = $self->unescape (join ('', $_->children));
    s/\s+$//;
    $self->output (switchquotes ('.Sh', $_));
    $self->outindex ('Subsection', $_);
    $$self{NEEDSPACE} = 0;
}

# Start a list.  For indents after the first, wrap the outside indent in .RS
# so that hanging paragraph tags will be correct.
sub cmd_over {
    my $self = shift;
    local $_ = shift;
    unless (/^[-+]?\d+\s+$/) { $_ = $$self{indent} }
    if (@{ $$self{INDENTS} } > 0) {
        $self->output (".RS $$self{INDENT}\n");
    }
    push (@{ $$self{INDENTS} }, $$self{INDENT});
    $$self{INDENT} = ($_ + 0);
}

# End a list.  If we've closed an embedded indent, we've mangled the hanging
# paragraph indent, so temporarily replace it with .RS and set WEIRDINDENT.
# We'll close that .RS at the next =back or =item.
sub cmd_back {
    my $self = shift;
    $$self{INDENT} = pop @{ $$self{INDENTS} };
    unless (defined $$self{INDENT}) {
        carp "Unmatched =back";
        $$self{INDENT} = 0;
    }
    if ($$self{WEIRDINDENT}) {
        $self->output (".RE\n");
        $$self{WEIRDINDENT} = 0;
    }
    if (@{ $$self{INDENTS} } > 0) {
        $self->output (".RE\n");
        $self->output (".RS $$self{INDENT}\n");
        $$self{WEIRDINDENT} = 1;
    }
    $$self{NEEDSPACE} = 1;
}

# An individual list item.  Emit an index entry for anything that's
# interesting, but don't emit index entries for things like bullets and
# numbers.  rofficate bullets too while we're at it (so for nice output, use
# * for your lists rather than o or . or - or some other thing).
sub cmd_item {
    my $self = shift;
    $_ = $self->parse_text ({ -expand_ptree => 'collapse' }, @_);
    $_ = join ('', $_->children);
    s/\s+$//;
    my $index;
    if (/\w/ && !/^\w[.\)]\s*$/) {
        $index = $_;
        $index =~ s/^\s*[-*+o.]?\s*//;
    }
    s/^\*(\s|\Z)/E<_bullet>$1/;
    $_ = $self->unescape ($_);
    if ($$self{WEIRDINDENT}) {
        $self->output (".RE\n");
        $$self{WEIRDINDENT} = 0;
    }
    $self->output (switchquotes ('.Ip', $_, $$self{INDENT}));
    $self->outindex ($index ? ('Item', $index) : ());
    $$self{NEEDSPACE} = 0;
}

# Begin a block for a particular translator.  Setting VERBATIM triggers
# special handling in textblock().
sub cmd_begin {
    my $self = shift;
    local $_ = shift;
    my ($kind) = /^(\S+)/ or return;
    if ($kind eq 'man' || $kind eq 'roff') {
        $$self{VERBATIM} = 1;
    } else {
        $$self{EXCLUDE} = 1;
    }
}

# End a block for a particular translator.  We assume that all =begin/=end
# pairs are properly closed.
sub cmd_end {
    my $self = shift;
    $$self{EXCLUDE} = 0;
    $$self{VERBATIM} = 0;
}

# One paragraph for a particular translator.  Ignore it unless it's intended
# for man or roff, in which case we output it verbatim.
sub cmd_for {
    my $self = shift;
    local $_ = shift;
    my $line = shift;
    return unless s/^(?:man|roff)\b[ \t]*\n?//;
    $self->output ($_);
}


############################################################################
# Link handling
############################################################################

# Handle links.  We can't actually make real hyperlinks, so this is all to
# figure out what text and formatting we print out.
sub buildlink {
    my $self = shift;
    local $_ = shift;

    # Smash whitespace in case we were split across multiple lines.
    s/\s+/ /g;

    # If we were given any explicit text, just output it.
    if (m{ ^ ([^|]+) \| }x) { return $1 }

    # Okay, leading and trailing whitespace isn't important.
    s/^\s+//;
    s/\s+$//;

    # Default to using the whole content of the link entry as a section
    # name.  Note that L<manpage/> forces a manpage interpretation, as does
    # something looking like L<manpage(section)>.  Do the same thing to
    # L<manpage(section)> as we would to manpage(section) without the L<>;
    # see guesswork().  If we've added italics, don't add the "manpage"
    # text; markup is sufficient.
    my ($manpage, $section) = ('', $_);
    if (/^"\s*(.*?)\s*"$/) {
        $section = '"' . $1 . '"';
    } elsif (m{ ^ [-:.\w]+ (?: \( \S+ \) )? $ }x) {
        ($manpage, $section) = ($_, '');
        $manpage =~ s/^([^\(]+)\(/'E<_FS_I>' . $1 . 'E<_FE_I>'/e;
    } elsif (m%/%) {
        ($manpage, $section) = split (/\s*\/\s*/, $_, 2);
        if ($manpage =~ /^[-:.\w]+(?:\(\S+\))?$/) {
            $manpage =~ s/^([^\(]+)\(/'E<_FS_I>' . $1 . 'E<_FE_I>'/e;
        }
        $section =~ s/^\"\s*//;
        $section =~ s/\s*\"$//;
    }
    if ($manpage && $manpage !~ /E</) {
        $manpage = "the $manpage manpage";
    }

    # Now build the actual output text.
    my $text = '';
    if (!length ($section) && !length ($manpage)) {
        carp "Invalid link $_";
    } elsif (!length ($section)) {
        $text = $manpage;
    } elsif ($section =~ /^[:\w]+(?:\(\))?/) {
        $text .= 'the ' . $section . ' entry';
        $text .= (length $manpage) ? " in $manpage"
                                   : " elsewhere in this document";
    } else {
        $text .= 'the section on "' . $section . '"';
        $text .= " in $manpage" if length $manpage;
    }
    $text;
}


############################################################################
# Escaping and fontification
############################################################################

# Most of the deep magic.  All E<> sequences are deferred until we reach
# this point, and we've accumulated some additional magic sequences in the
# process.
sub unescape {
    my $self = shift;
    local $_ = shift;

    # rofficate backslashes and dashes but keep hyphens hyphens.
    s/\\/\\e/g;
    s/(\G|^|[^a-zA-Z])-/$1\\-/g;

    # Ensure double underbars have a tiny space between them.
    s/__/_\\|_/g;

    # Protect leading quotes from interpretation as commands.
    s/^([.\'])/\\&$1/gm;

    # If there aren't any E<> sequences, all done.
    return $_ unless /E</;

    # B<someI<thing> else> should map to \fBsome\f(BIthing\fB else\fR.  The
    # old pod2man didn't get this right; the second \fB was \fR, so nested
    # sequences didn't work right.  We take care of this by using variables
    # as a combined pointer to our current font sequence, and set each to
    # the number of current nestings of start tags for that font.  Use them
    # as a vector to look up what font sequence to use.
    my ($fixed, $bold, $italic) = (0, 0, 0);
    my %magic = (F => \$fixed, B => \$bold, I => \$italic);
    s { E<_F(.)_(.)> } {
        ${ $magic{$2} } += ($1 eq 'S') ? 1 : -1;
        $$self{FONTS}{($fixed && 1) . ($bold && 1) . ($italic && 1)};
    }gxe;

    # Now clean up all the rest of our escapes.
    s { E< ([^>]+) > } {
        if (exists $ESCAPES{$1}) {
            $ESCAPES{$1};
        } else {
            carp "Unknown escape E<$1>";
            "E<$1>";
        }
    }gxe;
    $_;
}


############################################################################
# *roff-specific guesswork
############################################################################

# Call guesswork on the parse tree and then do a bottom-up expansion.
sub collapse {
    my ($self, $ptree, $noguess) = @_;
    my @output;
    unless ($noguess) {
        @output = map { ref ($_) ? $_ : guesswork ($_) } $ptree->children;
    } else {
        @output = $ptree->children;
    }
    for (@output) {
        if (ref) {
            my $cguess = $noguess || ($_->cmd_name =~ /[^BIS]/);
            $self->collapse ($_->parse_tree, $cguess);
            my $text = join ('', $_->parse_tree->children);
            $_ = $self->interior_sequence ($_->name, $text, $_);
        }
    }
    $ptree->children (@output);
    $ptree;
}

# Takes a text block to perform guesswork on; this is guaranteed not to
# contain any interior sequences.  Returns the text block with remapping
# done.  We map things to internal E<> escapes, which we can leave in the
# text block due to the way we process them.  When we output E<> escapes, we
# output \0 instead of E and then fix it at the end of the routine; this is
# to prevent the E from being picked up as part of a word by other rules.
sub guesswork {
    local $_ = shift;

    # Italize functions in the form func().
    s{
        \b
        (
            [:\w]+ \(\)
        )
    } { "\0<_FS_I>" . $1 . "\0<_FE_I>" }egx;

    # func(n) is a reference to a manual page.  Make it \fIfunc\fR\|(n).
    s{
        \b
        (\w[-:.\w]+)
        (
            \( [^\)] \)
        )
    } { "\0<_FS_I>" . $1 . "\0<_FE_I>\0<_thsp>" . $2 }egx;

    # Convert simple Perl variable references to a fixed-width font.
    s{
        ( \s+ )
        ( [\$\@%] [\w:]+ )
        (?! \( )
    } { $1 . "\0<_FS_F>" . $2 . "\0<_FE_F>"}egx;

    # Translate -- into a real emdash.
    s{      \b -- \b      } {      "\0<_emdash>"      }egx;
    s{    (\s) -- (\s)    } { $1 . "\0<_emdash>" . $2 }egx;
    s{      \" -- ([^\"]) } {    "\"\0<_emdash>" . $1 }egx;
    s{ ([^\"]) -- \"      } { $1 . "\0<_emdash>\""    }egx;

    # Fix up double quotes.
    s{ \" ([^\"]+) \" } { "\0<_lquote>" . $1 . "\0<_rquote>" }egx;

    # Make C++ into \*(C+, which is a squinched version.
    s{ \b C\+\+ } {\0<_cplus>}gx;

    # Map PI to \*(PI.
    s{ \b PI \b } {\0<_pi>}gx;

    # Make all caps a little smaller.  Be careful here, since we don't want
    # to make @ARGV into small caps, nor do we want to fix the MIME in
    # MIME-Version, since it looks weird with the full-height V.
    s{
        ( ^ | [\s\(\"\'\[\{<] )
        ( [A-Z] [A-Z] [/A-Z+:\d_\$-]* )
        (?! -\w )
        \b
    } { $1 . "\0<_sm>" . $2 . "\0<_endsm>" }egx;

    # All done.
    s/\0</E</g;
    $_;
}


############################################################################
# Output formatting
############################################################################

# Make vertical whitespace.
sub makespace {
    my $self = shift;
    $self->output ($$self{INDENT} > 0 ? ".Sp\n" : ".PP\n");
}

# Output any pending index entries, and optionally an index entry given as
# an argument.  Support multiple index entries in X<> separated by slashes,
# and strip special escapes from index entries.
sub outindex {
    my ($self, $section, $index) = @_;
    my @entries = map { split m%\s*/\s*% } @{ $$self{INDEX} };
    return unless ($section || @entries);
    $$self{INDEX} = [];
    my $output;
    if (@entries) {
        for (@entries) { s/E<[^>]+>//g }
        my $output = '.IX Xref "'
            . join (' ', map { s/\"/\"\"/; $_ } @entries)
            . '"' . "\n";
    }
    if ($section) {
        $index =~ s/\"/\"\"/;
        $index =~ s/E<[^>]+>//g;
        $output .= ".IX $section " . '"' . $index . '"' . "\n";
    }
    $self->output ($output);
}

# Output text to the output device.
sub output { print { $_[0]->output_handle } $_[1] }

__END__

.\" These are some extra bits of roff that I don't want to lose track of
.\" but that have been removed from the preamble to make it a bit shorter
.\" since they're not currently being used.  They're accents and special
.\" characters we don't currently have escapes for.
.if n \{\
.    ds ? ?
.    ds ! !
.    ds q
.\}
.if t \{\
.    ds ? \s-2c\h'-\w'c'u*7/10'\u\h'\*(#H'\zi\d\s+2\h'\w'c'u*8/10'
.    ds ! \s-2\(or\s+2\h'-\w'\(or'u'\v'-.8m'.\v'.8m'
.    ds q o\h'-\w'o'u*8/10'\s-4\v'.4m'\z\(*i\v'-.4m'\s+4\h'\w'o'u*8/10'
.\}
.ds v \\k:\h'-(\\n(.wu*9/10-\*(#H)'\v'-\*(#V'\*(#[\s-4v\s0\v'\*(#V'\h'|\\n:u'\*(#]
.ds _ \\k:\h'-(\\n(.wu*9/10-\*(#H+(\*(#F*2/3))'\v'-.4m'\z\(hy\v'.4m'\h'|\\n:u'
.ds . \\k:\h'-(\\n(.wu*8/10)'\v'\*(#V*4/10'\z.\v'-\*(#V*4/10'\h'|\\n:u'
.ds 3 \*(#[\v'.2m'\s-2\&3\s0\v'-.2m'\*(#]
.ds oe o\h'-(\w'o'u*4/10)'e
.ds Oe O\h'-(\w'O'u*4/10)'E
.if \n(.H>23 .if \n(.V>19 \
\{\
.    ds v \h'-1'\o'\(aa\(ga'
.    ds _ \h'-1'^
.    ds . \h'-1'.
.    ds 3 3
.    ds oe oe
.    ds Oe OE
.\}

############################################################################
# Documentation
############################################################################
