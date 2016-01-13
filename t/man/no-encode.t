#!/usr/bin/perl
#
# Tests for graceful degradation to non-utf8 output
# in case Encode is not available

use 5.006;
use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
    ok(!$INC{'Encode.pm'}, 'Encode is not loaded yet');
    unshift @INC, sub { die 'refusing to load Encode' if $_[1] eq 'Encode.pm' };
    ok(! eval { require Encode; 1 }, 'cannot load Encode anymore');
    use_ok('Pod::Man');
}

local $SIG{__WARN__} = sub { die 'no warnings expected' };

my ($parser, $output);
my $pod = "=encoding latin1\n\n=head1 NAME\n\nBeyonc\xE9!";

$parser = Pod::Man->new(utf8 => 0, name => 'test');
$parser->output_string(\$output);
$parser->parse_string_document($pod);
like($output, qr/Beyonce/, 'works without Encode for non-utf8 output');

my $output2;
{
    local $SIG{__WARN__} = sub {like($_[0], qr/falling back to non-utf8/,
        'Pod::Man->new() warns with utf8 when Encode is not available') };
    $parser = Pod::Man->new(utf8 => 1, name => 'test');
}
$parser->output_string(\$output2);
$parser->parse_string_document($pod);
is($output2, $output, 'degraded gracefully to non-utf8 output');
