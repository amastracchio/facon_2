# alertstuff.pl - routines specific to alerts
# $Id: alertstuff.pl.in,v 1.10 2002/05/28 15:46:50 facon Exp $
# from facon 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# $Revision: 1.10 $

use strict;

# functions:
#   %alerts = &read_alerts;
#   &write_alerts( %alerts);
#   ($status, $value) = &get_alert_status( $host, $realrrd, $dsname);
#	&set_alert_status( $host, $realrrd, $dsname, $status, $value);

# Need this for locking
use Fcntl ':flock'; # import LOCK_* constants

# Define the current alert_version (format of alert file)
$main::alert_version = 2;

#----------------------------------------------------------- read_alerts ---
sub read_alerts {
	my $file = "$main::config{DATADIR}/ALERTS";

	my ($host, $realrrd, $var, $status, $old_status, $value, $start, 
		$lastalert, $lastchange, $quench, $comment, $errors, 
		$alert_version, $open_how, $lastsent);
	unless (-f $file) {
		&error("missing alerts ($file); assumed empty");
		&logit( 'ALERTS', undef, undef, undef, undef, 
			'missing ALERTS file created');
		return ();
	}
	my %alerts = ();

	if( $main::alerts_readonly) { $open_how = ''; }
	else { $open_how = '+'; }
	open (ALERTS, "${open_how}<$file") or &abort("can't open $file: $!");
	flock ALERTS, LOCK_SH or &abort("can't get lock on ALERTS: $!");

# Check version number
	$alert_version = <ALERTS>;
	if ($alert_version =~ /^VERSION (\d+)/) { $alert_version = ${1} + 0; }
	else {
		$alert_version = 0;
		seek (ALERTS, 0, 0) or &abort("can't seek alerts file");
	}

	while (<ALERTS>) {
		chomp;
		next if (/^#/ or /^\s*$/);

		if ($alert_version == 0) {
			($host, $realrrd, $var, $status, $value, $start, $lastalert,
				$lastchange, $quench, $comment) = split(' ',$_,10);
			$old_status = '';
			$lastsent = '';
		}
		elsif ($alert_version == 1) {
			($host, $realrrd, $var, $status, $old_status, $value, $start, 
				$lastalert, $lastchange, $quench, $comment) = 
				split(' ',$_,11);
			$lastsent = '';
		}
		elsif ($alert_version == 2) {
			($host, $realrrd, $var, $status, $old_status, $value, $start, 
				$lastalert, $lastchange, $quench, $lastsent, $comment) = 
				split(' ',$_,12);
		}
		else { &abort("unknown alert_version ($alert_version)"); }
		
		# Make sure that we haven't got garbage here
		$errors = 0;
		if ( !defined $host) {
			&debug("read_alerts: undefined host in alerts")
				if ($main::debug>1);
			$errors++;
		}
		if( !defined $realrrd) {
			&debug("read_alerts: undefined realrrd in alerts")
				if ($main::debug>1);
			$errors++;
		}
		if( !defined $var) {
			&debug("read_alerts: undefined var in alerts")
				if ($main::debug>1);
			$errors++;
		}
		if( !defined $status) {
			&debug("read_alerts: undefined status in alerts")
				if ($main::debug>1);
			$errors++;
		}
		if( !defined $old_status) {
			&debug("read_alerts: undefined old_status in alerts")
				if ($main::debug>1);
			$errors++;
		}
		if( !defined $value) {
			&debug("read_alerts: undefined value in alerts")
				if ($main::debug>1);
			$errors++;
		}
		if( !defined $start) {
			&debug("read_alerts: undefined start in alerts")
				if ($main::debug>1);
			$errors++;
			next;
		}
		if( !defined $lastalert) {
			&debug("read_alerts: undefined lastalert in alerts")
				if ($main::debug>1);
			$errors++;
			next;
		}
		if( !defined $lastchange) {
			&debug("read_alerts: undefined lastchange in alerts")
				if ($main::debug>1);
			$errors++;
			next;
		}
		if( !defined $quench) {
			&debug("read_alerts: undefined quench in alerts")
				if ($main::debug>1);
			$errors++;
			next;
		}
		if( !defined $lastsent) {
			&debug("read_alerts: undefined $lastsent in alerts")
				if( $main::debug>1);
			++$errors;
			next;
		}

		# Don't look at it any more if there are errors in it.
		if ($errors) {
			&debug("read_alerts: errors in alerts file '$_'; record skipped")
				if ($main::debug);
			next;
		}

		# Make sure that we don't keep old alert info
		next unless( defined $main::config{HOST}{$host});
		next unless( defined $main::config{HOST}{$host}{RRD}{$realrrd});

		# Make sure that we've got the status as a string, not a number.
		# It's wrong, but everything else expects it.  For now.
		if( $status =~ /^\d+$/) { $status = $main::statuses{$status}; }
		if( $old_status =~ /^\d+$/) {
			$old_status = $main::statuses{$old_status};
		}
		if( $lastsent eq '') { $lastsent = 0; }

		# Good enough.  Transfer to the alerts hash.
		$alerts{$host}{$realrrd}{$var}{STATUS} = $status;
		$alerts{$host}{$realrrd}{$var}{OLDSTATUS} = $old_status;
		$alerts{$host}{$realrrd}{$var}{VALUE} = $value;
		$alerts{$host}{$realrrd}{$var}{START} = $start;
		$alerts{$host}{$realrrd}{$var}{LASTALERT} = $lastalert;
		$alerts{$host}{$realrrd}{$var}{LASTCHANGE} = $lastchange;
		$alerts{$host}{$realrrd}{$var}{QUENCH} = $quench;
		$alerts{$host}{$realrrd}{$var}{LASTSENT} = $lastsent;
		$alerts{$host}{$realrrd}{$var}{COMMENT} = $comment;
	}
	flock ALERTS, LOCK_UN or &abort("can't unlock ALERTS: $!");
	close (ALERTS);
	return %alerts;
}

#--------------------------------------------------------- write_alerts ---
sub write_alerts {
	return if( $main::alerts_readonly);
	my (%alerts) = @_;
	my $file = "$main::config{DATADIR}/ALERTS";
	my ($host, $realrrd, $wildrrd, $var);

# Untaint $file
	if ($file =~ /^(.*)$/) { $file = $1; }

# Open, lock and version-stamp the new ALERTS file
	open (ALERTS, ">$file.new") or &abort("can't open $file.new: $!");
	flock ALERTS, LOCK_EX or &abort("can't lock ALERTS: $!");
	print ALERTS "VERSION $main::alert_version\n";

#	print STDERR Dumper(\%alerts) if ($main::debug>2);
	my $now = time;
	foreach $host (sort keys %alerts) {
		foreach $realrrd (@{$main::config{HOST}{$host}{RRDS}}) {
			($wildrrd) = &get_rrd($realrrd);
			foreach $var ( @{$main::config{RRD}{$wildrrd}{DATANAMES}}) {

# Make sure we've got values for all the fields, even if we have to fake it
				unless (defined $alerts{$host}{$realrrd}{$var}{VALUE}) {
					$alerts{$host}{$realrrd}{$var}{VALUE} = 0;
				}
				unless (defined $alerts{$host}{$realrrd}{$var}{STATUS}) {
					$alerts{$host}{$realrrd}{$var}{STATUS} = 'OK';
				}
				unless (defined $alerts{$host}{$realrrd}{$var}{OLDSTATUS}) {
					$alerts{$host}{$realrrd}{$var}{OLDSTATUS} = 'OK';
				}
				unless (defined $alerts{$host}{$realrrd}{$var}{START}) {
					$alerts{$host}{$realrrd}{$var}{START} = 'NONE';
				}
				unless (defined $alerts{$host}{$realrrd}{$var}{QUENCH}) {
					$alerts{$host}{$realrrd}{$var}{QUENCH} = 0;
				}
				unless (defined $alerts{$host}{$realrrd}{$var}{COMMENT}) {
					$alerts{$host}{$realrrd}{$var}{COMMENT} = '';
				}
				unless (defined $alerts{$host}{$realrrd}{$var}{LASTALERT}) {
					$alerts{$host}{$realrrd}{$var}{LASTALERT} = 'NONE';
				}
				unless (defined $alerts{$host}{$realrrd}{$var}{LASTCHANGE}) {
					$alerts{$host}{$realrrd}{$var}{LASTCHANGE} = 'NONE';
				}
				unless (defined $alerts{$host}{$realrrd}{$var}{LASTSENT}) {
					$alerts{$host}{$realrrd}{$var}{LASTSENT} = 'NONE';
				}

				if (defined $alerts{$host}{$realrrd}{$var}{STATUS}) {
					&debug("wrote alertdata for $host $realrrd $var") 
						if ($main::debug>2);
					print ALERTS "$host $realrrd $var " .
						$alerts{$host}{$realrrd}{$var}{STATUS} .' '.
						$alerts{$host}{$realrrd}{$var}{OLDSTATUS} .' '.
						$alerts{$host}{$realrrd}{$var}{VALUE} .' '.
						$alerts{$host}{$realrrd}{$var}{START} .' '.
						$alerts{$host}{$realrrd}{$var}{LASTALERT} .' '.
						$alerts{$host}{$realrrd}{$var}{LASTCHANGE} .' '.
						$alerts{$host}{$realrrd}{$var}{QUENCH} .' '.
						$alerts{$host}{$realrrd}{$var}{LASTSENT} .' '.
						$alerts{$host}{$realrrd}{$var}{COMMENT} ."\n";
				}
				else {
					&debug("no alert for $host $realrrd $var") 
						if ($main::debug>2);
				}
			}
		}
	}

	flock ALERTS, LOCK_UN or &abort("can't unlock ALERTS: $!");
	close(ALERTS);
	rename "$file.new", $file or &error("can't rename $file.new to $file: $!");
}

#-------------------------------------------------------- get_alert_status ---
sub get_alert_status {
	my( $host, $realrrd, $dsname) = @_;
	
	unless( defined %main::alerts_cache) {
		%main::alerts_cache = &read_alerts();
	}

	my $status = $main::alerts_cache{$host}{$realrrd}{$dsname}{STATUS};
	my $value = $main::alerts_cache{$host}{$realrrd}{$dsname}{VALUE};
	$status = 'UNDEFINED' unless( defined $status);
	$value = 'UNDEFINED' unless( defined $value);
	if (defined $main::config{(uc $status) . 'STATUS'}) {
		$status = $main::config{(uc $status) . 'STATUS'};
	}
	else { $status = 'UNKNOWN=' . $status; }
	
	return ($status, $value);
}

#-------------------------------------------------------- set_alert_status ---
sub set_alert_status {
	my( $host, $realrrd, $var, $new_status, $new_value) = @_;
	my( $now, $old_status);
	$now = time();

	# What was the previous status?
	if( defined $main::alerts{$host}{$realrrd}{$var}{STATUS}) {
		$old_status = $main::alerts{$host}{$realrrd}{$var}{STATUS};
	}
	else { $old_status = 'OK'; }

	# Has the status changed?
	if( $old_status ne $new_status) {
		$main::alerts{$host}{$realrrd}{$var}{OLDSTATUS} = $old_status;
		$main::alerts{$host}{$realrrd}{$var}{STATUS} = $new_status;
		$main::alerts{$host}{$realrrd}{$var}{START} = $now;
		$main::alerts{$host}{$realrrd}{$var}{LASTCHANGE} = $now;
		if( $new_status ne 'OK') {
			$main::alerts{$host}{$realrrd}{$var}{LASTALERT} = $now;
		}
	}

	# Always update the value
	$main::alerts{$host}{$realrrd}{$var}{VALUE} = $new_value;

	# Doesn't set LASTSENT on purpose

}

#---------------------------------------------------------------------- EOD ---
# say loading went OK
1;
