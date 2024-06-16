#!/usr/bin/perl -w

# macinfo.cgi - reformat the output of macinfo
# $Id: macinfo.cgi.in,v 1.8 2002/08/19 18:46:31 remstats Exp $
# from remstats 1.0.13a

# Copyright 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Configuration   - - -

use strict;

# What is this program called, for file-names and error-messages.
$main::prog = 'macinfo.cgi';
# Where is macinfo?
$main::macinfo_prog = '/home/ed857416/3p/remstats/bin/macinfo';
$main::macinfo_options = '-N';
# Where is the config dir
$main::config_dir = '/home/ed857416/3p/remstats/etc/config';
# Debugging anyone?
$main::debug = 0;

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.8 $'))[1];

# - - -   Setup   - - -

# So -T will stop whinging.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ed857416/3p/remstats/bin';
use lib '.', '/home/ed857416/3p/remstats/lib';
use Getopt::Std;
require "remstats.pl";
require "accessstuff.pl";
require "cgistuff.pl";
require "htmlstuff.pl";
require "snmpstuff.pl";

my %opt = ();
getopts("d:f:h", \%opt);

if (defined $opt{'h'}) { &usage; } # no return
if (defined $opt{'f'}) { $main::config_dir = $opt{'f'}; }
if (defined $opt{'d'}) { $main::debug = $opt{'d'}; }

&read_config_dir($main::config_dir, 'general', 'html', 'links', 'colors',
	'tools', 'times', 'oids', 'rrds', 'customgraphs', 'groups', 
	'host-templates', 'hosts', 'view-templates', 'views');

# Initialize some useful variables
%main::R = &cgi_request;
&cgi_sendheaders(
	'Description: ' . $main::prog . '/' . $main::version .
		'from remstats 1.0.13a',
	'Content-type: text/html');
#$main::url = 'http://' . &cgi_var("SERVER_NAME") . ':' . 
#	&cgi_var('SERVER_PORT');
$main::url = $main::config{CGIURL};
my $script_name = &cgi_var('SCRIPT_NAME');
if ($script_name =~ m#^/#) { $main::url .= $script_name; }
else { $main::url .= '/'. $script_name; }

$| = 1; # no buffering please
print cgi_fmtrequest(%main::R) if ($main::debug);

&abort("access prohibited") unless( &access_control( $main::prog));

my ($host, $ip, $cmd, $comhost, $interface, @hostlist, $hosts, $html, 
	%indices, $title, $name);

# Load in the IP<->host cache map explicitly for IP# references
$main::ip_cache_readonly = 1;
&read_ip_cache();

if (defined $main::R{'host'}) {
	if ($main::R{'host'} =~ /^([-.a-zA-Z0-9]+)$/) {
		$host = lc $1;
		if (defined $main::config{HOST}{$host}) {
			$ip = &get_ip( $host);
			&debug("using our host $host") if( $main::debug);
		}
		elsif( defined $main::ip_cache{IP}{$host}) {
			$ip = $host;
			$host = $main::ip_cache{IP}{$host};
			&debug("using ip $host for $ip") if( $main::debug);
		}
		else { &abort("unknown host and not IP"); }
	}
	else { &abort("bad host spec '$main::R{'host'}'"); }
}
else { &abort("missing host"); }

# Now get the community string for this host
$comhost = &get_comhost( $host, undef, undef, $ip);
&debug("using '$comhost' for SNMP") if( $main::debug);

# - - -   Mainline   - - -

# Do the headers
%indices = &init_indices();
$title = $main::prog . ' for ' . $host;
$html = &html_header( $title, $title, %indices) .
	"<H1>$title</H1>\n<UL><TABLE>\n";

# Read the output from macinfo
$cmd = $main::macinfo_prog . ' ' . $main::macinfo_options .
	' ' . $comhost;
open( PIPE, "$cmd|") or &abort("can't open pipe from '$cmd': $!");
while(<PIPE>) {
	chomp;
	($interface, @hostlist) = split(' ', $_);

	# Now make the host-names links to their remstats pages
	$hosts = '';
	foreach $name (sort @hostlist) {
		next if( $name eq '?');
		if( defined $main::config{HOST}{$name}) {
			$hosts .= ' <A HREF="' .$main::config{HTMLURL} . '/' . $name . 
				'/index.cgi">' . $name . '</A>';
		}
		else { $hosts .= ' ' . $name; }
	}
	$html .= '<TR><TD ALIGN="LEFT" VALIGN="TOP">' . $interface . "</TD>\n" .
		'<TD ALIGN="LEFT" VALIGN="TOP">' . $hosts . "</TD></TR>\n";
}
close(PIPE);
$html .= "</TABLE>\n</UL>" . &html_footer();
print $html;

exit 0;

#----------------------------------------------------------------- abort ---
sub abort {
	my ($msg) = @_;
	&error("ABORT: $msg");
	exit 1;
}

#------------------------------------------------- debug ---
sub debug {
	my ($msg) = @_;

	&error("DEBUG: $!");
}

#-------------------------------------------------- error ---
sub error {
	my ($msg) = @_;

	open (ERROR, ">>/tmp/errors") or 
		die "$main::prog: can't open /tmp/errors: $!\n";
	print ERROR "ERROR: $msg\n";
	close (ERROR);
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

#---------------------------------------------------- keep_strict_happy ---
sub keep_strict_happy {
	$main::ip_cache_readonly = 0;
}
