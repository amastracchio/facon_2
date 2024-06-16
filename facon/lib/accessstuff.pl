# accessstuff.pl -- access-control routines
# $Id: accessstuff.pl.in,v 1.3 2003/03/13 14:28:38 facon Exp $
# from facon 1.0.13a

# Copyright 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

use strict;

# $Revision: 1.3 $

#------------------------------------------------------------ routine list ---
# exit 6 unless( &access_control( $main::prog));
#---------------------------------------------------------- access_control ---
# See if the current user from the current location is allowed to run this
# program.
#-----------------------------------------------------------------------------
sub access_control {
	my $program = shift @_;
	unless( defined $program) { $program = $main::prog; }
	unless( defined $program) { $program = $0; }
	my( $user, $ip, $file, $line, $access, $match_program, $match_user,
		$match_group, $match_ip_host, %groups, @lines);

	# Some checking
	unless( defined $program) {
		&abort("INTERNAL: access_control not passed program name.");
	}

	# Get a user from somewhere
	if( defined $ENV{'REMOTE_USER'} and
			$ENV{'REMOTE_USER'} =~ /^([-a-z0-9_]+)$/) {
		$user = $1;
		&debug("got user from REMOTE_USER ($user)") if( $main::debug>1);
	}
	else { $user = 'UNKNOWN'; }

	# Get an IP number
	if( defined $ENV{'REMOTE_ADDR'} and
			$ENV{'REMOTE_ADDR'} =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/) {
		$ip = $1;
		&debug("got IP number from REMOTE_ADDR ($ip)") if( $main::debug>1);
	}
	else { $ip = 'UNKNOWN'; }

	# Read the groups later, if any access-control line specifies a group

	# Read the access-control file
	@lines = &read_config_access( $main::config_dir);

	# Check each line, in order
	foreach $line (@lines) {
		&debug("RAW: $line") if( $main::debug>1);
		($access, $match_program, $match_user, $match_group, $match_ip_host) =
			split(' ', $line);
		
		# Does this program patch?
		if( $match_program eq '*') {
			&debug("  program wildcard matched")
				if( $main::debug>1);
		}
		elsif( $program eq $match_program) {
			&debug("  program $program matched $match_program")
				if( $main::debug>1);
		}
		else {
			&debug("  program does not match ($program != $match_program)")
				if( $main::debug>1);
			next;
		}

		# Does this user match?
		if( $match_user eq '*') {
			&debug("  user wildcard matched")
				if( $main::debug>1);
		}
		elsif( $user eq $match_user) {
			&debug("  user $user matched $match_user")
				if( $main::debug>1);
		}
		else {
			&debug("  user does not match ($user != $match_user)")
				if( $main::debug>1);
			next;
		}

		# Does this group match?
		if( $match_group eq '*') {
			&debug("  group wildcard matched")
				if( $main::debug>1);
		}
		else {
			unless( %groups) {
				%groups = &read_config_htgroup();
			}
			if( defined $groups{$match_group}{$user}) {
				&debug("  user $user matched in group $match_group")
					if( $main::debug>1);
			}
			else {
				&debug("  user $user not in group $match_group)")
					if( $main::debug>1);
				next;
			}
		}

		# Does the ip/host match
		if( $match_ip_host eq '*') {
			&debug("  host wildcard matched")
				if( $main::debug>1);
		}
		elsif( &access_match_ip_host( $ip, $match_ip_host)) {
			&debug("  host $ip matched $match_ip_host")
				if( $main::debug>1);
		}
		else {
			&debug("  host does not match ($ip != $match_ip_host)")
				if( $main::debug>1);
			next;
		}

		# Everything matched, return the specified access
		&debug("access_control returned '$access' from: $line")
			if( $main::debug);
		return ($access eq 'allow') ? 1 : 0;

	}

	# Unless they put in an explicit allow everything else at the end,
	# we'll forbid access.
	return 0;
}

#----------------------------------------------------- read_config_htgroup ---
# Read the htgroup file into a hash to make lookups easy.
#-----------------------------------------------------------------------------
sub read_config_htgroup {
	my( $file, $line, $group, $users, @users, $user, %groups);
	%groups = ();

	$file = $main::config_dir . '/htgroup';
	unless( -f $file) { return %groups; }

	open( HTGROUP, "<$file") or &abort("can't open $file: $!");
	&debug("reading $file...") if( $main::debug);
	while( defined ( $line = <HTGROUP>)) {
		chomp $line;
		($group, $users) = split(':', $line);
		@users = split(',', $users);
		foreach $user (@users) { $groups{$group}{$user} = 1; }
	}
	close( HTGROUP);

	return %groups;
}

#---------------------------------------------------- access_match_ip_host ---
sub access_match_ip_host {
	my( $ip, $match_ip_host) = @_;
	my( $host);

	# Match a full IP number
	if( $match_ip_host =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ and
			$ip eq $match_ip_host) {
		&debug("  ip matched full $ip") if( $main::debug>1);
		return 1;
	}

	# Match an IP prefix
	elsif( $match_ip_host =~ /\.$/ and
			substr( $ip, 0, length($match_ip_host)) eq $match_ip_host) {
		&debug("  ip matched prefix $match_ip_host") if( $main::debug>1);
		return 1;
	}

	# Match domain-names
	else {
		$host = lc( &get_host( $ip));
		unless( defined $host) {
			&debug("can't resolve $ip but I need to; say no match")
				if( $main::debug>1);
			return 0;
		}

		if( $match_ip_host =~ /^\./ and
				substr($host, length($host) - length($match_ip_host)) eq
				lc( $match_ip_host)) {
			&debug("  domain suffix matched $match_ip_host")
				if( $main::debug>1);
			return 1;
		}
		elsif( lc( $match_ip_host) eq $host) {
			&debug("  domain matched $match_ip_host") if( $main::debug>1);
			return 1;
		}
		else {
			&debug("  no match $match_ip_host <=> $ip($host)")
				if( $main::debug>1);
			return 0;
		}
	}
}

#------------------------------------------------------ read_config_access ---
# This routine is unlike all the other read_config_? routines.  It simply
# returns a list of the non-comment lines without parsing or inserting
# them into the %main::config structure.  It only exists because other
# places might need to read the file, without knowing where it is.
#-----------------------------------------------------------------------------
sub read_config_access {
	my( $config_dir) = @_;
	my( $file, $line, @lines);

	$file = $main::config_dir . '/access';
	open( ACCESS, "<$file") or
		&abort("can't open access-control file $file: $!");

	while(defined( $line = <ACCESS>)) {
		chomp $line;
		next if( $line =~ /^#/ or $line =~ /^\s*$/); # no comments
		push @lines, $line;
	}
	close(ACCESS);
	return @lines;
}

# All done.  Say Goodnight Dick.
1;
