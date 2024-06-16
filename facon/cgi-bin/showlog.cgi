#!/usr/bin/perl -Tw
# showlog.cgi - show log files
# CVS $Id: showlog.cgi.in,v 1.15 2003/05/20 19:28:05 remstats Exp $
# from remstats 1.0.13a
# Copyright 1999 - 2003 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Configuration   - - -

use strict;

# What is this program called, for file-names and error-messages.
$main::prog = 'showlog.cgi';
# So -T will stop whinging.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ed857416/3p/remstats/bin';
# Where is the config dir
$main::config_dir = '/home/ed857416/3p/remstats/etc/config';
# Where is the event logger
$main::logevent = 'You can also <A HREF="/remstats/log-event.cgi">log an event</A>.';
# Debugging anyone?
$main::debug = 0;
# What does an event look like?
#@valid_events = ('ALERT', 'BOOT', 'COMMENT', 'EVENT', 'NEWHOST', 'QUENCH', 'TOPOLOGY');

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.15 $'))[1];

# - - -   Setup   - - -

use lib '.', '/home/ed857416/3p/remstats/lib', '/usr/local/rrdtool/lib/perl';
use Getopt::Std;
use Time::Local;
require "remstats.pl";
require "accessstuff.pl";
require "cgistuff.pl";
require "htmlstuff.pl";

# Don't try to update IP_CACHE; don't have access from cgi
$main::ip_cache_readonly = 1;

my %opt = ();
getopts("d:f:h", \%opt);

if (defined $opt{'h'}) { &usage; } # no return
if (defined $opt{'f'}) { $main::config_dir = $opt{'f'}; }
if (defined $opt{'d'}) { $main::debug = $opt{'d'}; }

&read_config_dir($main::config_dir, 'general', 'html', 'links', 'tools');

# Initialize some useful variables
%main::R = &cgi_request;
&cgi_sendheaders('Description: Remstats Log Report');
$main::url = 'http://' . &cgi_var("SERVER_NAME") . ':' .
	&cgi_var('SERVER_PORT');
my $script_name = &cgi_var('SCRIPT_NAME');
if ($script_name =~ m#^/#) { $main::url .= $script_name; }
else { $main::url .= '/'. $script_name; }

$| = 1; # no buffering please

print &cgi_fmtrequest(%main::R) if ( $main::debug);

&abort("access prohibited") unless( &access_control( $main::prog));

%main::indices = &init_indices; # for headers

# When are we interested in?
my ($day, $month, $endday, $endmonth);

if (!defined $main::R{'start'} and !defined $main::R{'end'}) {
	my (undef, undef, undef, $mday, $mon, $year) = localtime;
	++$mon;
	$year += 1900;
	$main::R{'start'} = $main::R{'end'} = sprintf('%04d%02d%02d',
		$year, $mon, $mday);
	&debug("default date = $main::R{'start'}") if ($main::debug);
}
if (defined $main::R{'start'} and !defined $main::R{'end'}) {
	$main::R{'end'} = $main::R{'start'};
}
if (!defined $main::R{'start'} and defined $main::R{'end'}) {
	$main::R{'start'} = $main::R{'end'};
}

my ($previous_day_start, $previous_day_end, $previous_week_start, 
	$previous_week_end, $previous_month_start, $previous_month_end,
	$next_day_start, $next_day_end, $next_week_start, $next_week_end,
	$next_month_start, $next_month_end);

if ($main::R{'start'} =~ /^(-?\d*)$/) { $main::start = $1; }
else { &abort("invalid start '$main::R{'start'}'"); }
if ($main::R{'end'} =~ /^(-?\d*)$/) { $main::end = $1; }
else { &abort("invalid end '$main::R{'end'}'"); }

$main::start = &shift_time( $main::start, -0);
$main::end = &shift_time( $main::end, -0);
&debug("start=$main::start, end=$main::end") if( $main::debug);

$previous_day_start = &shift_time($main::start, -1);
$previous_day_end = $main::start;
$previous_week_start = &shift_time($main::start, -7);
$previous_week_end = $main::start;
$previous_month_start = &shift_time($main::start, -30);
$previous_month_end = $main::start;
$next_day_start = &shift_time($main::start, +1);
$next_day_end = $next_day_start + 60*60*24;
$next_week_start = &shift_time($main::start, +7);
$next_week_end = $next_week_start + 60*60*24*7;
$next_month_start = &shift_time($main::start, +30);
$next_month_end = &shift_time($next_month_start, +30);

$main::previous_day = 
	'start='. $previous_day_start .
	'&end='. $previous_day_end;
$main::previous_week = 
	'start='. $previous_week_start .
	'&end='. $previous_week_end;
$main::previous_month = 
	'start='. $previous_month_start .
	'&end='. $previous_month_end;
$main::next_day = 
	'start='. $next_day_start .
	'&end='. $next_day_end;
$main::next_week = 
	'start='. $next_week_start .
	'&end='. $next_week_end;
$main::next_month = 
	'start='. $next_month_start .
	'&end='. $next_month_end;

(undef, undef, undef, $day, $month) = &split_timestamp($main::start);
$month ++;
if ($day < 10) { $day = '0'. $day; }
if ($month < 10) { $month = '0'. $month; }
(undef, undef, undef, $endday, $endmonth) = &split_timestamp($main::end);
$endmonth ++;
if ($endday < 10) { $endday = '0'. $endday; }
if ($endmonth < 10) { $endmonth = '0'. $endmonth; }

my (@log_files, $when, $startdate, $enddate, $thisdate, $previous_day, 
	$next_day, $previous_week, $next_week, $previous_month, $next_month);

my @files = &list_files( $main::config{LOGDIR}, '.*\.log$');
@log_files = ();
$startdate = $month . $day;
$enddate = $endmonth . $endday;
&debug("startdate=$startdate, enddate=$enddate") if ($main::debug);

$when = " from $startdate to $enddate";
foreach my $file (@files) {
	&debug("checking file $file") if ($main::debug>1);
	if ($file =~ /(\d\d\d\d)\.log$/i) { $thisdate = $1; }
	else {
		&debug("skipping junk file '$file'") if ($main::debug);
		next;
	}

# Wrap-around range (i.e. over year-end)
	&debug("  this=$thisdate, start=$startdate, end=$enddate") if ($main::debug>1);
	if ($startdate > $enddate) {
		if ($thisdate >= $startdate or $thisdate <= $enddate) {
			&debug("  keeping $thisdate") if ($main::debug);
			push @log_files, $file;
		}
	}
	else {
		if ($thisdate >= $startdate and $thisdate <= $enddate) {
			&debug("  keeping $thisdate") if ($main::debug);
			push @log_files, $file;
		}
	}
}

if (defined $main::R{'event'} and $main::R{'event'} =~ /^([a-zA-Z\|]+)/i) {
	$main::event_pat = uc $1;
}
elsif (defined $main::R{'event'} and length($main::R{'event'})>0) {
	&abort("invalid event type '$main::R{'event'}'");
}
else { $main::event_pat = ''; }

if (defined $main::R{'host'} and $main::R{'host'} =~ /^([-a-zA-Z0-9.\|]+)$/) {
	$main::host_pat = lc $1;
}
elsif (defined $main::R{'host'} and length($main::R{'host'})>0) {
	&abort("invalid host pattern '$main::R{'host'}'");
}
else { $main::host_pat = ''; }

if (defined $main::R{'rrd'} and $main::R{'rrd'} =~ /^([-a-zA-Z0-9.\|]+)$/) {
	$main::rrd_pat = lc $1;
}
elsif (defined $main::R{'rrd'} and length($main::R{'rrd'})>0) {
	&abort("invalid rrd pattern '$main::R{'rrd'}'");
}
else { $main::rrd_pat = ''; }

if (defined $main::R{'variable'} and $main::R{'variable'} =~ /^([-a-zA-Z0-9.\|]+)$/) {
	$main::variable_pat = lc $1;
}
elsif (defined $main::R{'variable'} and length($main::R{'variable'}>0)) {
	&abort("invalid variable pattern '$main::R{'variable'}'");
}
else { $main::variable_pat = ''; }

if (defined $main::R{'message'} and $main::R{'message'} =~ /^([-a-zA-Z0-9. \|]+)$/) {
	$main::message_pat = lc $1;
}
elsif (defined $main::R{'message'} and length($main::R{'message'})>0) {
	&abort("invalid message pattern '$main::R{'message'}'");
}
else { $main::message_pat = ''; }

# - - -   Main Line   - - -

&debug("searching files: ".join(', ', @log_files)) if ($main::debug);
print &html_header("Log Report$when", 'Log Report', %main::indices);
print cgi_fmtrequest(%main::R) if ($main::debug);
my $done_header = 0;

my $logs = 0;
foreach my $log_file (@log_files) {
	$logs += &show_log( $log_file, $month, $day);
}
unless ($logs) {
	print "No logfiles available for that time period.\n";
}

# Show the selection form
print <<"EOD_TAIL";
</TABLE>

<P>
<TABLE WIDTH="100%"><TR><TD BGCOLOR="#DDDDDD"><H2>Log Selection</H2></TD></TR></TABLE>
</P>


<FORM METHOD="POST" ACTION="$main::url">
<TABLE ALIGN="CENTER">
<TR>
<TD VALIGN="TOP">Previous: <A HREF="$main::url?$main::previous_day">day</A> 
	<A HREF="$main::url?$main::previous_week">week</A> 
	<A HREF="$main::url?$main::previous_month">month</A></TD>
<TD VALIGN="TOP">Next: <A HREF="$main::url?$main::next_day">day</A>
	<A HREF="$main::url?$main::next_week">week</A> 
	<A HREF="$main::url?$main::next_month">month</A></TD>
</TR>
<TR>
<TD VALIGN="TOP">Date&nbsp;From:&nbsp;<INPUT NAME="start" SIZE=14 VALUE="$main::R{'start'}"></TD>
<TD VALIGN="TOP">To:&nbsp<INPUT NAME="endmonth" SIZE=14 VALUE="$main::R{'end'}"></TD>
</TR>

<TR>
<TD VALIGN="TOP">Event:&nbsp;<INPUT NAME="event" SIZE="12" VALUE="$main::event_pat"></TD>
<TD VALIGN="TOP">Host:&nbsp;<INPUT NAME="host" SIZE="12" VALUE="$main::host_pat"></TD>
</TR>
<TR>
<TD VALIGN="TOP">RRD:&nbsp;<INPUT NAME="rrd" SIZE="10" VALUE="$main::rrd_pat"></TD>
<TD VALIGN="TOP">Variable:&nbsp;<INPUT NAME="variable" SIZE="10" VALUE="$main::variable_pat"></TD>
</TR>
<TR>
<TD COLSPAN="2" VALIGN="TOP">Message:&nbsp;<INPUT NAME="message" SIZE="30" VALUE="$main::message_pat"></TD>
</TR>

<TR>
<TD ALIGN="CENTER" VALIGN="TOP"><INPUT TYPE="SUBMIT" VALUE="Send Query"></TD>
<TD ALIGN="CENTER" VALIGN="TOP"><INPUT TYPE="RESET" VALUE="Clear Form"></TD>
</TR>

</TABLE>
</FORM>
EOD_TAIL

print $main::logevent . &html_footer;

0;

#----------------------------------------------------------------- abort ---
sub abort {
	my ($msg) = @_;
	print <<"EOD_ABORT";
content-type: text/html

<HTML>
<HEAD><TITLE>$main::prog Abort</TITLE></HEAD>
<BODY>
<H1>$main::prog (version $main::version) Abort</H1>
$msg
</BODY>
</HTML>
EOD_ABORT
	exit 1;
}

#------------------------------------------------- debug ---
sub debug {
	my ($msg) = @_;

	print "<BR><B>DEBUG</B>: $msg\n";
}

#-------------------------------------------------- error ---
sub error {
	my ($msg) = @_;

	print "<BR><B>ERROR</B>: $msg\n";
}

#---------------------------------------------------- usage ---
sub usage {
	print STDERR <<"EOD_USAGE";
$main::prog version $main::version
usage: $main::prog [options]
where options are:
	-d ddd  set debugging level to 'ddd'
	-f fff  use 'fff' for config-dir [$main::config_dir]
	-h      show this help
EOD_USAGE
	exit 0;
}

#--------------------------------------------------- show_log ---
sub show_log {
	my ($file, $month, $day) = @_;
	my ($date, $time, $type, $host, $rrd, $var, $value, $msg, $html, $showhost);

	&debug("searching log $file...") if ($main::debug);
	open (LOG, "<$file") or return 0;
	while (<LOG>) {
		chomp;
		($date, $time, $type, $host, $rrd, $var, $value, $msg) = split(' ', $_, 8);
		&debug("  raw data: $date $time $type $host $rrd $var $value $msg") if ($main::debug>1);
		if ($host eq '-') { $host = $showhost = ''; }
		else {
			$showhost = "<A HREF=\"$main::config{HTMLURL}/$host/index.cgi\">$host</A>";
		}
		if ($rrd eq '-') { $rrd = ''; }
		if ($var eq '-') { $var = ''; }
		if ($value eq '-') { $value = ''; }
		else {
			$value = int($value / 100) * 100;  # round off a bit
		}
		if ($msg eq '-') { $msg = ''; }

# Select this record, or not?
		if ( length($main::host_pat)>0 and 
				$host !~ /$main::host_pat/i) {
			&debug("host '$host' doesn't match '$main::host_pat'; skipped")
				if ($main::debug);
			next;
		}
		elsif ( length($main::event_pat)>0 and 
				$type !~ /$main::event_pat/i) {
			&debug("event '$type' doesn't match '$main::event_pat'; skipped")
				if ($main::debug);
			next;
		}
		elsif ( length($main::rrd_pat)>0 and 
				$rrd !~ /$main::rrd_pat/i) {
			&debug("rrd '$rrd' doesn't match '$main::rrd_pat'; skipped")
				if ($main::debug);
			next;
		}
		elsif ( length($main::variable_pat)>0 and 
				$var !~ /$main::variable_pat/i) {
			&debug("variable '$var' doesn't match '$main::variable_pat'; skipped")
				if ($main::debug);
			next;
		}
		elsif ( length($main::message_pat)>0 and 
				$msg !~ /$main::message_pat/i) {
			&debug("message '$msg' doesn't match '$main::message_pat'; skipped")
				if ($main::debug);
			next;
		}
			
		$msg =~ s/\&/&amp;/g;
		$msg =~ s/\</&lt;/g;
		$msg =~ s/\>/&gt;/g;
		unless($main::done_header) {
			$main::done_header = 1;
			$html = <<"EOD_HEADER";

<TABLE BORDER=1 ALIGN="CENTER">
<TR>
<TH VALIGN=TOP>Date</TH>
<TH VALIGN=TOP>Time</TH>
<TH VALIGN=TOP>Type</TH>
<TH VALIGN=TOP>Host</TH>
<TH VALIGN=TOP>RRD</TH>
<TH VALIGN=TOP>Var</TH>
<TH VALIGN=TOP>Value</TH>
<TH VALIGN=TOP>Message</TH>
</TR>
EOD_HEADER
		}

		$html .= <<"EOD_LOG_LINE";
<TR>
	<TD VALIGN="TOP" ALIGN="LEFT">$date</TD>
	<TD VALIGN="TOP" ALIGN="LEFT">$time</TD>
	<TD VALIGN="TOP" ALIGN="LEFT">$type</TD>
	<TD VALIGN="TOP" ALIGN="LEFT">$showhost</TD>
	<TD VALIGN="TOP" ALIGN="LEFT">$rrd</TD>
	<TD VALIGN="TOP" ALIGN="LEFT">$var</TD>
	<TD VALIGN="TOP" ALIGN="RIGHT">$value</TD>
	<TD VALIGN="TOP" ALIGN="LEFT">$msg</TD>
</TR>
EOD_LOG_LINE
	}
	close LOG;
	print $html;
1;
}

#--------------------------------------------------- show_days ---
sub show_days {
	my ($month) = @_;

	my $html = &html_header("Log Report for month $month", 'Log Report', %main::indices);
	$html .= "<HR>\nThere are log files for the following days:<BR>\n<UL>\n";
	$html .= &get_daylist( $month);

	$html .= "</UL>\n". $main::logevent . &html_footer;
	print $html;
}

#-------------------------------------------------- get_daylist ---
sub get_daylist {
	my ($month) = @_;
	my $html = '';
	my %days = ();
	my $thismonth;

	foreach my $file (&list_files( $main::config{LOGDIR})) {
		&debug("looking at log file '$file'") if ($main::debug>1);
		next unless ($file =~ m#/(\d\d)(\d\d)\.log$#);
		$thismonth = $1;
		next unless ($thismonth eq $month);
		$days{$2} = 1;
	}

	foreach my $day (sort keys %days) {
		$html .= " <A HREF=\"$main::url?date=$month$day\">$day</A>\n";
	}

$html;
}

#--------------------------------------------------- get_monthlist ---
sub get_monthlist {
	my %months = ();
	my $html = '';

	foreach my $file (&list_files( $main::config{LOGDIR})) {
		&debug("looking at log file '$file'") if ($main::debug>1);
		next unless ($file =~ m#/(\d\d)\d\d\.log$#);
		$months{$1} = 1;
	}
	foreach my $month (sort keys %months) {
		$html .= " <A HREF=\"$main::url?date=$month\">$month</A>\n";
	}
$html;
}

#--------------------------------------------------- show_months ---
sub show_months {
	my %months = ();

	my $html = &html_header('Log Report', 'Log Report', %main::indices);
	$html .= "<HR>\nThere are log files for the following months:<BR>\n<UL>\n";

	foreach my $file (&list_files( $main::config{LOGDIR})) {
		&debug("looking at log file '$file'") if ($main::debug>1);
		next unless ($file =~ m#/(\d\d)\d\d\.log$#);
		$months{$1} = 1;
	}

	foreach my $month (sort keys %months) {
		$html .= " <A HREF=\"$main::url?$month\">$month</A>\n";
	}
		
	$html .= "</UL>\n". $main::logevent . &html_footer;
	print $html;
}

#--------------------------------------------------- date_shift ---
sub date_shift {
	my ($day, $month, $days_shift) = @_;
	my ($year, $that_day, $that_month, $now, $then, $string);
	$year = (localtime(time()))[5];

	$now = timelocal(0,0,0, $day, $month-1, $year);
	$then = $now + $days_shift*24*60*60;
	(undef, undef, undef, $that_day, $that_month) = localtime($then);
	$string = sprintf( "day=%02d&month=%02d", $that_day, $that_month);

	return $string;
}

#-------------------------------------------------------------- shift_time ---
# shift a date (either timestamp or YYYYMMDD or YYMMDDHHMMSS) by a day
# week or month.
#-----------------------------------------------------------------------------
sub shift_time {
	my ($date, $shift) = @_;
	my ($sec, $min, $hour, $mday, $mon, $year);

	# Deal with YYYYMMDD
	if (length($date) == 8) {
		$year = substr($date,0,4) + 0;
		$mon = substr($date,4,2) - 1;
		$mday = substr($date,6,2) + 0;
		($sec, $min, $hour) = (0,0,0);
		if ($shift == 30) {
			$mon += 1;
			if ($mon > 11) { $mon = 0; $year += 1; }
		}
		if ($shift == -30) {
			$mon -= 1;
			if ($mon < 0) { $mon = 11; $year -= 1; }
		}
		&debug("short date is $year-$mon-$mday-$hour-$min-$sec")
			if( $main::debug);
		$date = timelocal($sec, $min, $hour, $mday, $mon, $year);
		if ($shift >= -7 and $shift <= 7) {
			$date += $shift * 60*60*24;
		}
	}

	# Deal with YYYYMMDDHHMMSS
	elsif (length($date) == 14) {
		$year = substr($date,0,4) + 0;
		$mon = substr($date,4,2) - 1;
		$mday = substr($date,6,2) + 0;
		$hour = substr($date,8,2) + 0;
		$min = substr($date,10,2) + 0;
		$sec = substr($date,12,2) + 0;
		if ($shift == 30) {
			$mon += 1;
			if ($mon > 11) { $mon = 0; ++$year; }
		}
		elsif ($shift == -30) {
			$mon -= 1;
			if ($mon < 0) { $mon = 11; --$year; }
		}
		&debug(" long date is $year-$mon-$mday-$hour-$min-$sec")
			if( $main::debug);
		$date = timelocal($sec, $min, $hour, $mday, $mon, $year);
		if ($shift >= -7 and $shift <= 7) {
			$date += $shift * 60*60*24;
		}
	}
	else {
		# Treat month shifts specially
		if ($shift == 30) {
			($sec, $min, $hour, $mday, $mon, $year) = localtime($date);
			$mon ++;
			if ($mon > 11) { $mon = 0; ++$year; }
			$date = timelocal($sec, $min, $hour, $mday, $mon, $year);
		}
		elsif ($shift == -30) {
			($sec, $min, $hour, $mday, $mon, $year) = localtime($date);
			$mon --;
			if ($mon < 0) { $mon = 11; --$year; }
			$date = timelocal($sec, $min, $hour, $mday, $mon, $year);
		}
		# Otherwise, it's just a number of days
		else {
			$date += $shift * 60*60*24;
		}
	}
	($sec, $min, $hour, $mday, $mon, $year) = localtime($date);
	$date = sprintf('%04d%02d%02d%02d%02d%02d', $year + 1900, $mon + 1, 
		$mday, $hour, $min, $sec);
	return $date;
}

#-------------------------------------------------------- split_timestamp ---
sub split_timestamp {
	my $string = shift @_;
	my ($year, $mon, $mday, $hour, $min, $sec) = 
		unpack('A4 A2 A2 A2 A2 A2', $string);
	&debug("split_timestamp: str='$string' => $year, ", $mon-1, ", 
		$mday, $hour, $min, $sec") if ($main::debug);
	return ($sec+0, $min+0, $hour+0, $mday+0, $mon-1, $year+0);
}

#---------------------------------------------------- keep_strict_happy ---
sub keep_strict_happy {
	$main::ip_cache_readonly = 0;
}
