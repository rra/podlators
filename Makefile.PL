# Makefile.PL for podlators.
# $Id$

BEGIN {
    require 5.004;
    eval { require File::Spec };
    if ($@) { die "You need to install the File::Spec module first!\n" }
}

# Use File::Spec to handle paths, for portability.
sub script { File::Spec->catfile ('scripts', @_) }

use ExtUtils::MakeMaker;
WriteMakefile (
    NAME         => 'Pod',
    DISTNAME     => 'podlators',
    PL_FILES     => { script ('pod2txt.PL') => script ('pod2txt') },
    EXE_FILES    => [ script ('pod2txt') ],
    PREREQ_PM    => { 'File::Spec' => 0 },
    ($] >= 5.005 ?
     (ABSTRACT   => 'Convert POD data to various other formats',
      AUTHOR     => 'Russ Allbery (rra@stanford.edu)') : ()),
    VERSION_FROM => 'VERSION',
    realclean    => { FILES => script ('pod2txt') }
);
