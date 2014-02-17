#!/usr/bin/perl -w
my @sqlinput=();
my @sqloutput=();

use strict;
use CGI qw(:standard);
use DBI;
use Time::ParseDate;
use Time::Local;

my $dbuser="UUUUU";
my $dbpasswd="XXXXX";


my $cookiename="PortfolioSession";
my $inputcookiecontent = cookie($cookiename);
my $outputcookiecontent = undef;
my $deletecookie=0;
my $user = undef;
my $password = undef;
my $logincomplain=0;

my $action;
my $run;

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

if (defined(param("act"))) { 
  $action=param("act");
  if (defined(param("run"))) { 
    $run = param("run") == 1;
  } else {
    $run = 0;
  }
} else {
  $action="base";
  $run = 1;
}

if (defined($inputcookiecontent)) { 
  # Has cookie, let's decode it
  ($user,$password) = split(/\//,$inputcookiecontent);
  $outputcookiecontent = $inputcookiecontent;
} else {
  # No cookie, treat as anonymous user
  ($user,$password) = ("anon","anonanon");
}

if ($action eq "login") { 
  if ($run) { 
    ($user,$password) = (param('user'),param('password'));
    if (ValidUser($user,$password)) { 
      # if the user's info is OK, then give him a cookie
      # that contains his username and password 
      # the cookie will expire in one hour, forcing him to log in again
      # after one hour of inactivity.
      # Also, land him in the base query screen
      $outputcookiecontent=join("/",$user,$password);
      $action = "base";
      $run = 1;
    } else {
      # uh oh.  Bogus login attempt.  Make him try again.
      # don't give him a cookie
      $logincomplain=1;
      $action="login";
      $run = 0;
    }

  } else {
    #
    # Just a login screen request, but we should toss out any cookie
    # we were given
    #
    undef $inputcookiecontent;
    ($user,$password)=("anon","anonanon");
  }
}




#
# If we are being asked to log out, then if 
# we have a cookie, we should delete it.
#
my $loggedout = undef;
if ($action eq "logout") {
  $deletecookie=1;
  $action = "base";
  $loggedout = 1;
  $user = "anon";
  $password = "anonanon";
  $run = 1;
  #undef $outputcookiecontent;
}

sub ValidUser {
  my ($user,$password)=@_;
  my @col;
  eval {
  	@col=ExecSQL($dbuser,$dbpasswd, "select count(*) from portfolio_user where email=? and password=?","COL",$user,$password);
  };
  if ($@) { 
    return 0;
  } else {
    return $col[0]>0;
  }
}

my $registercomplain = 0;
if ($action eq "registeruser") {
  if ($run) { 
    ($user,$password) = (param('user'),param('password'));
    my @result;
    eval {
      ExecSQL($dbuser, $dbpasswd, "insert into portfolio_user (email, password) values (?,?)", "COL", $user, $password);
    }; 
    if ($@) {
      $registercomplain=1;
      $action="register";
      $run = 0;
    } else {
      $outputcookiecontent=join("/",$user,$password);
      $action = "base";
      $run = 1;
    }  
  }  
}

if ($action eq "deposit") {
	my $amount = param("deposit");
  my $portfolio = param("portfolio");
	my @result = undef;
	eval { 
		@result = ExecSQL($dbuser,$dbpasswd,"select cash_balance from portfolio where user_email=? and name=?", "COL", $user, $portfolio);
	};
	if (@result) {
		my $new_amount = $result[0] + $amount;
		eval {
			ExecSQL($dbuser, $dbpasswd, "update portfolio set cash_balance=? where user_email=? and name=?", undef, $new_amount, $user, $portfolio);
		};
	}
  $action = "base";		
}

if ($action eq "withdraw") {
	my $amount = param("withdraw");
  my $portfolio = param("portfolio");
	my @result = undef;
	eval { 
		@result = ExecSQL($dbuser,$dbpasswd,"select cash_balance from portfolio where user_email=? and name=?", "COL", $user, $portfolio);
	};	
	if (@result) {
		my $new_amount = $result[0] - $amount;
		eval {
			ExecSQL($dbuser, $dbpasswd, "update portfolio set cash_balance=? where user_email=? and name=?", undef, $new_amount, $user, $portfolio);
		};
	}
  $action = "base";
}

if ($action eq "buy") {
  my $symbol = param("symbol");
  my $quantity = param("quantity");
  my $portfolio = param("portfolio");
  my @result = undef;
  my @count = undef;
  eval {
    @count = ExecSQL($dbuser, $dbpasswd, "select count(symbol) from all_data where symbol=?","COL",$symbol);
  };
  if ($count[0] > 0) {
    eval {
      @result = ExecSQL($dbuser, $dbpasswd, "select quantity from users_stock where user_email=? and symbol=? and portfolio_name=?", "COL", $user, $symbol, $portfolio);
    };
    my $new_quantity = 0;  
    if (@result) {
      $new_quantity = $result[0] + $quantity;   
      eval {
        ExecSQL($dbuser, $dbpasswd, "update users_stock set quantity=? where user_email=? and symbol=? and portfolio_name=?", undef, $new_quantity, $user, $symbol, $portfolio);
      };
    } else {
      $new_quantity = $quantity;  
      eval {
        ExecSQL($dbuser, $dbpasswd, "insert into users_stock (user_email, symbol, quantity, portfolio_name) values (?,?,?,?)", undef, $user, $symbol, $new_quantity, $portfolio);
      };   
    }
  }  
  $action = "base";
}

if ($action eq "sell") {
  my $symbol = param("symbol");
  my $quantity = param("quantity");
  my $portfolio = param("portfolio");
  my @result = undef;
  my @count = undef;
  eval {
    @count = ExecSQL($dbuser, $dbpasswd, "select count(symbol) from all_data where symbol=?","COL",$symbol);
  };
  if ($count[0] > 0) {
    eval {
      @result = ExecSQL($dbuser, $dbpasswd, "select quantity from users_stock where user_email=? and symbol=? and portfolio_name=?", "COL", $user, $symbol, $portfolio);
    };
    my $new_quantity = 0;  
    if (@result) {
      $new_quantity = $result[0] - $quantity;   
      eval {
        ExecSQL($dbuser, $dbpasswd, "update users_stock set quantity=? where user_email=? and symbol=? and portfolio_name=?", undef, $new_quantity, $user, $symbol, $portfolio);
      };
    } else {
      $new_quantity = -$quantity;  
      eval {
        ExecSQL($dbuser, $dbpasswd, "insert into users_stock (user_email, symbol, quantity, portfolio_name) values (?,?,?,?)", undef, $user, $symbol, $new_quantity, $portfolio);
      };   
    } 
  }   
  $action = "base";
}

if ($action eq "new") {
  my $symbol = param("symbol");
  my $open = param("open");
  my $close = param("close");
  my $low = param("low");
  my $high = param("high");
  my $volume = param("volume");
  my $date = param("timestamp");
  my @datearr = split('-', $date);
  my $day = $datearr[2];
  my $month = $datearr[1];
  my $year = $datearr[0];
  my $timestamp = timelocal(0,0,0,$day,$month,$year);
  eval {
    ExecSQL($dbuser, $dbpasswd, "insert into new_data (symbol, timestamp, open, close, low, high, volume) values (?,?,?,?,?,?,?)", undef, $symbol, $timestamp, $open, $close, $low, $high, $volume);
  };
  $action = "base";
}

if ($action eq "newportfolio") {
  my $portfolio = param("portfolio");
  eval {
    ExecSQL($dbuser, $dbpasswd, "insert into portfolio (name, user_email, cash_balance) values (?,?,?)", undef, $portfolio, $user, 0);
  };
  $action = "base";
}

my @outputcookies;

if (defined($outputcookiecontent)) { 
  my $cookie=cookie(-name=>$cookiename,
		    -value=>$outputcookiecontent,
		    -expires=>($deletecookie ? '-1h' : '+1h'));
  push @outputcookies, $cookie;
} 

print header(-expires=>'now', -cookie=>\@outputcookies);



print '
  <!DOCTYPE HTML>
    <html>
      <head>
        <title>Portfolio</title>
        <link href="css/bootstrap.min.css" rel="stylesheet">
        <script src="//ajax.googleapis.com/ajax/libs/jquery/2.0.3/jquery.min.js"></script>
        <script type="text/javascript" src="js/portfolio.js"></script>
      </head>
      <body>
        <div class="container">
';

if ($action eq "base" || $action eq "login" || $action eq "logout") {
  if (!defined($outputcookiecontent) || defined($loggedout)) {
    if ($logincomplain) { 
      print "Login failed.  Try again.<p>";
    }         
    print '
    <div class="row">
      <div class="col-md-6 col-md-offset-3">
        <h3>Log into your portfolio</h3>
      </div>
    </div>    
    <div class="row" style="padding-top:2em">
      <div class="col-md-6 col-md-offset-3">
        <form method="POST" class="form-horizontal" role="form">
          <div class="form-group">
            <label for="inputEmail3" class="col-sm-2 control-label">Email</label>
            <div class="col-sm-10">
              <input type="email" class="form-control" id="inputEmail3" placeholder="Email" name="user">
            </div>
          </div>
          <div class="form-group">
            <label for="inputPassword3" class="col-sm-2 control-label">Password</label>
            <div class="col-sm-10">
              <input type="password" class="form-control" id="inputPassword3" placeholder="Password" name="password">
            </div>
          </div>
          <div class="form-group">
            <div class="col-sm-offset-2 col-sm-10">
              <input type="hidden" name="act" value="login">
              <input type="hidden" name="run" value="1">
              <button type="submit" class="btn btn-primary">Sign in</button>
            </div>
          </div>
        </form>
        <form method="POST" class="form-horizontal" role="form">
          <div class="form-group">
            <div class="col-sm-offset-2 col-sm-10">
              <p>New user?</p>
              <input type="hidden" name="act" value="register">
              <input type="hidden" name="run" value="1">
              <button type="submit" class="btn btn-info">Register</button>
            </div>
          </div>
        </form>
      </div>
    </div>
    ';
  } else {
    print '  
     <div class="page-header">
      <a class="pull-right" href="application_design.pdf">Application Design</a>
      <br>
      <a class="pull-right" href="er_diagram.pdf">ER Diagram</a>
      <br>
      <a class="pull-right" href="relational_design.pdf">Relational Design</a>
      <br>
      <a class="pull-right" href="code.tar.gz">Code Tarball</a>
      <h1>Portfolio</h1>
      <form method="POST">
        <input type="hidden" name="act" value="logout">
        <input type="hidden" name="run" value="1">
        <button type="submit" class="btn btn-primary btn-xs" style="width:6em">Logout</button>
      </form>

  	 </div>';
    print 'Portfolio: <select id="portfolio">';
    print '<option value="select holder">Select portfolio</option>';
    my @portfolios = undef;
    eval {
      @portfolios = ExecSQL($dbuser,$dbpasswd,"select name from portfolio where user_email=?","COL",$user);
    };
    foreach(@portfolios) {
      print '<option value='.$_.'>'.$_.'</option>';
    }
    print '</select>  ';
    print 'New portfolio: 
      <input type="text" id="portfolio-name" placeholder="Portfolio Name">
      <input type="hidden" id="current-portfolio">
      <button type="button" id="portfolio-button" class="btn btn-primary btn-xs">Submit</button>';
    my $portfolio = param("portfolio");
    print '<div class="row" id="portfolio-info">';
    if (defined($portfolio)) {
      print '   
      		<div class="col-md-6">
            <div class="row">
      			<h4>Cash Account</h4>
      			<p id="balance">Balance:
      	';
      	my @result = undef;
        
      	eval { 
      		@result = ExecSQL($dbuser,$dbpasswd,"select cash_balance from portfolio where user_email=? and name=?", "COL", $user, $portfolio);
      	};
      	print $result[0];
      	print '
          		</p>
              <input type="number" step="any" min="0" required id="deposit-input" placeholder="Amount" name="deposit">
              <button type="button" id="deposit-button" class="btn btn-primary btn-xs" style="width:6em">Deposit</button>
              <br>
              <input type="number" step="any" min="0" required id="withdraw-input" placeholder="Amount" name="withdraw">
              <button type="button" id="withdraw-button" class="btn btn-primary btn-xs" style="width:6em">Withdraw</button>	
              </div>
              <div class="row">
                <br>
                <h4>Automated trading strategy</h4>
                Stock: <select id="auto-symbol">';
        my @currentstocks = undef;
        eval {
          @currentstocks = ExecSQL($dbuser,$dbpasswd, "select symbol from users_stock where user_email=? and portfolio_name=?","COL",$user, $portfolio);
        };
        foreach(@currentstocks) {
          print '<option value='.$_.'>'.$_.'</option>';
        }
        print '</select>
              <br>
              Start: <input type="date" id="start-date">          
              <br>
              End: <input type="date" id="end-date">
              <br>
              Amount ($): <input type="number" step="any" min="0" required id="auto-amount" placeholder="Amount" name="amount">
              <br>
              Trading cost: <input type="number" step="any" min="0" required id="trading-cost" placeholder="Trading Cost" name="trading-cost">
              <br>
              <button type="button" id="auto-button" class="btn btn-primary btn-xs">Run strategy</button> 
              <br>
              <p id="auto-stats">
              </p>
              </div>
            </div>
          	<div class="col-md-6">	
          		<h4>Stocks</h4>
        ';
        my @stocks = undef;
        my $stockquery = "select stock_data.symbol, user_data.quantity, stock_data.close, user_data.quantity*stock_data.close 
          from (select symbol, close from all_data stock where symbol in (select symbol from users_stock where user_email=? and portfolio_name=?) and timestamp = (select max(timestamp) 
          from all_data where symbol = stock.symbol)) stock_data left outer join (select symbol, quantity from users_stock where user_email=? and portfolio_name=?) user_data 
          on stock_data.symbol=user_data.symbol order by stock_data.symbol";
        eval {
          @stocks = ExecSQL($dbuser,$dbpasswd,$stockquery, undef, $user, $portfolio, $user, $portfolio);
        };  
        my $stockstable = undef;
        $stockstable = MakeTable("stocks-table", "STOCKS", ["Symbol", "Quantity", "Close", "Present Value"],@stocks);
        print $stockstable;
        print '<select id="symbol1">';
        foreach(@currentstocks) {
          print '<option value='.$_.'>'.$_.'</option>';
        }
        print "</select>";
        print '<select id="symbol2">';
        foreach(@currentstocks) {
          print '<option value='.$_.'>'.$_.'</option>';
        }
        print "</select>";
        print '<button type="button" id="cov-button" class="btn btn-primary btn-xs">Show covariance matrix</button><br><br>';     
        print '          
              <input type="text" required id="buy-symbol" placeholder="Stock Symbol" name="symbol">
              <input type="number" step="any" min="0" required id="buy-quantity" placeholder="Quantity" name="quantity">
              <button type="button" id="buy-button" class="btn btn-primary btn-xs" style="width:6em">Bought</button>
              <br>  
              <input type="text" required id="sell-symbol" placeholder="Stock Symbol" name="symbol">
              <input type="number" step="any" min="0" required id="sell-quantity" placeholder="Quantity" name="quantity">
              <button type="button" id="sell-button" class="btn btn-primary btn-xs" style="width:6em">Sold</button>
          	  <br>
              <br>  
              <input type="text" required id="new-symbol" placeholder="Stock Symbol" name="symbol">
              <input type="number" step="any" min="0" required id="open-price" placeholder="Open" name="open">
              <input type="number" step="any" min="0" required id="close-price" placeholder="Close" name="close">
              <input type="number" step="any" min="0" required id="low-price" placeholder="Low" name="low">
              <input type="number" step="any" min="0" required id="high-price" placeholder="High" name="high">
              <input type="number" step="any" min="0" required id="volume" placeholder="Volume" name="volume">
              <input type="date" id="timestamp">
              <button type="button" id="new-button" class="btn btn-primary btn-xs" style="width:6em">New Info</button>
              <br>
        ';    
        print '</div>';  
    }
    print '</div>';
  }
}

if ($action eq "register") {
  if ($registercomplain) { 
      print "Registration failed.  Try again.<p>";
    }  
  print '
    <div class="row">
      <div class="col-md-6 col-md-offset-3">
        <h3>Enter an email and password</h3>
      </div>
    </div>    
    <div class="row" style="padding-top:2em">
      <div class="col-md-6 col-md-offset-3">
        <form method="POST" class="form-horizontal" role="form">
          <div class="form-group">
            <label for="inputEmail3" class="col-sm-2 control-label">Email</label>
            <div class="col-sm-10">
              <input type="email" class="form-control" id="inputEmail3" placeholder="Email" name="user">
            </div>
          </div>
          <div class="form-group">
            <label for="inputPassword3" class="col-sm-2 control-label">Password</label>
            <div class="col-sm-10">
              <input type="password" class="form-control" id="inputPassword3" placeholder="Password" name="password">
            </div>
          </div>
          <div class="form-group">
            <div class="col-sm-offset-2 col-sm-10">
              <input type="hidden" name="act" value="registeruser">
              <input type="hidden" name="run" value="1">
              <button type="submit" class="btn btn-primary">Register</button>
            </div>
          </div>
        </form>
      </div>
    </div>    
  ';
}

if ($action eq "info") {
  my $symbol = param("symbol");
  print '
    <div class="page-header">
      <h1>' . $symbol . '</h1>
      <form method="POST">
        <input type="hidden" name="act" value="logout">
        <input type="hidden" name="run" value="1">
        <button type="submit" class="btn btn-primary btn-xs" style="width:6em">Logout</button>
      </form>
     </div> 
  ';
}

print '</div>
      </body>
      </html>
';





#
#
#
#Copied from rwb.pl, deleted anything using debug variable
#
sub MakeTable {
  my ($id,$type,$headerlistref,@list)=@_;
  my $out;
  #
  # Check to see if there is anything to output
  #
  if ((defined $headerlistref) || ($#list>=0)) {
    # if there is, begin a table
    #
    $out="<table id=\"$id\" class=\"table table-condensed table-bordered\">";
    #
    # if there is a header list, then output it in bold
    #
    if (defined $headerlistref) { 
      $out.="<tr>".join("",(map {"<th>$_</th>"} @{$headerlistref}))."</tr>";
    }
    #
    # If it's a single row, just output it in an obvious way
    #
    if ($type eq "ROW") { 
      #
      # map {code} @list means "apply this code to every member of the list
      # and return the modified list.  $_ is the current list member
      #
      $out.="<tr>".(map {defined($_) ? "<td>$_</td>" : "<td>(null)</td>" } @list)."</tr>";
    } elsif ($type eq "COL") { 
      #
      # ditto for a single column
      #
      $out.=join("",map {defined($_) ? "<tr><td>$_</td></tr>" : "<tr><td>(null)</td></tr>"} @list);
    } elsif ($type eq "STOCKS") {
      foreach my $row (@list) {
        $out.="<tr>";
        my @cells = map {"<td>$_</td>"} @{$row};
        my $symbolstart = substr $cells[0], 4;
        my $symbol = substr $symbolstart, 0, -5;
        $out.="<td><a href=\"stock.pl?symbol=$symbol\">$symbol</a></td>";
        $out.=join("", @cells[1..$#cells]);
        $out.="</tr>";
      }
    } else { 
      #
      # For a 2D table, it's a bit more complicated...
      #
      $out.= join("",map {"<tr>$_</tr>"} (map {join("",map {defined($_) ? "<td>$_</td>" : "<td>(null)</td>"} @{$_})} @list));
    }
    $out.="</table>";
  } else {
    # if no header row or list, then just say none.
    $out.="(none)";
  }
  return $out;
}

sub MakeRaw {
  my ($id, $type,@list)=@_;
  my $out;
  #
  # Check to see if there is anything to output
  #
  $out="<pre id=\"$id\">\n";
  #
  # If it's a single row, just output it in an obvious way
  #
  if ($type eq "ROW") { 
    #
    # map {code} @list means "apply this code to every member of the list
    # and return the modified list.  $_ is the current list member
    #
    $out.=join("\t",map { defined($_) ? $_ : "(null)" } @list);
    $out.="\n";
  } elsif ($type eq "COL") { 
    #
    # ditto for a single column
    #
    $out.=join("\n",map { defined($_) ? $_ : "(null)" } @list);
    $out.="\n";
  } else {
    #
    # For a 2D table
    #
    foreach my $r (@list) { 
      $out.= join("\t", map { defined($_) ? $_ : "(null)" } @{$r});
      $out.="\n";
    }
  }
  $out.="</pre>\n";
  return $out;
}

sub ExecSQL {
  my ($user, $passwd, $querystring, $type, @fill) =@_;

  my $dbh = DBI->connect("DBI:Oracle:",$user,$passwd);
  if (not $dbh) { 
    # if the connect failed, record the reason to the sqloutput list (if set)
    # and then die.
    die "Can't connect to database because of ".$DBI::errstr;
  }
  my $sth = $dbh->prepare($querystring);
  if (not $sth) { 
    #
    # If prepare failed, then record reason to sqloutput and then die
    #
    my $errstr="Can't prepare $querystring because of ".$DBI::errstr;
    $dbh->disconnect();
    die $errstr;
  }
  if (not $sth->execute(@fill)) { 
    #
    # if exec failed, record to sqlout and die.
    my $errstr="Can't execute $querystring with fill (".join(",",map {"'$_'"} @fill).") because of ".$DBI::errstr;
    $dbh->disconnect();
    die $errstr;
  }
  #
  # The rest assumes that the data will be forthcoming.
  #
  #
  my @data;
  if (defined $type and $type eq "ROW") { 
    @data=$sth->fetchrow_array();
    $sth->finish();
    $dbh->disconnect();
    return @data;
  }
  my @ret;
  while (@data=$sth->fetchrow_array()) {
    push @ret, [@data];
  }
  if (defined $type and $type eq "COL") { 
    @data = map {$_->[0]} @ret;
    $sth->finish();
    $dbh->disconnect();
    return @data;
  }
  $sth->finish();
  $dbh->disconnect();
  return @ret;
}