#!/usr/bin/perl -w

# graph.cgi - dynamically emit a remstats graph, for static pages
# $Id: graph.cgi.in,v 1.16 2003/05/20 19:29:21 remstats Exp $
# from remstats 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Configuration   - - -

use strict;

# What is this program called, for file-names and error-messages.
$main::prog = 'graph.cgi';
# So -T will stop whinging.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ed857416/3p/remstats/bin';
# Where is the config dir
$main::config_dir = '/home/ed857416/3p/remstats/etc/config';
# Debugging anyone?
$main::debug = 0;
# Image only, i.e. no headers?
$main::image_only = 0;

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.16 $'))[1];

# - - -   Setup   - - -

use lib '.', '/home/ed857416/3p/remstats/lib', '/usr/local/rrdtool/lib/perl';
use Getopt::Std;
use RRDs;
require "remstats.pl";
require "accessstuff.pl";
require "cgistuff.pl";
require "htmlstuff.pl";

# Don't try to update IP_CACHE; don't have access from cgi
$main::ip_cache_readonly = 1;
$main::sent_headers = 0;

my %opt = ();
getopts('d:f:hi', \%opt);

if (defined $opt{'h'}) { &usage; } # no return
if (defined $opt{'f'}) { $main::config_dir = $opt{'f'}; }
if (defined $opt{'d'}) { $main::debug = $opt{'d'}; }
if (defined $opt{'i'}) { $main::image_only = 1; }

&read_config_dir($main::config_dir, 'general', 'html', 'links', 'colors',
	'tools', 'times', 'oids', 'rrds', 'customgraphs', 'groups', 
	'host-templates', 'hosts', 'view-templates', 'views');

# Initialize some useful variables
%main::R = &cgi_request();
# $main::url = 'http://' . &cgi_var("SERVER_NAME") . ':' . 
#	&cgi_var('SERVER_PORT');
#$main::url = $main::config{CGIURL};
#my $script_name = &cgi_var('SCRIPT_NAME');
#if ($script_name =~ m#^/#) { $main::url .= $script_name; }
#else { $main::url .= '/'. $script_name; }
$main::url = &cgi_var('SCRIPT_NAME');

$| = 1; # no buffering please
&debug( &cgi_fmtrequest(%main::R)) if ($main::debug);

&abort("access prohibited") unless( &access_control( $main::prog));

# Declare variables
my ($customgraph, $host, $realrrd, $wildrrd, $wildpart, $fixedrrd, 
	$graph, $graphtime, $start, $end, $height, $width, $form, @rrdgraph,
	$graphfile, $rrdfile, $error);

( $customgraph, $host, $realrrd, $wildrrd, $wildpart, $fixedrrd, 
	$graph, $graphtime, $start, $end, $height, $width, $form, @rrdgraph) =
	&parse_form();

# Host-specific graph
if (defined $host and defined $fixedrrd) {
	$rrdfile = $main::config{DATADIR} .'/'. $host .'/'. $fixedrrd .'.rrd';
	push @rrdgraph, &do_subs($rrdfile, $realrrd, $wildpart, $host, undef, 
		$graph, $graphtime, @{$main::config{RRD}{$wildrrd}{GRAPH}{$graph}});
}

# Customgraph
elsif (defined $customgraph) {
	push @rrdgraph, &do_subs( undef, undef, undef, undef, undef, undef,
		$graphtime, @{$main::config{CUSTOMGRAPH}{$customgraph}{GRAPH}});
}

# Some mishmash, missing required fields
else {
	&abort("missing required fields");
}

# Are we generating a form to wrap the image, or...
if( $form) {
	&generate_form( $customgraph, $host, $realrrd, $wildrrd, $wildpart, 
		$fixedrrd, $graph, $graphtime, $start, $end, $height, $width, 
		$form, @rrdgraph);
}

# ... are we generating the image itself?
else {

	# Make sure there is enough defined
	unless( ( $host and $realrrd and $graph) or $customgraph) {
		&abort("neither host nor customgraph are defined");
	}

	# Let the browser know what's coming down the pipe
	&cgi_sendheaders('Description: Remstats Graph Generator ' .
		$main::prog . ' version ' . $main::version,
		'Content-type: image/png') unless($main::image_only);
	$main::sent_headers = 1;

	$graphfile = ($main::debug) ? '/tmp/graph.png' : '-';
	RRDs::graph $graphfile, @rrdgraph;
	if ($error = RRDs::error) { &abort('RRD error: '.$error); }
}

exit 0;

#----------------------------------------------------------------- abort ---
sub abort {
	&error( 'ABORT: ' . join('', @_));
	exit 1;
}

#----------------------------------------------------------------- debug ---
sub debug {
	&error('DEBUG: ' . join('', @_));
}

#------------------------------------------------------------------ error ---
sub error {
	my $msg = join('', @_);

	open (ERROR, ">>/tmp/${main::prog}-errors") or 
		die "$main::prog: can't open /tmp/errors: $!\n";
	print ERROR "ERROR: $msg\n";
	close (ERROR);
	
	# Make sure that we've got some HTTP headers so we can see the message
	unless( $main::sent_headers) {
		&cgi_sendheaders('Content-type: text/html');
		$main::sent_headers = 1;
	}
	print "<H1>ERROR</H1>\n$msg\n";
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
  -i      output image only, not HTTP headers

In CGI mode, it takes a standard form-type, URL, e.g.
  $main::url?host=xxx&rrd=xxx&graph=zzz&graphtime=aaa
with the permissible fields being, host, rrd, graph, graphtime, start,
end, height and width.  The start, end, height and width, override
those specified in the graph definition.  You must specify either (host,
rrd and graph) or (customgraph) and graphtime.
EOD_USAGE
	exit 0;
}

#---------------------------------------------------- keep_strict_happy ---
sub keep_strict_happy {
	$main::ip_cache_readonly = 0;
}

#------------------------------------------------------------ parse_form ---
sub parse_form {
	my( $host, $customgraph, @rrdgraph, $realrrd, $wildrrd, $wildpart,
		$fixedrrd, $graph, $graphtime, $start, $end);

	# Pull out the host-name
	if (defined $main::R{'host'} and $main::R{'host'} ne '') {
		if ($main::R{'host'} =~ /^([-.a-zA-Z0-9]+|_remstats_)$/) {
			$host = lc $1;
			unless (defined $main::config{HOST}{$host}) {
				&abort("unknown host '$host'");
			}
			&debug("  host='$host'") if ($main::debug);
		}
		else { &abort("bad host spec '$main::R{'host'}'"); }
	}

	# or the customgraph name
	elsif (defined $main::R{'customgraph'} and $main::R{'customgraph'} ne '') {
		if ($main::R{'customgraph'} =~ /^([-a-zA-Z0-9._]+)$/) {
			$customgraph = $1;
			unless (defined $main::config{CUSTOMGRAPH}{$customgraph}) {
				&abort("unknown customgraph '$customgraph'") if ($main::debug);
			}
			&debug("  customgraph='$customgraph'") if ($main::debug);
		}
		else { &abort("bad customgraph spec '$main::R{'customgraph'}'"); }
	}

	# The RRD name
	if (defined $host and defined $main::R{'rrd'} and $main::R{'rrd'} ne '') {
		if ($main::R{'rrd'} =~ /^([-:\/.a-zA-Z0-9]+)$/) {
			$realrrd = lc $1;
			($wildrrd, $wildpart, $fixedrrd) = &get_rrd($realrrd);
			if (!defined $wildrrd) {
				&abort("unknown rrd $realrrd");
			}
			&debug(" rrd='$realrrd', wild='$wildrrd'") if ($main::debug);
		}
		else { &abort("bad rrd spec '$main::R{'rrd'}'"); }
	}
	elsif (defined $customgraph) { }

	# The graph name
	if (defined $host and defined $wildrrd and defined $main::R{'graph'} and 
			$main::R{'graph'} ne '') {
		if ($main::R{'graph'} =~ /^([-.a-zA-Z0-9\*]+)$/) {
			$graph = lc $1;
			unless (defined $main::config{RRD}{$wildrrd}{GRAPH}{$graph}) {
				&abort("unknown graph '$graph' for rrd '$realrrd'");
			}
			&debug("  graph='$graph'") if ($main::debug);
		}
		else { &abort("bad graph spec '$main::R{'graph'}'"); }
	}
	elsif (defined $customgraph) { }

	# The graphtime, or start/end or default time
	if (defined $main::R{'time'}) { $main::R{'graphtime'} = $main::R{'time'}; }
	if (defined $main::R{'graphtime'} and $main::R{'graphtime'} ne '') {
		if ($main::R{'graphtime'} =~ /^([-a-zA-Z0-9]+)$/) {
			$graphtime = lc $1;
			unless (defined $main::config{TIME}{$graphtime}) {
				&abort("unknown timespan '$graphtime'"); 
			}
			&debug("  time='$graphtime'") if ($main::debug);
		}
		else { &abort("bad graphtime spec '$main::R{'graphtime'}'"); }
	}

	# Can specify start/end on the URL
	if( defined $main::R{'start'} and $main::R{'start'} ne '') {
		if( $main::R{'start'} =~ m#^([-+:/\.0-9acdehimnorstuwy\s]+)$#) {
			push @rrdgraph, '--start', $1;
			$start = $1;
		}
		else {
			&abort("unknown start time format ($main::R{'start'})");
		}
	}
	else {
		# Prepare the graph start/end and image-type
		if( defined $graphtime and
				defined $main::config{TIME}{$graphtime}{START}) {
			@rrdgraph = ('--start', $main::config{TIME}{$graphtime}{START});
			$start = $main::config{TIME}{$graphtime}{START};
		}
		else {
			push @rrdgraph, '--start', '-1d';
			$start = '-1d';
		}
	}

	# Might have an end too
	if( defined $main::R{'end'} and $main::R{'end'} ne '') {
		if( $main::R{'end'} =~ m#^([-+:/\.0-9acdehimnorstuwy\s]+)$#) {
			push @rrdgraph, '--end', $1;
			$end = $1;
			if( defined $main::R{'start'}) { $graphtime .= ' - ' . $1; }
		}
		else {
			&abort("unknown end time format ($main::R{'end'})");
		}
	}
	else {
		if( defined $graphtime and 
				defined $main::config{TIME}{$graphtime}{FINISH}) {
			if( $main::config{TIME}{$graphtime}{FINISH} == 0) {
				$end = 'now';
			}
			else {
				push @rrdgraph, '--end',
					$main::config{TIME}{$graphtime}{FINISH};
				$end = $main::config{TIME}{$graphtime}{FINISH};
			}
		}
		else {
			push @rrdgraph, '--end', 'now';
			$end = 'now';
		}
	}

	# What image type?
	push @rrdgraph, '--imgformat', $main::config{IMAGETYPE};

	# User-specified width
	if( defined $main::R{'width'} and $main::R{'width'} ne '') {
		if( $main::R{'width'} =~ /^(\d+)$/) {
			push @rrdgraph, '--width', $1;
			$width = $1;
		}
		else {
			&abort("unknown width format ($main::R{'width'})");
		}
	}

	# User-specified height
	if( defined $main::R{'height'} and $main::R{'height'} ne '') {
		if( $main::R{'height'} =~ /^(\d+)$/) {
			push @rrdgraph, '--height', $1;
			$height = $1;
		}
		else {
			&abort("unknown height format ($main::R{'height'})");
		}
	}

	# Is this a form, or just the image?
	if( defined $main::R{'form'}) {
		if( $main::R{'form'} =~ /^(y|Y|t|T|1)/) {
			$form = 1;
		}
		elsif( $main::R{'form'} =~ /^(n|N|f|F|0)/) {
			$form = 0;
		}
		else { &abort('malformed form field'); }
	}
	else { $form = 0; }

	unless( $host or $customgraph) { $form = 1; }

	return( $customgraph, $host, $realrrd, $wildrrd, $wildpart, $fixedrrd,
		$graph, $graphtime, $start, $end, $height, $width, $form, @rrdgraph);
}

#-------------------------------------------------------- generate_form ---
sub generate_form {
	my( $customgraph, $host, $realrrd, $wildrrd, $wildpart, $fixedrrd,
		$graph, $graphtime, $start, $end, $height, $width, $form, 
		@rrdgraph) = @_;
	my( $graphtime_options, $url_with_args);

	# Get those headers out there, so that error messages will show up.
	&cgi_sendheaders('Description: Remstats Graph Generator ' .
		$main::prog . ' version ' . $main::version,
		'Content-type: text/html') unless($main::image_only);

	# Which have we got?  A host or custom graph?
	if( defined $host) {
		$customgraph = '';
	}
	elsif( defined $customgraph) {
		$host = '';
	}
	else {
		&abort("neither host nor customgraph defined");
	}

	# Show all the graph-times
	$graphtime_options = join("\n", map { '<OPTION VALUE="' . $_ .  '">' .
		$_ .  '</OPTION>'} (sort keys %{$main::config{TIME}}));

	# Populate the index links
	%main::indices = &init_indices();

	# Make the whole $url_with_args
	$url_with_args = &make_url_with_args( $customgraph, $host, $realrrd, 
		$wildrrd, $wildpart, $fixedrrd, $graph, $graphtime, $start, $end, 
		$height, $width, $form);

	$host = '' unless( defined $host);
	$realrrd = '' unless( defined $realrrd);
	$graph = '' unless( defined $graph);
	$customgraph = '' unless( defined $customgraph);
	$height = '' unless( defined $height);
	$width = '' unless( defined $width);

	print &html_header('Graph Browser', '', %main::indices);
	print <<"EOD_FORM";
<FORM METHOD="POST" ACTION="$main::url">
<P ALIGN="CENTER"><IMG SRC="$url_with_args"></P>
<NOBR>Host: <INPUT NAME="host" VALUE="$host"></NOBR>
<NOBR>RRD: <INPUT NAME="rrd" VALUE="$realrrd"></NOBR>
<NOBR>Graph: <INPUT NAME="graph" VALUE="$graph"></NOBR>
- Or -
<NOBR>Customgraph: <INPUT NAME="customgraph" VALUE="$customgraph"><BR></NOBR>

<NOBR>Start: <INPUT NAME="start" VALUE="$start"></NOBR>
<NOBR>End: <INPUT NAME="end" VALUE="$end"></NOBR>
- Or -
<NOBR>Graph-time: <SELECT NAME="graphtime">
	$graphtime_options
	</SELECT></NOBR>
<BR>

<NOBR>Width: <INPUT NAME="width" VALUE="$width"></NOBR>
<NOBR>Height: <INPUT NAME="height" VALUE="$height"></NOBR>
<INPUT TYPE="HIDDEN" NAME="form" VALUE="1">
</P>

<P><INPUT TYPE="SUBMIT" VALUE="Make graph">
<INPUT TYPE="RESET" VALUE="Clear form">
</P>
</FORM>
EOD_FORM
	print &html_footer();
}

#------------------------------------------------------ make_url_with_args ---
sub make_url_with_args {
	my( $customgraph, $host, $realrrd, $wildrrd, $wildpart, $fixedrrd,
		$graph, $graphtime, $start, $end, $height, $width, $form) = @_;
	my $url;

	# Host or ...
	if( defined $host && $host ne '' && defined $realrrd && $realrrd ne '' &&
			defined $graph && $graph ne '') {
		$url = $main::url . '?host=' . $host . '&rrd=' .
			$realrrd . '&graph=' . $graph;
	}
	# ... customgraph?
	elsif( defined $customgraph && $customgraph ne '') {
		$url = $main::url . '?customgraph=' . $customgraph;
	}
	else { &abort("neither host nor customgraph defined"); }

	# Start and end?
	if( $start and $end) {
		if( $start) { $url .= '&start=' . $start; }
		else { $url .= '&start=' . '-1d'; }
		if( $end) { $url .= '&end=' . $end; }
		$url .= '&graphtime=';
	}

	# Graphtime or ...
	elsif( $graphtime) {
		$url .= '&graphtime=' . $graphtime;
		$url .= '&start=&end=';
	}

	# Height and width overrides?
	if( $height) { $url .= '&height=' . $height; }
	if( $width) { $url .= '&width=' . $width; }

	# Purposefully not copying the 'form' field
	return $url;
}
