#!/usr/bin/perl -Tw

# ping.cgi - let people ping the monitored hosts
# $Id: ping.cgi.in,v 1.13 2002/06/27 18:02:02 remstats Exp $
# from remstats 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Configuration   - - -

# What is this program called, for file-names and error-messages.
$main::prog = 'ping.cgi';
# Where is the configuration
$main::config_dir = '/home/ed857416/3p/remstats/etc/config';
# How to invoke ping
$main::ping = '/home/ed857416/3p/remstats/bin/multiping -i 1 -s 80 -c 5 %s';
# So -T will stop whinging.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin';

# Debugging anyone?
$main::debug = 0;

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.13 $'))[1];

# - - -   Setup   - - -

$| = 1; # no buffering please

use lib '.', '/home/ed857416/3p/remstats/lib';
require "remstats.pl";
require "accessstuff.pl";
require "cgistuff.pl";
require "htmlstuff.pl";

# Don't try to update IP_CACHE; don't have access from cgi
$main::ip_cache_readonly = 1;

&read_config_dir( $main::config_dir, 'general', 'links', 'colors', 'html');

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

# - - -   Main Line   - - -

my %indices = &init_indices();
my $title = $main::prog . '(version ' . $main::version . ')';
print &html_header( $title, $title,  %indices);

my $host;
if (defined $main::R{'host'} and $main::R{'host'} =~ /^([-0-9a-zA-Z.]+)$/) {
	$host = $1;
}
elsif (defined $main::R{'host'}) {
	&abort("bad or empty host field: $main::R{'host'}");
}
else {
	print <<"EOD_FORM";
<FORM METHOD="POST" ACTION="$main::url">
Ping host: <INPUT NAME="host" SIZE=20> <INPUT TYPE="SUBMIT" VALUE="Do it">
<A CLASS="BUT" HREF="$main::url?host=$host">Do it again</A>
</FORM>
</BODY>
</HTML>
EOD_FORM
	print &html_footer();
	exit 0;
}

$main::ping = sprintf($main::ping, $host);

print <<"EOD_HEADER";
<FORM METHOD="POST" ACTION="$main::url">
Ping Host: <INPUT NAME="host" SIZE=20 VALUE="$host"> <INPUT TYPE="SUBMIT" VALUE="Do it">
<A CLASS="BUT" HREF="$main::url?host=$host">Do it again</A>
</FORM>
<HR>
<PRE>
EOD_HEADER
	open (PIPE, "$main::ping|") or &abort("Can't start ping: $!");
	while (<PIPE>) {
		print $_;
	}
	close (PIPE);
	print <<"EOD_FOOTER";
</PRE>
EOD_FOOTER

print &html_footer();

0;

#-------------------------------------------------------------------- abort ---
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

#---------------------------------------------------- keep_strict_happy ---
sub keep_strict_happy {
	$main::ip_cache_readonly = 0;
}
