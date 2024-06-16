# snmpstuff.pl - some snmp-related utility routines, mostly fluff
# $Id: snmpstuff.pl.in,v 1.9 2002/08/19 18:43:06 facon Exp $
# from facon 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# $Revision: 1.9 $

use strict;

#------------------------------------------------- routines ---
#
# $string = &snmpiftype($num);
# $string = &snmpifstatus($num);
# &snmp_load_oids;
# $ifname = &to_ifname($wildpart);
# $ifname = &get_ifname($comhost, $ifindex);
# $comhost = &get_comhost($host, $realrrd, $wildrrd [,$ip]);
# $ifindex = &get_ifindex( $host, $comhost, $ifname);

# - - -   Setup   - - -

use SNMP_util "0.69";

# Tell it to shut up.
$SNMP_Session::suppress_warnings = 2;

# Generic usefull OIDs.  The others have gone to the config file.
&snmpmapOID('ifName', '1.3.6.1.2.1.31.1.1.1.1');
&snmpmapOID('ifAlias', '1.3.6.1.2.1.31.1.1.1.18');

#----------------------------------------------------- snmpiftype ---
# What kind of an interface have we got here.  Preferably a short name.
sub snmpiftype {
	my ($num) = @_;
	my $type;
	if (! defined $num) { $type = 0; }
	elsif (defined $snmpget::iftype[$num]) {
		$type = $snmpget::iftype[$num-1];
	}
	else { $type = $num; }
$type;
}

@snmpget::iftype = (
	'other', 'regular', 'hdh', 'ddnx25', 'rfc877x25', 'ethernet',
	'802.3', 'tokenbus', 'tokenring', '802.6', 'starlan', 'proteon10m',
	'proteon80m', 'hyperchannel', 'fddi', 'lapb', 'sdlc', 'ds1', 'e1',
	'isdnbri', 'isdnpri', 'proppointtopointserial', 'ppp', 'loopback',
	'eon', 'ethernet3m', 'nsip', 'slip', 'ultra', 'ds3', 'sip', 
	'framerelay', 'rs232', 'para', 'arcnet', 'arcnetplus', 'atm',
	'miox25', 'sonet', 'x25ple', '802.2llc', 'localtalk', 'smdsdxi',
	'framerelayservice', 'v35', 'hssi', 'hippi', 'modem', 'aal5',
	'sonetpath', 'sonetvt', 'smdsicip', 'propvirtual', 'propmultiplexor',
);

#------------------------------------------------- snmpifstatus ---
# Status as a string.  Numbers aren't very helpful.
sub snmpifstatus {
	my ($num) = @_;
	return 'MISSING' unless (defined $num);
	return ('up', 'down', 'test', 'unknown', 'dormant')[$num-1];
}

#-------------------------------------------------- snmp_load_oids ---
# make the snmp package know about our OIDs
sub snmp_load_oids {
	my $oid;
	foreach my $oidname (keys %{$main::config{OID}}) {
		$oid = $main::config{OID}{$oidname};
		&snmpmapOID($oidname, $oid);
		&debug("snmp_load_oids: $oidname = $oid") if ($main::debug>2);
	}
}

#--------------------------------------------------- to_ifname ---
sub to_ifname {
	my ($ifname) = @_;
	if (defined $ifname) {
		$ifname =~ tr/A-Z /a-z_/;
		$ifname =~ tr#-a-z0-9:_\./##cd;
	}
$ifname;
}


#--------------------------------------------------- to_diskname ---
sub to_diskname {
	my ($diskname) = @_;
	if (defined $diskname) {
		$diskname =~ tr/A-Z /a-z_/;
		$diskname =~ tr#-a-z0-9:_\./##cd;
	}
$diskname;
}



#----------------------------------------------------------- get_ifname ---
# get the ifname (or ifdescr) from the ifindex
sub get_ifname {
	my ($comhost, $ifindex) = @_;
	&debug("get_ifname: START($comhost,$ifindex)") if ($main::debug>1);
	my ($ifdescr) = &snmpget( $comhost, 'ifDescr.'. $ifindex);
	my ($ifname) = &snmpget( $comhost, 'ifName.'. $ifindex);
	if (!defined $ifname or $ifname =~ /^\s*$/) { $ifname = $ifdescr; }
	$ifname = &to_ifname( $ifname);
	&debug("get_ifname: FINISH($ifname)") if ($main::debug>1);
$ifname;
}

#----------------------------------------------------------- get_ifname ---
# get the ifname (or ifdescr) from the ifindex
sub get_diskname {
	my ($comhost, $dskindex) = @_;
	&debug("get_diskname: START($comhost,$dskindex)") if ($main::debug>1);
	my ($dskdescr) = &snmpget( $comhost, '.1.3.6.1.4.1.2021.9.1.3.'. $dskindex);
	my ($dskname) = &snmpget( $comhost, '.1.3.6.1.4.1.2021.9.1.2.'. $dskindex);
	if (!defined $dskname or $dskname =~ /^\s*$/) { $dskname = $dskdescr; }
	$dskname = &to_diskname( $dskname);
	&debug("get_diskname: FINISH($dskname)") if ($main::debug>1);
$dskname;
}

#------------------------------------------------------------- get_comhost ---
sub get_comhost {
	my ($host, $realrrd, $wildrrd, $ip) = @_;
	my ($community, $comhost);

# Get the community from somewhere
	if (defined $main::config{HOST}{$host}{COMMUNITY}) {
		$community = $main::config{HOST}{$host}{COMMUNITY};
	}
	elsif (defined $main::config{COMMUNITY}) {
		$community = $main::config{COMMUNITY};
	}
	elsif (defined $main::community) {
		$community = $main::community;
	}
	else {
		$community = 'public'; # unlikely to be correct, but it is the default
	}

# Use the IP number, if supplied
	if (defined $ip) { $comhost = $community .'@'. $ip; }
	else { $comhost = $community .'@'. $host; }

# Get the SNMP port, if specified
	if( defined $realrrd && $realrrd =~ /^([^:]+):(.+)$/) {
		$comhost .= ':' . $2;
	}
	elsif (defined $wildrrd and defined $main::config{RRD}{$wildrrd}{PORT}) {
		$comhost .= ':'. $main::config{RRD}{$wildrrd}{PORT};
	}
	elsif (defined $main::config{HOST}{$host}{SNMPPORT}) {
		$comhost .= ':'. $main::config{HOST}{$host}{SNMPPORT};
	}

	return $comhost;
}

#----------------------------------------------------------- get_ifindex ---
sub get_ifindex {
	my ($host, $comhost, $real_wildpart) = @_;
	my ($ifindex, $ifname, $ifdescr, $fixed_wildpart, $fixed_ifname, $wildpart);

	# Use in-memory cache, if we've got it
	$wildpart = $real_wildpart;
	if( defined $main::ifindex_cache{$wildpart}) {
		return $main::ifindex_cache{$wildpart};
	}

	# Drop a trailing port-number
	if( $wildpart =~ /^([^:]+):.*$/o) { $wildpart = $1; }

	# See if we have the ifIndex cached
	$fixed_wildpart = &to_filename(&to_ifname($wildpart));
	my $file = "$main::config{DATADIR}/$host/IFINDEX-$fixed_wildpart";

	if (-f $file) {
		&debug("ifindex cache file exists ($file)") if ($main::debug>1);
		($ifindex) = &get_status($host, 'IFINDEX-'.$fixed_wildpart);
		$ifname = &get_ifname( $comhost, $ifindex);

		# Make sure that it's correct, as Cisco likes to renumber interfaces
		if (defined $ifname) {
			$fixed_ifname = &to_filename($ifname);
			if ($ifname =~ /^$wildpart$/i) {
				&debug("    ifIndex for $host $ifname is $ifindex, " .
					"fixed='$fixed_ifname' (cached)") if ($main::debug>1);
				$main::ifindex_cache{$real_wildpart} = $ifindex;
				return $ifindex;
			}
			else {
				&debug("ifindex $ifindex name($ifname) " .
					"fixed='$fixed_ifname' doesn't match " .
					"interface($wildpart)") if ($main::debug>1);
			}
		}
		else {
			&debug("missing cached interface $ifindex") if ($main::debug>1);
			return undef;
		}
	}
	&debug("ifIndex not cached for $host interface '$wildpart'")
		if ($main::debug>1);

	# Not cached, have to search for it.  This is why I cache them.
	# Collect the names of all the interfaces so we don't have to walk all the
	# interfaces for each one.

	# I don't know why snmpwalk returns them as number:number, but it does and
	# nothing likes to see them that way.
	unless (defined $main::ifindices) {
		my ($ix1, $ix2, $i, $foundsome);
		$foundsome = 0;
		foreach $i (&snmpwalk($comhost, 'ifIndex')) {
			next unless (defined $i);
			($ix1, $ix2) = split(':',$i,2);
			&error("ix1($ix1) != ix2($ix2) and I don't know which to use.")
				if ($ix1 != $ix2);
			$ifname = &get_ifname( $comhost, $ix1);
			&debug("  index=$ix1, name='$ifname'") if ($main::debug>1);
			next unless (defined $ifname);
			$foundsome = 1;
			$fixed_ifname = &to_filename($ifname);
			&debug("  index $ix1 is $ifname, fixed='$fixed_ifname'")
				if ($main::debug>1);

			# Only store the first ocurrance of the name
			next if (defined $main::ifindices{$ifname});
			$main::ifindices{$ifname} = $ix1;
		}

		# Note that we can't contact this host if we found no interfaces
		unless ($foundsome) {
			$main::ifindices{NOINTERFACES} = 1;  # define it
			$main::no_interfaces = 1;
			return undef;
		}
	}

	# Did we find it?
	if (defined $main::ifindices{$wildpart}) {
		$ifindex = $main::ifindices{$wildpart};
		&debug("ifIndex for $host $ifname is $ifindex (search)")
			if ($main::debug>1);
		&put_status($host, 'IFINDEX-'. $fixed_wildpart, $ifindex);
		&debug("ifIndex for $wildpart ($ifindex) written to $file") 
			if ($main::debug>1);
		$main::ifindex_cache{$real_wildpart} = $ifindex;
		return $ifindex;
	}
	else {
		&error("$host interface $wildpart not found");
	}


	return undef;
}


#----------------------------------------------------------- get_diskindex ---
sub get_diskindex {
	my ($host, $comhost, $real_wildpart) = @_;
	my ($diskindex, $diskname, $diskdescr, $fixed_wildpart, $fixed_diskname, $wildpart);

	# Use in-memory cache, if we've got it
	$wildpart = $real_wildpart;
	if( defined $main::diskindex_cache{$wildpart}) {
		return $main::diskindex_cache{$wildpart};
	}

	# Drop a trailing port-number
	if( $wildpart =~ /^([^:]+):.*$/o) { $wildpart = $1; }

	# See if we have the ifIndex cached

	my $diskn = &to_diskname($wildpart);
	$fixed_wildpart = &to_filename($diskn);

	my $file = "$main::config{DATADIR}/$host/DISKINDEX-$fixed_wildpart";
	print "disk cache = $file\n";

	if (-f $file) {
#		&debug("ifindex cache file exists ($file)") if ($main::debug>1);
#		($ifindex) = &get_status($host, 'IFINDEX-'.$fixed_wildpart);
#		$ifname = &get_diskname( $comhost, $ifindex);
#
#		# Make sure that it's correct, as Cisco likes to renumber interfaces
#		if (defined $ifname) {
#			$fixed_ifname = &to_filename($ifname);
#			if ($ifname =~ /^$wildpart$/i) {
#				&debug("    ifIndex for $host $ifname is $ifindex, " .
#					"fixed='$fixed_ifname' (cached)") if ($main::debug>1);
#				$main::ifindex_cache{$real_wildpart} = $ifindex;
#				return $ifindex;
#			}
#			else {
#				&debug("ifindex $ifindex name($ifname) " .
#					"fixed='$fixed_ifname' doesn't match " .
#					"interface($wildpart)") if ($main::debug>1);
#			}
#		}
#		else {
#			&debug("missing cached interface $ifindex") if ($main::debug>1);
#			return undef;
#		}
	}
	&debug("diskIndex not cached for $host interface '$wildpart'")
		if ($main::debug>1);

	# Not cached, have to search for it.  This is why I cache them.
	# Collect the names of all the interfaces so we don't have to walk all the
	# interfaces for each one.

	# I don't know why snmpwalk returns them as number:number, but it does and
	# nothing likes to see them that way.
	unless (defined $main::diskindices) {
		my ($ix1, $ix2, $i, $foundsome);
		$foundsome = 0;
		my $ii = 0;
		# super trucho pero dskIndex no funciona
		my @adisk;
		while ($ii <10) {
		   $ii++;
		   my $valor;
		   ($valor) = &snmpget($comhost, "1.3.6.1.4.1.2021.9.1.1.$ii");
		   push(@adisk,$valor) if (defined $valor);
	        }

		foreach $i (@adisk) {
#			next unless (defined $i);
#			($ix1, $ix2) = split(':',$i,2);
			$ix1 = $i;
#			&error("ix1($ix1) != ix2($ix2) and I don't know which to use.")
#				if ($ix1 != $ix2);
			$diskn = &get_diskname( $comhost, $ix1);
			&debug("  index=$ix1, name='$diskn'") if ($main::debug>1);
#			next unless (defined $ifname);
#			$foundsome = 1;
			$fixed_diskname = &to_filename($diskn);
			
#			&debug("  index $ix1 is $ifname, fixed='$fixed_diskname'")
#				if ($main::debug>1);
#
#			# Only store the first ocurrance of the name
#			next if (defined $main::ifindices{$ifname});
			$main::diskindices{$diskn} = $ix1;
		}
#
#		# Note that we can't contact this host if we found no interfaces
#		unless ($foundsome) {
#			$main::ifindices{NOINTERFACES} = 1;  # define it
#			$main::no_interfaces = 1;
#			return undef;
#		}
	}
#
#	# Did we find it?
	if (defined $main::diskindices{$wildpart}) {
		$diskindex = $main::diskindices{$wildpart};
		&debug("diskIndex for $host $diskindex is $diskindex (search)")
			if ($main::debug>1);
		&put_status($host, 'DISKINDEX-'. $fixed_wildpart, $diskindex);
		&debug("diskindex for $wildpart ($diskindex) written to $file") 
			if ($main::debug>1);
		$main::dskindex_cache{$real_wildpart} = $diskindex;
		return $diskindex;
	}
#	else {
#		&error("$host interface $wildpart not found");
#	}
#
#
	return undef;
}


# - - -   Good Night   - - -
1;

