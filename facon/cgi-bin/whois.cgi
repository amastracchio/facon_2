#!/usr/bin/perl -Tw

# whois.cgi - let people get whois info
# $Id: whois.cgi.in,v 1.11 2002/06/24 14:56:44 remstats Exp $
# from remstats 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Configuration   - - -

use strict;

# What is this program called, for file-names and error-messages.
$main::prog = 'whois.cgi';
# Where is the config dir
$main::config_dir = '/home/ed857416/3p/remstats/etc/config';
# How to invoke whois
$main::whois = '/usr/bin/whois';
# Where to send them if no server is specified
$main::default_server = 'whois.arin.net';
# There are lots of NICs now.  The common ones I know for looking up 
# hosts/IP#s are:
my %nics = (
	'whois.ripe.net' => '%s',
	'whois.apnic.net' => '%s',
	'whois.aunic.net' => '%s',
#	'(whois\.[-a-zA-Z0-9\.]+\.[a-zA-Z]{2,4})' => '%s',
);


# Debugging anyone?
$main::debug = 0;

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.11 $'))[1];

# - - -   Setup   - - -

$ENV{PATH} = '/home/ed857416/3p/remstats/bin:/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin';

use lib '.', '/home/ed857416/3p/remstats/lib', '/usr/local/rrdtool/lib/perl';
require "remstats.pl";
require "accessstuff.pl";
require "cgistuff.pl";
require "htmlstuff.pl";

# Don't try to update IP_CACHE; don't have access from cgi
$main::ip_cache_readonly = 1;

&read_config_dir( $main::config_dir, 'general', 'links', 'colors', 'html');

# Initialize some useful variables
%main::R = &cgi_request;
&cgi_sendheaders('Description: remstats whois.cgi');
$main::url = 'http://' . &cgi_var("SERVER_NAME") . ':' . &cgi_var('SERVER_PORT')
	. &cgi_var('SCRIPT_NAME');

my $title = $main::prog . ' (version ' . $main::version . ')';
my %indices = &init_indices();
print &html_header( $title, $title, %indices);

&cgi_fmtrequest(%main::R) if ($main::debug);

&abort("access prohibited") unless( &access_control( $main::prog));

# Is this really fwhois?  Isn't incompatible syntax wonderful? NFC
if (-l $main::whois) {
	&debug("whois is a symlink") if ($main::debug);
	my $real_whois = readlink $main::whois or
		&abort("error reading whois symlink: $main::whois");
	if ($real_whois =~ m#fwhois#) { $main::fwhois = 1; }
	else { $main::fwhois = 0; }
}
elsif ($main::whois =~ m#fwhois#) { $main::fwhois = 1; }
else { $main::fwhois = 0; }
&debug("fwhois=<B>$main::fwhois</B>") if ($main::debug);

# - - -   Main Line   - - -

# Where are we going to get the info
my ($server, $query);
if (defined $main::R{'server'}) {
	&debug("server=<B>$main::R{'server'}</B>") if ($main::debug);
	if ($main::R{'server'} =~ /^([-a-zA-Z0-9.]+)$/) {
		$server = $1;
	}
	else { &abort("malformed server string '$main::R{'server'}'"); }
}
else { $server = $main::default_server; }

# What are we asking about?
$query = '';
if (defined $main::R{'query'}) {
	&debug("query=<B>$main::R{'query'}</B>") if ($main::debug);
	if ($main::R{'query'} =~ m#^([-a-zA-Z0-9_\./]+)$#) { $query = $1; }
	else { &abort("malformed query string '$main::R{'query'}'"); }
}

$| = 1; # no buffering please
print <<"EOD_FORM";
<FORM METHOD="POST" ACTION="$main::url">
Query:
<INPUT NAME="query" SIZE=20 VALUE="$query">
Server:
<INPUT NAME="server" SIZE=20 VALUE="$server">
<INPUT TYPE="SUBMIT" VALUE="Do it">
</FORM>
EOD_FORM

unless (defined $query) {
	print &html_footer();
	exit 0;
}

my $cmd = &make_whois( $server, $query);

print "<HR><PRE>\n";

# Collect the info
#my @lines = ();
#open (PIPE, "$cmd|") or &abort("can't open pipe from $cmd");
#@lines = <PIPE>;
#close (PIPE);
my @lines = `$cmd`;

&debug("raw whois info:\n<BR>" . join("\n<BR>", @lines)) if ($main::debug);

my ($tag, $addr, $nic, $newquery, $linkurl, $thenic, $found);

# Look for indirection
$found = 0;
foreach (@lines) {
	next unless (/^\s+Whois\s+Server:\s+(.*)$/i);
	$server = $1;
	$found = 1;
	&debug("found indirect server <B>$server</B>") if ($main::debug);
	last;
}

# If we found indirection, follow it
if ($found) {
	$cmd = &make_whois( $server, $query);
	@lines = `$cmd`;
	if ($?) { &abort("can't run whois2: $?"); }
	&debug("raw indirect whois info:\n<BR>" . join("\n<BR>", @lines)) 
		if ($main::debug);
}

# Mark up some things specially
foreach (@lines) {

	# Things that look like urls should be links
	s#(http://\S+[^,.;])#<A HREF="$1">$1</A>#g;

	# Parenthesised things are to be whois'd
	if (m#\(([A-Z][-A-Z0-9]+)\)#) {
		$tag = $1;
		unless ($tag =~ /^(ph|phone|fax)$/i) {
			s#\($tag\)#\(<A HREF="$main::url?server=$server&query=$tag">$tag</A>\)#;
		}
	}

	# If it looks like an email address, make it a mailto
	if (m#\s([-a-z0-9_\.]+\@[-a-z0-9\.]+)\s#i) {
		$addr = $1;
		s#$addr#<A HREF="mailto:$addr">$addr</A>#;
	}

	# If it's a NIC we know make it a whois link to them
	$found = 0;
	foreach $nic (keys %nics) {
		if (/$nic/i) {

			# It's a wildcard whois host
			if( defined $1) {
				next if( $found);
				$thenic = $1;
				next if( defined $nics{$thenic});
				$newquery = $query;
			}

			# It's a specific whois host
			else {
				$newquery = sprintf $nics{$nic}, $query;
				$thenic = $nic;
				$found = 1;
			}

			s#${thenic}#<A HREF="${main::url}\?server=${thenic}\&query=${newquery}">${thenic}</A>#i;
			&debug("subbed in link to <B>$nic</B>") if ($main::debug);
		}
	}
	print $_;
}
print "</PRE>\n", &html_footer();
0;

#------------------------------------------------------------------ abort ---
sub abort {
	my ($msg) = @_;
	print <<"EOD_ABORT";
<H1>Abort</H1>
$msg
EOD_ABORT
	print &html_footer();
	exit 1;
}

#--------------------------------------------------------------- make_whois ---
sub make_whois {
	my ($server, $query) = @_;
# *&%*&$* fwhois
	my $cmd = $main::whois .' ';
	if ($main::fwhois) { $cmd .= "'". $query ."'@". $server; }
	else { $cmd .= ' -h '. $server ." '". $query ."'"; }
	&debug("whois cmd=<B>$cmd</B>") if ($main::debug);
$cmd;
}

#------------------------------------------------------------------ debug ---
sub debug {
	my $msg = join('', @_);
	print "<BR>DEBUG: $msg<BR>\n";
}

#---------------------------------------------------- keep_strict_happy ---
sub keep_strict_happy {
	$main::ip_cache_readonly = 0;
}
