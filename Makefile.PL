# Build instructions for podlators.
#
# We need to use ExtUtils::MakeMaker since this module is part of Perl core,
# which only supports that build method, and because it is a dependency of
# other build systems like Module::Build.
#
# Copyright 1999-2001, 2008, 2010, 2012, 2014-2016, 2018-2019, 2022, 2024
#     Russ Allbery <rra@cpan.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

# Do not use autodie here.  When podlators is built as part of Perl core, it
# is built before autodie is available.
use 5.012;
use warnings;

use ExtUtils::MakeMaker;
use File::Spec;

# The hash of all the metadata.  This will be modified before WriteMakefile to
# remove keys not supported by the local version of ExtUtils::MakeMaker.
my $dist_version = MM->parse_version(File::Spec->catfile(qw(lib Pod Man.pm)));
my %metadata = (
    NAME             => 'Pod',
    DISTNAME         => 'podlators',
    ABSTRACT         => 'Convert POD data to various other formats',
    AUTHOR           => 'Russ Allbery <rra@cpan.org>',
    LICENSE          => 'perl_5',
    EXE_FILES        => ['scripts/pod2man', 'scripts/pod2text'],
    VERSION          => $dist_version,
    MIN_PERL_VERSION => '5.012',
    PL_FILES         => {},

    # Clean some additional files.
    clean => { FILES => File::Spec->catdir('t', 'tmp') },

    # Dependencies on other modules.
    PREREQ_PM => { 'Pod::Simple' => 3.26 },

    # Older versions of ExtUtils::MakeMaker don't pick up nested test
    # directories by default.
    test => { TESTS => 't/*/*.t' },

    # Additional metadata.
    META_ADD => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Pod::Man' => {
                file    => 'lib/Pod/Man.pm',
                version => $dist_version,
            },
            'Pod::ParseLink' => {
                file    => 'lib/Pod/ParseLink.pm',
                version => $dist_version,
            },
            'Pod::Text' => {
                file    => 'lib/Pod/Text.pm',
                version => $dist_version,
            },
            'Pod::Text::Color' => {
                file    => 'lib/Pod/Text/Color.pm',
                version => $dist_version,
            },
            'Pod::Text::Overstrike' => {
                file    => 'lib/Pod/Text/Overstrike.pm',
                version => $dist_version,
            },
            'Pod::Text::Termcap' => {
                file    => 'lib/Pod/Text/Termcap.pm',
                version => $dist_version,
            },
        },
        resources => {
            bugtracker => {
                web => 'https://github.com/rra/podlators/issues',
            },
            homepage   => 'https://www.eyrie.org/~eagle/software/podlators/',
            repository => {
                url  => 'https://github.com/rra/podlators.git',
                web  => 'https://github.com/rra/podlators',
                type => 'git',
            },
        },
    },
);

# Generate the actual Makefile.  Pick an arbitrary module to pull the version
# from, since they should all have the same version.
WriteMakefile(%metadata);
