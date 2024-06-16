#!/usr/bin/perl -Tw

# datapage.cgi - show the requested html template with dynamic data
#		interpolations, from SNMP data, RRD files, remstats status files
#		and remstats graphs.
# $Id: datapage.cgi.in,v 1.15 2002/06/24 14:56:44 remstats Exp $
# from remstats 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Configuration   - - -

# What is this program called, for file-names and error-messages.
$main::prog = 'datapage.cgi';
# So -T will stop whinging.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ed857416/3p/remstats/bin';
# Where is the config dir
$main::config_dir = '/home/ed857416/3p/remstats/etc/config';
# Limit on variable expansion looping
$main::maxloops = 5;
$main::macroname_pat = '[-0-9a-z_.]+';
# What do macro args look like
$main::macroarg_pat = '[-0-9A-Z_.]+';

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.15 $'))[1];

# - - -   Setup   - - -

# Who provides the file-include function for htmlstuff?
$main::includer = 'DATAPAGE::PATHINCLUDE';

use lib '.', '/home/ed857416/3p/remstats/lib', '/usr/local/rrdtool/lib/perl';
use SNMP_util;
use RRDs;
use Getopt::Std;
require "remstats.pl";
require "accessstuff.pl";
require "cgistuff.pl";
require "snmpstuff.pl";
require "alertstuff.pl";
require "datastuff.pl";
require "miscstuff.pl";
require "htmlstuff.pl";
require "private.pl";

# Don't try to change ALERTS; no access from cgi
$main::alerts_readonly = 1;

my ( %opt, $query);
%opt = ();
getopts('d:f:hp:', \%opt);

if (defined $opt{'h'}) { &usage; } # no return
if (defined $opt{'f'}) { $main::config_dir = $opt{'f'}; }
if (defined $opt{'d'}) { $main::debug = $opt{'d'}; } else { $main::debug = 0; }
if( defined $opt{'p'}) { $query = $opt{'p'}; }

&read_config_dir($main::config_dir, 'general', 'html', 'links', 'tools', 
	'times', 'oids', 'rrds', 'groups', 'host-templates', 'hosts');
&snmp_load_oids;

# Initialize some useful variables
my %request = &cgi_request;

$| = 1; # no buffering please
&debug(cgi_fmtrequest(%request)) if ($main::debug);

&abort("access prohibited") unless( &access_control( $main::prog));

# Don't try to update IP_CACHE; don't have access from cgi
$main::ip_cache_readonly = 1;

# - - -   Main Line   - - -

# Which page are we supposed to show
$query = &cgi_var(QUERY_STRING) unless( defined $query);
if (defined $query and length($query) > 0) {
	if ($query =~ /^([-0-9a-zA-Z\._]+)$/) {
		$query = $1;
	}
	else { &abort("Bad query string: $query"); }
}
else { &abort("missing query string"); }
my $script_file = $config{DATAPAGEDIR} .'/'. $query .'.page';
&debug("  looking for script $script_file") if ($main::debug);
unless (-f $script_file) { &abort("unknown query: <b>$query</b>"); }

# Global Variables
$main::var{htmldir} = $config{HTMLDIR};
$main::var{datadir} = $config{DATADIR};
$main::var{htmlurl} = $config{HTMLURL};

# Local Variables
my ($in_macro, $defining_macro, $macroname, $cmdline);

# Read the top, configuration part
my ($newhost, $host, $community, $port, $comhost, @oids, $myname, 
	$page, $oidname, $oid, $config);
$config = '';
open (SCRIPT, "<$script_file") or &abort("can't open $script_file: $!");
while (<SCRIPT>) {
	chomp;
	next if(/^#/ or /^\s*$/);
# We're done with the top
	last if(/^BEGIN-PAGE\s*$/);
	$config .= $_ . "\n";
}

# Slurp the rest of the page
$page = join('', <SCRIPT>);
close (SCRIPT);

@lines = split("\n", $config);
$main::errors = '';
$main::debugging = '';
($in_macro, $defining_macro) = (0, 0);

# A new host to query
while ($cmdline = shift @lines) {

	next if ($cmdline =~ /^\s*$/);
	&debug("cmdline: $cmdline") if ($main::debug>1);

	# Deal with macro definition
	if ($defining_macro) {
		unless ($cmdline =~ /^(macroend|endmacro)\s*$/) {
			push @{$main::macro{$macroname}}, $cmdline;
			&debug("  $macroname: $cmdline") if ($main::debug>1);
			next;
		}
	}
	# Deal with macro args, if in a macro
	if ($in_macro) {
		$cmdline =~ s#\$\{($main::macroarg_pat)\}#$main::args{$1}#egm;
		&debug("  macro args sub'd: $cmdline") if ($main::debug>1);
	}

	# First, do substitutions so the remaining code is simpler
	$cmdline = &variable_substitution($cmdline);

	# Do the common stuff
	if ($cmdline =~ 
			/^(oid|rrd|status|eval|scale|range|alertstatus|alertvalue)\s/) {
		&do_common($cmdline);
	}

	# Macro definition
	elsif ($cmdline =~ /^macro\s+($main::macroname_pat)\s*(.*)$/) {
		if ($defining_macro) {
			&error("macros can't define macros: $cmdline");
			next;
		}
		$defining_macro = 1;
		$macroname = lc $1;
		$main::macro_argnames{$macroname} = [split(' ', uc $2)];
		&debug("defining macro $macroname(". 
				join(',',@{$main::macro_argnames{$macroname}}) .')')
			if ($main::debug);
	}
	elsif ($cmdline =~ /^(macroend|endmacro)\s*$/) {
		unless ($defining_macro) {
			&error("can't end a macro that hasn't begun");
			next;
		}
		$defining_macro = 0;
		&debug("definition of $macroname ended") if ($main::debug);
		undef $macroname;
	}

	# Macro invocation
	elsif ($cmdline =~ /^%($main::macroname_pat)\s*(.*)$/) {
		$macroname = lc $1;
		my @args = split(' ', $2);
		unless (defined $main::macro{$macroname}) {
			&error("no macro called $macroname; skipped") if ($main::debug);
			next;
		}

        my $argname;
        for (my $i=0; $i<=$#args; ++$i) {
            $argname = uc ${$main::macro_argnames{$macroname}}[$i];
            $args{$argname} = $args[$i];
            &debug("  $macroname: arg $argname set to '$args[$i]'")
				if ($main::debug>1);
        }

		unshift @lines, 'endMACROinvocation '. $macroname;
		unshift @lines, @{$main::macro{$macroname}};
		$in_macro = 1;
		&debug("invoked macro $macroname") if ($main::debug);
	}
	elsif ($cmdline =~ /^endMACROinvocation\s+(\S+)$/) {
		$in_macro = 0;
		&debug("end of macro $1") if ($main::debug);
	}

	# Script-triggered debugging
	elsif( $cmdline =~ /^debug\s+(\d+)\s*$/) { $main::debug = $1; }
	elsif ( $cmdline =~ /^nodebug\s*$/) { $main::debug = 0; }

	# Mark the end, before the end-of-file
    elsif ($cmdline =~ /^\*EOD\*\s*$/) {
        last;
    }


	# Garbage here
	else {
		&error("unknown line: $cmdline");
	}
}

# Now we come to the interesting parts

# Do macro expansion first, so that it can be usefull, e.g. contain 
# variable substitutions like: <DATAPAGE::MACRO macroname arg1 ...>
$page =~ s/<DATAPAGE::MACRO\s+($main::macroname_pat)(\s+([^>]+))*>/&macro_sub($1,$3)/oegm;

# Include remstats status files.  The cookie looks like:
#	<DATAPAGE::STATUS host-name status-file-name>
$page =~ s/<DATAPAGE::STATUS\s+([-0-9a-zA-Z.]+)\s+([-0-9A-Za-z.]+)\s*>/&my_get_status($1,$2)/egm;

# A "variable" created by status, rrd, oid or eval lines.  The
# cookie looks like: <DATAPAGE::VAR>
$page =~ s/<DATAPAGE::VAR\s+([-0-9a-zA-Z_.]+)\s*>/&sub_var("$1")/egm;

# A remstats html header with indices.  The cookie looks like:
#	<DATAPAGE::HEADER title goes here>
$page =~ s/<DATAPAGE::HEADER\s+([^>]+)\s*>/&my_header($1)/egm;

# Include the status headers like: <DATAPAGE::STATUSHEADER hostname>
$page =~ s/<DATAPAGE::STATUSHEADER\s+([^\s>]+)\s*>/&status_header($1)/egm;

# Include tools like: <DATAPAGE::TOOLBAR hostname>
$page =~ s/<DATAPAGE::TOOLBAR\s+([^\s>]+)\s*>/&toolbar($1)/egm;

# Similarly, an html footer
$page =~ s/<DATAPAGE::FOOTER>/&html_footer/egm;

# dataimage.cgi can generate imagemaps which we can include here
$page =~ s/<DATAPAGE::INCLUDE\s+([^>]+)>/&include_file($1)/egm;

# dataimage.cgi can include any file now
$page =~ s/<DATAPAGE::PATHINCLUDE\s+([^>]+)>/&pathinclude_file($1)/egm;

# A remstats defined graph, interpreted by rrdcgi (ugh).  The cookie
# looks like:
#	<DATAPAGE::GRAPH host-name rrd-name graph-name graph-time>
my $rrdcgicount = 0;
$rrdcgicount += $page =~ s#<DATAPAGE::GRAPH\s+([-0-9a-zA-Z.]+)\s+([-0-9A-Za-z._/]+)\s+([-0-9A-Za-z._]+)\s+([-0-9A-Za-z._]+)\s*>#&my_graph($1,$2,$3,$4)#egm;

# Similarly, a remstats custom graph (i.e. not tied to a host).  
# The cookie looks like:
#	<DATAPAGE::CUSTOMGRAPH customgraph-name graph-time>
$rrdcgicount += $page =~ s/<DATAPAGE::CUSTOMGRAPH\s+([-0-9A-Za-z._]+)\s+([-0-9A-Za-z._]+)\s*>/&my_customgraph($1,$2)/egm;

# Show the errors, if they asked
$page =~ s/<DATAPAGE::ERRORS>/$main::errors/egm;

# Show the debugging info, if they asked
$page =~ s/<DATAPAGE::DEBUG>/$main::debugging/egm;

# if $rrdcgicount > 0 we need to feed the page through rrdcgi
# TODO

# Show it
print $page;

0;

#----------------------------------------------------------------- abort ---
sub abort {
	my ($msg) = @_;
	print <<"EOD_ABORT";
content-type: text/html

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

#------------------------------------------------- debug ---
sub debug {
	my ($msg) = @_;

	if ($main::debug) {
		$main::debugging .= "<b>DEBUG</b>: $msg<br>\n";
	}
}

#-------------------------------------------------- error ---
sub error {
	my ($msg) = @_;

	$main::errors .= "<b>ERROR</b>: $msg<br>\n";
}

#------------------------------------------------- my_get_status ---
sub my_get_status {
	my ($host, $file) = @_;
	my $string = &get_status($host, $file);
	if ($string =~ /^(.*) \(STALE\)\s*$/) {
		$string = $1;
	}
	return $string;
}

#---------------------------------------------------- my_header ---
sub my_header {
	my ($title) = @_;
	my %indices = &init_indices;
	my $string = &html_header($title, '', %indices);
	return $string;
}

#----------------------------------------------------- my_graph ---
sub my_graph {
	my ($host, $realrrd, $graph, $graphtime) = @_;
	my $string = &make_rrdcgi_graph( $host, undef, $host, $realrrd, 
		$graph, $graphtime);
	return $string;
}

#----------------------------------------------------- my_customgraph ---
sub my_customgraph {
	my ($customgraph, $graphtime) = @_;
	my $string = &make_custom_graph( $main::config{HTMLDIR} .'/CUSTOM',
		undef, $customgraph, $graphtime);
	return $string;
}

#---------------------------------------------------- usage ---
sub usage {
	print STDERR <<"EOD_USAGE";
$main::prog version $main::version
usage: $prog [options]
where options are:
  -d ddd  set debugging level to 'ddd'
  -f fff  use 'fff' for config-dir [$main::config_dir]
  -h      show this help
  -p ppp  show page 'ppp'
EOD_USAGE
	exit 0;
}

#---------------------------------------------------- include_file ---
sub include_file {
	my ($file) = @_;
	my $input = '';

	$file = $config{DATAPAGEDIR} .'/'. $file;
	open (INCLUDE, "<$file") or
		return <<"EOD_MESSAGE";
<h1>Error reading file</H1>
Error: $!<BR>
Probably an included file ($file) is being updated; please reload page
EOD_MESSAGE
	while (<INCLUDE>) {
		$input .= $_;
	}
	close (INCLUDE);
	return $input;
}

#---------------------------------------------------- pathinclude_file ---
sub pathinclude_file {
	my ($file) = @_;
	my $input = '';

	open (INCLUDE, "<$file") or
		return <<"EOD_MESSAGE";
<h1>Error reading file</H1>
Error: $!<BR>
Probably an included file ($file) is being updated; please reload page
EOD_MESSAGE
	while (<INCLUDE>) {
		$input .= $_;
	}
	close (INCLUDE);
	return $input;
}

#--------------------------------------------------- macro_sub ---
sub macro_sub {
	my ($macro_name, $args) = @_;
	my ($string, $argname, @args, %args);

	&debug("macro_sub: passed($macro_name, $args)") if ($main::debug>1);
	unless (defined $main::macro{$macro_name}) {
		return "ERROR: no such macro as '$macroname'\n";
	}

	# Get ready to do the arg substitutions
	@args = split(' ', $args);
	for (my $i=0; $i<=$#args; ++$i) {
		$argname = uc ${$main::macro_argnames{$macro_name}}[$i];
		$args{$argname} = $args[$i];
		&debug("  $macro_name: arg $argname set to '$args[$i]'")
			if ($main::debug>2);
	}

	$string = join("\n", @{$main::macro{$macro_name}});
	$string =~ s#\$\{($main::macroarg_pat)\}#$args{$1}#egm;

	$string = &variable_substitution( $string);
	&debug("macro_sub: returned:\n$string\n") if ($main::debug>1);

	return $string;
}

#----------------------------------------------------- datapage_get_ifname ---
sub datapage_get_ifname {
	my ($hostname, $ifindex) = @_;
	my ($comhost, $ifname);

	$comhost = &get_comhost( $hostname );
	if (defined $comhost) {
		$ifname = &get_ifname( $comhost, $ifindex);
	}
	return (defined $ifname) ? $ifname : $ifindex;
}

#------------------------------------------------------ sub_var ---
sub sub_var {
	my ($varname) = @_;
	if (defined $main::var{$varname}) {
		return $main::var{$varname};
	}
	else {
		return "UNKNOWNVAR=$varname";
	}
}

#------------------------------------------------------ keep_strict_happy ---
sub keep_strict_happy {
	$main::includer = 0;
	$main::ip_cache_readonly = 0;
	$main::alerts_readonly = 0;
}

#-------------------------------------------------- variable_substitution ---
sub variable_substitution {
	my $cmdline = shift @_;
	my $loops = 0;
	while ($loops++ < $main::maxloops and 
			$cmdline =~ s/\$\{([-0-9a-zA-Z_.]+)\}/&sub_var("$1")/egm) {
		if ($loops >= $main::maxloops) {
			&error("too much nesting: $cmdline");
			last;
		}
		&debug("sub line to: $cmdline") if ($main::debug);
	}
	return $cmdline;
}
