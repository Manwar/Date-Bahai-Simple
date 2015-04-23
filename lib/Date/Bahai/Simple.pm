package Date::Bahai::Simple;

$Date::Bahai::Simple::VERSION = '0.02';

=head1 NAME

Date::Bahai::Simple - Represents Bahai date.

=head1 VERSION

Version 0.02

=cut

use 5.006;
use Data::Dumper;
use Time::localtime;

use Moo;
use namespace::clean;

use overload q{""} => 'as_string', fallback => 1;

=head1 DESCRIPTION

Represents the Bahai date.

=cut

has major => (is => 'rw');
has cycle => (is => 'rw');
has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has day   => (is => 'rw', predicate => 1);

with 'Date::Utils::Bahai';

sub BUILD {
    my ($self) = @_;

    $self->validate_year($self->year)   if $self->has_year;
    $self->validate_month($self->month) if $self->has_month;
    $self->validate_day($self->day)     if $self->has_day;

    unless ($self->has_year && $self->has_month && $self->has_day) {
        my $today = localtime;
        my $year  = $today->year + 1900;
        my $month = $today->mon + 1;
        my $day   = $today->mday;
        my ($major, $cycle, $y, $m, $d) = $self->gregorian_to_bahai($year, $month, $day);
        $self->major($major);
        $self->cycle($cycle);
        $self->year($y);
        $self->month($m);
        $self->day($d);
    }
}

=head1 SYNOPSIS

    use strict; use warnings;
    use Date::Bahai::Simple;

    # prints today's bahai date
    print Date::Bahai::Simple->new->as_string, "\n";

    my $date = Date::Bahai::Simple->new({ major => 1, cycle => 10,  year => 1, month => 1, day => 1 });
    print "Date: $date\n";

    # prints equivalent Julian date
    print $date->to_julian, "\n";

    # prints equivalent Gregorian date
    print $date->to_gregorian, "\n";

    # prints day of the week index (0 for Jamal, 1 for Kamal and so on)
    print $date->day_of_week, "\n";

=head1 METHODS

=head2 to_julian()

Returns julian date equivalent of the Bahai date.

=cut

sub to_julian {
    my ($self) = @_;

    my $year  = ($self->julian_to_gregorian($self->bahai_epoch))[0];
    my $month = $self->month;
    my $gregorian_year = (361 * ($self->major - 1)) +
                         (19  * ($self->cycle - 1)) +
                         ($self->year - 1) + $year;

    return $self->gregorian_to_julian($gregorian_year, 3, 20)
           +
           (19 * ($month - 1))
           +
           (($month != 20) ? 0 : ($self->is_gregorian_leap_year($gregorian_year + 1) ? -14 : -15))
           +
           $self->day;
}

=head2 to_gregorian()

Returns gregorian date (yyyy-mm-dd) equivalent of the Bahai date.

=cut

sub to_gregorian {
    my ($self) = @_;

    my @date = $self->julian_to_gregorian($self->to_julian);
    return sprintf("%04d-%02d-%02d", $date[0], $date[1], $date[2]);
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

sub as_string {
    my ($self) = @_;

    return sprintf("%d, %s %d BE",
                   $self->day, $self->bahai_months->[$self->month], $self->get_year);
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
