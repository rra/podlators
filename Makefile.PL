# Makefile.PL for pod-translators.
# $Id$
use ExtUtils::MakeMaker;
WriteMakefile (
    NAME         => 'Pod::SimpleText',
    DISTNAME     => 'Pod-SimpleText',
    EXE_FILES    => [ 'scripts/pod2txt' ],
    ($] >= 5.005 ?
     (ABSTRACT   => 'Convert POD data to formatted ASCII text',
      AUTHOR     => 'Russ Allbery (rra@stanford.edu)') : ()),
    VERSION_FROM => 'lib/Pod/SimpleText.pm',
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' }
);
