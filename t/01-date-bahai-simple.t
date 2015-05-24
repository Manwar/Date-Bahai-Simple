#!/usr/bin/perl

use 5.006;
use Test::More tests => 25;
use strict; use warnings;
use Date::Bahai::Simple;

is(Date::Bahai::Simple->new({major => 1, cycle => 10, year => 1, month => 1, day => 1})->as_string, '1, Baha 172 BE');
is(Date::Bahai::Simple->new({major => 1, cycle => 10, year => 1, month => 1, day => 1})->to_julian, 2457102.5);
is(Date::Bahai::Simple->new({major => 1, cycle => 10, year => 1, month => 1, day => 1})->get_year, 172);
is(Date::Bahai::Simple->new({major => 1, cycle => 10, year => 1, month => 1, day => 1})->year, 1);
is(Date::Bahai::Simple->new({major => 1, cycle => 10, year => 1, month => 1, day => 1})->month, 1);
is(Date::Bahai::Simple->new({major => 1, cycle => 10, year => 1, month => 1, day => 1})->major, 1);
is(Date::Bahai::Simple->new({major => 1, cycle => 10, year => 1, month => 1, day => 1})->cycle, 10);
is(Date::Bahai::Simple->new({major => 1, cycle => 10, year => 1, month => 1, day => 1})->day_of_week, 6);
is(Date::Bahai::Simple->new({major => 1, cycle => 10, year => 1, month => 1, day => 1})->to_gregorian, '2015-03-21');

eval { Date::Bahai::Simple->new->validate_year(-168); };
like($@, qr/ERROR: Invalid year \[\-168\]./);

eval { Date::Bahai::Simple->new->validate_month(21); };
like($@, qr/ERROR: Invalid month \[21\]./);

eval { Date::Bahai::Simple->new->validate_day(20); };
like($@, qr/ERROR: Invalid day \[20\]./);

my @gregorian = Date::Bahai::Simple->new({ major => 1, cycle => 10, year => 1, month => 2, day => 8 })->to_gregorian;
is(join(", ", @gregorian), '2015-04-16');

my @bahai = Date::Bahai::Simple->new->get_major_cycle_year(171);
is(join(", ", @bahai), '1, 10, 1');

my $g_date = Date::Bahai::Simple->new->from_gregorian(2015, 4, 16);
is($g_date->major, 1);
is($g_date->cycle, 10);
is($g_date->year, 1);
is($g_date->month, 2);
is($g_date->day, 8);

my $j_date = Date::Bahai::Simple->new->from_julian(2457102.5);
is($j_date->major, 1);
is($j_date->cycle, 10);
is($j_date->year, 1);
is($j_date->month, 1);
is($j_date->day, 1);
is($j_date->to_julian, 2457102.5);

done_testing();
