#!/usr/bin/perl -Tw

# traceroute.cgi - let people traceroute the monitored hosts
# $Id: traceroute.cgi.in,v 1.14 2002/06/24 14:56:44 remstats Exp $
# from remstats 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Configuration   - - -

use strict;

# What is this program called, for file-names and error-messages.
$main::prog = 'traceroute.cgi';

# Where is the config-dir
$main::config_dir = '/home/ed857416/3p/remstats/etc/config';

# For NANOG's improved traceroute (including ASN and SOA lookup)
$main::traceroute = '/home/ed857416/3p/remstats/bin/traceroute';
%main::traceroute_opts = (
	'no_names' => '-n',
	'ASNs' => '-A',
	'owners' => '-O',
	'fast' => '-U',
);
%main::checked = ();

# What is the whois script called (in same URL subtree as this script)
$main::whois = 'whois.cgi';

# Debugging anyone?
$main::debug = 0;

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.14 $'))[1];

# - - -   Setup   - - -

$SIG{INT} = 'trap';
$SIG{QUIT} = 'trap';
$SIG{PIPE} = 'trap';
$SIG{ALRM} = 'trap';
$SIG{HUP} = 'trap';
$SIG{ABRT} = 'trap';
$SIG{TERM} = 'trap';

# So that -T doesn't whinge.  It *is* safer for programs which might start
# other programs without explicit directories specified.
$ENV{PATH} = '/home/ed857416/3p/remstats/bin:/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin';

use lib '.', '/home/ed857416/3p/remstats/lib';
require "remstats.pl";
require "accessstuff.pl";
require "cgistuff.pl";
require "htmlstuff.pl";

# Don't try to update IP_CACHE; don't have access from cgi
$main::ip_cache_readonly = 1;

&cgi_sendheaders('Description: remstats traceroute.cgi');

&read_config_dir( $main::config_dir, 'general', 'links', 'colors', 'html');

# Initialize some useful variables
%main::R = &cgi_request;
&cgi_fmtrequest(%main::R) if ($main::debug);

&abort("access prohibited") unless( &access_control( $main::prog));

$main::url = 'http://' . &cgi_var("SERVER_NAME") . ':' . &cgi_var('SERVER_PORT')
	. &cgi_var('SCRIPT_NAME');

my @temp = split('/',&cgi_var('SCRIPT_NAME'));
pop @temp;
$main::whois = 'http://' . &cgi_var("SERVER_NAME") . ':' . &cgi_var('SERVER_PORT')
	. join('/',@temp) . '/' . $main::whois;

# Clear the environment
%ENV = ();

# Show the headers
my %indices = &init_indices();
my $title = $main::prog . ' (version ' . $main::version .')';
print &html_header( $title, $title, %indices);

# - - -   Main Line   - - -

# Make sure we have a valid hostname
undef $main::host;
if (defined $main::R{'host'} and $main::R{'host'} =~ /^([-0-9a-zA-Z.]+)$/) {
	$main::host = $1;
}
elsif (defined $main::R{'host'}) { &abort("Bad host field: $main::R{'host'}"); }

# Pull in the options from the form
foreach my $option (sort keys %main::traceroute_opts) {
	if (defined $main::R{$option} and $main::R{$option}) {
		$main::checked{$option} = 'CHECKED';
	}
	elsif (defined $main::R{$option}) { $main::checked{$option} = ''; }
}

# Set the checked options in the new form
$main::options_html = '';
foreach my $option (sort keys %main::traceroute_opts) {
	$main::options_html .= "\t" . '<INPUT TYPE="CHECKBOX" NAME="' . $option .
		'" ' .  $main::checked{$option} . ">&nbsp;$option\n";
}
if (length($main::options_html) > 0) {
	$main::options_html = '<BR>Options: '. $main::options_html ."<BR>\n";
}

# If we have no host, just show the form
unless (defined $main::host) {
	&show_form;
	print &html_footer();
	exit 0;
}

# Look up the IP number
use Socket;
my $ip = gethostbyname($main::host);
unless (defined $ip) { &abort("Can't find IP number for $main::host"); }
$ip = inet_ntoa($ip);

$| = 1; # no buffering please
&show_form;
print <<"EOD_HEADER";
<HR>
<B>Destination:</B> $main::host ($ip)
<PRE>
EOD_HEADER

# Build the command-line options, depending on the checked boxes
$main::traceroute_opts = '';
foreach my $option (keys %main::checked) {
	if ($main::checked{$option}) {
		$main::traceroute_opts .= ' '. $main::traceroute_opts{$option};
	}
}

my $cmd = $main::traceroute .' '. $main::traceroute_opts .' '. $main::host;
&debug("command is: '$cmd'") if ($main::debug);
$main::headers_sent = 1;

open (TRACEROUTE, "$cmd|") or &abort("Can't start traceroute: $!");

my ($owner, $line, $new, $number);
while (<TRACEROUTE>) {
	$line = $_;
	&debug("raw line: '$line'") if ($main::debug);

# Color the anomalies
	$line =~ s#\*#<SPAN STYLE="background-color:yellow">*</SPAN>#g;
	$line =~ s#!([HNPA]|\d+)#<SPAN STYLE="background-color:red">!$1</SPAN>#g;

# Hack a whois lookup in for the IP number
	if ($line =~ /\s\((\d+\.\d+\.\d+\.\d+)\)\s/i) {
		$ip = $1;
		$line =~ s/\s\($ip\)\s/ \(<A HREF="$main::whois?query=$ip">$ip<\/A>\) /
	}

# Hack in a whois lookup for the AS numbers
	if ($line =~ m#\s\[([AS0-9/]+)\]\s#i) {
		@temp = split('/', $1);
		undef $new;
		foreach (@temp) {
			($number = $_) =~ tr/AS//d;
			if (defined $new) { $new .= '/'; }
			else { $new = '['; }
			$new .= '<A HREF='. $main::whois .'?query='. $number .'>'. $_ .'</A>';
		}
		$new .= ']';
		$line =~ s#\s\[([AS0-9/]+)\]\s# $new #;
	}

# Hack a mailto url for the owner, because we can
	if ($line =~ /\s([-a-z0-9]+\@[-a-z0-9\.]+)\s/i) {
		$owner = $1;
		$line =~ s/$owner/<A HREF="mailto:$owner">$owner<\/A>/;
	}

	print $line or &abort("Can't write traceroute results: $!");
}
close (TRACEROUTE);
print <<"EOD_FOOTER";
</PRE>

<P>
Odd things you might see in the above display:
<UL>
<SPAN STYLE="background-color:yellow">*</SPAN> - 
	Lost a probe packet<BR>
<SPAN STYLE="background-color:red">!H</SPAN> - 
	Host not reachable, i.e. the last hop knows that there is no such host<BR>
<SPAN STYLE="background-color:red">!N</SPAN> - 
	Network not reachable, i.e. the last hop knows you can't get there<BR>
<SPAN STYLE="background-color:red">!P</SPAN> - 
	Protocol not available; never seen this, but you won't get past it<BR>
<SPAN STYLE="background-color:red">!A</SPAN> - 
	Administratively prohibited, i.e. the administrator won't let you<BR>
<SPAN STYLE="background-color:red">!M</SPAN> - 
	Need fragmentation, i.e. the router is seriously broken<BR>
<SPAN STYLE="background-color:red">!S</SPAN> - 
	Source-route failed, but then most vendors don't get it right and
	some people purposefully turn it off<BR>
</UL>
</P>

<HR>
<A HREF="$main::url?$main::host">Do that one again.</A>
EOD_FOOTER
print &html_footer();

0;

#--------------------------------------------------------------------- abort ---
sub abort {
	my $msg = join('', @_);
	unless ($main::headers_sent) {
		print "content-type: text/html\n\n";
	}
	print <<"EOD_ABORT";
<H1>$main::prog (version $main::version) Abort</H1>
$msg
</BODY>
</HTML>
EOD_ABORT
	exit 1;
}

#--------------------------------------------------------------------- error ---
sub error {
	my $msg = join('', @_);
	&abort( $msg);
}

#--------------------------------------------------------------------- debug ---
sub debug {
	my $msg = join('', @_);
	if ($main::debug) { print "<BR>DEBUG: $msg\n"; }
}

#--------------------------------------------------------------------- trap ---
# exit if we get any indications that the user went away
sub trap {
	my ($sig) = @_;
	die "died on signal $sig\n";
}

#--------------------------------------------------------------- show_form ---
sub show_form {
	print <<"EOD_FORM";
<FORM METHOD="POST" ACTION="$main::url">
Traceroute to: <INPUT NAME="host" SIZE=20 VALUE="$main::host"> <INPUT TYPE=SUBMIT VALUE="Do it">
$main::options_html
</FORM>
EOD_FORM
}

#---------------------------------------------------- keep_strict_happy ---
sub keep_strict_happy {
	$main::ip_cache_readonly = 0;
}
