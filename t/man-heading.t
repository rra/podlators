#!/usr/bin/perl -w
#
# man-options.t -- Additional tests for Pod::Man options.
#
# Copyright 2002, 2004, 2006, 2008, 2009 Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.

BEGIN {
    chdir 't' if -d 't';
    if ($ENV{PERL_CORE}) {
        @INC = '../lib';
    } else {
        unshift (@INC, '../blib/lib');
    }
    unshift (@INC, '../blib/lib');
    $| = 1;
    print "1..4\n";
}

END {
    print "not ok 1\n" unless $loaded;
}

use Pod::Man;

$loaded = 1;
print "ok 1\n";

my $n = 2;
while (<DATA>) {
    my %options;
    next until $_ eq "###\n";
    while (<DATA>) {
        last if $_ eq "###\n";
        my ($option, $value) = split (' ', $_, 2);
        chomp $value;
        $options{$option} = $value;
    }
    open (TMP, '> tmp.pod') or die "Cannot create tmp.pod: $!\n";
    print TMP "=head1 NAME\n\ntest - Test man page\n";
    close TMP;
    my $parser = Pod::Man->new (%options) or die "Cannot create parser\n";
    open (OUT, '> out.tmp') or die "Cannot create out.tmp: $!\n";
    $parser->parse_from_file ('tmp.pod', \*OUT);
    close OUT;
    open (TMP, 'out.tmp') or die "Cannot open out.tmp: $!\n";
    my $heading;
    while (<TMP>) {
        if (/^\.TH/) {
            $heading = $_;
            last;
        }
    }
    close TMP;
    unlink ('tmp.pod', 'out.tmp');
    my $expected = '';
    while (<DATA>) {
        last if $_ eq "###\n";
        $expected .= $_;
    }
    if ($heading eq $expected) {
        print "ok $n\n";
    } else {
        print "not ok $n\n";
        print "Expected\n========\n$expected\nOutput\n======\n$heading\n";
    }
    $n++;
}

# Below the marker are sets of options and the corresponding expected .TH line
# from the man page.  This is used to test specific features or problems with
# Pod::Man.  The options and output are separated by lines containing only
# ###.

__DATA__

###
date 2009-01-17
release 1.0
###
.TH TMP 1 "2009-01-17" "1.0" "User Contributed Perl Documentation"
###

###
date 2009-01-17
name TEST
section 8
release 2.0-beta
###
.TH TEST 8 "2009-01-17" "2.0-beta" "User Contributed Perl Documentation"
###

###
date 2009-01-17
release 1.0
center Testing Documentation
###
.TH TMP 1 "2009-01-17" "1.0" "Testing Documentation"
###
