# Makefile.PL for podlators.

use Config;

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

sub man1pod {
    my ($dir, $file) = @_;
    my $base = $file;
    $base =~ s/\..*//;
    my $output = File::Spec->catfile ('blib', 'man1',
                                      $base . '.' . $Config{man1ext});
    return File::Spec->catfile ($dir, $file), $output;
}

# Install the modules into the Perl core directory for versions of Perl at
# 5.6.0 or higher, since these modules now come with Perl.
use ExtUtils::MakeMaker;
WriteMakefile (
    NAME          => 'Pod',
    DISTNAME      => 'podlators',
    ($] >= 5.006 ?
     (INSTALLDIRS => 'perl') : ()),
    EXE_FILES     => [ script ('pod2text', 'pod2man') ],
    MAN1PODS      => { man1pod ('scripts', 'pod2man'),
                       man1pod ('scripts', 'pod2text'),
                       man1pod ('pod', 'perlpodstyle.pod') },
    PREREQ_PM     => { 'Encode'      => 0,
                       'File::Spec'  => 0.8,
                       'Pod::Simple' => 3.06 },
    ($] >= 5.005 ?
     (ABSTRACT    => 'Convert POD data to various other formats',
      AUTHOR      => 'Russ Allbery <rra@stanford.edu>') : ()),
    ($] >= 5.010 ?
     (LICENSE     => 'perl') : ()),
    VERSION_FROM  => 'VERSION',
);
