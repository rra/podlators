# Makefile.PL for podlators.
# $Id$

BEGIN {
    require 5.004;
    eval { require File::Spec };
    if ($@) { die "You need to install the File::Spec module first!\n" }
}

# Use File::Spec to handle paths, for portability.
sub script {
    my @scripts = map { File::Spec->catfile ('scripts', $_) } @_;
    wantarray ? @scripts : join (' ', @scripts);
}

use ExtUtils::MakeMaker;
WriteMakefile (
    NAME         => 'Pod',
    DISTNAME     => 'podlators',
    PL_FILES     => { script ('pod2text.PL', 'pod2text'),
                      script ('pod2roff.PL', 'pod2roff') },
    EXE_FILES    => [ script ('pod2text', 'pod2roff') ],
    PREREQ_PM    => { 'File::Spec' => 0, 'Pod::Parser' => 0 },
    ($] >= 5.005 ?
     (ABSTRACT   => 'Convert POD data to various other formats',
      AUTHOR     => 'Russ Allbery (rra@stanford.edu)') : ()),
    VERSION_FROM => 'VERSION',
    realclean    => { FILES => scalar script ('pod2text', 'pod2roff') }
);
