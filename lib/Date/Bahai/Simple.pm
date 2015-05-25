package Date::Bahai::Simple;

$Date::Bahai::Simple::VERSION = '0.06';

=head1 NAME

Date::Bahai::Simple - Represents Bahai date.

=head1 VERSION

Version 0.06

=cut

use 5.006;
use Data::Dumper;
use Time::localtime;
use POSIX qw/floor/;
use Astro::Utils;

use Moo;
use namespace::clean;

use overload q{""} => 'as_string', fallback => 1;

=head1 DESCRIPTION

Represents the Bahai date.

=cut

our $BAHAI_MONTHS = [
    '',
    'Baha',    'Jalal', 'Jamal',  'Azamat', 'Nur',       'Rahmat',
    'Kalimat', 'Kamal', 'Asma',   'Izzat',  'Mashiyyat', 'Ilm',
    'Qudrat',  'Qawl',  'Masail', 'Sharaf', 'Sultan',    'Mulk',
    'Ala'
];

our $BAHAI_CYCLES = [
    '',
    'Alif', 'Ba',     'Ab',    'Dal',  'Bab',    'Vav',
    'Abad', 'Jad',    'Baha',  'Hubb', 'Bahhaj', 'Javab',
    'Ahad', 'Vahhab', 'Vidad', 'Badi', 'Bahi',   'Abha',
    'Vahid'
];

our $BAHAI_DAYS = [
    '<yellow><bold>    Jamal </bold></yellow>',
    '<yellow><bold>    Kamal </bold></yellow>',
    '<yellow><bold>    Fidal </bold></yellow>',
    '<yellow><bold>     Idal </bold></yellow>',
    '<yellow><bold> Istijlal </bold></yellow>',
    '<yellow><bold> Istiqlal </bold></yellow>',
    '<yellow><bold>    Jalal </bold></yellow>'
];

has bahai_epoch  => (is => 'ro', default => sub { 2394646.5     });
has bahai_days   => (is => 'ro', default => sub { $BAHAI_DAYS   });
has bahai_months => (is => 'ro', default => sub { $BAHAI_MONTHS });
has bahai_cycles => (is => 'ro', default => sub { $BAHAI_CYCLES });

has major => (is => 'rw');
has cycle => (is => 'rw');
has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has day   => (is => 'rw', predicate => 1);

with 'Date::Utils';

sub BUILD {
    my ($self) = @_;

    $self->validate_day($self->day)     if $self->has_day;
    $self->validate_month($self->month) if $self->has_month;
    $self->validate_year($self->year)   if $self->has_year;

    unless ($self->has_year && $self->has_month && $self->has_day) {
        my $today = localtime;
        my $year  = $today->year + 1900;
        my $month = $today->mon + 1;
        my $day   = $today->mday;
        my $date  = $self->from_gregorian($year, $month, $day);
        $self->major($date->major);
        $self->cycle($date->cycle);
        $self->year($date->year);
        $self->month($date->month);
        $self->day($date->day);
    }
}

=head1 SYNOPSIS

    use strict; use warnings;
    use Date::Bahai::Simple;

    # prints today's bahai date
    print Date::Bahai::Simple->new->as_string, "\n";

    # print given bahai date
    print Date::Bahai::Simple->new({ major => 1, cycle => 10,  year => 1, month => 1, day => 1 })->as_string, "\n";

    # prints equivalent Julian date
    print Date::Bahai::Simple->new({ major => 1, cycle => 10,  year => 1, month => 1, day => 1 })->to_julian, "\n";

    # prints equivalent Gregorian date
    print Date::Bahai::Simple->new({ major => 1, cycle => 10,  year => 1, month => 1, day => 1 })->to_gregorian, "\n";

    # prints day of the week index (0 for Jamal, 1 for Kamal and so on)
    print Date::Bahai::Simple->new({ major => 1, cycle => 10,  year => 1, month => 1, day => 1 })->day_of_week, "\n";

=head1 METHODS

=head2 to_julian()

Returns julian date equivalent of the Bahai date.

=cut

sub to_julian {
    my ($self) = @_;

    my ($g_year)  = $self->julian_to_gregorian($self->bahai_epoch);
    my ($gm, $gd) = _vernal_equinox_month_day($g_year);
    my $gy = (361 * ($self->major - 1)) +
             (19  * ($self->cycle - 1)) +
             ($self->year - 1) + $g_year;

    return $self->gregorian_to_julian($gy, $gm, $gd)
           +
           (19 * ($self->month - 1))
           +
           (($self->month != 20) ? 0 : ($self->is_gregorian_leap_year($gy + 1) ? -14 : -15))
           +
           $self->day;
}

=head2 from_julian($julian_date)

Returns Bahai  date as an object of type L<Date::Bahai::Simple> equivalent of the
given Julian date C<$julian_date>.

=cut

sub from_julian {
    my ($self, $julian_date) = @_;

    $julian_date = floor($julian_date) + 0.5;
    my $gregorian_year = ($self->julian_to_gregorian($julian_date))[0];
    my $start_year     = ($self->julian_to_gregorian($self->bahai_epoch))[0];

    my $j1 = $self->gregorian_to_julian($gregorian_year, 1, 1);
    my ($gm, $gd) = _vernal_equinox_month_day($gregorian_year);
    my $j2 = $self->gregorian_to_julian($gregorian_year, $gm, $gd);

    my $bahai_year = $gregorian_year - ($start_year + ((($j1 <= $julian_date) && ($julian_date <= $j2)) ? 1 : 0));
    my ($major, $cycle, $year) = $self->get_major_cycle_year($bahai_year);

    my $b_date1 = Date::Bahai::Simple->new({
        major => $major, cycle => $cycle, year => $year, month => 1, day => 1 });
    my $days  = $julian_date - $b_date1->to_julian;

    my $b_date2 = Date::Bahai::Simple->new({
        major => $major, cycle => $cycle, year => $year, month => 20, day => 1 });
    my $bld   = $b_date2->to_julian;
    my $month = ($julian_date >= $bld) ? 20 : (floor($days / 19) + 1);

    my $b_date3 = Date::Bahai::Simple->new({
        major => $major, cycle => $cycle, year => $year, month => $month, day => 1 });
    my $day   = ($julian_date + 1) - $b_date3->to_julian;

    return Date::Bahai::Simple->new({
        major => $major, cycle => $cycle, year => $year, month => $month, day => $day });
}

=head2 to_gregorian()

Returns gregorian date (yyyy-mm-dd) equivalent of the Bahai date.

=cut

sub to_gregorian {
    my ($self) = @_;

    my @date = $self->julian_to_gregorian($self->to_julian);
    return sprintf("%04d-%02d-%02d", $date[0], $date[1], $date[2]);
}

=head2 from_gregorian($year, $month, $day)

Returns Bahai  date as an object of type L<Date::Bahai::Simple> equivalent of the
given gregorian C<$year>, C<$month> and C<$day>.

=cut

sub from_gregorian {
    my ($self, $year, $month, $day) = @_;

    my $date = $self->from_julian($self->gregorian_to_julian($year, $month, $day));
    return Date::Bahai::Simple->new({
        major => $date->major,
        cycle => $date->cycle,
        year  => $date->year,
        month => $date->month,
        day   => $date->day });
}


=head2 day_of_week()

Returns day of the week, starting 0 for Jamal, 1 for Kamal and so on.

    +-------------+--------------+----------------------------------------------+
    | Arabic Name | English Name | Day of the Week                              |
    +-------------+--------------+----------------------------------------------+
    | Jamal       | Beauty       | Sunday                                       |
    | Kamal       | Perfection   | Monday                                       |
    | Fidal       | Grace        | Tuesday                                      |
    | Idal        | Justice      | Wednesday                                    |
    | Istijlal    | Majesty      | Thursday                                     |
    | Istiqlal    | Independence | Friday                                       |
    | Jalal       | Glory        | Saturday                                     |
    +-------------+--------------+----------------------------------------------+

=cut

sub day_of_week {
    my ($self) = @_;

    return $self->jwday($self->to_julian);
}

=head2 get_year()

Returns the bahai year e.g. 172

=cut

sub get_year {
    my ($self) = @_;

    return ($self->major * (19 * ($self->cycle - 1))) + $self->year;
}

=head2 get_major_cycle_year($bahai_year)

Returns major, cycle and year as list of the given C<$bahai_year>.

=cut

sub get_major_cycle_year {
    my ($self, $bahai_year) = @_;

    my $major = floor($bahai_year / 361) + 1;
    my $cycle = floor(($bahai_year % 361) / 19) + 1;
    my $year  = ($bahai_year % 19) + 1;

    return ($major, $cycle, $year);
}

=head2 validate_month($month)

Dies if the given C<$month> is not a valid Bahai month.

=cut

sub validate_month {
    my ($self, $month) = @_;

    die("ERROR: Invalid month [$month].\n")
        unless (defined($month) && ($month =~ /^\d{1,2}$/) && ($month >= 1) && ($month <= 20));
}

=head2 validate_day($day)

Dies if the given C<$day> is not a valid Bahai day.

=cut

sub validate_day {
    my ($self, $day) = @_;

    die ("ERROR: Invalid day [$day].\n")
        unless (defined($day) && ($day =~ /^\d{1,2}$/) && ($day >= 1) && ($day <= 19));
}

sub as_string {
    my ($self) = @_;

    return sprintf("%d, %s %d BE",
                   $self->day, $self->bahai_months->[$self->month], $self->get_year);
}

#
#
# PRIVATE METHODS

sub _vernal_equinox_month_day {
    my ($year) = @_;

    # Source: Wikipedia
    # In 2014, the Universal House of Justice selected  Tehran, the birthplace of
    # Baha'u'lláh, as the location to which the date of  the vernal equinox is to
    # be fixed, thereby "unlocking" the Badi calendar from the Gregorian calendar.
    # For determining  the dates,  astronomical  tables from reliable sources are
    # used.
    # In  the  same  message  the  Universal  House  of  Justice decided that the
    # birthdays  of  the Bab and Baha'u'lláh will be celebrated on "the first and
    # the  second  day  following  the  occurrence  of  the eighth new moon after
    # Naw-Ruz"  (also with the use of astronomical tables) and fixed the dates of
    # the Bahaí Holy Days in the Baha'í calendar, standardizing dates for Baha'ís
    # worldwide. These changes came into effect as of sunset on 20 March 2015.The
    # changes  take effect from the next Bahai New Year, from sunset on March 20,
    # 2015.

    my $month = 3;
    my $day   = 20;

    if ($year >= 2015) {
        my $equinox_date = calculate_equinox('mar', 'utc', $year);
        if ($equinox_date =~ /\d{4}\-(\d{2})\-(\d{2})\s/) {
            $month = $1;
            $day   = $2;
        }
    }

    return ($month, $day);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/Date-Bahai-Simple>

=head1 BUGS

Please report any bugs / feature requests to C<bug-date-bahai-simple at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Bahai-Simple>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Bahai::Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Bahai-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Bahai-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Bahai-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Bahai-Simple/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Date::Bahai::Simple
