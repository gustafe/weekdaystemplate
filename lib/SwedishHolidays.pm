package SwedishHolidays; # -*- CPerl -*-

@ISA = ('Exporter');
@EXPORT = qw( &swedish_holidays &swedish_weekdays &swedish_months );

use Date::Calc qw(Day_of_Week Add_Delta_YMD Easter_Sunday Today_and_Now);

sub date_info {
    my @date = @_;
    my $date_format = "%d-%02d-%02d";
    my $day_of_week = Day_of_Week( @date );
    my $dt_string = sprintf($date_format, @date);
    my $sw_date = sprintf("%sen den %d %s", swedish_weekdays( $day_of_week), $date[2], swedish_months( $date[1]));
    my $date = { 'date' => $dt_string, 'DoW' => $day_of_week , sw_date=>$sw_date};
    return $date;
}


sub add_day {
    my $delta = pop @_;
    my @date = @_;
    return Add_Delta_YMD( @date, 0,0,$delta );
}

my @now = Today_and_Now;
sub swedish_holidays {

    # Given a year as an argument, return as array reference of hash references with the following keys:

    # * date: ISO date
    # * holiday: name of the holiday
    # * sw_date: date in Swedish
    # * legal: <bool>, whether this is a legal holiday or not
    my @array;
    my %dates;
    my $year = shift;
    die "year out of range (1583 to 2299) or bad format: $year\n" if (( $year < 1583 or $year > 2299) or $year !~ m/\d{4}/) ;

    ### constants

    my $MS_MIN = '06-20'; # midsummer's day is first Saturday after this date
    my $AH_MIN = '10-31'; # All Saints Day is first Saturday after this date 


    my $fixed_dates = { 'Nyårsdagen' => '01-01',           # New Years Day
			'Trettondagen' =>	'01-06',   # Epiphany
			'Första maj' => '05-01',           # May Day
			'Sveriges nationaldag' => '06-06', # National day
			'Juldagen' => '12-25',             # Christmas Day 
			'Annandag jul' =>	'12-26'};  # Boxing day

    my $holidays = {};
    ### calculate moveable feasts 

    my @paskdagen = Easter_Sunday( $year );
    # Easter Day
    push @array, {holiday=>'Påskdagen',legal=>1,emoji=>'🐣',  %{date_info( @paskdagen )}};
    # Good Friday
    push @array, {holiday=>'Långfredagen', legal=>1,emoji=>'✝',  %{date_info( add_day(@paskdagen,-2) )}};
    # Easter Monday
    push @array, {holiday=>'Annandag påsk', legal=>1,  %{date_info( add_day(@paskdagen,1) )}};
    # Ascension Day
    push @array, {holiday=>'Kristi Himmelsfärdsdagen', legal=>1,  %{date_info( add_day(@paskdagen,39) )}};
    # Pentecost
    push @array, {holiday=>'Pingstdagen', legal=>1,  %{date_info( add_day(@paskdagen,49) )}};

    # search for first Saturday after some dates
    my @midsommar = ( $year, split('-', $MS_MIN) );
    while ( Day_of_Week(@midsommar) != 6 ) {
	@midsommar = add_day( @midsommar, 1 );
    }
    push @array, {holiday=>'Midsommardagen', legal=>1,  %{date_info( @midsommar )}};
    push @array, {holiday=>'Midsommarafton',legal=>0, %{date_info(add_day(@midsommar,-1))}};
    my @allhelgona = ( $year, split('-', $AH_MIN) );
    while ( Day_of_Week(@allhelgona) != 6 ) {
	@allhelgona = add_day( @allhelgona,1 );
    }
    push @array, {holiday=>'Alla helgons dag', legal=>1, emoji=>'🎃', %{date_info( @allhelgona )}};

    foreach my $holiday ( keys %{$fixed_dates} ) {
	my $date = $fixed_dates->{$holiday};
	$holidays->{$holiday} = date_info($year, split('-', $date));
	push @array, {holiday=>$holiday, legal=>1,  %{date_info( $year, split('-',$date))}};
    }
    # add some customary holidays

    push @array, {holiday=>'Julafton', legal=>0, emoji=>'🎅',%{date_info($year,12,24)}};
    push @array, {holiday=>'Nyårsafton', legal=>0, emoji=>'🎆', %{date_info($year,12,31)}};
    for my $m (1..12) {
	my $di = date_info( $year, $m, 13 );

	if ($di->{DoW}==5) { # fri 13th
	    push @array, {holiday=>"Fredag den 13:e " .swedish_months( $m), legal=>0, date=>$di->{date}, sw_date=>$di->{sw_date}, emoji=>'🍾'};
	}
    }
    if ($year == $now[0]) {
	push @array, {holiday=>'Idag', legal=>0, %{date_info( @now[0..2])}};
    }

    return \@array;

}

sub swedish_weekdays {
    my @wd_names = qw(måndag tisdag onsdag torsdag fredag lördag söndag);
    my $DoW = shift;
    die "weekday index out of range (1 to 7) or bad format: $DoW\n" unless (( $DoW > 0 and $DoW < 8 ) and $DoW =~ m/\d{1}/ );
#    return $DoW;
    return $wd_names[$DoW - 1];

}

sub swedish_months {
    my @month_names = qw ( januari februari mars april maj juni juli augusti september oktober november december );
    my $mon = shift;
    die "month index out of range (1 to 12) or bad format: $mon\n" unless (( $mon > 0 and $mon < 13) and $mon =~ m/\d+/ );
    return $month_names[$mon - 1];
}

1;
