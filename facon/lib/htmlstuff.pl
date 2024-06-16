# htmlstuff.pl - html-related common routines
# $Id: htmlstuff.pl.in,v 1.38 2003/03/13 14:14:18 facon Exp $
# from facon 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Version History   - - -

use strict;

# $Revision: 1.38 $

# %indices = &init_indices();
# $html .= &html_header( $title, $thisis, %indices);
# $html .= &bare_html_header( $title);
# $html .= &toolbar( $host [,$ip]);
# $html .= &html_footer();
# $html .= &status_header( $host [,$ip]);
# $html .= &rrd_status_header( $host, $realrrd, $wildrrd, $fixedrrd, $graph);
# &sec_to_dhms( $secs);
# &make_rrdcgi_graph( $dir, $prefix, $host, $realrrd, $graph, $graphtime, 
#	$alttext, $rrdfile);
# &make_custom_graph( $dir, $prefix, $customgraph, $graphtime);
# $url = &make_host_index_url( $host);
# &webgroupdir( $dir);

#------------------------------------------------------------ init_indices ---
sub init_indices {
	my %indices;

	%indices = (
		$main::config{HTML}{QUICKINDEX} =>	$main::config{HTMLURL} . 
			'/quick-index.cgi',
#		$main::config{HTML}{RRDINDEX} =>	$main::config{HTMLURL} .
#			'/rrd-index.cgi', 
		$main::config{HTML}{PINGINDEX} =>	$main::config{HTMLURL} .
			'/ping-index.cgi',
		$main::config{HTML}{ALERTREPORT} => $main::config{CGIURL} .
			'/alert.cgi',
		$main::config{HTML}{ALERTINDEX} => 	$main::config{CGIURL} .
			'/datapage.cgi?alert-index',
		$main::config{HTML}{CUSTOMINDEX} =>	$main::config{HTMLURL} .
			'/CUSTOM/index.cgi',
		$main::config{HTML}{VIEWINDEX} =>	$main::config{HTMLURL} .
			'/view-index.cgi',
		$main::config{HTML}{LOGREPORT} => 	$main::config{CGIURL} .
			'/showlog.cgi'
	);
	return %indices;
}

#-------------------------------------------------------- bare_html_header ---
# Generate just the top-of-page HTML, up to but not including <BODY>
#-----------------------------------------------------------------------------
sub bare_html_header {
	my $title = shift @_;
	my( $html, $refresh, $refreshtime, $author);

	# Add a refresh META tag
	$refreshtime = $refresh = $main::config{HTMLREFRESH};
	if (defined $refresh) {
		$refresh = "<META HTTP-EQUIV=\"refresh\" CONTENT=\"$refresh\">";
	}
	else { $refresh = ''; }
	$author = 'terskine@users.sourceforge.net';

	$html = <<"EOD_BARE_HEADER";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<!-- written by facon 1.0.13a $main::prog version $main::version -->
<!-- begin bare_html_header -->
<HTML>
<HEAD>
<TITLE>Facon 2 - $title</TITLE>
<LINK REV=MADE HREF="mailto:$author">
<LINK REL="stylesheet" TYPE="text/css" HREF="$main::config{HTMLURL}/default.css">
<META HTTP-EQUIV="description" CONTENT="$title">
<META HTTP-EQUIV="keywords" CONTENT="facon,rrdtool,$title">
$refresh
</HEAD>
<RRD::GOODFOR -$refreshtime>
<!-- end bare_html_header -->

EOD_BARE_HEADER

	return $html;
}

#------------------------------------------------------------- html_header ---
# Generate the usual facon header: top-of-page HTML plus index button list
#-----------------------------------------------------------------------------
sub html_header {
	my $title = shift @_;
	my $thisis = shift @_;
	my %indices = @_ if (defined $_[0]);
	my ($html, $author, $printed_index, $index, $fixed, $prefix, $background);

	# First the bare necessities
	$html = &bare_html_header( $title);

	# Set a background, if requested
	$background = $main::config{BACKGROUND}; 
	if (defined $background) { $background = ' '. $background; }
	else { $background = ''; }

	# A logo, if they wanted one
	if (defined $main::config{LOGOURL}) {
		if (defined $main::config{HOMEURL}) {
			$prefix = '<A HREF="'. $main::config{HOMEURL} .'">'.
				'<IMG SRC="'. $main::config{LOGOURL} 
				.'" BORDER=0 ALT="logo"></A>';
		}
		else {
			$prefix = '<IMG SRC="'. $main::config{LOGOURL} 
				.'" BORDER=0 ALT="logo">';
		}
	}
	else { $prefix = ''; }

	# The facon logo, though I'm not sure it's used any more
	# FIXME, still used?
#	my $facon_logo = '<IMG SRC="' . $main::config{HTMLURL} .
#		'/IMAGES/facon.png" BORDER="0" ALT="Facon">';

	$html .= <<"EOD_HEADER";
<!-- begin html_header -->
<BODY$background>
<TABLE BORDER="0" ALIGN="CENTER">
<TR>
<TD ALIGN="LEFT" VALIGN="MIDDLE"><SPAN CLASS="TITLE">$prefix</SPAN></TD>
<TD ALIGN="CENTER" VALIGN="MIDDLE"><SPAN CLASS="TITLE">Facon 2 - $title</SPAN></TD>
<TD ALIGN="RIGHT" VALIGN="MIDDLE"><SPAN CLASS="TITLE"></SPAN></TD>
</TR>
</TABLE>
EOD_HEADER

# Show the index-line, if the possibilities were provided
	$printed_index = 0;
	foreach $index (sort keys %indices) {
		next unless (defined $indices{$index});
		unless ($printed_index) {
			$printed_index++;
#			$html .= "<HR>\n<B>$main::config{HTML}{INDICES}</B>: \n";
			$html .= "<HR>\n";
		}
		($fixed = $index) =~ s# #&nbsp;#g;
		if ($index eq $thisis) {
			$html .= $fixed ."\n";
		}
		else {
			$html .= <<"EOD_INDEX";
$main::config{HTML}{INDEXPREFIX}<A CLASS="BUT" HREF="$indices{$index}">$fixed</A>$main::config{HTML}{INDEXSUFFIX}
EOD_INDEX
		}
	}

	# Set up the MOTD file
	unless (-f $main::config{HTML}{MOTDFILE} or 
			-l $main::config{HTML}{MOTDFILE}) {
		open (MOTD, ">$main::config{HTML}{MOTDFILE}") or
			&error("can't touch MOTD file ($main::config{HTML}{MOTDFILE}): $!");
		close(MOTD);
	}
	$html .= '<RRD::INCLUDE '. $main::config{HTML}{MOTDFILE} .">\n";

	# Say good-night, Dick
	if ($printed_index) { $html .= "\n<!-- end html_header -->\n<HR>\n"; }

	&debug("header: $html") if ($main::debug>1);
	return $html;
}

#--------------------------------------------------------------- toolbar ---
sub toolbar {
	my ($host, $ip) = @_;
	my ($html, $tool, $thishtml, $fixed, @tools);

	if (defined $main::config{HOST}{$host}{TOOLS}) {
		@tools = @{$main::config{HOST}{$host}{TOOLS}};
	}
	else { @tools = @{$main::config{HTML}{DEFAULTTOOLS}}; }

	unless (defined $ip) { $ip = &get_ip( $host); }

	$html = "\n<!-- begin toolbar -->\n<B>$main::config{HTML}{TOOLS}</B>: \n";
	foreach $tool (@tools) {
		($fixed = $tool) =~ s# #&nbsp;#g;
		if ($fixed =~ /^([^:]+):(.*)$/) {
			$tool = $1;
			$fixed = $2;
		}

		unless (defined $main::config{TOOL}{$tool}) {
			warn "$host wants tool $tool, but it's not defined; skipped\n";
			next;
		}

		($thishtml) =  &do_subs(undef, undef, undef, $host, $ip, undef, 
			undef, $main::config{TOOL}{$tool});
		$html .= <<"EOD_TOOL";
$main::config{HTML}{TOOLPREFIX}<A CLASS="BUT" HREF="$thishtml">$fixed</A>$main::config{HTML}{TOOLSUFFIX}
EOD_TOOL
	}
	$html .= "<!-- end toolbar -->\n<HR>\n";
$html;
}

#--------------------------------------------------------- html_footer ---
sub html_footer {
	my $html = "\n<!-- begin html_footer -->\n<HR>\n";
#	my $html = "\n<!-- begin html_footer -->\n<HR><B>" .
#		$main::config{HTML}{LINKS} . ":</B> ";

# Now the user-supplied links
	my ($name, $url, $image);
	if (defined $main::config{LINKS}) {
		foreach my $link (@{$main::config{LINKS}}) {
			$name = $$link{NAME};
			$url = $$link{URL};
			$image = $$link{IMAGE};

			# We have an "image"
			if (defined $image) {
				# It's a URL (absolute or relative) of an image
				if( $image =~ m#^(http:|ftp:|/|\.\.)#) {
					$html .= <<"EOD_IMAGE";
<A HREF="$url"><SPAN STYLE="vertical-align: top"><IMG SRC="$image" ALT="$name" BORDER="0"></SPAN></A>
EOD_IMAGE
				}
				# It's raw html, insert it
				else {
					$html .= '<A HREF="' . $url . '">' . $image . "</A>\n";
				}
			}
			else {
				$html .= <<"EOD_TEXT";
$main::config{HTML}{LINKPREFIX}<A CLASS="BUT" HREF="$url">$name</A>$main::config{HTML}{LINKSUFFIX}
EOD_TEXT
			}
		}
	}

	my $now = time;
	my $updated = &timestamp($now);

	$html .= <<"EOD_LASTCHANGE";
<BR>\n<FONT SIZE="-1">This page last updated on $updated by facon version 1.0.13a</FONT>.
<!-- end html_footer -->
</BODY>
</HTML>
EOD_LASTCHANGE

$html;
}

#-------------------------------------------------------- status_header ---
sub status_header {
	my ($host, $ip) = @_;
	my ($status, $stale, $file, $interfaces, @files, $interface, $html,
		$hostdesc, $name, $email, $show_interfaces, $header);

	unless (defined $main::includer) { $main::includer = 'RRD::INCLUDE'; }

	$html = "\n<!-- begin status_header -->\n<TABLE WIDTH=\"100%\">\n";

# What is this host anyway?
	$hostdesc = $main::config{HOST}{$host}{DESC} 
		if (defined $main::config{HOST}{$host}{DESC});
	if (defined $hostdesc) {
		$html .= &make_value_header( $main::config{HTML}{DESCRIPTION},
			$hostdesc);
	}

# Who do we talk to
	if (defined $main::config{HOST}{$host}{CONTACTNAME}) {
		$name = $main::config{HOST}{$host}{CONTACTNAME};
		$email = $main::config{HOST}{$host}{CONTACTEMAIL};
		$html .= &make_value_header( $main::config{HTML}{CONTACT},
			$name . ' &lt;<A HREF="mailto:' . $email . '">' . $email .
				'</A>&gt');
	}

# IP numbers are good to see
	unless (defined $ip) { $ip = &get_ip( $host); }
	if (defined $ip) {
		$html .= &make_value_header( $main::config{HTML}{IPNUMBER}, $ip);
	}

# Collect the software description (Operating System usually)
	$file = "$main::config{DATADIR}/$host/SOFTWARE";
	if (-f $file) {
		$html .= &make_file_header( $main::config{HTML}{OPERATINGSYSTEM}, 
			$file);
	}

# Collect the host hardware description
	$file = "$main::config{DATADIR}/$host/HARDWARE";
	if (-f $file) {
		$html .= &make_file_header( $main::config{HTML}{HARDWARE}, $file);
	}

# Collect the host memory size
	$file = "$main::config{DATADIR}/$host/MEMORY-SIZE";
	if (-f $file) {
		$html .= &make_file_header( $main::config{HTML}{MEMORYSIZE}, $file);
	}

# Collect the interfaces
	$show_interfaces = (defined $main::config{HOST}{$host}{SHOWINTERFACES}) ?
		$main::config{HOST}{$host}{SHOWINTERFACES} :
		$main::config{HTML}{SHOWINTERFACES};
	if ($show_interfaces) {
		@files = &list_files("$main::config{DATADIR}/$host", 
			'HARDWARE-snmpif-*');
		push @files, &list_files("$main::config{DATADIR}/$host", 
			'HARDWARE-if-*');
		push @files, &list_files("$main::config{DATADIR}/$host", 
			'HARDWARE-ntnetworkinterface-*');
		undef $interfaces;
		foreach (@files) {
			open (INTERFACE, "<$_") or do {
				&error("can't open $_: $!");
				next;
			};
			($interface = $_) =~ s/.*-([^-]+)$/$1/;
			if (defined $interfaces) {
				$interfaces .= "<BR>\n". $interface .': '. 
					join('', <INTERFACE>);
			}
			else { $interfaces = $interface .': '. join('', <INTERFACE>); }
			close (INTERFACE);
		}
		if ($interfaces) {
			$html .= &make_value_header( $main::config{HTML}{INTERFACES},
				$interfaces);
		}
	}

# Make a pretty uptime display
	$file = "$main::config{DATADIR}/$host/UPTIME.html";
	if (-f $file) {
		$html .= &make_file_header( $main::config{HTML}{UPTIME}, $file);
	}

	# Include the host status
	if( defined $main::config{HOST}{$host}{STATUSFILE}) {
		$file = $main::config{HOST}{$host}{STATUSFILE};
	}
	else {
		$file = 'STATUS.html';
	}
	$file = $main::config{DATADIR} . '/' . $host . '/' . $file;

	if (-f $file) {
		$html .= "\t" . '<TR><TD CLASS="LABEL" VALIGN="TOP"><B>' .
			$main::config{HTML}{STATUS} .':</B></TD>' .
			'<TD CLASS="VALUE" VALIGN="TOP"><' . $main::includer . ' ' . 
			$file . '> at ';
		if ($main::includer eq 'RRD::INCLUDE') {
			$html .= '<RRD::TIME::NOW "%Y-%m-%d %H:%M:%S"></TD></TR>' . "\n";
		}
		else {
			$html .= '<DATAPAGE::VAR now></TD></TR>' . "\n";
		}
	}

	# Show a host note, if there is a file
	$file = "$main::config{DATADIR}/$host/NOTE.html";
	if (-f $file) {
		$html .= &make_file_header( $main::config{HTML}{NOTE}, $file);
	}

	# Show host-specific headers
	foreach $header ( sort keys %{$main::config{HOST}{$host}{HEADERFILE}}) {
		$file = $main::config{DATADIR} . '/' . $host . '/' . 
			$main::config{HOST}{$host}{HEADERFILE}{$header};
		if( -f $file) {
			$html .= &make_file_header( $header, $file);
		}
	}

	$html .= "</TABLE>\n<!--end status_header -->\n<HR>\n";

	return $html;
}

#-------------------------------------------------------- make_valueheader ---
# Make HTML for a header which includes a file to get its value
sub make_value_header {
	my( $header, $value) = @_;
	my $html .= "\t" . '<TR><TD CLASS="LABEL" VALIGN="TOP"><B>' .
		$header . ':</B></TD>' .
		'<TD CLASS="VALUE" VALIGN="TOP">' . $value . 
		'</TD></TR>' . "\n";
	return $html;
}
#--------------------------------------------------------- make_file_header ---
# Make HTML for a header which includes a file to get its value
sub make_file_header {
	my( $header, $file) = @_;
	my $html = "\t" . '<TR><TD CLASS="LABEL" VALIGN="TOP"><B>' .
		$header . ':</B></TD>' .
		'<TD CLASS="VALUE" VALIGN="TOP"><' . $main::includer .' '. $file .
		'></TD></TR>' . "\n";
	return $html;
}

#-------------------------------------------------------- rrd_status_header ---
sub rrd_status_header {
	my ($host, $realrrd, $wildrrd, $fixedrrd, $graph) = @_;
	my ($status, $stale, $printed);
	unless (defined $main::includer) { $main::includer = 'RRD::INCLUDE'; }

	$printed = 0;
	my $html = "<!-- begin rrd_status -->\n";
	$html .= "\n<TABLE WIDTH=\"100%\">\n";

	if (defined $main::config{HOST}{$host}{RRDDESC}{$realrrd}) {
		$printed = 1;
		$html .= &make_value_header( $main::config{HTML}{DESCRIPTION},
			$main::config{HOST}{$host}{RRDDESC}{$realrrd});
	}

	if (defined $main::config{RRD}{$wildrrd}{GRAPHDESC}{$graph}) {
		$printed = 1;
		$html .= &make_value_header( $main::config{HTML}{DESCRIPTION},
			$main::config{RRD}{$wildrrd}{GRAPHDESC}{$graph});
	}

	my $file = "$main::config{DATADIR}/$host/SOFTWARE-$fixedrrd";
	if (-f $file) {
		$printed = 1;
		$html .= &make_file_header( $main::config{HTML}{OPERATINGSYSTEM},
			$file);
	}

	$file = "$main::config{DATADIR}/HARDWARE-.$fixedrrd";
	if (-f $file) {
		$printed = 1;
		$html .= &make_file_header( $main::config{HTML}{HARDWARE}, $file);
	}

	$file = "$main::config{DATADIR}/$host/STATUS-$fixedrrd";
	if (-f $file) {
		$printed = 1;
		$html .= &make_file_header( $main::config{HTML}{STATUS}, $file);
	}

	$file = "$main::config{DATADIR}/$host/ERROR-$fixedrrd";
	if (-f $file) {
		$printed = 1;
		$html .= &make_file_header( $main::config{HTML}{COMMENT}, $file);
	}

	$file = "$main::config{DATADIR}/$host/COMMENT-$fixedrrd";
	if (-f $file) {
		$printed = 1;
		$html .= &make_file_header( $main::config{HTML}{COMMENT}, $file);
	}

	$html .= "</TABLE>\n<!-- end rrd_status -->\n<HR>\n";
	if( $printed) { return $html; }
	else { return ''; }

$html;
}

#----------------------------------------------------- make_custom_graph ---
sub make_custom_graph {
	my ($dir, $prefix, $customgraph, $graphtime) = @_;
	my ($rrdgraph, $graphfile);

	$graphfile = $customgraph .'-'. $graphtime .'.'. $main::config{IMAGETYPE};
	if (defined $prefix) { $graphfile = $prefix .'-'. $graphfile; }

	$rrdgraph = '<RRD::GRAPH '. $main::config{HTMLDIR} . '/' . $dir . '/' . 
		$graphfile .  ' --lazy'.
		' --start '. $main::config{TIME}{$graphtime}{START};
	unless ($main::config{TIME}{$graphtime}{FINISH} == 0) {
		$rrdgraph .= ' --end '. $main::config{TIME}{$graphtime}{FINISH};
	}
	$rrdgraph .= ' --imgformat '. $main::config{IMAGETYPE} .
		' --imginfo \'<IMG SRC="' . $main::config{HTMLURL} . '/' .  $dir . 
		'/%s" WIDTH="%lu" HEIGHT="%lu" ALT="' .
		$customgraph .' '. $graphtime .'">\' ' .
		" '". join("' '", &do_subs(undef, undef, undef, undef, undef,
		$customgraph, $graphtime, 
		@{$main::config{CUSTOMGRAPH}{$customgraph}{GRAPH}})) ."'>";
	
	return $rrdgraph;
}

#------------------------------------------------------- make_rrdcgi_graph ---
sub make_rrdcgi_graph {
	my ($dir, $prefix, $host, $realrrd, $graph, $graphtime, $alttext,
		$override_rrdfile, $override_start, $override_end) = @_;
	# XXX fix docs at top
	my ($realgraph, $rrdfile, $wildrrd, $wildpart, $fixedrrd, $fixedgraph);
	my ($rrdgraph, $rrddesc);

	($wildrrd, $wildpart, $fixedrrd) = &get_rrd($realrrd);
	unless (defined $wildrrd) {
		&error("make_rrdcgi_graph: unknown rrd '$realrrd'; " .
			"skipped graph '$graph'");
		return "[unknown rrd '$realrrd' for graph '$graph']";
	}
	unless (defined $main::config{RRD}{$wildrrd}{GRAPH}{$graph}) {
		&error("make_rrdcgi: unknown graph '$graph' in rrd '$realrrd'; " .
			"skipped");
		return "[unknown graph '$graph' in rrd '$wildrrd' for '$realrrd']";
	}

	unless (defined $main::includer) { $main::includer = 'RRD::INCLUDE'; }

	# Make the graph filename
	$realgraph = $graph;
	if (defined $wildpart) { $realgraph =~ s/\*/$wildpart/; }
	unless( defined $main::config{TIME}{$graphtime}) {
		&error("unknown graphtime '$graphtime' in $realrrd; 'day' used");
		$graphtime = 'day';
	}
	$fixedgraph = &to_filename($realrrd .'-'. $realgraph .'-'. $graphtime .'.'.
		$main::config{IMAGETYPE});
	if (defined $prefix) { $fixedgraph = $prefix .'-'. $fixedgraph; }

	$rrdgraph = '<RRD::GRAPH ' . $main::config{HTMLDIR} . '/';
	if( defined $dir) { $rrdgraph .= $dir . '/'; }
	$rrdgraph .= $fixedgraph .  ' --lazy ';

	# Set the start and end times
	if( $override_start) {
		$rrdgraph .= '--start ' . $override_start;
	}
	else {
		$rrdgraph .= '--start ' .  $main::config{TIME}{$graphtime}{START};
	}

	if( $override_end) {
		$rrdgraph .= ' --end ' . $override_end ;
	}
	elsif ($main::config{TIME}{$graphtime}{FINISH} != 0) {
		$rrdgraph .= ' --end ' . $main::config{TIME}{$graphtime}{FINISH};
	}

# Now stick in the description
	if (defined $main::config{HOST}{$host}{RRDDESC}{$realrrd}) {
		$rrddesc = $main::config{HOST}{$host}{RRDDESC}{$realrrd} .' ';
	}
	else { $rrddesc = ''; }

# and here's the IMG tag
	$rrdgraph .= ' --imgformat '. $main::config{IMAGETYPE} .
		' --imginfo \'<IMG SRC="'. $main::config{HTMLURL} . '/' . $dir . '/%s' .
		'" WIDTH="%lu" HEIGHT="%lu" ALT="';

# ... the alt text
	if (defined $alttext) {
		$alttext =~ s/"/\&quot;/g;
		$alttext =~ s/'/\&#39;/g;
		$rrdgraph .= $alttext . '">\' ';
	}
	else {
		$rrdgraph .= $rrddesc . '[' . $host . ' ' . $realgraph . ' ' .
			$graphtime . ']">\' ';
	}

# Hack to get the thumbnails to show up right
	if ($graphtime eq 'thumb') {
		$rrdgraph .= "<$main::includer ". $main::config{DATADIR} .'/'. $host 
			.'/STATUS-BACKGROUND.html>';
		$rrdgraph .= ' --width '. $main::config{THUMBWIDTH} .
			' --height '. $main::config{THUMBHEIGHT};
	}

	# Allow overriding the calculated rrd-file (for rt-updater)
	if( $override_rrdfile) {
		$rrdfile = $override_rrdfile;
	}
	else {
		$rrdfile = $main::config{DATADIR} . '/' . $host . '/' . $fixedrrd .
			'.rrd';
	}
	my @temp;

	# If graphtime is thumb, then we're only doing the thumb graph
	if ($graphtime eq 'thumb') {
		@temp = @{$main::config{RRD}{$wildrrd}{GRAPH}{'thumb'}};
	}
	else { @temp = @{$main::config{RRD}{$wildrrd}{GRAPH}{$graph}}; }

	$rrdgraph .= " '". join("' '", &do_subs($rrdfile, $realrrd, $wildpart, 
		$host, undef, $realgraph, $graphtime, @temp));
	$rrdgraph .= "'>";

	return $rrdgraph;
}

#------------------------------------------------------------- header_bar ---
sub header_bar {
	my $text = join('', @_);
	$text = $main::config{HTML}{GROUPPREFIX} . $text .
		$main::config{HTML}{GROUPSUFFIX};
	return $text
}

#--------------------------------------------------- make_host_index_url ---
sub make_host_index_url {
	my $host = shift @_;
	my $url = $main::config{HTMLURL} . '/' . $host . '/index.cgi';
	return $url;
}

#------------------------------------------------------------ webgroup_dir ---
sub webgroup_dir {
	my $dir = shift @_;
	my( $gid);

	# Cache the webgroup gid
	unless( defined $main::webgroup_gid) {
		$main::webgroup_gid = (getgrnam( 'facon'))[2];
		unless( defined $main::webgroup_gid) {
			&error("can't get gid for facon: $!");
			return;
		}
	}

	# Make sure this directory is owned by the correct group
	$gid = (stat $dir)[5];
	unless( $gid == $main::webgroup_gid) {
		chown -1, $main::webgroup_gid, $dir or do {
			&error("can't chown $dir to facon: $!");
			return;
		};
		chmod 02775, $dir or do {
			&error("can't chmod $dir to 2775: $!");
			return;
		};
	}
}

# Say it's OK
1;
