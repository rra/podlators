# Build instructions for podlators.
#
# We need to use ExtUtils::MakeMaker since this module is part of Perl core,
# which only supports that build method, and because it is a dependency of
# other build systems like Module::Build.
#
# Copyright 1999, 2000, 2001, 2008, 2010, 2012, 2014, 2015
#     Russ Allbery <rra@cpan.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.

use 5.006;
use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;
use File::Spec;

# Generate full paths for scripts distributed in the bin directory.
#
# @scripts - List of script names
#
# Returns: List of relative paths from top of distribution
sub scripts {
    my (@scripts) = @_;
    return map { File::Spec->catfile('bin', $_) } @scripts;
}

# Generate an association between a source file and a destination man page for
# non-module man pages.  ExtUtils::MakeMaker only really understands how to
# generate man pages for modules, so we need to help it for the script man
# pages and (particularly) the perlpodstyle man page.
#
# $directory - Directory containing the file
# $file      - File containing POD in that directory
#
# Returns: The path to the file with POD and the output man page, as a pair
sub man1pod {
    my ($directory, $file) = @_;

    # Determine the base name of the file by stripping any *.pod suffix.
    my $basename = $file;
    $basename =~ s{ [.]pod }{}xms;

    # Determine the output file name for the generated man page.
    my $outname = $basename . q{.} . $Config{man1ext};
    my $outpath = File::Spec->catfile(qw(blib man1), $outname);
    return (File::Spec->catfile($directory, $file), $outpath);
}

# Generate the actual Makefile.  Pick an arbitrary module to pull the version
# from, since they should all have the same version.
WriteMakefile(
    NAME         => 'Pod',
    DISTNAME     => 'podlators',
    ABSTRACT     => 'Convert POD data to various other formats',
    AUTHOR       => 'Russ Allbery <rra@cpan.org>',
    EXE_FILES    => [ scripts('pod2text', 'pod2man') ],
    VERSION_FROM => 'lib/Pod/Man.pm',

    # Override the files that generate section 1 man pages.
    MAN1PODS => {
        man1pod('bin', 'pod2man'),
        man1pod('bin', 'pod2text'),
        man1pod('pod', 'perlpodstyle'),
    },

    # Dependencies on other modules.
    PREREQ_PM => {
        'Encode'      => 0,
        'Pod::Simple' => 3.06,
    },

    # ExtUtils::MakeMaker doesn't pick up nested test directories by default.
    test => { TESTS => 't/*/*.t' },

    # For ExtUtils::MakeMaker 6.31 and later, we can specify the license.
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ? (
        LICENSE => 'perl',
    ) : ()),

    # For ExtUtils::MakeMaker 6.46 or later, we can provide some additional
    # metadata.
    ($ExtUtils::MakeMaker::VERSION >= 6.46 ? (
        META_ADD => {
            resources => {
                repository => 'git://git.eyrie.org/perl/podlators.git',
                bugtracker =>
                  'https://rt.cpan.org/Public/Dist/Display.html?Name=podlators',
            },
        },
    ) : ()),

    # For ExtUtils::MakeMaker 6.48 and later, we can specify the minimum Perl
    # version required.
    ($ExtUtils::MakeMaker::VERSION >= 6.48 ? (
        MIN_PERL_VERSION => '5.006',
    ) : ()),
);
