#! /usr/bin/env perl -wT
use Modern::Perl '2015';
###
use utf8;
binmode( STDOUT, ':encoding(UTF-8)' );

use Time::Piece;
use Data::Dump qw/dump/;

use FindBin qw/$Bin/;
BEGIN {
    if ($Bin =~ m!([\w\./\-]+)!) {
	$Bin = $1;
    } else {
	die "Bad directory $Bin";
    }
}
use Template;
use lib "$Bin/lib";
use CGI qw(:standard start_ul *table -utf8);

use CGI::Carp qw(fatalsToBrowser);
use SwedishHolidays qw( swedish_months );


# Swedish week day abbreviations
Time::Piece::day_list(qw/sön mån tis ons tor fre lör/);
#Time::Piece::mon_list(qw/Januari Februari Mars April Maj Juni Juli Augusti September Oktober November December/);
#my @swe_mon = qw/januari februari mars april maj juni juli augusti september oktober november december/;

# user input for year, otherwise current year
my $t = localtime;
my $year = $ENV{QUERY_STRING} // $t->year;
die "enter a valid year (1900 and onwards)"
    unless ( $year =~ m/\d{4}/ and $year >= 1900 );

my $year_weeks;

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
	my $YW = sprintf( "%04dW%02d", $day->strftime("%G"), $day->week );
        push @{ $year_weeks->{ $YW }->{day} }, $day;
	$year_weeks->{$YW}->{mon}->{$day->mon}++;
    }

}

my $data;
# format for output

# output the data
push @{$data->{content}}, "# Veckokalender för $year\n";
for my $yw ( sort keys %{$year_weeks} ) {
    # for my $m (sort {$a<=>$b}keys %{$data{$yw}->{mon}}) {
    # 	say "$m: ". $data{$yw}->{mon}{$m}
    # }

    if (scalar keys %{$year_weeks->{$yw}{mon}} > 1) {
	push @{$data->{content}},"\n### $yw (".join(' - ', map {swedish_months($_)}sort {$a<=>$b} keys %{$year_weeks->{$yw}{mon}}) . ")\n";
    } else {
	push @{$data->{content}},  "\n### $yw (".swedish_months((keys %{$year_weeks->{$yw}{mon}})[0]).")\n";
    }
    
#    say "\n### $yw\n";
     for my $d ( @{ $year_weeks->{$yw}{day}} ){
         push @{$data->{content}}, sprintf("%s %s  ", $d->date, $d->day);
     }
}

my $tt = Template->new( {INCLUDE_PATH=>"$Bin/templates"});
my $out = header( {-type=>'text/markdown',-charset=>'utf-8'} );
my $template= 'veckodagar.tt';
$tt->process( $template, $data, \$out) or die $tt->error();
print $out;
