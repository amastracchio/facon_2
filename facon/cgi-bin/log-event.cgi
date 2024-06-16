#!/usr/bin/perl -Tw

# log-event.cgi - let people log a manual event
# $Id: log-event.cgi.in,v 1.8 2002/06/24 14:56:44 remstats Exp $
# from remstats 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Configuration   - - -

# What is this program called, for file-names and error-messages.
$main::prog = 'log-event.cgi';
# Where is the config dir?
$main::config_dir = '/home/ed857416/3p/remstats/etc/config';

# Debugging anyone?
$main::debug = 0;

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.8 $'))[1];

# - - -   Setup   - - -

# So -T will stop whinging.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin';

use lib '.', '/home/ed857416/3p/remstats/lib', '/usr/local/rrdtool/lib/perl';
require "remstats.pl";
require "accessstuff.pl";
require "cgistuff.pl";
require "htmlstuff.pl";

# Don't try to update IP_CACHE; don't have access from cgi
$main::ip_cache_readonly = 1;

# Initialize some useful variables
my %R = &cgi_request;
&cgi_sendheaders("Description: $main::prog version $main::version");
$main::url = 'http://' . &cgi_var("SERVER_NAME") . ':' . 
	&cgi_var('SERVER_PORT');
if (&cgi_var('SCRIPT_NAME') =~ m#^/#) {
	$main::url .= &cgi_var('SCRIPT_NAME');
}
else { $main::url .= '/'. cgi_var('SCRIPT_NAME') }

print &cgi_fmtrequest(%R) if ($main::debug);

&abort("access prohibited") unless( &access_control( $main::prog));

&read_config_dir($main::config_dir, 'general', 'html', 'colors');
%indices = &init_indices;

# - - -   Main Line   - - -

if (defined $R{'action'}) { &process(%R); }
else { &show_form; }

0;

#---------------------------------------------------------------- abort ---
sub abort {
	my ($msg) = @_;

	print <<"EOD_ABORT";
<html>
<head><title>$main::prog Abort</title></header>
<body>
<h1>$main::prog (version $main::version) Abort</h1>
$msg
</body>
</html>
EOD_ABORT
	exit 1;
}

#--------------------------------------------------------------- show_form ---
sub show_form {
	my (%R) = @_;
	
	print &html_header('Log Event', 'Log Event', %main::indices);
	print <<"EOD_FORM";
<hr>

<h1>Log a Manual Event</h1>
<div style="text-align:center">
<form method="POST" action="$main::url">
<table border=1>
<tr>
	<td valign=top>Host:</td>
	<td valign=top><input name="host" size=30></td>
</tr>
<tr>
	<td valign=top>RRD:</td>
	<td valign=top><input name="rrd" size=30></td>
</tr>
<tr>
	<td valign=top>Variable:</td>
	<td valign=top><input name="variable" size=30></td>
</tr>
<tr>
	<td valign=top>Value:</td>
	<td valign=top><input name="value" size=30></td>
</tr>
<tr>
	<td valign=top>Message:</td>
	<td valign=top><input name="message" size=30></td>
</tr>
<tr>
	<td valign=top>Event Type:</td>
	<td valign=top><input name="eventtype" size=20 value="EVENT"></td>
</tr>

<tr>
	<td colspan=2 align=center>
		<input type=submit value="Post Event">
		<input type=reset value="Clear Form">
		<input type=hidden name="action" value="event">
	</td>
</tr>
</table>
</form>
</div>
EOD_FORM
	print &html_footer;
}

#------------------------------------------------------------- process ---
sub process {
	my %R = @_;
	my ($host, $rrd, $variable, $value, $message, $eventtype);

# Validate fields
	if (defined $R{'host'} and 
			$R{'host'} =~ /^\s*([-a-zA-Z0-9\.]{3,256})\s*$/) {
		$host = lc $1;
		&debug("host = '$host'") if ($main::debug);
	}
	elsif (defined $R{'host'} and $R{'host'} !~ /^\s*$/) { &abort("bad host format for '$R{'host'}'"); }

	if (defined $R{'rrd'} and 
			$R{'rrd'} =~ /^\s*([-a-zA-Z0-9_\.]{1,256})\s*$/) {
		$rrd = $1;
		&debug("rrd = '$rrd'") if ($main::debug);
	}
	elsif (defined $R{'rrd'} and $R{'rrd'} !~ /^\s*$/) { &abort("bad rrd format for '$R{'rrd'}'"); }
	
	if (defined $R{'variable'} and 
			$R{'variable'} =~ /^\s*([a-zA-Z0-9_\.]{1,256})\s*$/) {
		$variable = $1;
		&debug("variable = '$variable'") if ($main::debug);
	}
	elsif (defined $R{'variable'} and $R{'variable'} !~ /^\s*$/) { &abort("bad variable format for '$R{'variable'}'"); }

	if (defined $R{'value'} and
			$R{'value'} =~ /^\s*([+-]?\d*(\.\d+)?)\s*$/) {
		$value = $1;
		&debug("value = '$value'") if ($main::debug);
	}
	elsif (defined $R{'value'} and $R{'value'} !~ /^\s*$/) { &abort("bad value format for '$R{'value'}'"); }

# I.E. no <>& or unprintable
	if (defined $R{'message'} and
			$R{'message'} =~ /^\s*(.*?)\s*$/) {
		$message = $1;
		&debug("message = '$message'") if ($main::debug);
	}
	elsif (defined $R{'message'} and $R{'message'} !~ /^\s*$/) { &abort("bad message format for '$R{'message'}'"); }

	if (defined $R{'eventtype'} and
			$R{'eventtype'} =~ /^\s*([0-9a-zA-Z]+)\s*$/) {
		$eventtype = $1;
		&debug("eventtype = '$eventtype'") if ($main::debug);
	}
	elsif (defined $R{'eventtype'} and $R{'eventtype'} !~ /^\s*$/) { &abort("bad eventtype format for '$R{'eventtype'}'"); }
	else { $eventtype = 'EVENT'; }

	$message = '[from '. $ENV{'REMOTE_ADDR'} .'] '. $message;
	&logit( $eventtype, $host, $rrd, $variable, $value, $message);

	print &html_header('Log Event', 'Log Event', %main::indices);
	print "<H3 align=left>Logged event for $host</H3>\n" . &html_footer;
	
}

#----------------------------------------------------- debug ---
sub debug {
	my ($msg) = @_;

	print "<BR>DEBUG: $msg\n";
}

#----------------------------------------------------- error ---
sub error {
	my ($msg) = @_;

	print "<H1>ERROR: $msg</H1>\n";
}

#---------------------------------------------------- keep_strict_happy ---
sub keep_strict_happy {
	$main::ip_cache_readonly = 0;
}
