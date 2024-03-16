#!/usr/bin/perl
#
# Tests the handling of the date added to the man page header in the output of
# Pod::Man.
#
# Copyright 2009, 2014-2015, 2018-2019, 2022, 2024 Russ Allbery <rra@cpan.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

use 5.012;
use warnings;

use Pod::Man;
use POSIX qw(strftime);

use Test::More tests => 6;

# Start with environment variables affecting the date stripped.
local $ENV{SOURCE_DATE_EPOCH} = undef;
local $ENV{POD_MAN_DATE} = undef;

# Check that the results of device_date matches strftime.  There is no input
# file name, so this will use the current time.
my $parser = Pod::Man->new;
is(
    $parser->devise_date,
    strftime('%Y-%m-%d', gmtime()),
    'devise_date matches strftime',
);

# Set the override environment variable and ensure that it's honored.
local $ENV{POD_MAN_DATE} = '2014-01-01';
is($parser->devise_date, '2014-01-01', 'devise_date honors POD_MAN_DATE');

# Check that an empty environment variable is honored.
local $ENV{POD_MAN_DATE} = q{};
is($parser->devise_date, q{}, 'devise_date honors empty POD_MAN_DATE');

# Set another environment variable and ensure that it's honored.
local $ENV{POD_MAN_DATE} = undef;
local $ENV{SOURCE_DATE_EPOCH} = 1439390140;
is($parser->devise_date, '2015-08-12', 'devise_date honors SOURCE_DATE_EPOCH');

# Check that POD_MAN_DATE overrides SOURCE_DATE_EPOCH.
local $ENV{POD_MAN_DATE} = '2013-01-01';
local $ENV{SOURCE_DATE_EPOCH} = 1482676620;
is(
    $parser->devise_date, '2013-01-01',
    'devise_date honors POD_MAN_DATE over SOURCE_DATE_EPOCH',
);

# Check that an invalid SOURCE_DATE_EPOCH is not accepted.  Be careful to
# avoid false failures if the test is run exactly at the transition from one
# day to the next.
local $ENV{POD_MAN_DATE} = undef;
local $ENV{SOURCE_DATE_EPOCH} = '1482676620B';
my ($year, $month, $day) = (gmtime())[5, 4, 3];
my $expected_old = sprintf('%04d-%02d-%02d', $year + 1900, $month + 1, $day);
my $seen = $parser->devise_date();
($year, $month, $day) = (gmtime())[5, 4, 3];
my $expected_new = sprintf('%04d-%02d-%02d', $year + 1900, $month + 1, $day);

if ($expected_old eq $expected_new || $seen eq $expected_old) {
    is(
        $parser->devise_date,
        $expected_old,
        'devise_date ignores invalid SOURCE_DATE_EPOCH',
    );
} else {
    is(
        $parser->devise_date,
        $expected_new,
        'devise_date ignores invalid SOURCE_DATE_EPOCH',
    );
}
