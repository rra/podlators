#!/usr/bin/perl
#
# Build script for the podlators distribution.
#
# Copyright 1999, 2000, 2001, 2008, 2010, 2012, 2014
#     Russ Allbery <rra@cpan.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.

use 5.006;
use strict;
use warnings;

use Module::Build;

# Basic package configuration.
my $build = Module::Build->new(
    dist_name            => 'podlators',
    dist_abstract        => 'Format POD source into various output formats',
    dist_author          => 'Russ Allbery <rra@cpan.org>',
    dist_version         => '4.00',
    license              => 'perl',
    recursive_test_files => 1,

    # module_name must be set to avoid warnings, even though it's not used.
    module_name => 'podlators',

    # perlpodstyle is another section 1 man page, but not a script.
    #
    # Currently, pod/perlpodstyle must not have an extension or the extension
    # will be included in the name of the generated man page.  See
    # <https://github.com/Perl-Toolchain-Gang/Module-Build/issues/32>.
    bindoc_dirs => [qw(bin pod)],

    # Add additional package metadata.
    meta_merge => {
        resources => {
            repository => 'git://git.eyrie.org/perl/podlators.git',
            bugtracker =>
              'https://rt.cpan.org/Public/Dist/Display.html?Name=podlators',
        },
    },

    # Other package relationships.
    configure_requires => { 'Module::Build' => 0.28 },
    requires           => {
        Encode        => 0,
        'Pod::Simple' => 3.06,
        perl          => '5.006',
    },
);

# Generate the build script.
$build->create_build_script;
