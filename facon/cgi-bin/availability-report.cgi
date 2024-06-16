#!/usr/bin/perl -Tw
# availability-report.cgi - show the availability report, or appropriate 
#   sections thereof
# CVS $Id: availability-report.cgi.in,v 1.13 2003/05/20 19:28:05 remstats Exp $
# from remstats 1.0.13a

# Copyright 1999 - 2003(c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Configuration   - - -

use strict;

# What is this program called, for file-names and error-messages.
$main::prog = 'availability-report.cgi';
# So -T will stop whinging.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ed857416/3p/remstats/bin';
# Where is the config dir
$main::config_dir = '/home/ed857416/3p/remstats/etc/config';
# Debugging anyone?
$main::debug = 0;
# Where is the availability-report script?
$main::availability_report = '/home/ed857416/3p/remstats/bin/availability-report';

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.13 $'))[1];

# - - -   Setup   - - -

use lib '.', '/home/ed857416/3p/remstats/lib', '/usr/local/rrdtool/lib/perl';
use Time::Local;
require "remstats.pl";
require "accessstuff.pl";
require "cgistuff.pl";
require "htmlstuff.pl";

&read_config_dir($main::config_dir, 'general', 'html', 'links', 'tools');

# Initialize some useful variables
%main::R = &cgi_request;
&cgi_sendheaders('Description: Remstats Availability Report');
$main::url = 'http://' . &cgi_var("SERVER_NAME") . ':' . 
	&cgi_var('SERVER_PORT');
my $script_name = &cgi_var('SCRIPT_NAME');
if ($script_name =~ m#^/#) { $main::url .= $script_name; }
else { $main::url .= '/'. $script_name; }

$| = 1; # no buffering please

print &cgi_fmtrequest(%main::R) if( $main::debug);

&abort("access prohibited") unless( &access_control( $main::prog));

%main::indices = &init_indices; # for headers

my ($errors, $time, $hosts, $rrds, $variables, $previous_day, $previous_week, 
	$previous_month, $next_day, $next_week, $next_month, $previous_day_start, 
	$previous_week_start, $previous_month_start, $next_day_start, 
	$next_week_start, $next_month_start, $previous_day_end, $previous_week_end, 
	$previous_month_end, $next_day_end, $next_week_end, $next_month_end);

# When are we interested in?
my ($start, $end);
if (defined $main::R{'start'} and defined $main::R{'end'}) {

	if ($main::R{'start'} =~ /^(\d+)$/) { $start = $1; }
	elsif ($main::R{'start'} =~ /^\s*$/) {
		my (undef, undef, undef, $mday, $mon, $year) = localtime();
		$start = timelocal(0,0,0, $mday, $mon, $year);
	}
	else { &abort("invalid start '$main::R{'start'}'"); }
	if ($main::R{'end'} =~ /^(\d+)$/) { $end = $1; }
	elsif ($main::R{'end'} =~ /^\s*$/) { $end = $start + 24*60*60; }
	else { &abort("invalid end '$main::R{'end'}'"); }

}
elsif (defined $main::R{'start'} or defined $main::R{'end'}) {
	&abort("you must specify both start and end, or neither");
}
else {
	my (undef, undef, undef, $mday, $mon, $year) = localtime();
	$start = timelocal(0,0,0, $mday, $mon, $year);
	$end = $start + 24*60*60;
	if ($end > time()) { $end = time(); }
}
if ($end > time()) { $end = time(); }
$time = " -t $start,$end";

$previous_day_start = &shift_time( $start, -1);
$previous_week_start = &shift_time( $start, -7);
$previous_month_start = &shift_time( $start, -30);
$next_day_start = &shift_time( $start, +1);
$next_week_start = &shift_time( $start, +7);
$next_month_start = &shift_time( $start, +30);

$previous_day_end = $previous_day_start + 24*60*60;
$previous_week_end = $previous_week_start + 7*24*60*60;
$previous_month_end = &shift_time( $previous_month_start, +30);
$next_day_end = $next_day_start + 24*60*60;
$next_week_end = $next_week_start + 7*24*60*60;
$next_month_end = &shift_time( $next_month_start, +30);

$previous_day = 'start='. $previous_day_start .'&end='. $previous_day_end;
$previous_week = 'start='. $previous_week_start .'&end='. $previous_week_end;
$previous_month = 'start='. $previous_month_start .'&end='. $previous_month_end;
$next_day = 'start='. $next_day_start .'&end='. $next_day_end;
$next_week = 'start='. $next_week_start .'&end='. $next_week_end;
$next_month = 'start='. $next_month_start .'&end='. $next_month_end;

# Any more restrictions?
if (defined $main::R{'host'} and $main::R{'host'} =~ /^([-a-zA-Z0-9\.,_]+)$/) {
	$hosts = ' -H '. lc $1;
}
elsif (defined $main::R{'host'} and length($main::R{'host'})>0) {
	&error("invalid host '$main::R{'host'}'");
	++$errors;
}
else { $hosts = ''; }

if (defined $main::R{'rrd'} and $main::R{'rrd'} =~ /^([-a-zA-Z0-9\.,]+)$/) {
	$rrds = ' -R '. lc $1;
}
elsif (defined $main::R{'rrd'} and length($main::R{'rrd'})>0) {
	&error("invalid rrd '$main::R{'rrd'}'");
	++$errors;
}
else { $rrds = ''; }

if (defined $main::R{'variable'} and $main::R{'variable'} =~ /^([-a-zA-Z0-9\.,]+)$/) {
	$variables = ' -V '. lc $1;
}
elsif (defined $main::R{'variable'} and length($main::R{'variable'}>0)) {
	&error("invalid variable '$main::R{'variable'}'");
	++$errors;
}
else { $variables = ''; }

if ($errors) { &abort("too many errors"); }

# Don't try to update the IP_CACHE; don't have access
$main::ip_cache_readonly = 1;

# - - -   Main Line   - - -

print &html_header('Availability Report', 'Availability Report', %main::indices);
print cgi_fmtrequest(%main::R) if ($main::debug);

my $cmd = $main::availability_report .' -c '. $time . $hosts . $rrds . $variables;
&debug("cmd='$cmd'") if ($main::debug);
open (PIPE, "$cmd 2>&1|") or &abort("can't open pipe to $main::availability_report: $!");
print <PIPE>;
close(PIPE);

# Show the selection form
print <<"EOD_TAIL";
</TABLE>

<P>
<TABLE WIDTH="100%"><TR><TD BGCOLOR="#DDDDDD"><H2>Selection</H2></TD></TR></TABLE>
</P>


<FORM METHOD="POST" ACTION="$main::url">
<TABLE ALIGN="CENTER">
<TR>
<TD VALIGN="TOP">Previous: <A HREF="$main::url?$previous_day">day</A> 
	<A HREF="$main::url?$previous_week">week</A> 
	<A HREF="$main::url?$previous_month">month</A></TD>
<TD VALIGN="TOP">Next: <A HREF="$main::url?$next_day">day</A>
	<A HREF="$main::url?$next_week">week</A> 
	<A HREF="$main::url?$next_month">month</A></TD>
</TR>
<TR>
<TD VALIGN="TOP">Date&nbsp;From:&nbsp;<INPUT NAME="start" SIZE=14></TD>
<TD VALIGN="TOP">To:&nbsp<INPUT NAME="end" SIZE=14></TD>
</TR>

<TR>
<TD VALIGN="TOP" COLSPAN="2">Host:&nbsp;<INPUT NAME="host" SIZE="12"></TD>
</TR>
<TR>
<TD VALIGN="TOP">RRD:&nbsp;<INPUT NAME="rrd" SIZE="10"></TD>
<TD VALIGN="TOP">Variable:&nbsp;<INPUT NAME="variable" SIZE="10"></TD>
</TR>

<TR>
<TD ALIGN="CENTER" VALIGN="TOP"><INPUT TYPE="SUBMIT" VALUE="Send Query"></TD>
<TD ALIGN="CENTER" VALIGN="TOP"><INPUT TYPE="RESET" VALUE="Clear Form"></TD>
</TR>

</TABLE>
</FORM>
EOD_TAIL

print &html_footer;

0;

#----------------------------------------------------------------- abort ---
sub abort {
	my ($msg) = @_;
	print <<"EOD_ABORT";
content-type: text/html

<html>
<head><title>$main::prog Abort</title></head>
<body>
<h1>$main::prog (version $main::version) Abort</h1>
$msg
</body>
</html>
EOD_ABORT
	exit 1;
}

#------------------------------------------------- debug ---
sub debug {
	my ($msg) = @_;

	print "<br><B>DEBUG</b>: $msg\n";
}

#-------------------------------------------------- error ---
sub error {
	my ($msg) = @_;

	print "<br><B>ERROR</b>: $msg\n";
}

#--------------------------------------------------- shift_time ---
# shift a date (either timestamp or YYYYMMDD or YYMMDDHHMMSS) by a day
# week or month.
sub shift_time {
	my ($date, $shift) = @_;
	my ($sec, $min, $hour, $mday, $mon, $year);

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
		$date = timelocal($sec, $min, $hour, $mday, $mon, $year);
		if ($shift >= -7 and $shift <= 7) {
			$date += $shift * 60*60*24;
		}
	}
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
		$date = timelocal($sec, $min, $hour, $mday, $mon, $year);
		if ($shift >= -7 and $shift <= 7) {
			$date += $shift * 60*60*24;
		}
	}
	else {
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
		else {
			$date += $shift * 60*60*24;
		}
	}
$date;
}

#---------------------------------------------------- keep_perl_happy ---
sub keep_perl_happy {
	$main::ip_cache_readonly = 0;
}
