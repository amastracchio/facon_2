# datastuff.pl - common parser elements between datapage and datagraph
# $Id: datastuff.pl.in,v 1.10 2003/05/15 11:58:55 facon Exp $
# from facon 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# $Revision: 1.10 $

use strict;

#-------------------------------------------------- supplied routines ---
# do_common( $line);

#------------------------------------------------------- do_common ---
# parser common code 
sub do_common {
	my ($line) = @_;
	my ($myname, $host, $oidname, $comhost, $port, $partname, $instance, $value,
		$file, $rrd, $dsname, $cf, $startfrom, $start, $step, $names, $data,
		$dataname, $i, $index, @limits, $frommin, $frommax, $tomin, $tomax,
		$community, $fixedrrd, $expr, $oid);

# Save an OID
	if ($line =~ /^oid\s+([-0-9a-zA-Z_\.]+)\s+([-0-9a-zA-Z_\.\@:]+)\s+([0-9a-zA-Z\.]+)\s*$/) {
		$myname = $1;
		$host = $2;
		$oidname = $3;

# parse the comhost string
		if ($host =~ /^(([^\@\s]+)@)?([-0-9a-zA-Z_\.]+)(:(\d+))?/i) {
			$community = $2;
			$host = $3;
			$port = $5;

			if (defined $community) { $comhost = $community .'@'. $host; }
			elsif (defined $main::config{HOST}{$host}{COMMUNITY}) {
				$comhost = $main::config{HOST}{$host}{COMMUNITY} .'@'. $host;
			}
			else { $comhost = 'public@'. $host; }

			if (defined $port) { $comhost .= ':'. $port; }
			&debug("  comhost = '$comhost'") if ($main::debug);
		}
		else {
			&error("comhost string invalid ($host)");
			$main::var{$myname} = 'SYNTAXERROR';
			return undef;
		}

# Deal with instances of an ifXxx
		if ($oidname =~ /^([a-zA-Z0-9_]+)(\.([0-9\.]+))?$/) {
			$partname = $1;
			$instance = $3;
			if (defined $main::config{OID}{$partname}) {
				$oid = $main::config{OID}{$partname};
				$oid .= (defined $instance) ? '.'. $instance : '';
				&snmpmapOID($myname, $oid);
				&debug("  oid mapping: $myname => $oidname => $oid")
					if ($main::debug);
			}
			else { &abort("unknown OIDname $oidname for $myname"); }
		}
		else { &abort("invalid oid form ($oidname)"); }

# Now fetch the data
		($value) = &snmpget( $comhost, $oid);
		if (defined $value) {
			$main::var{$myname} = $value;
			&debug("snmp $myname set to '$value'") if ($main::debug);
		}
		else {
			&error("no value at $comhost for $oidname");
			$main::var{$myname} = 'NOVALUE';
			return undef;
		}

	}

# Store a Status file value
	elsif ($line =~ /^status\s+([-0-9a-zA-Z_.]+)\s+([-0-9a-zA-Z_.]+)\s+([-0-9a-zA-Z_.]+)\s*$/) {
		$myname = $1;
		$host = $2;
		$file = $3;
		($value) = &my_get_status($host, $file);
		if ($value eq 'MISSING') { $value = ''; }
		$main::var{$myname} = $value;
		&debug("status $myname set to '$value'") if ($main::debug);
	}

# Store a RRD data value
	elsif ($line =~ m#^rrd\s+([-0-9a-zA-Z_.]+)\s+([-0-9a-zA-Z.]+)\s+([-0-9a-zA-Z_.:/]+)\s+([-0-9a-zA-Z_.]+)\s+([A-Z]+)\s*$#) {
		$myname = $1;
		$host = $2;
		$rrd = $3;
		$dsname = $4;
		$cf = $5;
		$fixedrrd = &to_filename($rrd);
		$file = $main::config{DATADIR} .'/'. $host .'/'. $fixedrrd .'.rrd';
		unless (-f $file) {
			&error("missing RRD $file");
			return undef;
		}
		$startfrom = RRDs::last $file;
		unless (defined $startfrom) {
			&error("rrdlast failed for $file: ". RRDs::error());
			$main::var{$myname} = 'RRDLASTFAILED';
			return undef;
		}
		($start, $step, $names, $data) = RRDs::fetch $file, $cf, 
			'--start', $startfrom;
		unless (defined $start) {
			&error("rrdfetch failed for $file: ". RRDs::error());
			$main::var{$myname} = 'RRDFETCHFAILED';
			return undef;
		}
		$i=-1;
		foreach $dataname (@$names) {
			if ($dataname eq $dsname) {
				$index = $i+1;
			}
			else { ++$i; }
		}
		if ($i == -1) {
			&error("$dsname not found in $rrd");
			$main::var{$myname} = 'RRDNODS';
			return undef;
		}
		my $dataline = @$data[0];
		$value = @$dataline[$index];
		unless (defined $value) {
			&error("no data for $dsname in $rrd");
			$main::var{$myname} = 'RRDNODATA';
			return undef;
		}
		if ($value =~ /^NaN$/i) {
			&error("no data values for $dsname in $rrd");
			$main::var{$myname} = 'RRDNOVALUES';
			return undef;
		}
		$main::var{$myname} = $value;
		&debug("rrd $myname set to '$value'") if ($main::debug);
	}

# Scale data
	elsif ($line =~ /^scale\s+([-0-9a-zA-Z_.]+)\s+(\d+(\s+\d+)*)\s*$/) {
		my $oldvalue;
		$myname = $1;
		@limits = split(' ', $2);
		if (defined $main::var{$myname}) {
			$oldvalue = $main::var{$myname}
		}
		else {
			&error("no such var as '$myname'");
			return undef;
		}
		$value = 0;
		for ($i=0; $i<= $#limits; ++$i) {
			if ($oldvalue > $limits[$i]) {
				$value = $i+1;
			}
			else { last; }
		}
		$main::var{$myname} = $value
		&debug("range set $myname to '$value'") if ($main::debug);
	}

# Map values onto a range
	elsif ($line =~ /^range\s+([-0-9a-zA-Z_.]+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$/) {
		$myname = $1;
		$frommin = $2;
		$frommax = $3;
		$tomin = $4;
		$tomax = $5;
		&debug("range $myname $frommin-$frommax $tomin-$tomax") if ($main::debug);
		&error("range not implemented, yet");
	}

# automap - take the range collected by &automap_add($value) and map value to [1..10] 
	elsif ($line =~ /^automap\s+([-0-9a-zA-Z_.]+)\s*$/) {
		$myname = $1;
		my $newvalue = &automap_range($main::var{$myname});
		&debug("automap $myname from $main::var{$myname} to $newvalue") if ($main::debug);
		$main::var{$myname} = $newvalue;
	}
	elsif ($line =~ /^automap_add\s+([-0-9a-zA-Z_.]+)\s*$/) {
		$myname = $1;
		&automap_add($main::var{$myname});
		&debug("automap_add $myname ($main::var{$myname})") if ($main::debug);
	}
	elsif ($line =~ /^automap_clear\s*$/) {
		undef $main::automap_min;
		undef $main::automap_max;
		&debug("automap_clear'd") if ($main::debug);
	}

# Eval: arithmetic and more, the lazy way
	elsif ($line =~ /^eval\s+([-0-9a-zA-Z_.]+)\s+(.*)/) {
		$myname = $1;
		$expr = $2;
		if ($expr =~ /^\s*=\s*(.*)/) { $expr = $1; }
		$main::var{$myname} = eval $expr;
		&debug("eval set $myname to '$main::var{$myname}'") if ($main::debug);
	}

# Get alert status for (host, rrd, var[, cf])
	elsif( $line =~ m#^alertstatus\s+([-0-9a-zA-Z_.]+)\s+([-0-9a-zA-Z.]+)\s+([-0-9a-zA-Z_.:/]+)\s+([-0-9a-zA-Z_.]+)(\s+([A-Z]+))?\s*$#) {
		$myname = $1;
		$host = $2;
		$rrd = $3;
		$dsname = $4;
		$cf = $6;
		$cf = 'AVERAGE' unless( defined $cf);
		($value) = &get_alert_status( $host, $rrd, $dsname, $cf);
		$main::var{$myname} = $value;
		&debug("alertstatus set $myname to '$value'") if ($main::debug);
	}

# Get alert value for (host, rrd, var[, cf])
	elsif( $line =~ m#^alertvalue\s+([-0-9a-zA-Z_.]+)\s+([-0-9a-zA-Z.]+)\s+([-0-9a-zA-Z_.:/]+)\s+([-0-9a-zA-Z_.]+)(\s+([A-Z]+))?\s*$#) {
		$myname = $1;
		$host = $2;
		$rrd = $3;
		$dsname = $4;
		$cf = $6;
		$cf = 'AVERAGE' unless( defined $cf);
		(undef, $value) = &get_alert_status( $host, $rrd, $dsname, $cf);
		$main::var{$myname} = $value;
		&debug("alertvalue set $myname to '$value'") if ($main::debug);
	}
# xxx

	else {
		&error("unknown common line: $line");
	}
}

#------------------------------------------- map1 ---
sub map1 {
	my ($value) = @_;

	if ($value < 25000) { $value = 0; }
	elsif ($value < 50000) { $value = 1; }
	elsif ($value < 100000) { $value = 2; }
	elsif ($value < 250000) { $value = 3; }
	elsif ($value < 500000) { $value = 4; }
	elsif ($value < 1000000) { $value = 5; }
	elsif ($value < 2500000) { $value = 6; }
	elsif ($value < 5000000) { $value = 7; }
	elsif ($value < 10000000) { $value = 8; }
	else { $value = 9; }

	return $value;
}

@main::map1_legend = ('<25K', '<50K', '<100K', 
	'<250K', '<500K', '<1M', '<2.5M', '<5M',
	'<10M', '>10M' );

#------------------------------------------- map2 ---
sub map2 {
	my ($value) = @_;

	if ($value < 1000) { $value = 0; }
	elsif ($value < 2500) { $value = 1; }
	elsif ($value < 5000) { $value = 2; }
	elsif ($value < 10000) { $value = 3; }
	elsif ($value < 25000) { $value = 4; }
	elsif ($value < 50000) { $value = 5; }
	elsif ($value < 100000) { $value = 6; }
	elsif ($value < 250000) { $value = 7; }
	elsif ($value < 500000) { $value = 8; }
	else { $value = 9; }

	return $value;
}

@main::map2_legend = ('<1K', '<2.5K', '<5K', '<10K', '<25K', '<50K',
	'<100K', '<250K', '<500K', '>500K');

#------------------------------------------------ automap_range ---
sub automap_range {
	my $value = shift @_;
	my ($power, $top, $bottom);

	unless (defined $main::automap_min and defined $main::automap_max) {
		&abort('automap_range called before automap_add');
	}

# Build the @main::automap_ranges array for grouping
	my (@steps, $step, $i, $limit);
	unless (@main::automap_ranges) {
		$power = int(&log10($main::automap_min));
		$bottom = $main::automap_min / 10**$power;
		if ($bottom < 2.5) { $bottom = 2.5; @steps = (5, 1, 2.5); }
		elsif ($bottom <= 5) { $bottom = 5; @steps = (1, 2.5, 5); }
		else { $bottom = 1; $power++; @steps = (2.5, 5, 1); }
		$bottom = $bottom * 10**$power;

# Add all the ranges, but make sure to cover up to the top
		@main::automap_ranges = $bottom;
		while (1) {
			$step = shift @steps;
			push @steps, $step;
			if ($step == 1) { $power++; }
			$limit = $step * (10**$power);
			last if( $limit > $main::automap_max);
			push @main::automap_ranges, $limit;
			if( @main::automap_ranges > 10) {
				shift @main::automap_ranges;
			}
		}
		&debug("automap_ranges created: ", join(' ', @main::automap_ranges))
			if ($main::debug);
	}

# Sort out which group the value belongs to
	for( $i=0; $i <= 8; ++$i) {
		if( $value <= $main::automap_ranges[$i]) {
			return $i+1;
		}
	}
	return 10;
}

#------------------------------------------------ automap_add ---
sub automap_add {
	my $value = shift @_;
	if (defined $main::automap_min &&
			$value < $main::automap_min && $value > 0) {
		$main::automap_min = $value;
	}
	elsif (! defined $main::automap_min && $value > 0) {
		$main::automap_min = $value;
	}
	if (defined $main::automap_max && $value > $main::automap_max) {
		$main::automap_max = $value;
	}
	elsif (! defined $main::automap_max) {
		$main::automap_max = $value;
	}
	&debug("automap_add: added $value") if ($main::debug);
	return 1;
}

#--------------------------------------------------------- automap_legend ---
sub automap_legend {
	my $value = shift @_;
	my $legend;
	&abort("automap_legend: arg must be in 1..10 ($value)")
		if ($value < 1 or $value > 10);

	$legend = $main::automap_ranges[$value];
	&debug("automap_legend: $value -> $legend") if($main::debug);
	if( $value == 10) { $legend = '>'; }
	else {
		if ($legend < 1) {
			$legend = sprintf( '%.1e', $legend);
		}
		else {
			$legend = &siunits($legend);
		}
		$legend = '<' . $legend;
	}

	return $legend;
}

#------------------------------------------------------------- Good-night ---
1;
