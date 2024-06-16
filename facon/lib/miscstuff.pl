# miscstuff.pl - miscellaneous utility functions
# $Id: miscstuff.pl.in,v 1.2 2002/05/28 15:52:19 facon Exp $
# from facon 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# $Revision: 1.2 $

use strict;

#-------------------------------------------------- supplied routines ---
# $text = &cisco_modem_protocol( $protocol);
# $text = &cisco_modem_modulation( $modulation);
# $text = &cisco_modem_speed( $speed);
# $text = &sub cisco_modem_state( $state);
# $text = &in_group( $value, @upper_limits);
# $text = &apcups_battery_replace_indicator( $code);
# $text = &apcups_battery_status( $code);
# $text = &log10( $value);
# $text = &bgp_error_to_string( $two_byte_code);
# $text = &apc_ups_status( $code);
# $km =  &m_or_km_to_km( $m_or_km);

#----------------------------------------------------- cisco_modem_protocol ---
sub cisco_modem_protocol {
	my ($protocol) = @_;
	my @protocols = ('ILLEGAL', 'normal', 'direct', 'reliableMNP',
		'reliableLAPM', 'syncMode', 'asyncMode', 'ara10', 'ara20', 'unknown');
	my $returned;
	
	if ($protocol > $#protocols) { $returned = $protocol; }
	else { $returned = $protocols[$protocol]; }

	return $returned;
}

#--------------------------------------------------- cisco_modem_modulation ---
sub cisco_modem_modulation {
	my ($modulation) = @_;
	my @modulations = ('ILLEGAL', 'unknown', 'bell103a', 'bell212a', 'v21',
		'v22', 'v22bis', 'v32', 'v32bis', 'vfc', 'v34', 'v17', 'v29', 'v33',
		'k56flex', 'v23', 'v32terbo', 'v34plus', 'v90', 'v27ter');
	my $returned;
	
	if ($modulation > $#modulations) { $returned = $modulation; }
	else { $returned = $modulations[$modulation]; }
	
	return $returned;
}

#--------------------------------------------------- cisco_modem_speed ---
sub cisco_modem_speed {
	my ($speed) = @_;

	if ($speed > 1000) {
		$speed = int($speed / 100)/10;
		$speed =~ s/\.?0+$//;
		$speed .= 'K';
	}
	return $speed;
}

#---------------------------------------------------- cisco_modem_state ---
sub cisco_modem_state {
	my ($state) = @_;
	my @states = ('ILLEGAL', 'unknown', 'onHook', 'offHook', 'connected',
		'busiedOut', 'disabled',
		'<span style="background-color: red">bad</span',
		'loopback', 'downloadFirmware',
		'<span background-color: red">downloadFirmwareFailed</span');
	my $returned;
	
	if ($state > $#states) { $returned = $state; }
	else { $returned = $states[$state]; }
	return $returned;
}

#---------------------------------------------------------------- in_group ---
# Given a value and an array of upper limits for membership in groups (sorted in
# ascending order), it will return the group number (zero origin).
sub in_group {
	my ($value, @upper_limits) = @_;
	my ($group, $i);

	$group = $#upper_limits + 1;
	for ($i=0; $i <= $#upper_limits; ++$i) {
		if ($value <= $upper_limits[$i]) {
			$group = $i;
			last;
		}
	}
	return $group;
}

#---------------------------------------- apcups_battery_replace_indicator ---
sub apcups_battery_replace_indicator {
	my $status = shift @_;
	$status = ('BADSTATUS', 'no', '<FONT COLOR="RED">YES</FONT>')[$status];
	&debug("apcups_battery_replace_indicator: returning '$status'")
		if ($main::debug);
	return $status;
}

#--------------------------------------------------- apcups_battery_status ---
sub apcups_battery_status {
	my $status = shift @_;
	$status = ('BADSTATUS', 'UNKNOWN', 'normal',
		'<FONT COLOR="RED">LOW</FONT>')[$status];
	&debug("apcups_battery_status: returning '$status'") if ($main::debug);
	return $status;
}

#------------------------------------------------ log10 ---
sub log10 {
	my $n = shift @_;
	return log($n)/log(10);
}


#--------------------------------------- bgp_error_to_string ---
sub bgp_error_to_string {
	my ($octets) = @_;
	my ($code, $subcode) = unpack('C C', $octets);
	my $string;
	&debug("bgp_to_string: octets='$octets'") if ($main::debug>1);

	# Message header error
	if ($code == 0) {
		$string = '';
	}
	elsif ($code == 1) {
		if ($subcode == 1) {
			$string = 'Connection Not Synchronized';
		}
		elsif ($subcode == 2) {
			$string = 'Bad Message Length';
		}
		elsif ($subcode == 3) {
			$string = 'Bad Message Type';
		}
		else {
			$string = 'unknown header error: '. $subcode;
		}
	}
	elsif ($code == 2) {
		if ($subcode == 1) {
			$string = 'unsupported version number';
		}
		elsif ($subcode == 2) {
			$string = 'bad peer AS';
		}
		elsif ($subcode == 3) {
			$string = 'bad BGP identifier';
		}
		elsif ($subcode == 4) {
			$string = 'unsupported optional parameter';
		}
		elsif ($subcode == 5) {
			$string = 'authentication failure';
		}
		elsif ($subcode == 6) {
			$string = 'unacceptable hold time';
		}
		else {
			$string = 'unknown OPEN error: '. $subcode;
		}
	}
	elsif ($code == 3) {
		if ($subcode == 1) {
			$string = 'malformed attribute list';
		}
		elsif ($subcode == 2) {
			$string = 'unrecognized well-known attribute';
		}
		elsif ($subcode == 3) {
			$string = 'missing well-known attribute';
		}
		elsif ($subcode == 4) {
			$string = 'attribute flags error';
		}
		elsif ($subcode == 5) {
			$string = 'attribute length error';
		}
		elsif ($subcode == 6) {
			$string = 'invalid origin attribute';
		}
		elsif ($subcode == 7) {
			$string = 'AS routing loop';
		}
		elsif ($subcode == 8) {
			$string = 'invalid NEXT_HOP attribute';
		}
		elsif ($subcode == 9) {
			$string = 'optional attribute error';
		}
		elsif ($subcode == 10) {
			$string = 'invalid network field';
		}
		elsif ($subcode == 11) {
			$string = 'malformed AS_PATH';
		}
		else {
			$string = 'unknown UPDATE error: '. $subcode;
		}
	}
	elsif ($code == 4) {
		$string = 'Hold Timer Expired';
	}
	elsif ($code == 5) {
		$string = 'Finite State Machine Error';
	}
	elsif ($code == 6) {
		$string = 'Cease';
	}
	else {
		$string = "unknown BGP error: $code $subcode";
	}
	return $string;
}

#---------------------------------------------------------- apc_ups_status ---
sub apc_ups_status {
	my ($status) = @_;
	
	if ($status == 1) { $status = 'unknown'; }
	elsif ($status == 2) { $status = 'Normal'; }
	elsif ($status == 3) {
		$status = '<span style="background-color: red">Low</span>';
	}
	else { $status = 'invalid('. $status .')'; }
	return $status;
}

#----------------------------------------------------------- m_or_km_to_km ---
sub m_or_km_to_km {
	my ($string) = @_;
	my ($number, $units, $km);

	if ($string =~ /^(\d+\.?|\.\d+|\d+\.\d+)\s*(m|km)/i) {
		$number = $1;
		$units = lc $2;
		if ($units eq 'km') { $km = $number; }
		elsif ($units eq 'm') { $km = $number / 1000; }
		else {
			&error("m_or_km_to_km: bad string '$string'; returning undef");
		}
	}
	else {
		$km = $string + 0;
	}
	return $km;
}
#-------------------------------------------------------------- Good-night ---
1;
