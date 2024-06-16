#!/usr/bin/perl -Tw

# alert.cgi - generate alert report dynamicly, and allow update
# $Id: alert.cgi.in,v 1.18 2003/03/13 14:25:49 remstats Exp $
# from remstats 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Configuration   - - -

# What is this program called, for file-names and error-messages.
$main::prog = 'alert.cgi';
# Where is the config dir
$main::config_dir = '/root/3p/facon/etc/config';
# How long a comment will be kept
$main::maxcomment = 80;

# Debugging anyone?
$main::debug = 0;

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.18 $'))[1];

# - - -   Setup   - - -

# Collect the required modules
use lib '.', '/root/3p/facon/lib', '/usr/local/rrdtool/lib/perl';
require "facon.pl";
require "accessstuff.pl";
require "alertstuff.pl";
require "cgistuff.pl";
require "htmlstuff.pl";
#use Data::Dumper;

&read_config_dir($main::config_dir, 'general', 'html', 'alerts', 'oids', 
	'times', 'rrds', 'groups', 'host-templates', 'hosts');

# Parse the request
%main::R = &cgi_request;
&cgi_sendheaders('Description: remstats Alert Report', 'Refresh: 600');
$main::url = 'http://' . &cgi_var("SERVER_NAME") . ':' . &cgi_var('SERVER_PORT')
	. &cgi_var('SCRIPT_NAME');

print &cgi_fmtrequest(%main::R) if ($main::debug);

&abort("access prohibited") unless( &access_control( $main::prog));

%main::status = ( 'OK'=>1, 'WARN'=>2, 'ERROR'=>3, 'CRITICAL'=>4 );

# Select the minimum status to be shown
if (defined $main::R{'minstatus'}) {
	if ($main::R{'minstatus'} =~ /^(OK|WARN|ERROR|CRITICAL)$/i) {
		$main::minstatus = $main::status{$1};
	}
	elsif ($main::R{'minstatus'} =~ /^\s*$/) { $main::minstatus = 2; }
	else { &abort ("minstatus is invalid"); }
}
else { $main::minstatus = 2; }

# Select the sort
if (defined $main::R{'sortby'}) {
	if ($main::R{'sortby'} =~ /^(host|rrd|status|start)$/i) {
		$main::sortby = lc $1;
	}
	elsif ($main::R{'minstatus'} =~ /^\s*$/) { $main::sortby = "none"; }
	else { &abort ("sortby is invalid"); }
}
else { $main::sortby = 'none'; }

# Get the indices
%main::indices = &init_indices;

# Suck in the alert statuses
$main::alerts_readonly = 1;
%main::alerts = &read_alerts;

# Don't try to update the IP_CACHE from cgi; don't have access
$main::ip_cache_readonly = 1;

# - - -   Main Line   - - -

&do_alerts;

0;

#------------------------------------------------------------ sort routines ---
sub byrrd {
	($hosta, $rrda, $vara) = @$a;
	($hostb, $rrdb, $varb) = @$b;

	return ($rrda cmp $rrdb) ? $rrda cmp $rrdb :
		(($hosta cmp $hostb) ? $hosta cmp $hostb :
		$vara cmp $varb );
}

sub bystatus {
	($hosta, $rrda, $vara) = @$a;
	($hostb, $rrdb, $varb) = @$b;
	$stata = $main::alerts{$hosta}{$rrda}{$vara}{STATUS};
	$statb = $main::alerts{$hostb}{$rrdb}{$varb}{STATUS};

	return ($stata cmp $statb) ? $stata cmp $statb :
		(($hosta cmp $hostb) ? $hosta cmp $hostb :
		(($rrda cmp $rrdb) ? $rrda cmp $rrdb :
		$vara cmp $varb ));
}

sub bystart {
	($hosta, $rrda, $vara) = @$a;
	($hostb, $rrdb, $varb) = @$b;
	$starta = $main::alerts{$hosta}{$rrda}{$vara}{START};
	$startb = $main::alerts{$hostb}{$rrdb}{$varb}{START};

	return ($starta cmp $startb) ? $starta cmp $startb :
		(($hosta cmp $hostb) ? $hosta cmp $hostb :
		(($rrda cmp $rrdb) ? $rrda cmp $rrdb :
		$vara cmp $varb ));
}

#------------------------------------------------------------ do_alerts ---
sub do_alerts {
	my $alerts_changed = 0;

	my $alertsfile = "$config{DATADIR}/ALERTS";
	print &html_header('Alert Report', 'Alert Report', %main::indices);

# what order do we want them in
	my @keys = ();
	foreach $host (sort keys %main::alerts) {
		foreach $realrrd (sort keys %{$main::alerts{$host}}) {
			foreach $var (sort keys %{$main::alerts{$host}{$realrrd}}) {
				push @keys, [$host, $realrrd, $var];
			}
		}
	}

# Re-sort the keys into the desired order
	if (($main::sortby eq 'none') or ($main::sortby eq 'host')) {
		;
	}
	elsif ($main::sortby eq 'rrd') {
		@keys = sort byrrd @keys;
	}
	elsif ($main::sortby eq 'status') {
		@keys = sort bystatus @keys;
	}
	elsif ($main::sortby eq 'start') {
		@keys = sort bystart @keys;
	}
	else { &abort("unknown sortby ($main::sortby)"); }

# We've got pending alerts
	if (-f $alertsfile) {
		print STDOUT <<"EOD_ALERT_TOP";
<FORM METHOD=POST ACTION="$url">
<P>
<TABLE BORDER=1>
<TR>
	<TH>host</TH>
	<TH>RRD</TH>
	<TH>variable</TH>
	<TH>value</TH>
	<TH>status</TH>
	<TH>old status</TH>
	<TH>alert start</TH>
	<TH>last change</TH>
	<TH>last alert</TH>
	<TH>quench</TH>
	<TH>comment</TH>
</TR>
EOD_ALERT_TOP
		my $now = time;
		my ($host, $realrrd, $var, $status, $old_status, $value, $start, 
			$lastalert, $lastchange, $newquench, $newcomment, $host_url);

		if (defined $main::R{'host'} and 
				$main::R{'host'} =~ m#^([-a-zA-Z0-9\.\|]*)$#i) {
			$main::R{'host'} = $1;
		}
		elsif (defined $main::R{'host'} and length($main::R{'host'}) == 0) {
			&error("bad host pattern ($main::R{'host'})");
		}
		else { $main::R{'host'} = ''; }

		if (defined $main::R{'rrd'} and 
				$main::R{'rrd'} =~ m#^([-a-zA-Z0-9\.\|/]*)$#i) {
			$main::R{'rrd'} = $1;
		}
		elsif (defined $main::R{'rrd'} and length($main::R{'rrd'}) > 0) {
			&error("bad rrd pattern ($main::R{'rrd'})");
		}
		else { $main::R{'rrd'} = ''; }

		if (defined $main::R{'variable'} and 
				$main::R{'variable'} =~ m#^([-a-zA-Z0-9\.\|/]*)$#i) {
			$main::R{'variable'} = $1;
		}
		elsif (defined $main::R{'variable'} and 
				length($main::R{'variable'}) == 0) {
			&error("bad variable pattern ($main::R{'variable'})");
		}
		else { $main::R{'variable'} = ''; }

		foreach $key (@keys) {
			($host, $realrrd, $var) = @$key;
			if (defined $main::R{'host'} &&
					$main::R{'host'} !~ /^\s*$/ &&
					$host !~ m/$main::R{'host'}/i) {
				&debug("skipped unwanted host $host") if ($main::debug);
				next;
			}
			if (defined $main::R{'rrd'} &&
					$main::R{'rrd'} !~ /^\s*$/ &&
					$realrrd !~ m/$main::R{'rrd'}/i) {
				&debug("skipped unwanted rrd $realrrd for $host")
					if ($main::debug);
				next;
			}
			if (defined $main::R{'variable'} &&
					$main::R{'variable'} !~ /^\s*$/ &&
					$var !~ m/$main::R{'variable'}/i) {
				&debug("skipped unwanted variable $var in $realrrd for $host")
					if ($main::debug);
				next;
			}
			$status = uc $main::alerts{$host}{$realrrd}{$var}{STATUS};
			$old_status = uc $main::alerts{$host}{$realrrd}{$var}{OLDSTATUS};
			$value = $main::alerts{$host}{$realrrd}{$var}{VALUE};
			$start = $main::alerts{$host}{$realrrd}{$var}{START};
			$lastalert = $main::alerts{$host}{$realrrd}{$var}{LASTALERT};
			$lastchange = $main::alerts{$host}{$realrrd}{$var}{LASTCHANGE};
			$quench = $main::alerts{$host}{$realrrd}{$var}{QUENCH};
			$comment = $main::alerts{$host}{$realrrd}{$var}{COMMENT};

			$quench_var = 'quench_'.$host.'_'.$realrrd.'_'.$var;
			$quench_var =~ tr#- .:/#_____#;
			if (defined $main::R{$quench_var} &&
					$main::R{$quench_var} =~ /^\s*([01])\s*$/) {
				$newquench = $1;
				$main::alerts{$host}{$realrrd}{$var}{QUENCH} = $newquench;
				$alerts_changed++;
			}
			else { $newquench = 0; }

			$comment_var = 'comment_'.$host.'_'.$realrrd.'_'.$var;
			$comment_var =~ tr#- .:/#_____#;
			$newcomment = $main::R{$comment_var};
			if (defined $newcomment) {
				if ($newcomment =~ /^\s*([ -~]{1,$maxcomment})$/) {
					$newcomment = $1;
				}
				$main::alerts{$host}{$realrrd}{$var}{COMMENT} = $newcomment;
				$comment = $newcomment;
				$alerts_changed++;
			}

			if (defined $ENV{HTTP_X_FORWARDED_FOR} and 
					$ENV{HTTP_X_FORWARDED_FOR} =~ 
					/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/) {
				$addr = $1;
				if (defined $ENV{REMOTE_ADDR} and 
						$ENV{REMOTE_ADDR} =~ 
						/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/) {
					$addr .= ' via '. $1;
				}
				else { $addr .= ' via unknown'; }
			}
			elsif (defined $ENV{REMOTE_ADDR} and 
					$ENV{REMOTE_ADDR} =~ 
					/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/) {
				$addr = $1;
			}
			else { $addr = 'unknown'; }

			if (defined $main::R{$quench_var} and $newquench) {
				&logit('QUENCH', $host, $realrrd, $var, $value, 
					(defined $newcomment) ? "[from $addr]". $newcomment : 
					"[from $addr]". '');
			}
			elsif (defined $newcomment and $newcomment !~ /^\s*$/) {
				&logit('COMMENT', $host, $realrrd, $var, $value, 
					"[from $addr]". $newcomment);
			}

			next unless ($main::status{$status} >= $main::minstatus);
			if (defined $config{(uc $status).'STATUS'}) {
				$status = $config{(uc $status).'STATUS'};
			}
			$value = &siunits($value);

			if ($lastalert == $start) { $lastalert = "-never-"; }
			else {
				$lastalert = &timestamp($lastalert) .'<BR>('. 
					&sec_to_dhms($now-$lastalert) .' ago)';
			}
			if ($lastchange > 0) {
				$lastchange = &timestamp($start) .'<BR>('.
					&sec_to_dhms($now-$lastchange) .' ago)';
			}
			else { $lastchange = '-never-'; }

			if ($start > 0 ) {
				$start = &timestamp($start) . '<BR>(' .
					&sec_to_dhms($now-$start) .' ago)';
			}
			else { $start = '-never-'; }

			if ($newquench) { $quench = " checked"; }
			else { $quench = ''; }

			$host_url = &make_host_index_url( $host);
			print STDOUT <<"EOD_ALERT_LINE";
<TR>
	<TD VALIGN="TOP"><A HREF="$host_url">$host</A></TD>
	<TD VALIGN="TOP">$realrrd</TD>
	<TD VALIGN="TOP">$var</TD>
	<TD VALIGN="TOP" align=right>$value</TD>
	<TD VALIGN="TOP">$status</TD>
	<TD VALIGN="TOP">$old_status</TD>
	<TD VALIGN="TOP">$start</TD>
	<TD VALIGN="TOP">$lastchange</TD>
	<TD VALIGN="TOP">$lastalert</TD>
	<TD VALIGN="TOP"><INPUT NAME="$quench_var" TYPE=checkbox VALUE="1"$quench></TD>
	<TD VALIGN="TOP"><INPUT NAME="$comment_var" SIZE=30 VALUE="$comment"></TD>
</TR>
EOD_ALERT_LINE
		}
		print STDOUT "</TABLE>\n";
	}

# Nothing.  Tell them.
	else {
		print STDOUT "<P>\nNo alerts pending.\n</P>\n";
	}

	print <<"EOD_FORM";
</P>

<P>
<TABLE WIDTH="100%"><TR>
<TD BGCOLOR="#d0d0d0"><H2>Alert Selection:</H2></TD>
</TR></TABLE>

Host:&nbsp;<INPUT NAME="host" SIZE=10 VALUE="$main::R{'host'}">

RRD:&nbsp;<INPUT NAME="rrd" SIZE=10 VALUE="$main::R{'rrd'}">

Variable:&nbsp;<INPUT NAME="variable" SIZE=10 VALUE="$main::R{'variable'}">

<SELECT NAME="minstatus">
	<OPTION VALUE="WARN" SELECTED>Status Level</OPTION>
	<OPTION VALUE="OK">OK</OPTION>
	<OPTION VALUE="WARN">Warning</OPTION>
	<OPTION VALUE="ERROR">Error</OPTION>
	<OPTION VALUE="CRITICAL">Critical</OPTION>
</SELECT>

<SELECT NAME="sortby">
	<OPTION VALUE="host">Sort by</OPTION>
	<OPTION VALUE="host">Host</OPTION>
	<OPTION VALUE="rrd">RRD</OPTION>
	<OPTION VALUE="status">Status</OPTION>
	<OPTION VALUE="start">Alert start time</OPTION>
</SELECT>

<INPUT TYPE="SUBMIT" value="Do it">
<INPUT TYPE="RESET" VALUE="Clear">

</FORM>
</P>
EOD_FORM

	print STDOUT &html_footer;
	close (STDOUT);
	&write_alerts(%main::alerts) if ($alerts_changed and 
		! $main::alerts_readonly);
}

#------------------------------------------------------------------ abort ---
sub abort {
	my $msg = join('', @_);
	print "<H1>$main::prog ($main::version): Abort</H1>\n$msg\n";
	exit 1;
}

#------------------------------------------------------------------- error ---
sub error {
	my $msg = join('', @_);
	print "<BR><B>ERROR:</B>$msg\n";
}

#------------------------------------------------------------------- debug ---
sub debug {
	my $msg = join('', @_);

	if ($main::debug) {
		print "<BR>DEBUG: $msg<br>\n";
	}
}

#---------------------------------------------------- keep_perl_happy ---
sub keep_perl_happy {
	$main::ip_cache_readonly = 0;
	$main::alerts_readonly = 0;
}
