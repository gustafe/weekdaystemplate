#! /usr/bin/env perl
use Modern::Perl '2015';
###
use utf8;
binmode( STDOUT, ':encoding(UTF-8)' );

use Time::Piece;

# Swedish week day abbreviations
Time::Piece::day_list(qw/sön mån tis ons tor fre lör/);


# user input for year, otherwise current year
my $t = localtime;
my $year = shift // $t->year;
die "enter a valid year (1900 and onwards)"
    unless ( $year =~ m/\d{4}/ and $year >= 1900 );

my %data;

for my $mon ( 1 .. 12 ) {

    # create a Time::Piece object for the first of the current month (guaranteed to exist)
    my $first_day = Time::Piece->strptime( sprintf( "%04d-%02d-%02d %02d:%02d", $year, $mon, 1, 12, 0 ),
					   "%Y-%m-%d %H:%M" );

    # figure out how many days this month has
    my $end_day = $first_day->month_last_day;
    for my $d ( 1 .. $end_day ) {

        # create a new object for every day
        my $day = Time::Piece->strptime( sprintf( "%04d-%02d-%02d %02d:%02d", $year, $mon, $d, 12, 0 ),
					 "%Y-%m-%d %H:%M" );

        # only include weekdays
        next unless $day->day_of_week > 0 and $day->day_of_week < 6;

        # we use ISO week year ("%G") for the hash key, see
        # http://johnbokma.com/blog/2019/09/04/iso-week-and-year-in-perl.html
        push @{ $data{ sprintf( "%04dW%02d", $day->strftime("%G"), $day->week ) } },
            join( ' ', $day->date, $day->day, ' ' );
    }

}

# output the data
for my $yw ( sort keys %data ) {
    say "\n### $yw\n";
    for my $d ( @{ $data{$yw} } ) {
        say $d;
    }
}

