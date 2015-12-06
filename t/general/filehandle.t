#!/usr/bin/perl
#
# Test the parse_from_filehandle method.
#
# This backward compatibility interface is not provided by Pod::Simple, so
# Pod::Man and Pod::Text had to implement it directly.  Test to be sure it's
# working properly.
#
# Copyright 2006, 2009, 2012, 2014, 2015 Russ Allbery <rra@cpan.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.

use 5.006;
use strict;
use warnings;

use lib 't/lib';

use File::Spec;
use Test::More tests => 4;
use Test::Podlators qw(slurp);

# Ensure the modules load properly.
BEGIN {
    use_ok('Pod::Man');
    use_ok('Pod::Text');
}

# Read the test data from the bottom of this script and return it.  The data
# is in three parts: POD source, Pod::Man output (without the header), and
# Pod::Text output, separated by lines containing only ###.
#
# Returns: Array of POD source, Pod::Man output, and Pod::Text output
sub get_data {
    while (defined(my $line = <DATA>)) {
        last if $line eq "###\n";
    }
    my @data = (q{}, q{}, q{});
    for my $i (0 .. $#data) {
        while (defined(my $line = <DATA>)) {
            last if $line eq "###\n";
            $data[$i] .= $line;
        }
    }
    return @data;
}

# Create a temporary directory to use for output, but don't fail if it already
# exists.  If we failed to create it, we'll fail later on.  We unfortunately
# have to create files on disk to easily create file handles for testing.
my $tmpdir = File::Spec->catdir('t', 'tmp');
if (!-d $tmpdir) {
    mkdir($tmpdir, 0777);
}

# Get the various data.
my ($pod, $man, $text) = get_data();

# Write the POD source to a temporary file that will underlie the input file
# handle.
my $infile = File::Spec->catdir('t', 'tmp', "tmp$$.pod");
open(my $input, '>', $infile) or BAIL_OUT("cannot create $infile: $!");
print {$input} $pod or BAIL_OUT("cannot write to $infile: $!");
close($input) or BAIL_OUT("cannot write to $infile: $!");

# Write the Pod::Man output to a file.
my $outfile = File::Spec->catdir('t', 'tmp', "tmp$$.man");
open($input, '<', $infile) or BAIL_OUT("cannot open $infile: $!");
open(my $output, '>', $outfile) or BAIL_OUT("cannot open $outfile: $!");
my $parser = Pod::Man->new;
$parser->parse_from_filehandle($input, $output);
close($input) or BAIL_OUT("cannot read from $infile: $!");
close($output) or BAIL_OUT("cannot write to $outfile: $!");

# Read the output back in and compare it.
my $got = slurp($outfile, 'man');
is($got, $man, 'Pod::Man output');

# Clean up the temporary output file.
unlink($outfile);

# Now, do the same drill with Pod::Text.  Parse the input to a temporary file.
$outfile = File::Spec->catdir('t', 'tmp', "tmp$$.txt");
open($input, '<', $infile) or BAIL_OUT("cannot open $infile: $!");
open($output, '>', $outfile) or BAIL_OUT("cannot open $outfile: $!");
$parser = Pod::Text->new;
$parser->parse_from_filehandle($input, $output);
close($input) or BAIL_OUT("cannot read from $infile: $!");
close($output) or BAIL_OUT("cannot write to $outfile: $!");

# Read the output back in and compare it.
$got = slurp($outfile);
is($got, $text, 'Pod::Text output');

# Clean up temporary files.
unlink($infile, $outfile);
rmdir($tmpdir);

# Below the marker are bits of POD, corresponding expected nroff output, and
# corresponding expected text output.  The input and output are separated by
# lines containing only ###.

# Unconfuse perlcritic.

=for stopwords
gcc

=cut

__DATA__

###
=head1 NAME

gcc - GNU project C and C++ compiler

=head1 C++ NOTES

Other mentions of C++.

=cut
###
.SH "NAME"
gcc \- GNU project C and C++ compiler
.SH "\*(C+ NOTES"
.IX Header " NOTES"
Other mentions of \*(C+.
###
NAME
    gcc - GNU project C and C++ compiler

C++ NOTES
    Other mentions of C++.

###
