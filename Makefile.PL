# Makefile.PL for podlators.

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

# Install the modules into the Perl core directory for versions of Perl at
# 5.6.0 or higher, since these modules now come with Perl.
use ExtUtils::MakeMaker;
WriteMakefile (
    NAME          => 'Pod',
    DISTNAME      => 'podlators',
    ($] >= 5.006 ?
     (INSTALLDIRS => 'perl') : ()),
    PL_FILES      => { script ('pod2text.PL', 'pod2text'),
                       script ('pod2man.PL', 'pod2man') },
    EXE_FILES     => [ script ('pod2text', 'pod2man') ],
    PREREQ_PM     => { 'File::Spec' => 0.8, 'Pod::Simple' => 3.04 },
    ($] >= 5.005 ?
     (ABSTRACT    => 'Convert POD data to various other formats',
      AUTHOR      => 'Russ Allbery (rra@stanford.edu)') : ()),
    ($] >= 5.010 ?
     (LICENSE     => 'perl') : ()),
    VERSION_FROM  => 'VERSION',
    realclean     => { FILES => scalar script ('pod2text', 'pod2man') }
);
