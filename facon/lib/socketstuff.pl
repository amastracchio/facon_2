# socketstuff.pl - routines for allowing working timeouts to sockets
# 	on open and read.
# $Id: socketstuff.pl.in,v 1.11 2002/05/28 15:54:51 facon Exp $
# from facon 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

use strict;
use POSIX ':signal_h';

# - - -   Version History   - - -

# $Revision: 1.11 $

# - - -   Usage   - - -

# (optional)
# local $SIG{'ALRM'} = sub { $main::socketstuff_alarm=1; die "timeout\n"; };
# alarm($timeout);	# optional
#
# ($socket, $status, [$timeout]) = 
#	&open_socket( $host, $port [,$timeout] [,$ip]);
# ($line, $status, [$timeout]) = &read_socket( $socket, [$timeout]);
# ($status, [$timeout]) = &write_socket( $socket, $string, [$timeout]);
#
# alarm(0);	# optional
# $SIG{'ALRM'} = 'DEFAULT';	# optional
# $socket->close();
#
# $response = http_get( $host, $port, $headers, $url, $timeout);

# If the optional $timeout args are supplied, alarm() will be called before and
# after the enclosing eval around the I/O and the remaining time will be 
# returned.  This should permit easier and proper handling of the timeout.

# - - -   Setup   - - -

use IO::Socket;

# Status "constant" values
$main::SOCKET_OK = 1;
$main::SOCKET_TIMEOUT = 2;
$main::SOCKET_ERROR = 3;

# Get rid of those *^%$* warnings from IO::Socket
BEGIN {
	$main::SIG{'__WARN__'} = sub {warn @_ unless $main::suppress_warnings; }
}
$main::suppress_warnings = 0;

#-------------------------------------------------- open_socket ---
# Pass it a host and port to connect to.
# Returns an IO::Socket and a status (see above).
sub open_socket {
	my ($host, $port, $timeout, $ip) = @_;
	my ($socket, $status);
	die "open_socket: host must be defined\n" unless (defined $host);
	die "open_socket: port must be defined\n" unless (defined $port);
	$main::suppress_warnings = 1;
	$main::socketstuff_alarm = 0;

	if (defined $timeout and $timeout > 0) {
		eval {
			sigaction SIGALRM, new POSIX::SigAction sub {
				$main::socketstuff_alarm = 1; die "timeout\n";
			};
			alarm($timeout);
			$socket = IO::Socket::INET->new( 
					Proto => 'tcp', 
					PeerAddr => ((defined $ip) ? $ip : $host),
					PeerPort => $port);
			$timeout = alarm(0);
		};
	}
	else {
		eval {
			$socket = IO::Socket::INET->new( 
				Proto => 'tcp', 
				PeerAddr => ((defined $ip) ? $ip : $host),
				PeerPort => $port);
		};
	}

	if ($@ and $@ =~ /^timeout\n/) {
		&debug("open_socket: open timeout on $host:$port")
			if($main::debug>1);
		$status = $main::SOCKET_TIMEOUT;
	}
	elsif ($@ or ! defined $socket) {
		&debug("open_socket: open error on $host:$port: $@")
			if ($main::debug>1);
		$status = $main::SOCKET_ERROR;
	}
	else {
		$status = $main::SOCKET_OK;
		$socket->autoflush(1);
	}
	$main::suppress_warnings = 0;
	return ($socket, $status, $timeout);
}

#---------------------------------------------------- read_socket ---
# Pass it an IO::Socket, probably obtained from open_socket.
# Returns a newline-terminated line and a status.
sub read_socket {
	my ($socket, $timeout, $what) = @_;
	my ($line, $status);
	
	&debug("read_socket: starting read") if ($main::debug>2);

# Local timeout handled here
	$main::suppress_warnings = 1;
	if (defined $timeout and $timeout > 0) {
		sigaction SIGALRM, new POSIX::SigAction sub {
			$main::socketstuff_alarm = 1; die "timeout\n";
		};
		eval {
			alarm($timeout);
			$line = <$socket>;
			$timeout = alarm(0);
		};
	}

# Timeout handled outside
	else { eval { $line = <$socket> }; }

	if ($@ and $@ =~ /^timeout\n/) {
		&debug("read_socket: read timeout" . 
			((defined $what) ? " for $what" : '')) 
			if ($main::debug>1);
		$status = $main::SOCKET_TIMEOUT;
	}
	elsif ($@) { 
		$! = $@;
		&debug("read_socket: read error" . 
			((defined $what) ? " for $what" : ''))
			if ($main::debug>1);
		$status = $main::SOCKET_ERROR;
	}
	else { $status = $main::SOCKET_OK; }
	$main::suppress_warnings = 0;
	&debug("read_socket: read done") if ($main::debug>2);

	return ($line, $status, $timeout);
}

#--------------------------------------------------- write_socket ---
sub write_socket {
	my ($socket, $string, $timeout, $what) = @_;
	my $status;

# Locally handled timeout
	$main::suppress_warnings = 1;
	if (defined $timeout and $timeout > 0) {
		eval {
			sigaction SIGALRM, new POSIX::SigAction sub {
				$main::socketstuff_alarm = 1; die "timeout\n";
			};
			alarm($timeout);
			$socket->print($string);
			$timeout = alarm(0);
		};
	}

# Timeout handled outside, and incompletely;
	else {
		eval {
			$socket->print($string);
		};
	}

	if ($@ and $@ eq "timeout\n") {
		&debug("write_socket: write timeout ". 
			((defined $what) ? " for $what" : '') 
			."writing '$string'") if ($main::debug>1);
		$status = $main::SOCKET_TIMEOUT;
	}
	elsif ($@) {
		&debug("write_socket: write error ". 
			((defined $what) ? " for $what" : '') 
			."writing '$string'") if ($main::debug>1);
		$status = $main::SOCKET_ERROR; 
		$! = $@; 
	}
	else { $status = $main::SOCKET_OK; }
	$main::suppress_warnings = 0;

	return ($status, $timeout);
}

#----------------------------------------------------------- port_send_get ---
# Returns ($response_string, $status, $timeout_left, $response_time)
sub port_send_get {
	my( $host, $port, $send, $timeout, $ip) = @_;
	my( $socket, $status, $line, $response, $start_time);
	unless(defined $ip) { $ip = &get_ip( $host); }
	&debug("connecting to $host:$port...") if( $main::debug);

	# Connect
	$start_time = time();
	($socket, $status, $timeout) = &open_socket( $host, $port, $timeout, $ip);
	unless( $status == $main::SOCKET_OK) {
		&error('cannot connect to ', $host, ':', $port);
		return( undef, $status, $timeout, time() - $start_time);
	}

	# Send them our string
	($status, $timeout) = &write_socket( $socket, $send, $timeout);
	unless( $status == $main::SOCKET_OK) {
		$socket->close();
		&error('cannot write to ', $host, ':', $port);
		return (undef, $status, $timeout, time() - $start_time);
	}
	
	# Get their string
	while(($line, $status, $timeout) = &read_socket( $socket, $timeout),
			(defined $line && ($status == $main::SOCKET_OK))) {
		&debug('RAW: ', $line) if( $main::debug>2);
		if( defined $response) { $response .= $line; }
		else { $response = $line; }
	}

	# All done.  Return what we got.
	$socket->close();
	return( $response, $status, $timeout, time() - $start_time);
}

#--------------------------------------------------------------------- END ---
# Tell perl it's OK
1;
