#!/usr/bin/perl -w

use strict;
use CGI qw(:standard);
use DBI;
use Time::ParseDate;
use Time::CTime;
use Getopt::Long;
use Time::Local;
use POSIX qw(strftime);

use FileHandle;

BEGIN {
  $ENV{PORTF_DBMS}="oracle";
  $ENV{PORTF_DB}="DDDDD";
  $ENV{PORTF_DBUSER}="UUUUU";
  $ENV{PORTF_DBPASS}="XXXXX";
  $ENV{PATH} = $ENV{PATH} . ":/home/UUUUU/www/Project-2";

  unless ($ENV{BEGIN_BLOCK}) {
    use Cwd;
    $ENV{ORACLE_BASE}="/raid/oracle11g/app/oracle/product/11.2.0.1.0";
    $ENV{ORACLE_HOME}=$ENV{ORACLE_BASE}."/db_1";
    $ENV{ORACLE_SID}="DDDDD";
    $ENV{LD_LIBRARY_PATH}=$ENV{ORACLE_HOME}."/lib";
    $ENV{BEGIN_BLOCK} = 1;
    exec 'env',cwd().'/'.$0,@ARGV;
  }
};

use stock_data_access;
my $symbol = param("symbol");
my $type = param("type");

if (!defined($type)) {
	my @outputcookies;
	print header(-expires=>'now', -cookie=>\@outputcookies);
	print '
	  <!DOCTYPE HTML>
	    <html>
	      <head>
	        <title>Portfolio</title>
	        <link href="css/bootstrap.min.css" rel="stylesheet">
	        <script src="//ajax.googleapis.com/ajax/libs/jquery/2.0.3/jquery.min.js"></script>
	        <script type="text/javascript" src="js/stock.js"></script>
	      </head>
	      <body>
	        <div class="container">
	    			<div class="page-header">
	      			<h1>' . $symbol . '</h1>
	     			</div>
	';
	print '
		<div class="row">
			<div class="col-md-12">';
	my $date = strftime "%m/%d/%Y", localtime;
	my $result = `getCOVBeta.pl --field close --from 1/1/1990 --to $date $symbol`;
	my @results = split('\t', $result);
  print "<h4>Statistics compared to SPY since 1990</h4>";
	print "Coefficient of variation: $results[0] Beta: $results[1]";
			print '	<h4>Plot of old and new data</h4>
				<label>Start date: </label> 
				<input type="date" id="start">
				<label>End date: </label> 
				<input type="date" id="end">
				<input type="hidden" id="symbol" value='.$symbol.'>
				<button type="button" id="submit-button" class="btn btn-primary btn-xs">Submit</button>
				<div id="past-div">
					<img id="past-plot" src="stock.pl?symbol='.$symbol.'&type=past">
				</div>
			</div>	
		</div>
		<div class="row">
			<div class="col-md-12">
				<h4>Plot of predicted data</h4>
				<label>Days before: </label>
				<input type="number" step="any" min="0" required id="previous" placeholder="Days before" name="previous" value="200">
				<label>Days after: </label>
        <input type="number" step="any" min="0" required id="future" placeholder="Days after" name="future" value="200">
        <input type="hidden" id="symbol" value='.$symbol.'>
        <button type="button" id="predict-button" class="btn btn-primary btn-xs">Predict</button>
				<div id="future-div">
					<img id="future-plot" src="stock.pl?symbol='.$symbol.'&previous=200&future=200&type=future">
				</div>	
			</div>	
		</div>
		<a href="plot_stock.pl?symbol='.$symbol.'&type=text">Table</a>
		';

		
	print '
	  			</div>
	  	</body>
	  </html>
	';
}

if ($type eq "past") {
	my $start = param("start");
	my $end = param("end");
	my @rows = undef;
  if (!defined($start) || !defined($end)) {
		@rows = ExecStockSQL("2D","select timestamp, close from all_data where symbol=? order by timestamp",$symbol);
	} else {
		my @datearr1 = split('-', $start);
	  my $day1 = $datearr1[2];
	  my $month1 = $datearr1[1];
	  my $year1 = $datearr1[0];
	  my $timestamp1 = timelocal(0,0,0,$day1,$month1,$year1);
	  my @datearr2 = split('-', $end);
	  my $day2 = $datearr2[2];
	  my $month2 = $datearr2[1];
	  my $year2 = $datearr2[0];
	  my $timestamp2 = timelocal(0,0,0,$day2,$month2,$year2);
		@rows = ExecStockSQL("2D","select timestamp, close from all_data where symbol=? and timestamp>? and timestamp<? order by timestamp",$symbol, $timestamp1, $timestamp2);
	}	
	print header(-type => 'image/png', -expires => '-1h' );
	open(GNUPLOT,"| gnuplot") or die "Cannot run gnuplot";
	print GNUPLOT "set term png\n";           # we want it to produce a PNG
	print GNUPLOT "set output\n";             # output the PNG to stdout
	print GNUPLOT "plot '-' using 1:2 with linespoints\n"; # feed it data to plot
	foreach my $r (@rows) {
	  print GNUPLOT $r->[0], "\t", $r->[1], "\n";
	}
	print GNUPLOT "e\n"; # end of data
	close(GNUPLOT);	
}	

if ($type eq "future") {
	my $previous = param("previous");
	my $future = param("future");
  my @rows = `time_series_symbol_project.pl $symbol $previous AWAIT $future AR 16`;
  my $length = $#rows;
  my @newrows = @rows[$length-199..$length];
  print header(-type => 'image/png', -expires => '-1h' );
  open(GNUPLOT,"| gnuplot") or die "Cannot run gnuplot";
	print GNUPLOT "set term png\n";           # we want it to produce a PNG
	print GNUPLOT "set output\n";             # output the PNG to stdout
	print GNUPLOT "plot '-' using 1:2 with linespoints\n"; # feed it data to plot
  foreach (@newrows) {
		my @cells = split(' ', $_);
		print GNUPLOT $cells[0], "\t", $cells[2], "\n";
	}	
	print GNUPLOT "e\n"; # end of data
	close(GNUPLOT);	
}

if ($type eq "auto") {
	my $start = param("start");
	my $end = param("end");
	my $amount = param("amount");
	my $tradingcost = param("tradingcost");
	my @startarr = split('-', $start);
	my @endarr = split('-', $end);
	my $startdate = $startarr[1].'/'.$startarr[2].'/'.$startarr[0];
	my $enddate = $endarr[1].'/'.$endarr[2].'/'.$endarr[0];
	my $call = "shannon_ratchet.pl $symbol $amount $tradingcost $startdate $enddate";
	my $result = `$call`;
	print header(-type => 'text/html', -expires => '-1h' );
	print '
	  <!DOCTYPE HTML>
	    <html>
	    	<body>
	    		<div>
	    		<p id="results">
	    			Results:
	    			<br>
	';
	print $result;
	print '
		</p>
		</div>
		</body>
		</html>
	';
}

if ($type eq "cov") {
	my $symbol1 = param("symbol1");
	my $symbol2 = param("symbol2");
	my @results = `get_covar.pl --field1 close --field2 close --from 1/1/1990 --to 11/15/2013 $symbol1 $symbol2`;
	print header(-type => 'text/html', -expires => '-1h' );
	print '
	<!DOCTYPE HTML>
	    <html>
	    	<body>
	    		<div id="results">
	';
	foreach (@results) {
		print "$_<br>";
	}
	print '
		</div>
		</body>
		</html>
	';
}

