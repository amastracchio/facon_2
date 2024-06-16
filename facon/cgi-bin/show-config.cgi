#!/usr/bin/perl -Tw

# show-config.cgi - let people see configuration info
# $Id: show-config.cgi.in,v 1.3 2002/08/14 11:38:32 remstats Exp $
# from remstats 1.0.13a

# Copyright 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Configuration   - - -

# What is this program called, for file-names and error-messages.
$main::prog = 'show-config.cgi';
# Where is the configuration
$main::config_dir = '/home/ed857416/3p/remstats/etc/config';
# So -T will stop whinging.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin';

# Debugging anyone?
$main::debug = 0;

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.3 $'))[1];

# - - -   Setup   - - -

$| = 1; # no buffering please

use lib '.', '/home/ed857416/3p/remstats/lib';
require "remstats.pl";
require "accessstuff.pl";
require "cgistuff.pl";
require "htmlstuff.pl";

# Don't try to update IP_CACHE; don't have access from cgi
$main::ip_cache_readonly = 1;

&read_config_dir($main::config_dir, 'general', 'html', 'times',
	'colors', 'archives', 'links', 'tools', 'remotepings',
	'scripts', 'alerts', 'oids', 'rrds', 'customgraphs',
	'groups', 'host-templates', 'hosts', 'view-templates', 'views',
	'availability', 'alert-destination-map', 'discovery', 'ntops',
	'environment', 'run', 'run-stages');

# Initialize some useful variables
%main::R = &cgi_request();
&cgi_sendheaders('Description: $main::prog version $main::version');
$main::url = 'http://' . &cgi_var("SERVER_NAME") . ':' . &cgi_var('SERVER_PORT')
	. &cgi_var('SCRIPT_NAME');
&debug("url='$url'") if( $main::debug);

print &cgi_fmtrequest(%main::R) if ( $main::debug);

&abort("access prohibited") unless( &access_control( $main::prog));

# Clear the environment
%ENV = ();

my( $host, %indices, $title, $good_fields, $host_template, $archive, $time,
	$rrd, $customgraph, $tool, $oid);
$good_fields = 0;

# - - -   Main Line   - - -

%main::indices = &init_indices();
$title = $main::prog . '(version ' . $main::version . ')';
print &html_header( $title, $title,  %main::indices);

# Do a host
if (defined $main::R{'host'} and
		$main::R{'host'} =~ /^([-0-9a-zA-Z.]+)$/) {
	$good_fields ++;
	$host = $1;
	&show_host( $host);
}
elsif (defined $main::R{'host'}) {
	&abort("bad host field: $main::R{'host'}");
}

# Do an RRD
if (defined $main::R{'rrd'} and
		$main::R{'rrd'} =~ m#^([-0-9a-zA-Z\./]+)$#) {
	$good_fields ++;
	$rrd = $1;
	&show_rrd( $rrd);
}
elsif (defined $main::R{'rrd'}) {
	&abort("bad rrd field: $main::R{'rrd'}");
}

# Do a Tool
if (defined $main::R{'tool'} and
		$main::R{'tool'} =~ /^([-0-9a-zA-Z.]+)$/) {
	$good_fields ++;
	$tool = $1;
	&show_tool( $tool);
}
elsif (defined $main::R{'tool'}) {
	&abort("bad tool field: $main::R{'tool'}");
}

# Do an Archive
if (defined $main::R{'archive'} and
		$main::R{'archive'} =~ /^([-0-9a-zA-Z.]+)$/) {
	$good_fields ++;
	$archive = $1;
	&show_archive( $archive);
}
elsif (defined $main::R{'archive'}) {
	&abort("bad archive field: $main::R{'archive'}");
}

# Do a Time
if (defined $main::R{'time'} and
		$main::R{'time'} =~ /^([-0-9a-zA-Z.]+)$/) {
	$good_fields ++;
	$time = $1;
	&show_time( $time);
}
elsif (defined $main::R{'time'}) {
	&abort("bad time field: $main::R{'time'}");
}

# Do a OID
if (defined $main::R{'oid'} and
		$main::R{'oid'} =~ /^([-0-9a-zA-Z.]+)$/) {
	$good_fields ++;
	$oid = $1;
	&show_oid( $oid);
}
elsif (defined $main::R{'oid'}) {
	&abort("bad oid field: $main::R{'oid'}");
}

# Do a custom graph
if (defined $main::R{'customgraph'} and
		$main::R{'customgraph'} =~ /^([-0-9a-zA-Z.]+)$/) {
	$good_fields ++;
	$customgraph = $1;
	&show_customgraph( $customgraph);
}
elsif (defined $main::R{'customgraph'}) {
	&abort("bad customgraph field: $main::R{'customgraph'}");
}

unless( $good_fields) { &show_form(); }

print &html_footer();
exit 0;

#--------------------------------------------------------------- show_host ---
sub show_host {
	$main::host = shift @_;
	my( %fields, @fields, $field, $description, $value);

	unless( defined $main::config{HOST}{$main::host}) {
		&abort("no such host as $main::host");
	}

	# Missing NOGRAPH, EXTRA, RRDDESC, ALERT..., KEY, NOAVAILABILITY,
	# SHOWINTERFACES, HEADERFILE
	@fields = ( 'DESC', 'ALIAS', 'GROUP', 'IP', 'VIA', 'COMMUNITY',
		'SNMPPORT', 'LOCATION', 'CONTACTNAME', 'CONTACTEMAIL',
		'TOOLS', 'RRDS', 'CUSTOMGRAPHS', 'NOGRAPH', 'ALERT', 'STATUSFILE', 
		'NTNAME', 'NTSTATUSSERVER', 'NTINDIRECTHOSTS'
	);
	%fields = (
		'IP' => 'IP#',
		'VIA' => 'Reachable via',
		'ALIAS' => 'Aliases',
		'GROUP' => 'Group',
		'COMMUNITY' => 'SNMP Community String',
		'SNMPPORT' => 'SNMP port number',
		'LOCATION' => 'Location',
		'CONTACTNAME' => 'Contact',
		'CONTACTEMAIL' => 'Contact Email',
		'DESC' => 'Description',
		'RRDS' => 'RRDs',
		'NOGRAPH' => 'Exclude Graphs',
		'CUSTOMGRAPHS' => 'Custom Graphs',
		'ALERT' => 'Host Alerts',
		'TOOLS' => 'Tools',
		'STATUSFILE' => 'Non-standard status file',
		'NTSTATUSSERVER' => 'NT stats via nt-status-server on',
		'NTNAME' => 'Windows NT host-name',
		'NTINDIRECTHOSTS' => 'NT hosts served',
	);

	%callbacks = (
		'ALIAS' => => \&format_list,
		'CONTACTEMAIL' => \&format_email,
		'CUSTOMGRAPHS' => \&format_customgraphs,
		'LOCATION' => \&format_list,
		'NTINDIRECTHOSTS' => \&format_list,
		'TOOLS' => \&format_tools,
		'RRDS' => \&format_rrds,
		'NOGRAPH' => \&format_nograph,
		'ALERT' => \&format_host_alerts,
	);

	print <<"EOD_HOST_TOP";
<H1><A HREF="$main::config{HTMLURL}/release/configfile-hosts.html">Host</A> $main::host</H1>
<TABLE ALIGN="CENTER" BORDER=1>
<TR>
	<TD ALIGN="CENTER" VALIGN="TOP" BGCOLOR="#DDDDDD" WIDTH="15%"><B>Field</B></TD>
	<TD ALIGN="CENTER" VALIGN="TOP" BGCOLOR="#DDDDDD"><B>Value</B></TD>
</TR>
EOD_HOST_TOP

	# Show them in my order
	foreach $field (@fields) {
		$description = $fields{$field};
		
		# Special formatting; each field supplies its own routine
		if( defined $callbacks{$field}) {
			$value = &{$callbacks{$field}}($main::config{HOST}{$main::host}{$field});
		}
		else {
			$value = $main::config{HOST}{$main::host}{$field};
		}

		&show_row( $description, $value);
	}
	print "</TABLE>\n";

}

#------------------------------------------------------------ format_list ---
# Given a reference to a list, join the elements with a space.
#----------------------------------------------------------------------------
sub format_list {
	my $listref = shift @_;
	return join(' ', @$listref);
}

#------------------------------------------------------------ format_email ---
# Make an email address into a link to a mailto URL
#-----------------------------------------------------------------------------
sub format_email {
	my $email = shift @_;
	return '<A HREF="mailto:' . $email . '">' . $email . '</A>';
}

#------------------------------------------------------------ format_tools ---
# Make tool names into links to show the configuration of that tool.
#-----------------------------------------------------------------------------
sub format_tools {
	my $listref = shift @_;
	my( $result, $tool);

	$result = '';
	foreach $tool (@$listref) {
		$result .= ' <A HREF="' . $main::url . '?tool=' . $tool . '">' .
			$tool . '</A>';
	}

	return $result;
}

#----------------------------------------------------- format_rrds ---
sub format_rrds {
	my $listref = shift @_;
	my( $result, $rrd, $extra, $desc);

	$result = <<"EOD_RRDS_TOP";
<TABLE BORDER=1>
<TR>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>RRD</B></TD>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>Extra</B></TD>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>Description</B></TD>
</TR>
EOD_RRDS_TOP
	foreach $rrd ( @$listref) {
		$extra = $main::config{HOST}{$main::host}{EXTRA}{$rrd};
		$desc = $main::config{HOST}{$main::host}{RRDDESC}{$rrd};
		$result .= <<"EOD_RRDS_ENTRY";
<TR>
	<TD ALIGN="LEFT" VALIGN="TOP"><A HREF="$main::url?rrd=$rrd&host=$main::host">$rrd</A></TD>
	<TD ALIGN="LEFT" VALIGN="TOP">$extra</TD>
	<TD ALIGN="LEFT" VALIGN="TOP">$desc</TD>
</TR>
EOD_RRDS_ENTRY
	}

	$result .= "</TABLE>\n";
	return $result;
}

#----------------------------------------------------- format_customgraphs ---
sub format_customgraphs {
	my $listref = shift @_;
	my( $result, $customgraph);

	$result = '';
	foreach $customgraph ( @$listref) {
		$result .= ' <A HREF="' . $main::url . '?customgraph=' . $customgraph .
			'">' . $rrd . '</A>';
	}

	return $result;
}

#---------------------------------------------------------------- show_row ---
# Show a single row of a (name,value) table
#----------------------------------------------------------------------------
sub show_row {
	my( $name, $value) = @_;
	print <<"EOD_ROW";
<TR>
	<TD ALIGN="LEFT" VALIGN="TOP" BGCOLOR="#dddddd">$name</TD>
	<TD ALIGN="LEFT" VALIGN="TOP">$value</TD>
</TR>
EOD_ROW
}

#------------------------------------------------------------------- abort ---
sub abort {
	my $msg = join('', @_);
	print <<"EOD_ABORT";
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

#----------------------------------------------------------------- error ---
sub error {
	my $msg = join('', @_);
	&abort( $msg);
}

#------------------------------------------------------------------ debug ---
sub debug {
	my $msg = join('', @_);
	print "<BR><B>DEBUG:</B> $msg\n";
}

#------------------------------------------------------- keep_strict_happy ---
sub keep_strict_happy {
	$main::ip_cache_readonly = 0;
}

#--------------------------------------------------------------- show_form ---
sub show_form {
	print <<"EOD_FORM";
<P>
You can access the following configuration items:
<UL>
[Here would be a list of what you can call up, to make it easier to browse
for those who don't know what they are looking at, yet.]
</UL>
</P>
EOD_FORM
}

#-------------------------------------------------------- format_collector ---
# Format a collector name into a link to the docs for that collector.
#-----------------------------------------------------------------------------
sub format_collector {
	my $collector = shift @_;
	my $result = '<A HREF="' . $main::config{HTMLURL} . '/release/' .
		$collector . '-collector.html">' . $collector . '</A>';
	return $result;
}

#------------------------------------------------------ format_data_source ---
# Format all the data definitions into something pretty.
#-----------------------------------------------------------------------------
sub format_data_source {
	my $hashref = shift @_;
	my( $data, $result, $alias, $dsdef, $extra, $type, $heartbeat, $min, $max);

	$result = <<"EOD_DATA_TOP";
<TABLE ALIGN="LEFT" VALIGN="TOP" BORDER=1>
<TR>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>Name</B></TD>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>Alias</B></TD>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>Type</B></TD>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>Heartbeat</B></TD>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>Min</B></TD>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>Max</B></TD>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>Extra</B></TD>
</TR>
EOD_DATA_TOP

	foreach $data ( @{$main::config{RRD}{$main::wildrrd}{DATANAMES}}) {
		$alias = $main::config{RRD}{$main::wildrrd}{DS}{$data}{ALIAS};
		$dsdef = $main::config{RRD}{$main::wildrrd}{DS}{$data}{DSDEF};
		$extra = $main::config{RRD}{$main::wildrrd}{DS}{$data}{EXTRA};
		( $type, $heartbeat, $min, $max) = split(':', $dsdef);
		$result .= <<"EOD_DATA_ROW";
<TR>
	<TD ALIGN="LEFT" VALIGN="TOP">$data</TD>
	<TD ALIGN="LEFT" VALIGN="TOP">$alias</TD>
	<TD ALIGN="LEFT" VALIGN="TOP">$type</TD>
	<TD ALIGN="LEFT" VALIGN="TOP">$heartbeat</TD>
	<TD ALIGN="LEFT" VALIGN="TOP">$min</TD>
	<TD ALIGN="LEFT" VALIGN="TOP">$max</TD>
	<TD ALIGN="LEFT" VALIGN="TOP">$extra</TD>
</TR>
EOD_DATA_ROW
	}

	$result .= "</TABLE>\n";
	return $result;
}

#------------------------------------------------------------ format_times ---
# Make time names to links to the definitions
#-----------------------------------------------------------------------------
sub format_times {
	my $listref = shift @_;
	my( $result, $time);

	$result = '';
	foreach $time (@$listref) {
		$result .= "\n\t" . '<A HREF="' . $main::url . '?time=' .
			$time . '">' .  $time . '</A>';
	}

	return $result;
}

#--------------------------------------------------------- format_archives ---
# Make archive names to links to the definitions
#-----------------------------------------------------------------------------
sub format_archives {
	my $listref = shift @_;
	my( $result, $archive);

	$result = '';
	foreach $archive (@$listref) {
		$result .= "\n\t" . '<A HREF="' . $main::url . '?archive=' .
			$archive . '">' .  $archive . '</A>';
	}

	return $result;
}

#------------------------------------------------------------- format_oids ---
# Make oid names to links to the definitions
#-----------------------------------------------------------------------------
sub format_oids {
	my $listref = shift @_;
	my( $oid, $result);

	$result = '';
	foreach $oid (@$listref) {
		$result .= ' <A HREF="' . $main::url . '?oid=' . $oid . '">' .
			$oid . '</A>';
	}

	return $result;
}

#---------------------------------------------------------- format_connect ---
# Make connect names links to the definitions
#-----------------------------------------------------------------------------
sub format_connect {
	my $connect = shift @_;
	my( $result);

	$result = '<A HREF="' . $main::url . '?connect=' . $connect . '">' .
		$connect . '</A>';

	return $result;
}

#----------------------------------------------------------- format_select ---
# Make select names links to the definitions
#-----------------------------------------------------------------------------
sub format_select {
	my $select = shift @_;
	my( $result);

	$result = ' <A HREF="' . $main::url . '?select=' . $select . '">' .
		$select . '</A>';

	return $result;
}

#--------------------------------------------------------------- show_tool ---
# Show a tool definition
#-----------------------------------------------------------------------------
sub show_tool {
	my $tool = shift @_;
	my( %fields, @fields, $field, $description, $value);

	unless( defined $main::config{TOOL}{$tool}) {
		&abort("no such tool as $tool");
	}

	print <<"EOD_TOOL_TOP";
<H1><A HREF="$main::config{HTMLURL}/release/configfile-tools.html">Tool</A> $tool</H1>
<TABLE ALIGN="CENTER" BORDER=1>
<TR>
	<TD ALIGN="CENTER" VALIGN="TOP" BGCOLOR="#DDDDDD" WIDTH="15%"><B>Field</B></TD>
	<TD ALIGN="CENTER" VALIGN="TOP" BGCOLOR="#DDDDDD"><B>Value</B></TD>
</TR>
EOD_TOOL_TOP

	&show_row( 'Definition', $main::config{TOOL}{$tool});
	print "</TABLE>\n";

}

#---------------------------------------------------------------- show_rrd ---
sub show_rrd {
	$main::realrrd = shift @_;
	my( %fields, @fields, $field, $description, $value);

	# Make sure we've got a known RRD
	($main::wildrrd) = &get_rrd( $realrrd);
	unless( defined $main::config{RRD}{$wildrrd}) {
		&abort("no such RRD as $realrrd");
	}

	# Missing: ALERT

	@fields = (
		'SOURCE', 'STEP', 'DATA', 'ARCHIVES', 'TIMES', 'PORT', 'OIDS',
		'ALERT', 'CURRENTVALUE', 'KEY', 'DBICONNECT', 'DBISELECT',
		'DBIMULTIROWID', 'GRAPHS',
	);
	%fields = (
		'SOURCE' => 'Collector',
		'STEP' => 'Step Time (sec)',
		'DATA' => 'Variables',
		'ARCHIVES' => 'Archives (RRAs)',
		'TIMES' => 'Graph Time-spans',
		'PORT' => 'TCP Port#',
		'OIDS' => 'SNMP Object IDs, OIDs',
		'ALERT' => 'Alerts',
		'CURRENTVALUE' => 'Current Value Files',
		'KEY' => 'Keys',
		'DBICONNECT' => 'DBI Connect Name',
		'DBISELECT' => 'DBI Select Name',
		'DBIMULTIROWID' => 'DBI Multi-row ID',
	);

	%callbacks = (
		'SOURCE' => \&format_collector,
		'DATA' => \&format_data_source,
		'ARCHIVES' => \&format_archives,
		'TIMES' => \&format_times,
		'OIDS' => \&format_oids,
		'DBICONNECT' => \&format_connect,
		'DBISELECT' => \&format_select,
		'GRAPHS' => \&format_graphs,
		'ALERT' => \&format_rrd_alerts,
	);

	print <<"EOD_RRD_TOP";
<H1><A HREF="$main::config{HTMLURL}/release/configfile-rrds.html">RRD</A> $main::realrrd ($main::wildrrd)</H1>
<TABLE ALIGN="CENTER" BORDER=1>
<TR>
	<TD ALIGN="CENTER" VALIGN="TOP" BGCOLOR="#DDDDDD" WIDTH="15%"><B>Field</B></TD>
	<TD ALIGN="CENTER" VALIGN="TOP" BGCOLOR="#DDDDDD"><B>Value</B></TD>
</TR>
EOD_RRD_TOP

	# Show them in my order
	foreach $field (@fields) {
		$description = $fields{$field};
		
		# Special formatting; each field supplies its own routine
		if( defined $callbacks{$field}) {
			$value = &{$callbacks{$field}}($main::config{RRD}{$main::wildrrd}{$field});
		}
		else {
			$value = $main::config{RRD}{$main::wildrrd}{$field};
		}

		&show_row( $description, $value);
	}
	print "</TABLE>\n";

}

#------------------------------------------------------------ show_archive ---
# Show an archive definition
#-----------------------------------------------------------------------------
sub show_archive {
	my $archive = shift @_;
	my( $cf, $xff, $steps, $rows);

	unless( defined $main::config{ARCHIVE}{$archive}) {
		&abort("no such archive as $archive");
	}

	($cf, $xff, $steps, $rows) = split(':', $main::config{ARCHIVE}{$archive});

	print <<"EOD_ARCHIVE_TOP";
<H1><A HREF="$main::config{HTMLURL}/release/configfile-archives.html">Archive</A> $archive</H1>
<TABLE ALIGN="CENTER" BORDER=1>
<TR>
	<TD ALIGN="CENTER" VALIGN="TOP" BGCOLOR="#DDDDDD" WIDTH="15%"><B>Field</B></TD>
	<TD ALIGN="CENTER" VALIGN="TOP" BGCOLOR="#DDDDDD"><B>Value</B></TD>
</TR>
EOD_ARCHIVE_TOP

#	&show_row( 'Definition', $main::config{ARCHIVE}{$archive});
	&show_row( 'Consolidation Function', $cf);
	&show_row( 'X-Files Factor', $xff);
	&show_row( 'Steps per Consolidated Data Point', $steps);
	&show_row( 'Rows to Retain', $rows);
	print "</TABLE>\n";

}

#--------------------------------------------------------------- show_time ---
# Show an time definition
#-----------------------------------------------------------------------------
sub show_time {
	my $time = shift @_;
	my( $start, $end);

	unless( defined $main::config{TIME}{$time}) {
		&abort("no such time as $time");
	}

	$start = $main::config{TIME}{$time}{START};
	$end = $main::config{TIME}{$time}{FINISH};

	print <<"EOD_TIME_TOP";
<H1><A HREF="$main::config{HTMLURL}/release/configfile-times.html">Time</A> $time</H1>
<TABLE ALIGN="CENTER" BORDER=1>
<TR>
	<TD ALIGN="CENTER" VALIGN="TOP" BGCOLOR="#DDDDDD" WIDTH="15%"><B>Field</B></TD>
	<TD ALIGN="CENTER" VALIGN="TOP" BGCOLOR="#DDDDDD"><B>Value</B></TD>
</TR>
EOD_TIME_TOP

#	&show_row( 'Definition', $main::config{TIME}{$time});
	&show_row( 'Start Time', $start);
	&show_row( 'End Time', $end);
	print "</TABLE>\n";

}

#--------------------------------------------------------------- show_oid ---
# Show an oid definition
#-----------------------------------------------------------------------------
sub show_oid {
	my $oid = shift @_;

	unless( defined $main::config{OID}{$oid}) {
		&abort("no such oid as $oid");
	}

	print <<"EOD_OID_TOP";
<H1><A HREF="$main::config{HTMLURL}/release/configfile-oids.html">OID</A> $oid</H1>
<TABLE ALIGN="CENTER" BORDER=1>
<TR>
	<TD ALIGN="CENTER" VALIGN="TOP" BGCOLOR="#DDDDDD" WIDTH="15%"><B>Field</B></TD>
	<TD ALIGN="CENTER" VALIGN="TOP" BGCOLOR="#DDDDDD"><B>Value</B></TD>
</TR>
EOD_OID_TOP

	&show_row( 'Definition', $main::config{OID}{$oid});
	print "</TABLE>\n";

}

#---------------------------------------------------------- format_nograph ---
# Format all the nograph entries for this host
#-----------------------------------------------------------------------------
sub format_nograph {
	my $hashref = shift @_;
	my( $realrrd, $graph, $result);

	$result = '';
	foreach $realrrd (sort keys %{$main::config{HOST}{$main::host}{NOGRAPH}}) {
		foreach $graph ( sort keys
				%{$main::config{HOST}{$main::host}{NOGRAPH}{$realrrd}}) {
			$result .= <<"EOD_NOGRAPH_ROW";
<TR>
	<TD ALIGN="LEFT" VALIGN="TOP">$realrrd</TD>
	<TD ALIGN="LEFT" VALIGN="TOP">$graph</TD>
</TR>
EOD_NOGRAPH_ROW
		}
	}

	if( $result) {
		$result = <<"EOD_DATA_TOP" . $result;
<TABLE ALIGN="LEFT" VALIGN="TOP" BORDER=1>
<TR>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>RRD</B></TD>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>Graph</B></TD>
</TR>
EOD_DATA_TOP
		$result .= "</TABLE>\n";
	}

	return $result;
}

#------------------------------------------------------ format_host_alerts ---
# Format all the alert entries on the current host
#-----------------------------------------------------------------------------
sub format_host_alerts {
	my $hashref = shift @_;
	my( $realrrd, $var, $result, $relation, $thresholds);

	$result = '';
	foreach $realrrd (sort keys %{$main::config{HOST}{$main::host}{ALERT}}) {
		foreach $var ( sort keys
				%{$main::config{HOST}{$main::host}{ALERT}{$realrrd}}) {
			$relation = $main::config{HOST}{$main::host}{ALERT}{$realrrd}{$var}{RELATION};
			$thresholds = join(' ', @{$main::config{HOST}{$main::host}{ALERT}{$realrrd}{$var}{THRESHOLDS}});
			$result .= <<"EOD_NOGRAPH_ROW";
<TR>
	<TD ALIGN="LEFT" VALIGN="TOP">$realrrd</TD>
	<TD ALIGN="RIGHT" VALIGN="TOP">$var</TD>
	<TD ALIGN="CENTER" VALIGN="TOP">$relation</TD>
	<TD ALIGN="LEFT" VALIGN="TOP">$thresholds</TD>
</TR>
EOD_NOGRAPH_ROW
		}
	}

	if( $result) {
		$result = <<"EOD_DATA_TOP" . $result;
<TABLE ALIGN="LEFT" VALIGN="TOP" BORDER=1>
<TR>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>RRD</B></TD>
	<TD ALIGN="RIGHT" VALIGN="TOP"><B>Variable</B></TD>
	<TD ALIGN="CENTER" VALIGN="TOP"><B>Relation</B></TD>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>Thresholds</B></TD>
</TR>
EOD_DATA_TOP
		$result .= "</TABLE>\n";
	}

	return $result;
}

#------------------------------------------------------ format_rrd_alerts ---
# Format all the alert entries on the current rrd
#-----------------------------------------------------------------------------
sub format_rrd_alerts {
	my $hashref = shift @_;
	my( $realrrd, $var, $result, $relation, $thresholds);

	$result = '';
	foreach $var ( sort keys
			%{$main::config{RRD}{$main::wildrrd}{ALERT}}) {
		$relation = $main::config{RRD}{$main::wildrrd}{ALERT}{$var}{RELATION};
		$thresholds = join(' ', @{$main::config{RRD}{$main::wildrrd}{ALERT}{$var}{THRESHOLDS}});
		$result .= <<"EOD_NOGRAPH_ROW";
<TR>
	<TD ALIGN="RIGHT" VALIGN="TOP">$var</TD>
	<TD ALIGN="CENTER" VALIGN="TOP">$relation</TD>
	<TD ALIGN="LEFT" VALIGN="TOP">$thresholds</TD>
</TR>
EOD_NOGRAPH_ROW
	}

	if( $result) {
		$result = <<"EOD_DATA_TOP" . $result;
<TABLE ALIGN="LEFT" VALIGN="TOP" BORDER=1>
<TR>
	<TD ALIGN="RIGHT" VALIGN="TOP"><B>Variable</B></TD>
	<TD ALIGN="CENTER" VALIGN="TOP"><B>Relation</B></TD>
	<TD ALIGN="LEFT" VALIGN="TOP"><B>Thresholds</B></TD>
</TR>
EOD_DATA_TOP
		$result .= "</TABLE>\n";
	}

	return $result;
}

#----------------------------------------------------------- format_graphs ---
sub format_graphs {
	my( $graph, $desc, $result, $text, $image);

	$result = '';
	foreach $graph (@{$main::config{RRD}{$main::wildrrd}{GRAPHS}}) {
		if( $result) { $result .= "<HR>\n"; }
		$desc = $main::config{RRD}{$main::wildrrd}{GRAPHDESC}{$graph};
		if( $main::host) {
			$image = '<DIV ALIGN="CENTER"><IMG SRC="' . $main::config{CGIURL} .
				'/graph.cgi?host=' .  $main::host . '&rrd=' .
				$main::wildrrd . '&graph=' . $graph .
				'&graphtime=day&form=0" BORDER=0></DIV>';
		}
		else { $image = ''; }
		$text = join("<BR>\n", @{$main::config{RRD}{$main::wildrrd}{GRAPH}{$graph}}) .
			"<BR>\n";
		$result .= <<"EOD_GRAPH_TITLE";
<P>
<H1>Graph - $graph on $main::wildrrd</H1>
<UL> $desc </UL>
$image
<H2>Definition</H2>
<TABLE BORDER=1 ALIGN="CENTER"><TR><TD><TT> $text </TT></TD></TR></TABLE>
</P>
EOD_GRAPH_TITLE
	}

	return $result;
}
