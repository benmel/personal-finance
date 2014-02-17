#!/usr/bin/perl

use Getopt::Long;
use Time::ParseDate;
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

$close=1;

$field='close';

&GetOptions("field=s" => \$field,
	    "from=s" => \$from,
	    "to=s" => \$to);

if (defined $from) { $from=parsedate($from);}
if (defined $to) { $to=parsedate($to); }


$#ARGV>=0 or die "usage: get_info.pl [--field=field] [--from=time] [--to=time] SYMBOL+\n";

while ($symbol=shift) {
  $sql = "select avg($field), stddev($field)  from all_data where symbol='$symbol'";
  $sql.= " and timestamp>=$from" if $from;
  $sql.= " and timestamp<=$to" if $to;

  ($mean,$std) = ExecStockSQL("ROW",$sql);

  my @covArr = `get_covar.pl --field1 close --field2 close --from $from --to $to $symbol SPY`;
  my $row = $covArr[5];
  my @covRow = split(" ", $row);
  my $covar = $covRow[2];
  
  
  $sql = "select avg($field), stddev($field) from all_data where symbol='SPY'";
  $sql.= " and timestamp>=$from" if $from;
  $sql.= " and timestamp<=$to" if $to;
  ($meanY,$stdY) = ExecStockSQL("ROW",$sql);
  my $covY = $stdY/$meanY;
  my $beta = $covar/$covY;
  my $cov = $std/$mean;
  print join("\t",$cov, $beta),"\n";
  
}
