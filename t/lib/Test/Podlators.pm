# Helper functions to test the podlators distribution.
#
# This module is an internal implementation detail of the podlators test
# suite.  It provides some supporting functions to make it easier to write
# tests.
#
# Copyright 2015 Russ Allbery <rra@cpan.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.

package Test::Podlators;

use 5.006;
use strict;
use warnings;

use Exporter;
use FileHandle;
use Test::More;

# For Perl 5.006 compatibility.
## no critic (ClassHierarchies::ProhibitExplicitISA)

# Declare variables that should be set in BEGIN for robustness.
our (@EXPORT_OK, @ISA, $VERSION);

# Set $VERSION and everything export-related in a BEGIN block for robustness
# against circular module loading (not that we load any modules, but
# consistency is good).
BEGIN {
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(read_test_data slurp);
    $VERSION   = '1.00';
}

# Read one set of test data from the provided file handle and return it.
# There are several different possible formats, which are specified by the
# format option.
#
# The data read from the file handle will be ignored until a line consisting
# solely of "###" is found.  Then, two or more blocks separated by "###" are
# read, ending with another line of "###".  There will always be at least an
# input and an output block, and may be more blocks based on the format
# configuration.
#
# $fh         - File handle to read the data from
# $format_ref - Reference to a hash of options describing the data
#   errors  - Set to true to read expected errors after the output section
#   options - Set to true to read a hash of options as the first data block
#
# Returns: Reference to hash of test data with the following keys:
#            input   - The input block of the test data
#            output  - The output block of the test data
#            errors  - Expected errors if errors was set in $format_ref
#            options - Hash of options if options was set in $format_ref
#          or returns undef if no more test data is found.
sub read_test_data {
    my ($fh, $format_ref) = @_;
    $format_ref ||= {};
    my %data;

    # Find the first block of test data.
    my $line;
    while (defined($line = <$fh>)) {
        last if $line eq "###\n";
    }
    if (!defined($line)) {
        return;
    }

    # If the format contains the options key, read the options into a hash.
    if ($format_ref->{options}) {
        while (defined(my $line = <$fh>)) {
            last if $line eq "###\n";
            my ($option, $value) = split(q{ }, $line, 2);
            if (defined($value)) {
                chomp $value;
            } else {
                $value = q{};
            }
            $data{options}{$option} = $value;
        }
    }

    # Read the input and output sections.
    my @sections = qw(input output);
    if ($format_ref->{errors}) {
        push(@sections, 'errors');
    }
    for my $key (@sections) {
        $data{$key} = q{};
        while (defined(my $line = <$fh>)) {
            last if $line eq "###\n";
            $data{$key} .= $line;
        }
    }
    return \%data;
}

# Slurp output data back from a file handle.  It would be nice to use
# Perl6::Slurp, but this is a core module, so we have to implement our own
# wheels.  BAIL_OUT is called on any failure to read the file.
#
# $file  - File to read
# $strip - If set to "man", strip out the Pod::Man header
#
# Returns: Contents of the file, possibly stripped
sub slurp {
    my ($file, $strip) = @_;
    my $fh = FileHandle->new($file, 'r') or BAIL_OUT("cannot open $file: $!");

    # If told to strip the man header, do so.
    if (defined($strip) && $strip eq 'man') {
        while (defined(my $line = <$fh>)) {
            last if $line eq ".nh\n";
        }
    }

    # Read the rest of the file and return it.
    my $data = do { local $/ = undef; <$fh> };
    $fh->close or BAIL_OUT("cannot read from $file: $!");
    return $data;
}

1;
__END__

=for stopwords
Allbery

=head1 NAME

Test::Podlators - Helper functions for podlators tests

=head1 SYNOPSIS

    use Test::Podlators qw(read_test_data);

    # Read the next block of test data, including options.
    my $data = read_test_data(\*DATA, { options => 1 });

=head1 DESCRIPTION

This module collects various utility functions that are useful for writing
test cases for the podlators distribution.  It is not intended to be, and
probably isn't, useful outside of the test suite for that module.

=head1 FUNCTIONS

None of these functions are imported by default.  The ones used by a
script should be explicitly imported.

=over 4

=item read_test_data(FH, FORMAT)

Reads a block of test data from FH, looking for test information according
to the description provided in FORMAT.  All data prior to the first line
consisting of only C<###> will be ignored.  Then, the test data must
consist of two or more blocks separated by C<###> and ending in a final
C<###> line.

FORMAT is optional, in which case the block of test data should be just
input text and output text.  If provided, it should be a reference to a
hash with one or more of the following keys:

=over 4

=item options

If set, the first block of data in the test description is a set of
options in the form of a key, whitespace, and a value, one per line.  The
value may be missing, in which case the value associated with the key is
the empty string.

=back

The return value is a hash with at least some of the following keys:

=over 4

=item input

The input data for the test.  This is always present.

=item options

If C<options> is set in the FORMAT argument, this is the hash of keys and
values in the options section of the test data.

=item output

The output data for the test.  This is always present.

=back

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Russ Allbery <rra@cpan.org>.

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut
