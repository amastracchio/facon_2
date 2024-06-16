# cgistuff.pl - some simple routines for CGI scripts, so I don't need all
#	the heavy-weight CGI modules just to parse fields.
# $Id: cgistuff.pl.in,v 1.7 2002/05/28 15:54:50 facon Exp $
# from facon 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Version History   - - -

# $Revision: 1.7 $

# Routines provided:
#	%request = &cgi_request;
#	$value = &cgi_var($name);
#	@names = &cgi_vars;
#	&cgi_sendheaders(@headers);
#	print &cgi_fmtrequest(%request);

use strict;

#----------------------------------------------------------- Initialization ---
# We've got to be unbuffered
$|=1;

#------------------------------------------------------------- cgi_request ---
# Get the CGI fields from stdin
sub cgi_request {
	my ($buffer, @pairs, $pair, $name, $value, %request);

# Get the input
	if (defined $ENV{'CONTENT_LENGTH'}) {
		&debug("reading content from stdin") if ($main::debug);
		read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
	}
	elsif (-t STDIN) {
		&debug("reading content from terminal") if ($main::debug);
		print STDERR "-- reading STDIN from terminal --\n";
		while (<STDIN>) {
			chomp;
			next if (/^\s*$/);
			if (defined $buffer) { $buffer .= '&' . $_; }
			else { $buffer = $_; }
		}
		$ENV{'SERVER_NAME'} = 'localhost';
		$ENV{'SERVER_PORT'} = '80';
		$ENV{'SCRIPT_NAME'} = (defined $main::prog) ? $main::prog : $0;
		if ($ENV{'SCRIPT_NAME'} !~ m#^/#) {
			$ENV{'SCRIPT_NAME'} = '/'. $ENV{'SCRIPT_NAME'};
		}
		$ENV{'REMOTE_ADDR'} = '127.0.0.1';
	}
	elsif (defined $ENV{'QUERY_STRING'} and $ENV{'QUERY_STRING'} =~ /^(.*)$/) {
		&debug("reading content from \$QUERY_STRING") if ($main::debug);
		$buffer = $1;
		$buffer =~ tr/ -~//cd; # no unprintable junk
	}
	else {
		&error("neither CONTENT_LENGTH nor QUERY_STRING defined and not a tty");
		return ();
	}

# Split the name-value pairs
	if (defined $buffer) {
		@pairs = split('&', $buffer);
		&debug("buffer is '$buffer'") if ($main::debug);
	}
	else { @pairs = (); }

	%request = ();
	foreach $pair (@pairs) {
		next if ($pair =~ /^\s*\r?\n?$/);
		($name, $value) = split('=', $pair);
		&debug("name='$name', value='$value'") if ($main::debug);

# Un-Webify plus signs and %-encoding
		if (-t STDIN and ! defined $value) {
			if (defined $ENV{'QUERY_STRING'}) {
				$ENV{'QUERY_STRING'} .= $pair;
			}
			else {
				$ENV{'QUERY_STRING'} = $pair;
			}
		}
		elsif ( -t STDIN and defined $name and defined $value) {
			$request{$name} = $value;
		}
		elsif ( ! -t STDIN and defined $name and defined $value) {
			$value =~ tr/\053/ /; # a plus
			$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

			&debug("Setting form variable '$name' to '$value'<P>")
				if ($main::debug);

			$request{$name} = $value;
		}
		else {
			&debug( "non-pair value ignored: '$pair'") 
				if( $main::debug);
		}
	}
%request;
}

#-----------------------------------------------------------cgi_fmtrequest ---
sub cgi_fmtrequest {
	my %request = @_;
	my $result = "<h1>Form Fields</h1>\n<p>\n";
	foreach my $key (sort keys %request) {
		$result .= "<BR>$key = '$request{$key}'\n";
	}
	$result .= "</P>\n<h1>CGI Variables</h1>\n<p>\n";
	foreach my $key (sort keys %ENV) {
		$result .= "<BR>$key = '$ENV{$key}'\n";
	}
	$result .= "</p>\n";
$result;
}

#----------------------------------------------------------------- cgi_var ---
sub cgi_var {
	my ($name) = @_;
	my $var = $ENV{$name};
$var;
}

#------------------------------------------------------------------ cgi_vars ---
sub cgi_vars {
	keys %ENV;
}

#----------------------------------------------------------- cgi_sendheaders ---
sub cgi_sendheaders {
	my @headers = @_;
	my $header;
	my $content_found = 0;

	foreach $header (@headers) {
		chomp $header;
		print $header . "\n";
		if ($header =~ /^content-type:/i) { $content_found = 1; }
	}
	if ($content_found) { print "\n"; }
	else { print "Content-type: text/html\n\n"; }
1;
}

#---------------------------------------------------------- url_decode ---
sub url_decode {
	my $value = shift @_;

	$value =~ tr/\053/ /; # a plus
	$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	return $value;
}

#--------------------------------------------------------------- END ---
# Say it loaded OK
1;
