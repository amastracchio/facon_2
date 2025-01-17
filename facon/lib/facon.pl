# facon.pl -- common routines for facon programs
# CVS $Id: facon.pl.in,v 1.81 2003/05/20 19:28:05 facon Exp $
# from facon 1.0.13a
# Copyright 1999 - 2003 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

use strict;

# $Revision: 1.81 $

#-------------------------------------------------------------- subs ---
# &read_config_dir( $config_dir); # note: no return value
# @args = &do_subs($rrdfile, $realrrd, $wildpart, $hostname, $ip,
#	$graph, $graphtime, @args);
# ($wildrrd, $wildpart, $fixedrrd, $realrrd) = &get_rrd($rrdspec);
# $ip = &get_ip($hostname);
# $host = &get_host( $ip);
# &read_ip_cache(readonly); # called by get_ip/get_host, if necessary
# &write_ip_cache(); # called at END to save any changes
#	The above two are controlled by $main::ip_cache_readonly and
#	$main::dont_use_ip_cache
# $ok = &make_a_dir ($dir);
# &put_status, ($host, $file, $status);
# ($status, $stale) = &get_status ( $host, $file);
# $filename = &to_filename($rrd_or_whatever);
# $string = &siunits($number);
# $string = &timestamp($secs);
# &testout($msg);
# @files = &list_files($dir [, $pattern]);
# @hosts = &hosts_with_key( $key);
# @rrds = &rrds_with_key( $key);
# true|false = &host_has_key( $host, $key);
# true|false = &rrd_has_key( $wildrrd, $key);
# $html = &make_uptime_flag( $uptime);
# @hosts = select_hosts( \@hosts, \@groups, \@keys);
# $number = &si_to_number( $si_string);
# &put_error( $host, $fixedrrd, $msg);
# &clear_error( $host, $fixedrrd);
# &check_stop_file();
# true|false = &check_collect_time( $host, $wildrrd, $fixedrrd);

#-------------------------------------------------------------- config ---

# Here's roughly how %main::config gets constructed

# $main::config{DATADIR} = $value;
# $main::config{HTMLDIR} = $value;
# $main::config{HTMLURL} = $value;
# $main::config{CGIDIR} = $value;
# $main::config{CGIURL} = $value;
# ($main::config{THUMBWIDTH}, $main::config{THUMBHEIGHT}) = split('x',$value,2);
# ($main::config{METADIR}, $main::config{METASUFFIX}) = split(' ',$value);
# $main::config{WEBMASTER} = $value;
# $main::config{BACKGROUND} = $value;
# $main::config{GROUPS} = [&make_array($value)];
# $main::config{STALETIME} = seconds;
# $main::config{MINUPTIME} = seconds;
# $main::config{KEEPALERTS} = seconds;
# $main::config{UPTIMEALERT} = seconds;
# $main::config{HTMLREFRESH} = seconds;
# $main::config{UPSTATUS} = $value;
# $main::config{UPUNSTABLESTATUS} = $value;
# $main::config{DOWNSTATUS} = $value;
# $main::config{DOWNUNSTABLESTATUS} = $value;
# $main::config{OKSTATUS} = $value;
# $main::config{WARNSTATUS} = $value;
# $main::config{ERRORSTATUS} = $value;
# $main::config{CRITICALSTATUS} = $value;
# $main::config{LOGOURL} = $value;
# $main::config{HOMEURL} = $value;
# $main::config{TOPURL} = $value;
# $main::config{SRCURL} = $value;
# @{$main::config{REMOTEPING}} = (remote-ping-servers);
# $main::config{DATAPAGEDIR} = $value;
# $main::config{RRDCGI} = $value;
# $main::config{LOGDIR} = $value;
# $main::config{PAGETEMPLATEDIR} = $value;
# $main::config{TRAPIGNORE} = $value;
# $main::config{COMMUNITY} = $value;
# $main::config{WATCHDOGTIMER} = $value;
# $main::config{IMAGETYPE} = $value;
# $main::config{PINGER} = $value;
# $main::config{COLLECTORS} = [ @values ];
# $main::config{MONITORS} = [ @values ];
# $main::config{PAGEMAKERS} = [ @values ];
# $main::config{MAXPORTPATTERNS} = $value;
# $main::config{FORCECOLLECTION} = $value;
# $main::config{TEMPDIR} = $value;
# $main::config{KEEPLOGS} = $value;
#
# $main::config{HTML}{ALERTINDEX} = $value;
# $main::config{HTML}{ALERTREPORT} = $value;
# $main::config{HTML}{ALERTFLAGCRITICAL} = $html;
# $main::config{HTML}{ALERTFLAGERROR} = $html;
# $main::config{HTML}{ALERTFLAGWARN} = $html;
# $main::config{HTML}{CUSTOMINDEX} = $value;
# $main::config{HTML}{LOGREPORT} = $value;
# $main::config{HTML}{OVERALLINDEX} = $value;
# $main::config{HTML}{PINGINDEX} = $value;
# $main::config{HTML}{RRDINDEX} = $value;
# $main::config{HTML}{QUICKINDEX} = $value;
# $main::config{HTML}{INDICES} = $value;
# $main::config{HTML}{LINKS} = $value;
# $main::config{HTML}{TOOLS} = $value;
# push @{$main::config{HTML}{DEFAULTTOOLS}}, split(' ', $value);
# $main::config{HTML}{DESCRIPTION} = $value;
# $main::config{HTML}{IPNUMBER} = $value;
# $main::config{HTML}{INTERFACES} = $value;
# $main::config{HTML}{OPERATINGSYSTEM} = $value;
# $main::config{HTML}{HARDWARE} = $value;
# $main::config{HTML}{MEMORYSIZE} = $value;
# $main::config{HTML}{UPTIME} = $value;
# $main::config{HTML}{STATUS} = $value;
# $main::config{HTML}{LASTUPDATEON} = $value;
# $main::config{HTML}{COMMENT} = $value;
# $main::config{HTML}{CONTACT} = $value;
# $main::config{HTML}{HOSTINDEX} = $value;
# $main::config{HTML}{GROUPINDEX} = $value;
# $main::config{HTML}{VIEWINDEX} = $value;
# $main::config{HTML}{VIEWINDICES} = $value;
# $main::config{HTML}{SHOWINTERFACES} = $value;
# $main::config{HTML}{KEEPIMAGES} = $value;
# $main::config{HTML}{INDEXPREFIX} = $value;
# $main::config{HTML}{INDEXSUFFIX} = $value;
# $main::config{HTML}{GROUPPREFIX} = $value;
# $main::config{HTML}{GROUPSUFFIX} = $value;
# $main::config{HTML}{HOSTPREFIX} = $value;
# $main::config{HTML}{HOSTSUFFIX} = $value;
# $main::config{HTML}{TOOLPREFIX} = $value;
# $main::config{HTML}{TOOLSUFFIX} = $value;
# $main::config{HTML}{LINKPREFIX} = $value;
# $main::config{HTML}{LINKSUFFIX} = $value;
# $main::config{HTML}{OUTOFRANGEPREFIX} = $value;
# $main::config{HTML}{OUTOFRANGESUFFIX} = $value;
#
# $main::config{OID}{$name} = $value;
#
# $main::config{TIME}{$name}{START} = eval $start;
# $main::config{TIME}{$name}{FINISH} = eval $finish;
# 
# $main::config{COLOR}{$name} = $value;
# 
# $main::config{ARCHIVE}{$name} = $value;
#
# push @{$main::config{LINKS}}, {
# 	NAME => $name,
# 	URL => $value
# };
# 
# $main::config{TOOL}{$name} = $value;
# 
# $main::config{SCRIPT}{$script}{SEND} = script-string
# $main::config{SCRIPT}{$script}{TIMEOUT} = seconds
# $main::config{SCRIPT}{$script}{PORT} = portnum
# $main::config{SCRIPT}{$script}{INFOPATTERN} = regex
# $main::config{SCRIPT}{$script}{VALUEPATTERN} = regex
# push @{$main::config{SCRIPT}{$script}{TESTS}}, uc $name;
# $main::config{SCRIPT}{$script}{uc $name} = $value;
#
# push @{$main::config{ALERT}} , {
# 	LEVEL => $level,
# 	HOST => $host,
# 	RRD => $realrrd,
# 	VAR => $var,
# 	MINTIME => $mintime,
# 	INTERVAL => $interval,
# 	PROG => $prog,
#  	ADDRESSES => [ @addresses ],
# };
# 
# $main::config{RRD}{$wildrrd}{STEP} = $1;
# $main::config{RRD}{$wildrrd}{SOURCE} = $1;
# $main::config{COLLECTOR}{$collector}{RRD}{$wildrrd} = 1;
# $main::config{COLLECTOR}{$collector}{HOST}{$host} = 1;
# $main::config{RRD}{$wildrrd}{DS}{$name}{ALIAS} = lc $alias;
# $main::config{RRD}{$wildrrd}{DS}{$name}{DSDEF} = lc $ds;
# $main::config{RRD}{$wildrrd}{DS}{$name}{EXTRA} = $extra;
# push @{$main::config{RRD}{$wildrrd}{DATANAMES}}, $name;
# $main::config{RRD}{$wildrrd}{ARCHIVES} = [split(' ',$1)];
# $main::config{RRD}{$wildrrd}{TIMES} = [split(' ',$1)];
# $main::config{RRD}{$wildrrd}{ALERT}{$var}{RELATION} = $relation;
# $comfig{RRD}{$wildrrd}{ALERT}{$var}{NODATA} = $status;
# $main::config{RRD}{$wildrrd}{PORT} = $port;
# $main::config{RRD}{$wildrrd}{KEY}{$key} = 1;
# @{$main::config{RRD}{$wildrrd}{ALERT}{$var}{THRESHOLDS}} = split(' ',$values);
# $main::config{RRD}{$wildrrd}{GRAPHDESC}{$graph} = $desc;
# push @{$main::config{RRD}{$wildrrd}{GRAPHS}}, $graph;
# push @{$main::config{RRD}{$wildrrd}{GRAPH}{$graph}}, &make_array($1);
# push @{$main::config{RRD}{$wildrrd}{OIDS}}, $main::config{OID}{$oidname};
# $main::config{RRD}{$wildrrd}{STATUSFILE}{$statusfile} = $variable
# $main::config{RRD}{$wildrrd}{DBICONNECT} = lc $1;
# $main::config{RRD}{$wildrrd}{DBISELECT} = lc $1;
# $main::config{RRD}{$wildrrd}{DBIMULTIROWID} = $1 - 1;
# $main::config{RRD}{$wildrrd}{CURRENTVALUE}{$variable}{STATUSFILE} =
#	$statusfile;
# $main::config{RRD}{$wildrrd}{CURRENTVALUE}{$variable}{FUNCTION} =	$function;
# 
# $main::config{HOST}{$host}{IP} = ip;
# $main::config{HOST}{$host}{VIA} = iplist;
# push @{$main::config{HOST}{$host}{ALIAS}}, @aliases
# $main::config{HOST}{$host}{GROUP} = group;
# $main::config{HOST}{$host}{COMMUNITY} = snmp-community
# $main::config{HOST}{$host}{LOCATION} = lat long text-comment
# $main::config{HOST}{$host}{CONTACTNAME} = Name Here
# $main::config{HOST}{$host}{CONTACTEMAIL} = email@address
# $main::config{HOST}{$host}{DESC} = description here;
# push @{$main::config{HOST}{$host}{RRDS}}, $realrrd;
# $main::config{HOST}{$host}{RRD}{$realrrd} = 1;
# $main::config{HOST}{$host}{NOGRAPH}{$realrrd}{$graph} = 1;
# $main::config{HOST}{$host}{EXTRA}{$realrrd} = $extra;
# $main::config{HOST}{$host}{RRDDESC}{$realrrd} = $rrddesc;
# @{$main::config{HOST}{$host}{TOOLS}} = split(' ',$1);
# $main::config{HOST}{$host}{ALERT}{$realrrd}{$var}{RELATION} = $relation;
# $main::config{HOST}{$host}{ALERT}{$realrrd}{$var}{NODATA} = $status;
# @{$main::config{HOST}{$host}{ALERT}{$realrrd}{$var}{THRESHOLDS}} = split(' ',$values);
# $main::config{HOST}{$host}{ALERT}{$realrrd}{$var}{NOALERT} = 1;
# push @{$main::config{GROUP}{$group}}, $host;
# $main::config{HOST}{$host}{SNMPPORT} = $port;
# $main::config{HOST}{$host}{KEY}{$key} = 1;
# push @{$main::config{HOST}{$host}{CUSTOMGRAPHS}}, $value;
# $main::config{HOST}{$host}{STATUSFILE} = $value;
# $main::config{HOST}{$host}{NTSTATUSSERVER} = $value;
# push @{$main::config{HOST}{$host}{NTINDIRECTHOSTS}, $ntserver;
# $main::config{HOST}{$host}{NTNAME} = $value;
# $main::config{HOST}{$host}{NOAVAILABILITY}{$realrrd}{$var} = 1;
# $main::config{HOST}{$host}{SHOWINTERFACES} = 1;
# $main::config{HOST}{$host}{HEADERFILE}{$header} = $file;

# push @{$main::config{CUSTOMGRAPHS}}, $graphname;
# push @{$main::config{CUSTOMGRAPH}{$graphname}{GRAPH}}, &make_array(graphspec);
# @{$main::config{CUSTOMGRAPH}{$graphname}{TIMES}} = split(' ',$_);
# $main::config{CUSTOMGRAPH}{$graphname}{DESC} = $graphname;

# $main::config{VIEW}{$view}{DESC} = $value;
# $main::config{VIEW}{$view}{TEMPLATE} = $value;
# $main::config{VIEW}{$view}{DATAPAGE} = $value;
# push @{$main::config{VIEW}{$view}{GRAPHS}}, "graph $1 $2 $3" or "customgraph $1"

# $main::config{ALERTTEMPLATE}{RRD}{$real_or_wild_rrd}
# $main::config{ALERTTEMPLATE}{ADDRESS}{$address_pattern}

# $main::config{RRDAVAIL}{$real_or_wild_rrd}{$varname}{CF} = $cf
# $main::config{RRDAVAIL}{$real_or_wild_rrd}{$varname}{RELATION} = $relation
# $main::config{RRDAVAIL}{$real_or_wild_rrd}{$varname}{THRESHOLD} = $threshold
# $main::config{HOSTAVAIL}{$host}{$real_or_wild_rrd}{$varname}{CF} = $cf
# $main::config{HOSTAVAIL}{$host}{$real_or_wild_rrd}{$varname}{RELATION} = $relation
# $main::config{HOSTAVAIL}{$host}{$real_or_wild_rrd}{$varname}{THRESHOLD} = $threshold
# $main::config{AVAILCOLORS} = [ @colors ]
# $main::config{AVAILTHRESHOLDS} = [ @thresholds ]

# push @{$main::config{ALERTDEST}{DEST}} = [ $dest, $time, $dow, $dom, $mon, $alias ];
# $main::config{ALERTDEST}{ALIAS}{$alias} = @method_addrs;
# $main::config{ALERTDEST}{METHOD}{$method} = $command_line;

# $main::config{DISCOVERY}{NTSTATUSSERVER} = $value;
# $main::config{DISCOVERY}{NTDOMAIN} = $value;
# $main::config{DISCOVERY}{DNSDOMAIN} = $value;
# $main::config{DISCOVERY}{SUBNETS} = $value;

# $main::config{DBICONNECT}{$connect_name}{SOURCE} = $value;
# $main::config{DBICONNECT}{$connect_name}{USER} = $value;
# $main::config{DBICONNECT}{$connect_name}{PASSWORD} = $value;

# $main::config{DBISELECT}{$select_name} = $select;

# push @{$main::config{RUN}}, [ $stage, $when ];

# $main::config{RUNSTAGE}{$stage}{$name}{ASYNC} = $async;
# $main::config{RUNSTAGE}{$stage}{$name}{FREQUENCY} = $frequency;
# $main::config{RUNSTAGE}{$stage}{$name}{COMMAND} = $command;

use Socket;
use Fcntl ':flock'; # import LOCK_* constants

%main::statuses = (
	'NODATA'	=> 0, 0 => 'NODATA',
	'OK'		=> 1, 1 => 'OK',
	'WARN'		=> 2, 2 => 'WARN',
	'ERROR'		=> 3, 3 => 'ERROR',
	'CRITICAL'	=> 4, 4 => 'CRITICAL',
);

#----------------------------------------------------- read_config_dir ---
# Remember to update check-config whenever you add a new section here.
sub read_config_dir {
	my ($configdir, @elements) = @_;
	my $errors = 0;

	unless (-d $configdir) {
		&abort("missing config-dir ($configdir)");
	}
	&debug("reading configuration") if ($main::config_debug);

# Untaint the configdir, so perl stops whinging
	if ($configdir =~ /^(.*)$/) {
		$configdir = $1;
	}

	foreach my $element (@elements) {
		if ($element eq 'general') {
			$errors += &read_config_general($configdir);
		}
		elsif ($element eq 'html') {
			$errors += &read_config_html($configdir);
		}
		elsif ($element eq 'times') {
			$errors += &read_config_times($configdir);
		}
		elsif ($element eq 'colors') {
			$errors += &read_config_colors($configdir);
		}
		elsif ($element eq 'archives') {
			$errors += &read_config_archives($configdir);
		}
		elsif ($element eq 'links') {
			$errors += &read_config_links($configdir);
		}
		elsif ($element eq 'tools') {
			$errors += &read_config_tools($configdir);
		}
		elsif ($element eq 'remotepings') {
			$errors += &read_config_remotepings($configdir);
		}
		elsif ($element eq 'scripts') {
			$errors += &read_config_scripts($configdir);
		}
		elsif ($element eq 'alerts') {
			$errors += &read_config_alerts($configdir);
		}
		elsif ($element eq 'oids') {
			$errors += &read_config_oids($configdir);
		}
		elsif( $element eq 'dbi') {
			$errors += &read_config_dbi( $configdir);
		}
		elsif ($element eq 'rrds') {
			$errors += &read_config_rrds($configdir);
		}
		elsif ($element eq 'customgraphs') {
			$errors += &read_config_customgraphs($configdir);
		}
		elsif ($element eq 'groups') {
			$errors += &read_config_groups($configdir);
		}
		elsif ($element eq 'view-templates') {
			$errors += &read_config_view_templates($configdir);
		}
		elsif ($element eq 'views') {
			$errors += &read_config_views($configdir);
		}
		elsif ($element eq 'hosts') {
			$errors += &read_config_hosts($configdir, 'hosts', 'HOST');
		}
		elsif ($element eq 'host-templates') {
			$errors += &read_config_hosts($configdir, 'host-templates', 
				'HOSTTEMPLATE');
		}
		elsif ($element eq 'alert-template-map') {
			$errors += &read_config_alert_template_map($configdir);
		}
		elsif ($element eq 'availability') {
			$errors += &read_config_availability($configdir);
		}
		elsif ($element eq 'alert-destination-map') {
			$errors += &read_config_alert_destination_map($configdir);
		}
		elsif ($element eq 'discovery') {
			$errors += &read_config_discovery($configdir);
		}
		elsif ($element eq 'ntops') {
			$errors += &read_config_ntops($configdir);
		}
		elsif ($element eq 'environment') {
			$errors += &read_config_environment($configdir);
		}
		elsif ($element eq 'run') {
			$errors += &read_config_run($configdir);
		}
		elsif ($element eq 'run-stages') {
			$errors += &read_config_run_stages($configdir);
		}
		else {
			&error('read_config_dir: unknown config section (',
				$element, '); skipped');
			++$errors;
		}
		&abort($errors, ' errors found') if ($errors > 0);
	}
}

#------------------------------------------------- read_config_general ---
sub read_config_general {
	my ($configdir) = @_;
	my $configfile = $configdir .'/general';
	my ($name, $value, $errors);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_general: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading general configuration") if ($main::config_debug);
	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		($name, $value) = /^\s*(\S+)\s+(.+)/;
		$value =~ s/\s+$//;

		if ($name eq 'datadir') {
			$main::config{DATADIR} = $value;
			&debug("  datadir $main::config{DATADIR}") if ($main::config_debug);
		}
		elsif ($name eq 'staletime') {
			$main::config{STALETIME} = $value;
			&debug("  staletime = $main::config{STALETIME}") if ($main::config_debug);
		}
		elsif ($name eq 'minuptime') {
			$main::config{MINUPTIME} = $value;
			&debug("  minuptime = $main::config{MINUPTIME}") if ($main::config_debug);
		}
		elsif ($name eq 'keepalerts') {
			$main::config{KEEPALERTS} = $value;
			&debug("  keepalerts = $main::config{KEEPALERTS}") if ($main::config_debug);
		}
		elsif ($name eq 'uptimealert') {
			$main::config{UPTIMEALERT} = $value;
			&debug("  uptimealert = $main::config{UPTIMEALERT}") if ($main::config_debug);
		}
		elsif ($name eq 'datapagedir') {
			$main::config{DATAPAGEDIR} = $value;
			&debug("  datapagedir $value") if ($main::config_debug);
		}
		elsif ($name eq 'logdir') {
			$main::config{LOGDIR} = $value;
			&debug("  logdir $value") if ($main::config_debug);
		}
		elsif ($name eq 'pagetemplatedir') {
			$main::config{PAGETEMPLATEDIR} = $value;
			&debug("  pagetemplatedir $value") if ($main::config_debug);
		}
		elsif ($name eq 'trapignore') {
			$main::config{TRAPIGNORE} = $value;
			&debug("  trapignore $value") if ($main::config_debug);
		}
		elsif ($name eq 'community') {
			$main::config{COMMUNITY} = $value;
			&debug("  community $value") if ($main::config_debug);
		}
		elsif ( $name eq 'watchdogtimer') {
			$main::config{WATCHDOGTIMER} = $value;
			&debug("  watchdogtimer $value") if ($main::config_debug);
		}
		elsif ( $name eq 'tempdir') {
			$main::config{TEMPDIR} = $value;
			&debug("  tempdir $value") if ($main::config_debug);
		}
		elsif ( $name eq 'pinger') {
			$main::config{PINGER} = $value;
			&debug("  pinger $value") if ($main::config_debug);
		}
		elsif ( $name eq 'collectors') {
			$main::config{COLLECTORS} = [ split(' ',$value) ];
			&debug("  collectors $value") if ($main::config_debug);
		}
		elsif ( $name eq 'monitors') {
			$main::config{MONITORS} = [ split(' ',$value) ];
			&debug("  monitors $value") if ($main::config_debug);
		}
		elsif ( $name eq 'pagemakers') {
			$main::config{PAGEMAKERS} = [ split(' ', $value) ] ;
			&debug("  pagemaker $value") if ($main::config_debug);
		}
		elsif ( $name eq 'max-port-patterns') {
			$main::config{MAXPORTPATTERNS} = $value;
			&debug("  max-port-patterns $value") if ($main::config_debug);
		}
		elsif ( $name eq 'keeplogs') {
			$value = $1;
			$main::config{KEEPLOGS} = $value;
			&debug("  keeplogs $value") if ($main::config_debug);
		}
		elsif ( $name eq 'force-collection') {
			if ($value =~ /^(yes|y|t|true|on)$/i) { $value = 1; }
			elsif ($value =~ /^(no|n|f|false|off)$/i) { $value = 0; }
			else {
				++$errors;
				&error("read_config_general: unknown value for force-collection ($value)");
				next;
			}
			$main::config{'FORCECOLLECTION'} = $value;
			&debug("  force-collection $value") if ($main::config_debug);
		}
		else {
			++$errors;
			&error("read_config_general: unknown line: $_");
			next;
		}
	}
	close (CONFIG);

# Now some checks to make sure we have required stuff
	unless (defined $main::config{DATADIR}) {
		&error("read_config_general: datadir not defined");
		++$errors;
	}

# Some required stuff can be safetly defaulted
	unless (defined $main::config{DATAPAGEDIR}) {
		$main::config{DATAPAGEDIR} = '/root/3p/facon/data/DATAPAGES';
	}
	unless (defined $main::config{STALETIME}) {
		$main::config{STALETIME} = 30*60;
	}
	unless (defined $main::config{MINUPTIME}) {
		$main::config{MINUPTIME} = 24*60*60;
	}
	unless (defined $main::config{KEEPALERTS}) {
		$main::config{KEEPALERTS} = 24*60*60;
	}
	unless (defined $main::config{LOGDIR}) {
		$main::config{LOGDIR} = $main::config{DATADIR}.'/LOGS';
	}
	unless (defined $main::config{WATCHDOGTIMER}) {
		$main::config{WATCHDOGTIMER} = 300;
	}
	unless (defined $main::config{TEMPDIR}) {
		$main::config{TEMPDIR} = '/root/3p/facon/tmp';
	}
	unless (defined $main::config{MAXPORTPATTERNS}) {
		$main::config{MAXPORTPATTERNS} = 15;
	}
	unless (defined $main::config{FORCECOLLECTION}) {
		$main::config{FORCECOLLECTION} = 1;
	}
	unless (defined $main::config{KEEPLOGS}) {
		$main::config{KEEPLOGS} = 360*24*60*60; # one year less 5 days
	}

	unless (defined $main::config{COLLECTORS}) {
		$main::config{COLLECTORS} = [ 'ping', 'port', 'snmp-route', 'log', 
			'unix-status', 'snmp', 'nt-status' , 'dbi' ];
	}
	unless (defined $main::config{MONITORS}) {
		$main::config{MONITORS} = [ 'ping', 'alert' ] ;
	}
	unless (defined $main::config{PAGEMAKERS}) {
		$main::config{PAGEMAKERS} = [ 'page-writer', 'snmpif-setspeed', 
			'datapage-alert-writer', 'datapage-interfaces', 
			'datapage-inventory', 'datapage-status' ];
	}
	unless( defined $main::config{PAGETEMPLATEDIR}) {
		$main::config{PAGETEMPLATEDIR} = 'page-templates';
	}

	return $errors;
}

#------------------------------------------------- read_config_html ---
sub read_config_html {
	my ($configdir) = @_;
	my $configfile = $configdir .'/html';
	my ($name, $value, $errors);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_html: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading html configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		($name, $value) = /^\s*(\S+)\s+(.+)/;
		$value =~ s/\s+$//;

		if( $name eq 'alertindex') {
			$main::config{HTML}{ALERTINDEX} = $value;
			&debug("  alertindex $value") if ($main::config_debug);
		}
		elsif ($name eq 'alertreport') {
			$main::config{HTML}{ALERTREPORT} = $value;
			&debug("  alertreport $value") if ($main::config_debug);
		}
		elsif ($name eq 'customindex') {
			$main::config{HTML}{CUSTOMINDEX} = $value;
			&debug("  customindex $value") if ($main::config_debug);
		}
		elsif ($name eq 'logreport') {
			$main::config{HTML}{LOGREPORT} = $value;
			&debug("  logreport $value") if ($main::config_debug);
		}
		elsif ($name eq 'overallindex') {
			$main::config{HTML}{OVERALLINDEX} = $value;
			&debug("  overallindex $value") if ($main::config_debug);
		}
		elsif ($name eq 'pingindex') {
			$main::config{HTML}{PINGINDEX} = $value;
			&debug("  pingindex $value") if ($main::config_debug);
		}
		elsif ($name eq 'rrdindex') {
			$main::config{HTML}{RRDINDEX} = $value;
			&debug("  rrdindex $value") if ($main::config_debug);
		}
		elsif ($name eq 'quickindex') {
			$main::config{HTML}{QUICKINDEX} = $value;
			&debug("  quickindex $value") if ($main::config_debug);
		}
		elsif ($name eq 'indices') {
			$main::config{HTML}{INDICES} = $value;
			&debug("  indices $value") if ($main::config_debug);
		}
		elsif ($name eq 'links') {
			$main::config{HTML}{LINKS} = $value;
			&debug("  links $value") if ($main::config_debug);
		}
		elsif ($name eq 'tools') {
			$main::config{HTML}{TOOLS} = $value;
			&debug("  tools $value") if ($main::config_debug);
		}
		elsif ($name eq 'default-tools') {
			push @{$main::config{HTML}{DEFAULTTOOLS}}, split(' ', $value);
			&debug("  default-tools $value") if ($main::config_debug);
		}
		elsif ($name eq 'description') {
			$main::config{HTML}{DESCRIPTION} = $value;
			&debug("  description $value") if ($main::config_debug);
		}
		elsif ($name eq 'ipnumber') {
			$main::config{HTML}{IPNUMBER} = $value;
			&debug("  ipnumber $value") if ($main::config_debug);
		}
		elsif ($name eq 'interfaces') {
			$main::config{HTML}{INTERFACES} = $value;
			&debug("  interfaces $value") if ($main::config_debug);
		}
		elsif ($name eq 'operatingsystem') {
			$main::config{HTML}{OPERATINGSYSTEM} = $value;
			&debug("  operatingsystem $value") if ($main::config_debug);
		}
		elsif ($name eq 'hardware') {
			$main::config{HTML}{HARDWARE} = $value;
			&debug("  hardware $value") if ($main::config_debug);
		}
		elsif ($name eq 'memory-size') {
			$main::config{HTML}{MEMORYSIZE} = $value;
			&debug("  memory-size $value") if ($main::config_debug);
		}
		elsif ($name eq 'uptime') {
			$main::config{HTML}{UPTIME} = $value;
			&debug("  uptime $value") if ($main::config_debug);
		}
		elsif ($name eq 'status') {
			$main::config{HTML}{STATUS} = $value;
			&debug("  status $value") if ($main::config_debug);
		}
		elsif ($name eq 'lastupdateon') {
			$main::config{HTML}{LASTUPDATEON} = $value;
			&debug("  lastupdateon $value") if ($main::config_debug);
		}
		elsif ($name eq 'comment') {
			$main::config{HTML}{COMMENT} = $value;
			&debug("  comment $value") if ($main::config_debug);
		}
		elsif ($name eq 'error') {
			$main::config{HTML}{ERROR} = $value;
			&debug("  error $value") if ($main::config_debug);
		}
		elsif ($name eq 'contact') {
			$main::config{HTML}{CONTACT} = $value;
			&debug("  contact $value") if ($main::config_debug);
		}
		elsif ($name eq 'note') {
			$main::config{HTML}{NOTE} = $value;
			&debug("  note $value") if ($main::config_debug);
		}
		elsif ($name eq 'hostindex') {
			$main::config{HTML}{HOSTINDEX} = $value;
			&debug("  hostindex $value") if ($main::config_debug);
		}
		elsif ($name eq 'groupindex') {
			$main::config{HTML}{GROUPINDEX} = $value;
			&debug("  groupindex $value") if ($main::config_debug);
		}
		elsif ($name eq 'viewindex') {
			$main::config{HTML}{VIEWINDEX} = $value;
			&debug("  viewindex $value") if ($main::config_debug);
		}
		elsif ($name eq 'viewindices') {
			if ($value =~ /^(yes|on|true|1)|(no|off|false|0)$/) {
				$value = (defined $1) ? 1 : 0 ;
			}
			else {
				&error("read_config_html: viewindices must be yes or no, not '$value'");
				++$errors;
				next;
			}
			$main::config{HTML}{VIEWINDICES} = $value;
			&debug("  viewindices $value") if ($main::config_debug);
		}
		elsif ($name eq 'showinterfaces') {
			if ($value =~ /^(yes|on|true|1)|(no|off|false|0)$/) {
				$value = (defined $1) ? 1 : 0 ;
			}
			else {
				&error("read_config_html: showinterfaces must be yes of no, not '$value'");
				++$errors;
				next;
			}
			$main::config{HTML}{SHOWINTERFACES} = $value;
			&debug("  showinterfaces $value") if ($main::config_debug);
		}
		elsif( $name eq 'indexprefix') {
			$main::config{HTML}{INDEXPREFIX} = &do_escapes($value);
			&debug("  indexprefix $value") if ($main::config_debug);
		}
		elsif( $name eq 'indexsuffix') {
			$main::config{HTML}{INDEXSUFFIX} = &do_escapes($value);
			&debug("  indexsuffix $value") if ($main::config_debug);
		}
		elsif( $name eq 'groupprefix') {
			$main::config{HTML}{GROUPPREFIX} = &do_escapes($value);
			&debug("  groupprefix $value") if ($main::config_debug);
		}
		elsif( $name eq 'groupsuffix') {
			$main::config{HTML}{GROUPSUFFIX} = &do_escapes($value);
			&debug("  groupsuffix $value") if ($main::config_debug);
		}
		elsif( $name eq 'toolprefix') {
			$main::config{HTML}{TOOLPREFIX} = &do_escapes($value);
			&debug("  toolprefix $value") if ($main::config_debug);
		}
		elsif( $name eq 'toolsuffix') {
			$main::config{HTML}{TOOLSUFFIX} = &do_escapes($value);
			&debug("  toolsuffix $value") if ($main::config_debug);
		}
		elsif( $name eq 'hostprefix') {
			$main::config{HTML}{HOSTPREFIX} = &do_escapes($value);
			&debug("  hostprefix $value") if ($main::config_debug);
		}
		elsif( $name eq 'hostsuffix') {
			$main::config{HTML}{HOSTSUFFIX} = &do_escapes($value);
			&debug("  hostsuffix $value") if ($main::config_debug);
		}
		elsif( $name eq 'linkprefix') {
			$main::config{HTML}{LINKPREFIX} = &do_escapes($value);
			&debug("  linkprefix $value") if ($main::config_debug);
		}
		elsif( $name eq 'linksuffix') {
			$main::config{HTML}{LINKSUFFIX} = &do_escapes($value);
			&debug("  linksuffix $value") if ($main::config_debug);
		}
		elsif( $name eq 'outofrangeprefix') {
			$main::config{HTML}{OUTOFRANGEPREFIX} = &do_escapes($value);
			&debug("  outofrangeprefix $value") if ($main::config_debug);
		}
		elsif( $name eq 'outofrangesuffix') {
			$main::config{HTML}{OUTOFRANGESUFFIX} = &do_escapes($value);
			&debug("  outofrangesuffix $value") if ($main::config_debug);
		}
		elsif ($name eq 'alertflagwarn') {
			$main::config{HTML}{ALERTFLAGWARN} = $value;
			&debug("  alertflagwarn $value") if ($main::config_debug);
		}
		elsif ($name eq 'alertflagerror') {
			$main::config{HTML}{ALERTFLAGERROR} = $value;
			&debug("  alertflagerror $value") if ($main::config_debug);
		}
		elsif ($name eq 'alertflagcritical') {
			$main::config{HTML}{ALERTFLAGCRITICAL} = $value;
			&debug("  alertflagcritical $value") if ($main::config_debug);
		}

# From [general] and not properly integrated
		elsif ($name eq 'htmldir') {
			$main::config{HTMLDIR} = $value;
			&debug("  htmldir $main::config{HTMLDIR}") if ($main::config_debug);
		}
		elsif ($name eq 'htmlurl') {
			$main::config{HTMLURL} = $value;
			&debug("  htmlurl $main::config{HTMLURL}") if ($main::config_debug);
		}
		elsif ($name eq 'cgidir') {
			$main::config{CGIDIR} = $value;
			&debug("  cgidir $main::config{CGIDIR}") if ($main::config_debug);
		}
		elsif ($name eq 'cgiurl') {
			$main::config{CGIURL} = $value;
			&debug("  cgiurl $main::config{CGIURL}") if ($main::config_debug);
		}
		elsif ($name eq 'viewdir') {
			$main::config{HTML}{VIEWDIR} = $value;
			&debug("  viewdir $main::config{HTML}{VIEWDIR}") if ($main::config_debug);
		}
		elsif ($name eq 'viewurl') {
			$main::config{HTML}{VIEWURL} = $value;
			&debug("  viewurl $main::config{HTML}{VIEWURL}") if ($main::config_debug);
		}
		elsif ($name eq 'motdfile') {
			$main::config{HTML}{MOTDFILE} = $value;
			&debug("  motdfile $main::config{HTML}{MOTDFILE}") if ($main::config_debug);
		}
		elsif ($name eq 'thumbnail') {
			($main::config{THUMBWIDTH}, $main::config{THUMBHEIGHT}) =
				split('\s?x\s?',$value,2);
			unless (defined $main::config{THUMBHEIGHT}) {
				++$errors;
				&error("read_config_html: invalid thumbnail value '$value'");
				next;
			}
			&debug("  thumbnail $main::config{THUMBWIDTH}x$main::config{THUMBHEIGHT}")
				if ($main::config_debug);
		}
		elsif ($name eq 'metadata') {
			($main::config{METADIR}, $main::config{METASUFFIX}) =
				split(' ',$value);
			unless (defined $main::config{METASUFFIX}) {
				++$errors;
				&error("read_config_html: invalid metadata value '$value'");
				next;
			}
			&debug("  metadata $main::config{METADIR} $main::config{METASUFFIX}")
				if ($main::config_debug);
		}
		elsif ($name eq 'webmaster') {
			$main::config{WEBMASTER} = $value;
			&debug("  webmaster $main::config{WEBMASTER}") if ($main::config_debug);
		}
		elsif ($name eq 'background') {
			$main::config{BACKGROUND} = $value;
			&debug("  background $main::config{BACKGROUND}") if ($main::config_debug);
		}
		elsif ($name eq 'htmlrefresh') {
			$main::config{HTMLREFRESH} = $value;
			&debug("  htmlrefresh = $main::config{HTMLREFRESH}") if ($main::config_debug);
		}
		elsif ($name eq 'upstatus') {
			$main::config{UPSTATUS} = $value;
			&debug("  upstatus = $main::config{UPSTATUS}") if ($main::config_debug);
		}
		elsif ($name eq 'upunstablestatus') {
			$main::config{UPUNSTABLESTATUS} = $value;
			&debug("  upunstablestatus = $main::config{UPUNSTABLESTATUS}") if ($main::config_debug);
		}
		elsif ($name eq 'downstatus') {
			$main::config{DOWNSTATUS} = $value;
			&debug("  downstatus = $main::config{DOWNSTATUS}") if ($main::config_debug);
		}
		elsif ($name eq 'downunstablestatus') {
			$main::config{DOWNUNSTABLESTATUS} = $value;
			&debug("  downunstablestatus = $main::config{DOWNUNSTABLESTATUS}") if ($main::config_debug);
		}
		elsif ($name eq 'okstatus') {
			$main::config{OKSTATUS} = $value;
			&debug("  okstatus = $main::config{OKSTATUS}") if ($main::config_debug);
		}
		elsif ($name eq 'warnstatus') {
			$main::config{WARNSTATUS} = $value;
			&debug("  warnstatus = $main::config{WARNSTATUS}") if ($main::config_debug);
		}
		elsif ($name eq 'errorstatus') {
			$main::config{ERRORSTATUS} = $value;
			&debug("  errorstatus = $main::config{ERRORSTATUS}") if ($main::config_debug);
		}
		elsif ($name eq 'criticalstatus') {
			$main::config{CRITICALSTATUS} = $value;
			&debug("  criticalstatus = $main::config{CRITICALSTATUS}") if ($main::config_debug);
		}
		elsif ($name eq 'logourl') {
			$main::config{LOGOURL} = $value;
			&debug("  logourl $main::config{LOGOURL}") if ($main::config_debug);
		}
		elsif ($name eq 'homeurl') {
			$main::config{HOMEURL} = $value;
			&debug("  homeurl $main::config{HOMEURL}") if ($main::config_debug);
		}
		elsif ($name eq 'topurl') {
			$main::config{TOPURL} = $value;
			&debug("  topurl $main::config{TOPURL}") if ($main::config_debug);
		}
		elsif ($name eq 'srcurl') {
			$main::config{SRCURL} = $value;
			&debug("  srcurl $main::config{SRCURL}") if ($main::config_debug);
		}
		elsif ($name eq 'rrdcgi') {
			$main::config{RRDCGI} = $value;
			&debug("  rrdcgi $value") if ($main::config_debug);
		}
		elsif ( $name eq 'imagetype') {
			if ($value =~ /^(gif|png)$/i) {
				$main::config{IMAGETYPE} = uc $1;
			}
			else {
				++$errors;
				&error("read_config_html: unknown imagetype ($value)");
				next;
			}
			&debug("  imagetype $1") if ($main::config_debug);
		}
		elsif ( $name eq 'uptimeflag') {
			$main::config{HTML}{UPTIMEFLAG} = $value;
			&debug("  uptimeflag $value") if ($main::config_debug);
		}
		elsif ( $name eq 'keepimages') {
			$main::config{HTML}{KEEPIMAGES} = $value;
			&debug("  keepimages $value") if ($main::config_debug);
		}
		else {
			++$errors;
			&error("read_config_html: unknown line: $_");
			next;
		}
	}
	close (CONFIG);

# Some defaults
	unless (defined $main::config{HTML}{ALERTINDEX}) {
		$main::config{HTML}{ALERTINDEX} = 'Alert Index';
	}
	unless (defined $main::config{HTML}{ALERTREPORT}) {
		$main::config{HTML}{ALERTREPORT} = 'Alert Report';
	}
	unless (defined $main::config{HTML}{CUSTOMINDEX}) {
		$main::config{HTML}{CUSTOMINDEX} = 'Custom Index'; }
	unless (defined $main::config{HTML}{LOGREPORT}) {
		$main::config{HTML}{LOGREPORT} = 'Log Report'; }
	unless (defined $main::config{HTML}{OVERALLINDEX}) {
		$main::config{HTML}{OVERALLINDEX} = 'Overall Index'; }
	unless (defined $main::config{HTML}{PINGINDEX}) {
		$main::config{HTML}{PINGINDEX} = 'Ping Index'; }
	unless (defined $main::config{HTML}{RRDINDEX}) {
		$main::config{HTML}{RRDINDEX} = 'RRD Index'; }
	unless (defined $main::config{HTML}{QUICKINDEX}) {
		$main::config{HTML}{QUICKINDEX} = 'Quick Index'; }
	unless (defined $main::config{HTML}{INDICES}) {
		$main::config{HTML}{INDICES} = 'Indices'; }
	unless (defined $main::config{HTML}{LINKS}) {
		$main::config{HTML}{LINKS} = 'Links'; }
	unless (defined $main::config{HTML}{TOOLS}) {
		$main::config{HTML}{TOOLS} = 'Tools'; }
	unless (defined $main::config{HTML}{DESCRIPTION}) {
		$main::config{HTML}{DESCRIPTION} = 'Description'; }
	unless (defined $main::config{HTML}{IPNUMBER}) {
		$main::config{HTML}{IPNUMBER} = 'IP #'; }
	unless (defined $main::config{HTML}{INTERFACES}) {
		$main::config{HTML}{INTERFACES} = 'Interfaces'; }
	unless (defined $main::config{HTML}{OPERATINGSYSTEM}) {
		$main::config{HTML}{OPERATINGSYSTEM} = 'Operating System';
	}
	unless (defined $main::config{HTML}{HARDWARE}) {
		$main::config{HTML}{HARDWARE} = 'Hardware'; }
	unless (defined $main::config{HTML}{MEMORYSIZE}) {
		$main::config{HTML}{MEMORYSIZE} = 'Memory'; }
	unless (defined $main::config{HTML}{UPTIME}) {
		$main::config{HTML}{UPTIME} = 'Uptime'; }
	unless (defined $main::config{HTML}{STATUS}) {
		$main::config{HTML}{STATUS} = 'Status'; }
	unless (defined $main::config{HTML}{LASTUPDATEON}) {
		$main::config{HTML}{LASTUPDATEON} = 'This page last updated on';
	}
	unless (defined $main::config{HTML}{COMMENT}) {
		$main::config{HTML}{COMMENT} = 'Comment'; }
	unless (defined $main::config{HTML}{CONTACT}) {
		$main::config{HTML}{CONTACT} = 'Contact'; }
	unless (defined $main::config{HTML}{NOTE}) {
		$main::config{HTML}{NOTE} = 'Note'; }
	unless (defined $main::config{HTML}{HOSTINDEX}) {
		$main::config{HTML}{HOSTINDEX} = 'Host Index'; }
	unless (defined $main::config{HTML}{GROUPINDEX}) {
		$main::config{HTML}{GROUPINDEX} = 'Group Index'; }
	unless (defined $main::config{HTML}{VIEWINDEX}) {
		$main::config{HTML}{VIEWINDEX} = 'View Index'; }
	unless (defined $main::config{HTML}{VIEWINDICES}) {
		$main::config{HTML}{VIEWINDICES} = 1; }
	unless (defined $main::config{HTML}{SHOWINTERFACES}) {
		$main::config{HTML}{SHOWINTERFACES} = 1; }
	unless (defined $main::config{HTML}{VIEWDIR}) {
		$main::config{HTML}{VIEWDIR} = $main::config{HTMLDIR} .'/VIEWS';
	}
	unless (defined $main::config{HTML}{VIEWURL}) {
		$main::config{HTML}{VIEWURL} = $main::config{HTMLURL} .'/VIEWS';
	}
	unless (defined $main::config{HTML}{MOTDFILE}) {
		$main::config{HTML}{MOTDFILE} = $main::config{HTMLDIR} .'/MOTD.html';
	}
	unless (defined $main::config{HTML}{KEEPIMAGES}) {
		$main::config{HTML}{KEEPIMAGES} = 24*60*60;
	}
	unless (defined $main::config{HTML}{DEFAULTTOOLS}) {
		$main::config{HTML}{DEFAULTTOOLS} = [ 'ping', 'traceroute',
			'availability', 'status' ];
	}

# Now some checks to make sure we have required stuff
	unless (defined $main::config{HTMLDIR}) {
		&error("read_config_html: htmldir not defined");
		++$errors;
	}
	unless (defined $main::config{HTMLURL}) {
		&error("read_config_html: htmlurl not defined");
		++$errors;
	}
	unless (defined $main::config{CGIDIR}) {
		&error("read_config_html: cgidir not defined");
		++$errors;
	}
	unless (defined $main::config{CGIURL}) {
		&error("read_config_html: cgiurl not defined");
		++$errors;
	}
	unless (defined $main::config{WEBMASTER}) {
		&error("read_config_html: webmaster not defined");
		++$errors;
	}

# Some required stuff can be safetly defaulted
	unless (defined $main::config{THUMBWIDTH}) {
		$main::config{THUMBWIDTH} = 30;
	}
	unless (defined $main::config{THUMBHEIGHT}) {
		$main::config{THUMBHEIGHT} = 30;
	}
	unless (defined $main::config{METADIR}) {
		$main::config{METADIR} = '.web';
	}
	unless (defined $main::config{METASUFFIX}) {
		$main::config{METASUFFIX} = '.meta';
	}
	unless (defined $main::config{BACKGROUND}) {
		$main::config{BACKGROUND} = 'bgcolor="white"';
	}
	unless (defined $main::config{UPSTATUS}) {
		$main::config{UPSTATUS} = 'UP';
	}
	unless (defined $main::config{UPUNSTABLESTATUS}) {
		$main::config{UPUNSTABLESTATUS} = 'UPUNSTABLE';
	}
	unless (defined $main::config{DOWNSTATUS}) {
		$main::config{DOWNSTATUS} = 'DOWN';
	}
	unless (defined $main::config{DOWNUNSTABLESTATUS}) {
		$main::config{DOWNUNSTABLESTATUS} = 'DOWNUNSTABLE';
	}
	unless (defined $main::config{LOGOURL}) {
		$main::config{LOGOURL} = 'LOGO';
	}
	unless (defined $main::config{HOMEURL}) {
		$main::config{HOMEURL} = 'HOME';
	}
	unless (defined $main::config{TOPURL}) {
		$main::config{TOPURL} = 'TOP';
	}
	unless (defined $main::config{SRCURL}) {
		$main::config{SRCURL} = 'http://facon.sourceforge.net/release/';
	}
	unless (defined $main::config{IMAGETYPE}) {
		$main::config{IMAGETYPE} = 'PNG';
	}
	unless (defined $main::config{HTMLREFRESH}) {
		$main::config{HTMLREFRESH} = 300;
	}
	unless (defined $main::config{HTML}{UPTIMEFLAG}) {
		$main::config{HTML}{UPTIMEFLAG} = 
			'&nbsp;<span style="background-color: red">*</span>';
	}
	unless (defined $main::config{HTML}{ALERTFLAGWARN}) {
		$main::config{HTML}{ALERTFLAGWARN} = 
			'&nbsp;<span CLASS="WARN">A</span>';
	}
	unless (defined $main::config{HTML}{ALERTFLAGERROR}) {
		$main::config{HTML}{ALERTFLAGERROR} = 
			'&nbsp;<span CLASS="ERROR">A</span>';
	}
	unless (defined $main::config{HTML}{ALERTFLAGCRITICAL}) {
		$main::config{HTML}{ALERTFLAGCRITICAL} = 
			'&nbsp;<span CLASS="CRITICAL">A</span>';
	}
	unless (defined $main::config{HTML}{INDEXPREFIX}) {
		$main::config{HTML}{INDEXPREFIX} = ' ';
	}
	unless (defined $main::config{HTML}{INDEXSUFFIX}) {
		$main::config{HTML}{INDEXSUFFIX} = ' ';
	}
	unless (defined $main::config{HTML}{GROUPPREFIX}) {
		$main::config{HTML}{GROUPPREFIX} = 
			'<TABLE WIDTH="100%"><TR><TD BGCOLOR="#DDDDDD"><FONT="+2"><B>';
	}
	unless (defined $main::config{HTML}{GROUPSUFFIX}) {
		$main::config{HTML}{GROUPSUFFIX} = 
			'</B></FONT></TD></TR></TABLE>' . "\n";
	}
	unless (defined $main::config{HTML}{TOOLPREFIX}) {
		$main::config{HTML}{TOOLPREFIX} = ' ';
	}
	unless (defined $main::config{HTML}{TOOLSUFFIX}) {
		$main::config{HTML}{TOOLSUFFIX} = ' ';
	}
	unless (defined $main::config{HTML}{HOSTPREFIX}) {
		$main::config{HTML}{HOSTPREFIX} = '[';
	}
	unless (defined $main::config{HTML}{HOSTSUFFIX}) {
		$main::config{HTML}{HOSTSUFFIX} = ']';
	}
	unless (defined $main::config{HTML}{LINKPREFIX}) {
		$main::config{HTML}{LINKPREFIX} = ' ';
	}
	unless (defined $main::config{HTML}{LINKSUFFIX}) {
		$main::config{HTML}{LINKSUFFIX} = ' ';
	}
	unless (defined $main::config{HTML}{OUTOFRANGEPREFIX}) {
		$main::config{HTML}{OUTOFRANGEPREFIX} = '<SPAN STYLE="background-color:yellow">';
	}
	unless (defined $main::config{HTML}{OUTOFRANGESUFFIX}) {
		$main::config{HTML}{OUTOFRANGESUFFIX} = '</SPAN>';
	}

	return $errors;
}

#------------------------------------------------- read_config_times ---
sub read_config_times {
	my ($configdir) = @_;
	my $configfile = $configdir .'/times';
	my ($name, $value, $errors, $start, $finish);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_times: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading times configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		($name, $start, $finish) = split(' ', $_, 3);
		if ($start =~ /^\s*([-0-9\* ]+)\s*$/) {
			$start = eval $1;
		}
		else {
			++$errors;
			&error("read_config_times: start expression invalid: $start");
			next;
		}
		if ($finish =~ /^\s*([-0-9\* ]+)\s*$/) {
			$finish = eval $1;
		}
		else {
			++$errors;
			&error("read_config_times: finish expression invalid: $finish");
			next;
		}
		$main::config{TIME}{$name}{START} = $start;
		$main::config{TIME}{$name}{FINISH} = $finish;
		&debug("  $name start=$main::config{TIME}{$name}{START}, " .
			"finish=$main::config{TIME}{$name}{FINISH}") if ($main::config_debug);
	}
	close (CONFIG);

	unless (defined $main::config{TIME}) {
		&errors("read_config_times: missing times config-file");
		++$errors;
	}

	return $errors;
}

#------------------------------------------------- read_config_colors ---
sub read_config_colors {
	my ($configdir) = @_;
	my $configfile = $configdir .'/colors';
	my ($name, $value, $errors);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_colors: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading colors configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		($name, $value) = split(' ',$_,2);

		$name = uc $name;
		$main::config{COLOR}{$name} = $value;
		&debug("  $name value='$value'") if ($main::config_debug);
	}
	close (CONFIG);

	unless (defined $main::config{COLOR}) {
		&error("read_config_colors: missing colors config-file");
		++$errors;
	}

	return $errors;
}

#------------------------------------------------- read_config_archives ---
sub read_config_archives {
	my ($configdir) = @_;
	my $configfile = $configdir .'/archives';
	my ($name, $value, $errors);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_archives: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading archives configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		($name, $value) = split(' ',$_,2);

		$main::config{ARCHIVE}{$name} = $value;
		&debug("  $name value='$value'") if ($main::config_debug);
	}
	close (CONFIG);

	unless (defined $main::config{ARCHIVE}) {
		&error("read_config_archives: missing archives config-file");
		++$errors;
	}

	return $errors;
}

#------------------------------------------------- read_config_links ---
sub read_config_links {
	my ($configdir) = @_;
	my $configfile = $configdir .'/links';
	my ($name, $url, $image, $errors);
	$errors = 0;

	unless (-f $configfile or -l $configfile) {
		&debug("no links config-file; skipped") if ($main::config_debug);
		return 0;
	}

	open (CONFIG, "<$configfile") or do {
		&error("read_config_links: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading links configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		($name, $url, $image) = split(' ', $_, 3);

		push @{$main::config{LINKS}}, 
			{NAME => $name, URL => $url, IMAGE => $image };
	}
	close (CONFIG);

	unless (defined $main::config{LINKS}) {
		&debug("missing links config-file; skipped") if ($main::config_debug);
	}
	return $errors;
}

#------------------------------------------------- read_config_tools ---
sub read_config_tools {
	my ($configdir) = @_;
	my $configfile = $configdir .'/tools';
	my ($name, $value, $errors);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_tools: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading tools configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		($name, $value) = split(' ',$_,2);

		$main::config{TOOL}{$name} = $value;
		&debug("  $name value='$value'") if ($main::config_debug);
	}
	close (CONFIG);

	unless (defined $main::config{TOOL}) {
		&error("read_config_tools: missing tools config-file; skipped");
	}

	return $errors;
}

#------------------------------------------------- read_config_remotepings ---
sub read_config_remotepings {
	my ($configdir) = @_;
	my $configfile = $configdir .'/remotepings';
	my ($name, $value, $errors);
	$errors = 0;

	unless (-f $configfile or -l $configfile) {
		&debug("no remotepings config-file; skipped") if ($main::config_debug);
		return 0;
	}

	open (CONFIG, "<$configfile") or do {
		&error("read_config_remotepings: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading remotepings configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);

		if (/^(\S+)\s*$/) {
			$name = $1;
			push @{$main::config{REMOTEPING}}, $name;
		}
		else {
			++$errors;
			&error("read_config_remotepings: unknown line: $_");
			next;
		}
		&debug("  $name") if ($main::config_debug);
	}
	close (CONFIG);

	unless (defined $main::config{REMOTEPING}) {
		&debug("missing remoteping config-file; skipped") if ($main::config_debug);
	}

	return $errors;
}

#------------------------------------------------- read_config_scripts ---
sub read_config_scripts {
	my ($configdir) = @_;

	unless (-d $configdir .'/scripts' or -l $configdir .'/scripts') {
		&error("read_config_scripts: missing $configdir/scripts config-subdir");
		return 1;
	}

	my @configfiles = &list_files ($configdir .'/scripts');
	my ($name, $value, $errors, $script);
	$errors = 0;

	&debug("") if ($main::config_debug);
	&debug("reading scripts configuration") if ($main::config_debug);

	foreach my $configfile (@configfiles) {
		open (CONFIG, "<$configfile") or do {
			++$errors;
			&error("read_config_scripts: can't open $configfile: $!");
			next;
		};
		$script = &basename($configfile);
		if ($script =~ /-$/) { $script .= '*'; } # for wildcard scripts
		while (<CONFIG>) {
			chomp;
			next if (/^#/ or /^\s*$/);
			($name, $value) = split(' ',$_,2);

			if ($name =~ /^(ok|warn|error|critical)$/i) {
				$main::config{SCRIPT}{$script}{uc $name} = $value;
				push @{$main::config{SCRIPT}{$script}{TESTS}}, uc $name;
				&debug("  $name value='$value'") if ($main::config_debug);
			}
			elsif ($name =~ /^(send|timeout|port|proxy|infopattern|valuepattern)$/i) {
				$value =~ s/\\n/\n/g;
				$value =~ s/\\r/\r/g;
				$main::config{SCRIPT}{$script}{uc $name} = $value;
				&debug("  $name value='$value'") if ($main::config_debug);
			}
			else {
				++$errors;
				&error("read_config_scripts: unknown line: $_");
				next;
			}
		}
		if (defined $main::config{SCRIPT}{$script}{TESTS} and not
				defined $main::config{SCRIPT}{$script}{SEND}) {
			++$errors;
			&error("read_config_scripts: script $script has status tests, but no send string");
		}
		close (CONFIG);
	}

	unless (defined $main::config{SCRIPT}) {
		&error("read_config_scripts: missing scripts config-file; skipped");
	}

	return $errors;
}

#------------------------------------------------- read_config_alerts ---
sub read_config_alerts {
	my ($configdir) = @_;
	my $configfile = $configdir .'/alerts';
	my ($errors);
	my ($level, $host, $realrrd, $var, $mintime, $interval, 
		@addresses);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_alerts: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading alerts configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);

		($level, $host, $realrrd, $var, $mintime, $interval, 
			@addresses) = split(' ',$_);
		$level = uc $level;
		if ($level eq '*') { $level = '.*'; }
		if ($host eq '*') { $host = '.*'; }
		if ($realrrd eq '*') { $realrrd = '.*'; }
		if ($var eq '*') { $var = '.*'; }
		push @{$main::config{ALERT}} , {
				LEVEL => $level,
				HOST => $host,
				RRD => $realrrd,
				VAR => $var,
				MINTIME => $mintime,
				INTERVAL => $interval,
				ADDRESSES => [ @addresses ],
			};
		&debug("  level=$level, host=$host, rrd=$realrrd, var=$var, " .
			"mintime=$mintime, interval=$interval, " .
			"addresses=".join(',',@addresses)) if ($main::config_debug);
	}
	close (CONFIG);

	unless (defined $main::config{ALERT}) {
		&error("read_config_alerts: missing alerts config-file; skipped");
	}

	return $errors;
}

#------------------------------------------------- read_config_oids ---
sub read_config_oids {
	my ($configdir) = @_;
	my $configfile = $configdir .'/oids';
	my ($name, $value, $errors);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_oids: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading oids configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		($name, $value) = split(' ',$_,2);

		$main::config{OID}{$name} = $value;
		&debug("  oid $name = $value") if ($main::config_debug);
	}
	close (CONFIG);

	unless (defined $main::config{OID}) {
		&error("read_config_oids: missing oids config-file; skipped");
	}

	return $errors;
}

#------------------------------------------------- read_config_rrds ---
sub read_config_rrds {
	my ($configdir) = @_;
	my $errors = 0;
	
	unless (-d $configdir .'/rrds' or -l $configdir .'/rrds') {
		&error("read_config_rrds: missing $configdir/rrds config-subdir");
		return 1;
	}

	my @configfiles = &list_files ($configdir .'/rrds');
	my ($collector, $name, $alias, $ds, $extra, $var, $relation, $values,
		$port, $oidname, $fulloidname, $statusfile, $variable, $graph,
		$wildrrd, $real_collector, $sub_collector, $status, $function);

	&debug("") if ($main::config_debug);
	&debug("reading rrds configuration") if ($main::config_debug);

	foreach my $configfile (@configfiles) {
		open (CONFIG, "<$configfile") or do {
			&error("read_config_rrds: can't open $configfile: $!");
			next;
		};
		$wildrrd = &basename($configfile);
		&debug("") if ($main::config_debug);
		&debug("rrd $wildrrd") if ($main::config_debug);
		if (substr($wildrrd,length($wildrrd)-1) eq '-') {
			$wildrrd .= '*';
			&debug("  wildcard '*' added") if ($main::config_debug);
		}
		while (<CONFIG>) {
			chomp;
			next if (/^#/ or /^\s*$/);

			if (/^step\s+(\d+)\s*$/i) {
				$main::config{RRD}{$wildrrd}{STEP} = $1;
				&debug("  step $1") if ($main::config_debug);
			}
			elsif (/^(collector|source)\s+(\S+)\s*$/i) {
				$collector = $2;
				($real_collector, $sub_collector) = split('\s*=\s*', 
					$collector,2);
				$main::config{RRD}{$wildrrd}{SOURCE} = $real_collector;
				if (defined $sub_collector) {
					$main::config{COLLECTOR}{$real_collector}{RRD}{$wildrrd} =
						$sub_collector;
				}
				else {
					$main::config{COLLECTOR}{$real_collector}{RRD}{$wildrrd}=1;
				}
				&debug("  source $collector") if ($main::config_debug);
			}
			elsif (/^data\s+(\S+)\s+(\S+)(\s+(.*))?$/i) {
				($name, $alias) = split('=',$1,2);
				$name = lc $name;
				unless (defined $alias) { $alias = $name; }
				$alias = lc $alias;
				$ds = $2;
				$extra = $4;

				$main::config{RRD}{$wildrrd}{DS}{$name}{ALIAS} = $alias;
				$main::config{RRD}{$wildrrd}{DS}{$name}{DSDEF} = $ds;
				$main::config{RRD}{$wildrrd}{DS}{$name}{EXTRA} = $extra
					unless (defined $extra and
						$extra =~ /^\s*$/);
				push @{$main::config{RRD}{$wildrrd}{DATANAMES}}, 
					$name;
				&debug("  data name=$name, alias=$alias, ds=$ds, extra=". 
					((defined $extra) ? $extra : '-undefined-')) 
					if ($main::config_debug);
			}
			elsif (/^archives\s+(.*)/i) {
				$main::config{RRD}{$wildrrd}{ARCHIVES} = 
					[split(' ',$1)];
				&debug("  archives $1") if ($main::config_debug);
			}
			elsif (/^times\s+(.*)/i) {
				$main::config{RRD}{$wildrrd}{TIMES} = 
					[split(' ',$1)];
				&debug("  times $1") if ($main::config_debug);
				foreach my $time (@{$main::config{RRD}{$wildrrd}{TIMES}}) {
					unless( defined $main::config{TIME}{$time}) {
						&error('unknown time (', $time, ') in definition of ',
							$wildrrd);
						++$errors;
					}
				}
			}
			elsif (/^alert\s+([a-z0-9_]+)\s+([<=>]|delta[<>]|<(day|week|month)stddev)\s+(-?\d+(\s+-?\d+){0,2})/i) {
				($var, $relation, $values) =
					($1, $2, $4);

				unless (defined $main::config{RRD}{$wildrrd}{DS}{$var}) {
					++$errors;
					&error("read_config_rrds($wildrrd): unknown variable ($var) in rrd $wildrrd: $_");
					next;
				}
				$main::config{RRD}{$wildrrd}{ALERT}{$var}{RELATION} = $relation;
				@{$main::config{RRD}{$wildrrd}{ALERT}{$var}{THRESHOLDS}} = split(' ',$values);
				&debug("  alert var=$var, rel=$relation, val=$values") if ($main::config_debug);
			}
			elsif (/^alert\s+([a-z0-9_]+)\s+nodata\s+(\S+)/i) {
				($var, $status) = ($1, uc $2);
				unless (defined $main::statuses{$status}) {
					&error("read_config_rrds($wildrrd): unknown status for nodata alert '$status' for rrd $wildrrd");
					++$errors;
					next;
				}
				$status = $main::statuses{$status};
				$main::config{RRD}{$wildrrd}{ALERT}{$var}{NODATA} = $status;
				&debug("  alert $wildrrd $var nodata $status") 
					if ($main::config_debug);
			}
			elsif (/^port\s+(\d+)\s*$/i) {
				$port = $1;
				$main::config{RRD}{$wildrrd}{PORT} = $port;
				&debug("  port $port") if ($main::config_debug);
			}
			elsif (/^oid\s+(\S+)\s*$/i) {
				$fulloidname = $1;
				($oidname) = split('\.',$fulloidname,2);
				if (defined $main::config{OID}{$oidname}) {
					push @{$main::config{RRD}{$wildrrd}{OIDS}}, $fulloidname;
				}
				else {
					++$errors;
					&error('read_config_rrds(', $wildrrd,
						'): unknown OID name (', $oidname, ') for rrd ',
						$wildrrd);
					next;
				}
			}
			# Stores the current value of an RRD in a status file
			elsif (/^currentvalue\s+([-a-zA-Z0-9._]+)\s+(.+)$/i) {
				$statusfile = $1;
				$variable = $2;

				# Deal with functions
				if( $variable =~ /^\&([a-zA-Z0-9_]+)\(([^\)]+)\)$/) {
					$function = $1;
					$variable = $2;
				}
				else { undef $function; }

				$main::config{RRD}{$wildrrd}{CURRENTVALUE}{$variable}{STATUSFILE} = $statusfile;
				$main::config{RRD}{$wildrrd}{CURRENTVALUE}{$variable}{FUNCTION} = $function;
				&debug("  currentvalue $statusfile $variable")
					if ($main::config_debug);
			}
			elsif (/^available\s+(.+?)\s*$/i) {
				$main::config{RRD}{$wildrrd}{AVAILABLE} = $1;
				&debug("  available $1") if ($main::config_debug);
			}
			elsif( /^keys\s+([-a-zA-Z_0-9\s]+)$/i) {
				&debug("  keys $1") if( $main::config_debug);
				my @keys = split(' ', $1);
				foreach my $key (@keys) {
					next if( length($key) == 0);
					$main::config{RRD}{$wildrrd}{KEY}{$key} = 1;
				}
			}
			elsif( /^connect\s+(\S+)/i) {
				&debug("  connect $1") if( $main::config_debug);
				$main::config{RRD}{$wildrrd}{DBICONNECT} = lc $1;
			}
			elsif( /^select\s+(\S+)/i) {
				&debug("  select $1") if( $main::config_debug);
				$main::config{RRD}{$wildrrd}{DBISELECT} = lc $1;
			}
			elsif( /^multirowid\s+(\d+)/i) {
				&debug("  multirowid $1") if( $main::config_debug);
				$main::config{RRD}{$wildrrd}{DBIMULTIROWID} = $1 - 1;
			}
			elsif (/^graph\s+(\S+)(\s+desc=('([^']+)'|"([^"]+)"))?\s*$/i) {
				$graph = $1;
				if (defined $4) {
					$main::config{RRD}{$wildrrd}{GRAPHDESC}{$graph} = $4;
				}
				elsif (defined $5) {
					$main::config{RRD}{$wildrrd}{GRAPHDESC}{$graph} = $5;
				}
				push @{$main::config{RRD}{$wildrrd}{GRAPHS}}, $graph;
				&debug("  graph $graph") if ($main::config_debug);
			}
			elsif (/\s+(.*)/) { # graph continuation
				&debug("    make_array adding to graph $graph")
					if ($main::config_debug);
				push @{$main::config{RRD}{$wildrrd}{GRAPH}{$graph}},
					&make_array($1);
				&debug("    $1") if ($main::config_debug);
			}
			else {
				++$errors;
				&error("read_config_rrds($wildrrd): unknown line: $_");
				next;
			}
		}
		close (CONFIG);
	}

	unless (defined $main::config{RRD}) {
		&error("read_config_rrds: missing rrd config-files");
		++$errors;
	}

	return $errors;
}

#------------------------------------------------- read_config_customgraphs ---
sub read_config_customgraphs {
	my ($configdir) = @_;

	unless (-d $configdir .'/customgraphs' or -l $configdir .'/customgraphs') {
		&error("read_config_customgraphs: missing $configdir/customgraphs config-subdir");
		return 1;
	}

	my @configfiles = &list_files( $configdir .'/customgraphs');
	my ($name, $value, $errors, $customgraph);
	$errors = 0;

	&debug("") if ($main::config_debug);
	&debug("reading customgraphs configuration") if ($main::config_debug);

	foreach my $configfile (@configfiles) {
		open (CONFIG, "<$configfile") or do {
			&error("can't open $configfile: $!");
			++$errors;
			next;
		};
		$customgraph = &basename($configfile);
		&debug("customgraph $customgraph") if ($main::config_debug);
		push @{$main::config{CUSTOMGRAPHS}}, $customgraph;
		while (<CONFIG>) {
			chomp;
			next if (/^#/ or /^\s*$/);
			($name, $value) = split(' ',$_,2);

			if (/^desc\s+(.*)$/i) {
				$main::config{CUSTOMGRAPH}{$customgraph}{DESC} = $1;
				&debug("  desc = $1") if ($main::config_debug);
			}
			elsif (/^times\s+(.*)/i) {
				@{$main::config{CUSTOMGRAPH}{$customgraph}{TIMES}} = split(' ',$1);
				&debug("  times = $1") if ($main::config_debug);
			}
			elsif (/^\s+(.*)/i) {
				push @{$main::config{CUSTOMGRAPH}{$customgraph}{GRAPH}}, &make_array($1);
				&debug("    $1") if ($main::config_debug);
			}
			else {
				++$errors;
				&error("read_config_customgraphs($customgraph): unknown line: $_");
			}
		}
		close (CONFIG);
	}

	unless (defined $main::config{CUSTOMGRAPH}) {
		&debug("missing customgraphs config-files;skipped") if ($main::config_debug);;
	}

	return $errors;
}

#------------------------------------------------- read_config_hosts ---
sub read_config_hosts {
	my ($configdir, $dir, $key) = @_;
	my $singular;
	if ($dir =~ /(.*)s$/) { $singular = $1; }
	else { $singular = $dir; }

	my $hosts_config_dir = $configdir .'/'. $dir;
	unless (-d $hosts_config_dir or -l $hosts_config_dir) {
		&error("read_config_hosts: missing $hosts_config_dir config-subdir");
		return 1;
	}

	my @configfiles = &list_files( $hosts_config_dir);
	my ($name, $value, $errors, $group, $tmp, @aliases, $lat, $lon, $desc,
		$email, $realrrd, $extra, $wildrrd, $collector, $graph,
		$var, $relation, $values, @keys, $host, $rrddesc, $port, $status,
		$ntserver, $template);
	$errors = 0;

	&debug("") if ($main::config_debug);
	&debug("reading $dir configuration") if ($main::config_debug);

	foreach my $configfile (@configfiles) {
		open (CONFIG, "<$configfile") or do {
			&error("read_config_hosts: can't open $configfile: $!");
			++$errors;
			next;
		};
		$host = &basename($configfile);
		&debug("") if ($main::config_debug);
		&debug("$singular $host") if ($main::config_debug);
		while (<CONFIG>) {
			chomp;
			next if (/^#/ or /^\s*$/);
			($name, $value) = split(' ',$_,2);
		
			if (/^ip\s+(\d+\.\d+\.\d+\.\d+)\s*$/i) {
				$main::config{$key}{$host}{IP} = $1 if ($key eq 'HOST');
				&debug("  ip $1") if ($main::config_debug);
			}

			elsif (/^group\s+(.*)\s*$/i) {
				($group = $1) =~ s/\s*$//;
				unless (grep /^$group$/, @{$main::config{GROUPS}}) {
					++$errors;
					&error('read_config_hosts(', $dir, '): ', $host,
						' wants to be in group ', $group, 
						', but that is not listed in groups config-file');
				}
				$main::config{$key}{$host}{GROUP} = $group;
				push @{$main::config{GROUP}{$group}}, $host
					if ($key eq 'HOST');
				$main::config{TEMPLATEGROUP}{$host} = $group
					if ($key eq 'HOSTTEMPLATE');
				&debug("  group $group") if ($main::config_debug);
			}
			elsif (/^desc\s+(.*)\s*$/i) {
				$main::config{$key}{$host}{DESC} = $1;
				&debug("  desc $1") if ($main::config_debug);
			}
			elsif (/^community\s+(\S+)\s*$/i) {
				$main::config{$key}{$host}{COMMUNITY} = $1;
				&debug("  community $1") if ($main::config_debug);
			}
			elsif (/^via\s+(.*)\s*$/i) {
				$main::config{$key}{$host}{VIA} = $1;
				$main::config{$key}{$host}{VIA} =~ s/\s+$//;
				&debug("  via $1") if ($main::config_debug);
			}
			elsif (/^alias(es)?\s+(.*)\s*$/i) {
				($tmp = $2) =~ s/\s+$//;
				@aliases = split(' ', $2);
				push @{$main::config{$key}{$host}{ALIASES}}, @aliases
			}
			elsif (/^location\s+([-+]?\d+(\.\d+)?[NS]?)\s+([-+]?\d+(\.\d+)?[EW]?)\s+(.*)/i) {
				$lat = $1; $lon = $3; $desc = $5;
				$main::config{$key}{$host}{LOCATION} = 
					[$lat, $lon, $desc];
				&debug("  location lat=$lat, lon=$lon, desc=$desc") 
					if ($main::config_debug);
			}
			elsif (/^contact\s+([^<]+)\s+<(.*)>/i) {
				$name = $1;
				$email = $2;
				$main::config{$key}{$host}{CONTACTNAME} = $name;
				$main::config{$key}{$host}{CONTACTEMAIL} = $email;
				&debug("  contact name='$name', email='$email'") 
					if ($main::config_debug);
			}
			elsif (/^rrd\s+(\S+)(\s+(.*))?$/i) {
				$realrrd = $1;
				$extra = $3;
				push @{$main::config{$key}{$host}{RRDS}}, $realrrd;
				$main::config{$key}{$host}{RRD}{$realrrd} = 1;
				if (defined $extra and $extra =~ 
						/\bdesc\s*=\s*('([^']+)'|"([^"]+)")/i) {
					if (defined $2) { $rrddesc = $2; }
					elsif (defined $3) { $rrddesc = $3; }
					else {
						&abort('read_config_hosts(', $dir, 
							'): rrddesc: can\'t happen: ', $_);
					}
					$main::config{$key}{$host}{RRDDESC}{$realrrd} = $rrddesc;
					$extra =~ s/\bdesc\s*=\s*('[^']+'|"[^"]+")//i;
					if ($extra =~ /^\s*$/) { undef $extra; }
				}
				unless (defined $extra and $extra =~ /^\s*$/) {
					$main::config{$key}{$host}{EXTRA}{$realrrd} = $extra;
				}
				($wildrrd) = &get_rrd($realrrd);
				next unless( defined $wildrrd);
				$collector = $main::config{RRD}{$wildrrd}{SOURCE};

				$main::config{COLLECTOR}{$collector}{HOST}{$host} = 1 
					if ($key eq 'HOST');
				$main::config{TEMPLATECOLLECTEDBY}{$host}{$collector} = 1 
					if ($key eq 'HOSTTEMPLATE');
				&debug("  rrd $realrrd, extra=" .
					((defined $extra) ? $extra : '-undefined-'))
					if ($main::config_debug);
			}
			elsif (/^nograph\s+(\S+)\s+(\S+)\s*$/i) {
				$realrrd = $1;
				$graph = $2;
				unless (defined $main::config{RRD}{$realrrd}) {
					++$errors;
					&error('read_config_hosts(', $dir, '): ',
						$host, ': no such rrd in: ', $_);
				}
				$main::config{$key}{$host}{NOGRAPH}{$realrrd}{$graph} = 1;
				&debug("  nograph $realrrd $graph") if ($main::config_debug);
			}

			elsif (/^tools\s+(.*)$/i) {
				@{$main::config{$key}{$host}{TOOLS}} = split(' ',$1);
				&debug("  tools $1") if ($main::config_debug);
			}

			elsif (m#^alert\s+([-a-z0-9:/._]+)\s+([a-z0-9_]+)\s+([<=>])\s+(\d+(\s+\d+){0,2})\s*$#i) {
				($realrrd, $var, $relation, $values) = ($1, $2, $3, $4);
				($wildrrd) = &get_rrd($realrrd);
#				unless (defined $main::config{$key}{$host}{RRDS} and
#						grep (/^$realrrd$/, @{$main::config{$key}{$host}{RRDS}})) {
				unless( defined $main::config{$key}{$host}{RRD}{$realrrd}) {
					if( $key eq 'HOST') {
						++$errors;
						&error('read_config_hosts(', $dir, '): ',
							$host, ': unknown rrd ', $realrrd, ': ', $_);
						next;
					}
				}
				unless (defined $main::config{RRD}{$wildrrd}{DS}{$var}) {
					++$errors;
					&error("read_config_hosts($dir): $host: unknown variable ($var) in rrd $wildrrd: $_");
					next;
				}
				$main::config{$key}{$host}{ALERT}{$realrrd}{$var}{RELATION} =
					$relation;
				@{$main::config{$key}{$host}{ALERT}{$realrrd}{$var}{THRESHOLDS}}
					= split(' ',$values);
				&debug("  alert $realrrd $var $relation $values")
					if ($main::config_debug);
			}
			elsif (m#^alert\s+([-a-z0-9:/._]+)\s+([a-z0-9_]+)\s+nodata\s+(\S+)#i) {
				($realrrd, $var, $status) = ($1, $2, uc $3);
				($wildrrd) = &get_rrd($realrrd);
				# Only check rrd instance on host records
				unless (defined $main::config{$key}{$host}{RRDS} and
						grep (/^$realrrd$/, @{$main::config{$key}{$host}{RRDS}})) {
					if( $key eq 'HOST') {
						++$errors;
						&error('read_config_hosts(', $dir, '): ',
							$host, ': unknown rrd ', $realrrd, ': ', $_);
						next;
					}
				}
				unless (defined $main::config{RRD}{$wildrrd}{DS}{$var}) {
					++$errors;
					&error("read_config_hosts($dir): $host: unknown variable ".
						"($var) in rrd $wildrrd: $_");
					next;
				}
				unless (defined $main::statuses{$status}) {
					&error("read_config_rrds($dir): $host: unknown status for ".
						"nodata alert for host $host rrd $realrrd '$status'");
					++$errors;
					next;
				}
				$status = $main::statuses{$status};
				$main::config{$key}{$host}{ALERT}{$realrrd}{$var}{NODATA} =
					$status;
				&debug("  alert $host $realrrd $var nodata $status") 
					if ($main::config_debug);
			}
			elsif (m#^noalert\s+([-a-z0-9:/._]+)\s+([a-z0-9_]+)\s*$#i) {
				($realrrd, $var) = ($1, $2);
				$main::config{$key}{$host}{ALERT}{$realrrd}{$var}{NOALERT} = 1;
				&debug("  noalert for $realrrd $var") if ($main::config_debug);
			}
			elsif (/^snmpport\s+(\d+)\s*$/i) {
				$port = $1;
				$main::config{$key}{$host}{SNMPPORT} = $port;
				&debug("  snmpport $port") if ($main::config_debug);
			}
			elsif (/^keys\s+([-a-zA-Z_0-9]+)(\s+([-a-zA-Z_0-9]+))*\s*$/) {
				my @keys;
				push @keys, $1;
				if (defined $2) { push @keys, split(' ',$2); }
				foreach my $hostkey (@keys) {
					next if (length($hostkey) == 0);
					$main::config{$key}{$host}{KEY}{$hostkey} = 1;
				}
				&debug('  keys ' . join(' ', @keys)) if( $main::config_debug);
			}
			elsif (/^customgraph\s+(\S+)\s*$/) {
				push @{$main::config{$key}{$host}{CUSTOMGRAPHS}}, $1;
				&debug("  customgraph $1") if ($main::config_debug);
			}
			elsif (/^statusfile\s+(\S+)\s*$/) {
				$main::config{$key}{$host}{STATUSFILE} = $1;
				&debug("  statusfile $1") if ($main::config_debug);
			}
			elsif (/^nt-status-server\s+(\S+)/i) {
				$ntserver = $1;
				$main::config{$key}{$host}{NTSTATUSSERVER} = $ntserver;
				push @{$main::config{$key}{$ntserver}{NTINDIRECTHOSTS}}, $host;
				&debug("  nt-status-server $ntserver") if ($main::config_debug);
			}
			elsif (/^ntname\s+(\S+)/) {
				$ntserver = $1;
				$main::config{$key}{$host}{NTNAME} = $ntserver;
				&debug("  ntname $ntserver") if ($main::config_debug);
			}
			elsif (/^template\s+(\S+)/) {
				$template = $1;
				&debug("  template $template") if ($main::config_debug);
				if (defined $main::config{HOSTTEMPLATE}{$template}) {
					&copy_host_template( \%{$main::config{$key}{$host}}, 
						\%{$main::config{HOSTTEMPLATE}{$template}}, 
						$template, $host);
				}
				else {
					&error('read_config_hosts(', $dir, '): ', $host,
						': unknown template ', $template);
					++$errors;
				}
			}
			elsif (/^noavailability\s+(\S+)\s+(\S+)\s*$/) {
				$realrrd = $1;
				$var = $2;
				$main::config{$key}{$host}{NOAVAILABILITY}{$realrrd}{$var} = 1;
				&debug("  noavailability $realrrd $var")
					if ($main::config_debug);
			}
			elsif ($name eq 'showinterfaces') {
				if ($value =~ /^(yes|y|true|t|1)|(no|n|false|f|0)$/i) {
					$value = (defined $1) ? 1 : 0;
				}
				else {
					&error('read_config_hosts(', $dir, '): ', $host,
						': showinterfaces must be yes or no');
					++$errors;
					next;
				}
				$main::config{HOST}{$host}{SHOWINTERFACES} = $value;
				&debug("  showinterfaces $value") if( $main::config_debug);
			}
			elsif( $name eq 'headerfile') {
				if( $value =~ /^(\S+)\s+(.*)/) {
					my( $file, $header) = ($1, $2);
					$main::config{HOST}{$host}{HEADERFILE}{$header} = $file;
					&debug("  headerfile $value") if( $main::config_debug);
				}
				else {
					&error('read_config_hosts(', $dir, '): ', $host,
						': headerfile directive malformed: ', $_);
					++$errors;
					next;
				}
			}
			else {
				++$errors;
				&error("read_config_hosts($dir): $host: unknown line: $_");
				next;
			}
		}
		close (CONFIG);
	}

	if ($key eq 'HOST' and !defined $main::config{$key}) {
		&error("read_config_hosts($dir): missing config-files");
		++$errors;
	}
	elsif ($key eq 'HOSTTEMPLATE' and !defined $main::config{$key}) {
		&debug("missing $dir config-files; skipped") if ($main::config_debug);
	}

$errors;
}

#----------------------------------------------------- copy_host_template ---
# Copy a host template into a host description.
#----------------------------------------------------------------------------
sub copy_host_template {
	my ($hashref1, $hashref2, $template, $host) = @_;
	my ($key, $group, $ntserver);

	foreach $key (keys %{$hashref2}) {
		$$hashref1{$key} = $$hashref2{$key};
		&debug("    copied $key") if ($main::config_debug);
	}

# Now the more difficult parts: side-effects in other parts of the config 
# structure.  Propagate the effect of group:
#	$main::config{$key}{$host}{GROUP} = $group;
#	push @{$main::config{GROUP}{$group}}, $host if ($key eq 'HOST');
#	$main::config{TEMPLATEGROUP}{$host} = $group if ($key eq 'HOSTTEMPLATE');

	if (defined $main::config{TEMPLATEGROUP}{$template}) {
		$group = $main::config{TEMPLATEGROUP}{$template};
		push @{$main::config{GROUP}{$group}}, $host;
		&debug("    propagate GROUP group=$group, host=$host")
			if ($main::config_debug);
	}

# Propagate the effect of rrd collectors:

	foreach $key (keys %{$main::config{TEMPLATECOLLECTEDBY}{$template}}) {
		$main::config{COLLECTOR}{$key}{HOST}{$host} = 1;
		&debug("    propagate COLLECTOR collector=$key, host=$host")
			if ($main::config_debug);
	}

# Propagate the effect of indirect nt-status-server:

	if (defined $main::config{HOSTTEMPLATE}{$template}{NTSTATUSSERVER}) {
		$ntserver = $main::config{HOSTTEMPLATE}{$template}{NTSTATUSSERVER};
		push @{$main::config{HOST}{$ntserver}{NTINDIRECTHOSTS}}, $host;
		&debug("    propagate NTINDIRECTHOSTS ntserver=$ntserver, host=$host")
			if ($main::config_debug);
	}
}

#------------------------------------------------- read_config_groups ---
sub read_config_groups {
	my ($configdir) = @_;
	my $configfile = $configdir .'/groups';
	my %config = ();
	my ($name, $value, $errors, $group);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_groups: can't open $configfile: $!");
		return 1;
	};
	
	&debug("") if ($main::config_debug);
	&debug("reading groups configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		$group = $_;
		$group =~ s/^\s+//;
		$group =~ s/\s+$//;
		push @{$main::config{GROUPS}}, $group;
		&debug("  added group '$group'") if ($main::config_debug);
	}
	close (CONFIG);

	unless (defined $main::config{GROUPS}) {
		&error("read_config_groups: missing groups config-file");
		++$errors;
	}

	return $errors;
}

#---------------------------------------- read_config_view_templates ---
sub read_config_view_templates {
	my ($configdir) = @_;
	my ($name, $value, $errors, $configfile, $template, $text);
	$errors = 0;

	unless (-d $configdir .'/view-templates' or -l $configdir .'/view-templates') {
		&error("read_config_view_templates: missing $configdir/view-templates config-subdir");
		return 1;
	}
	
	&debug("") if ($main::config_debug);
	&debug("reading view-templates configuration") if ($main::config_debug);

	my @configfiles = &list_files( $configdir .'/view-templates');
	foreach $configfile (@configfiles) {
		open (CONFIG, "<$configfile") or do {
			&error("read_config_view_templates: can't open $configfile: $!");
			return 1;
		};
		$template = &basename($configfile);
		&debug("") if ($main::config_debug);
		&debug("view-template $template") if ($main::config_debug);

		$text = '';
		while (<CONFIG>) {
			$text .= $_;
		}
		close (CONFIG);
		$main::config{VIEWTEMPLATE}{$template} = $text;

		unless (defined $main::config{VIEWTEMPLATE}) {
			&error("read_config_view_templates: no view-templates config-files; skipped");
		}
	}

	return $errors;
}

#------------------------------------------------- read_config_views ---
sub read_config_views {
	my ($configdir) = @_;
	my %config = ();
	my ($name, $value, $errors, $configfile, $view);
	$errors = 0;

	unless (-d $configdir .'/views' or -l $configdir .'/views') {
		&error("read_config_views: missing $configdir/views config-subdir");
		return 1;
	}
	&debug("") if ($main::config_debug);
	&debug("reading views configuration") if ($main::config_debug);

	my @configfiles = &list_files( $configdir .'/views');
	foreach $configfile (@configfiles) {
		open (CONFIG, "<$configfile") or do {
			&error("read_config_views: can't open $configfile: $!");
			return 1;
		};
		$view = &basename($configfile);
		&debug("") if ($main::config_debug);
		&debug("view $view") if ($main::config_debug);

		while (<CONFIG>) {
			chomp;
			next if (/^#/ or /^\s*$/);
			
			if (/^desc(ription)?\s+(.*)/i) {
				$main::config{VIEW}{$view}{DESC} = $2;
				&debug("  desc $2") if ($main::config_debug);
			}
			elsif (/^graph\s+(\S+)\s+(\S+)\s+(\S+)\s*$/i) {
				push @{$main::config{VIEW}{$view}{GRAPHS}}, "graph $1 $2 $3";
				&debug("  graph $1 $2 $3") if ($main::config_debug);
			}
			elsif (/^customgraph\s+(\S+)\s*$/i) {
				push @{$main::config{VIEW}{$view}{GRAPHS}}, 
					"customgraph $1";
				&debug("  customgraph $1") if ($main::config_debug);
			}
			elsif (/^template\s+(\S+)\s*$/i) {
				unless (defined $main::config{VIEWTEMPLATE}{$1}) {
					&error("read_config_views: $view: no such view template as '$1'; ignored");
					next;
				}
				$main::config{VIEW}{$view}{TEMPLATE} = $1;
				&debug("  template $1") if ($main::config_debug);
			}
			elsif (/^datapage\s+(\S+)\s*$/i) {
				$main::config{VIEW}{$view}{DATAPAGE} = $1;
				&debug("  datapage $1") if ($main::config_debug);
			}
			else {
				&error("read_config_views: $view: unknown line: $_");
				++$errors;
				next;
			}
		}
		close (CONFIG);

		if (((defined $main::config{VIEW}{$view}{GRAPHS} or 
				defined $main::config{VIEW}{$view}{CUSTOMGRAPHS}) and
				(defined $main::config{VIEW}{$view}{TEMPLATE} or
				defined $main::config{VIEW}{$view}{DATAPAGE})) or
				(defined $main::config{VIEW}{$view}{TEMPLATE} and
				defined $main::config{VIEW}{$view}{DATAPAGE})
				) {
			&error("read_config_views: $view: a view can have graphs/customgraphs or template or datapage");
			++$errors;
		}
		unless (defined $main::config{VIEW}) {
			&error("read_config_views: missing view config-file; skipped");
		}
	}

	return $errors;
}

#----------------------------------------- read_config_alert_template_map ---
sub read_config_alert_template_map {
	my ($configdir) = @_;
	my $configfile = $configdir .'/alert-template-map';
	my %config = ();
	my ($what, $name, $value, $errors);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_alert_template_map: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading alert-template-map configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		if (/^(rrd|address)\s+(\S+)\s+(\S+)\s*$/) {
			$what = uc $1;
			$name = $2;
			$value = $3;
			$main::config{ALERTTEMPLATE}{$what}{$name} = $value;
			&debug("  $1 $2 $3") if ($main::config_debug);
		}
		else {
			&error("read_config_alert_template_map: unknown line: $_; skipped");
			++$errors;
		}
	}
	close (CONFIG);

	return $errors;
}

#------------------------------------------------- read_config_availability ---
# read availibility configuration
sub read_config_availability {
	my ($configdir) = @_;
	my $configfile = $configdir .'/availability';
	my ($errors, $host, $rrd, $varname, $cf, $relation, $threshold);
	$errors = 0;

	unless (-f $configfile or -l $configfile) {
		&debug("no availability config-file; skipped") if ($main::config_debug);
		return 0;
	}
	open (CONFIG, "<$configfile") or do {
		&error("read_config_availability: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading availability configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		if (/^\s*rrd\s+(\S+)\s+(\S+)\s+(LAST|MIN|MAX|AVERAGE)\s+(<|<=|>|>=|=)\s+([-+]?\d+(\.\d+)?)\s*$/) {
			($rrd, $varname, $cf, $relation, $threshold) = ($1, $2, $3, $4, $5);
			$main::config{RRDAVAIL}{$rrd}{$varname}{CF} = $cf;
			$main::config{RRDAVAIL}{$rrd}{$varname}{RELATION} = $relation;
			$main::config{RRDAVAIL}{$rrd}{$varname}{THRESHOLD} = $threshold;
			&debug("  rrd $rrd $varname $relation $threshold")
				if ($main::config_debug);
		}
		elsif (/^\s*host\s+(\S+)\s+(\S+)\s+(\S+)\s+(LAST|MIN|MAX|AVERAGE)\s+(<|<=|>|>=|=)\s+([-+]?\d+(\.\d+)?)\s*$/) {
			($host, $rrd, $varname, $cf, $relation, $threshold) = ($1, $2, $3, $4, $5, $6);
			$main::config{HOSTAVAIL}{$host}{$rrd}{$varname}{CF} = $cf;
			$main::config{HOSTAVAIL}{$host}{$rrd}{$varname}{RELATION} = $relation;
			$main::config{HOSTAVAIL}{$host}{$rrd}{$varname}{THRESHOLD} = $threshold;
			&debug("  host $host $rrd $varname $relation $threshold")
				if ($main::config_debug);
		}
		elsif (/^colou?rs\s+(.*)$/) {
			my $temp = $1;
			$temp =~ s/\s+$//;
			my @colors = split(' ', $temp);
			$main::config{AVAILCOLORS} = [ @colors ];
			&debug("  colors ". join(' ', @colors)) if ($main::config_debug);
		}
		elsif (/^thresholds\s+(.*)$/) {
			my $temp = $1;
			$temp =~ s/\s+$//;
			my @thresholds = split(' ', $temp);
			$main::config{AVAILTHRESHOLDS} = [ @thresholds ];
			&debug("  thresholds ". join(' ', @thresholds)) if ($main::config_debug);
		}
		else {
			&error("read_config_availability: unknown line: $_");
			++$errors;
			next;
		}
	}
	close (CONFIG);

	unless (defined $main::config{RRDAVAIL} or
			defined $main::config{HOSTAVAIL}) {
		&debug("missing availability config-file; skipped") if ($main::config_debug);
	}

	return $errors;
}

#------------------------------------------------- read_config_ntops ---
sub read_config_ntops {
	my ($configdir) = @_;
	my $configfile = $configdir .'/ntops';
	my ($errors, $host, $port);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_ntops: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading ntops configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		($host, $port) = split(' ',$_,2);

		$main::config{NTOPS}{$host} = $port;
		&debug("  $host value='$port'") if ($main::config_debug);
		$main::config{COLLECTOR}{'ntop'}{HOST}{$host} = 1;
	}
	close (CONFIG);

	# Don't care if it's missing

	return $errors;
}

#--------------------------------------- read_config_alert_destination_map ---
# To clone a new config section from
sub read_config_alert_destination_map {
	my ($configdir) = @_;
	my $configfile = $configdir .'/alert-destination-map';
	my %config = ();
	my ($dest, $time, $dow, $dom, $mon, $alias, $rest, $method, @temp, $errors);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_alert_destination_map: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading alert-destination-map configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);

		if (/^map\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$/) {
			($dest, $time, $dow, $dom, $mon, $alias) =
				(lc $1, $2, $3, $4, $5, lc $6);
			push @{$main::config{ALERTDEST}{DEST}}, 
				[ $dest, $time, $dow, $dom, $mon, $alias ];
			&debug("  map $dest $time $dow $dom $mon $alias")
				if ($main::config_debug);
		}
		elsif (/^alias\s+(\S+)\s+(.*)$/) {
			$alias = $1;
			$rest = $2;
			$rest =~ s/\s+$//;
			@temp = split(' ', $rest);
			$main::config{ALERTDEST}{ALIAS}{$alias} =
				[ @temp ];
			&debug("  alias $alias $rest") if ($main::config_debug);
		}
		elsif (/^method\s+(\S+)\s+(.*)$/) {
			$method = $1;
			$rest = $2;
			$rest =~ s/\s+$//;
			$main::config{ALERTDEST}{METHOD}{$method} = $rest;
			&debug("  method $method $rest") if ($main::config_debug);
		}
		else {
			&error("read_config_alert_destination_map: unknown line: $_");
			++$errors;
		}
	}
	close (CONFIG);

	unless (defined $main::config{ALERTDEST}) {
		&error("read_config_alert_destinaion_map: missing config-file");
		++$errors;
	}

	return $errors;
}

#------------------------------------------------- read_config_discovery ---
# To read discovery related info
sub read_config_discovery {
	my ($configdir) = @_;
	my $configfile = $configdir .'/discovery';
	my %config = ();
	my ($name, $value, $errors);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_discovery: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading discovery configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		($name, $value) = split(' ',$_,2);

		if ($name eq 'nt-status-server') {
			$main::config{DISCOVERY}{NTSTATUSSERVER} = $value;
			&debug("  nt-status-server $value") if ($main::config_debug);
		}
		elsif ($name eq 'ntdomain') {
			$main::config{DISCOVERY}{NTDOMAIN} = $value;
			&debug("  ntdomain $value") if ($main::config_debug);
		}
		elsif ($name eq 'dnsdomain') {
			$main::config{DISCOVERY}{DNSDOMAIN} = $value;
			&debug("  dnsdomain $value") if ($main::config_debug);
		}
		elsif ($name eq 'subnets') {
			$main::config{DISCOVERY}{SUBNETS} = $value;
			&debug("  subnets $value") if ($main::config_debug);
		}
		else {
			&error("read_config_discovery: unknown: $_");
			++$errors;
		}
	}
	close (CONFIG);

	unless (defined $main::config{DISCOVERY}) {
		&error("read_config_discovery: missing config-file");
		++$errors;
# if optional, use the next line instead to the two above
#		&error("read_config_discovery: missing config-file; skipped");
	}

	return $errors;
}

#--------------------------------------------------------- read_config_dbi ---
sub read_config_dbi {
	my ($configdir) = @_;
	my( $config_file, $connect_dir, $select_dir, %config, $name, $value, 
		$errors, @config_files, $connect_name, $select, $select_name);

	$connect_dir = $configdir . '/dbi-connects';
	$select_dir = $configdir . '/dbi-selects';
	%config = ();
	$errors = 0;

	# Get the list of files for connects
	@config_files = &list_files( $connect_dir);
	&debug("reading dbi-connect configuration") if ($main::config_debug);
	foreach $config_file (@config_files) {

		open (CONFIG, "<$config_file") or do {
			&error("read_config_dbi: can't open $config_file: $!");
			return 1;
		};

		$connect_name = lc &basename( $config_file);
		while (<CONFIG>) {
			chomp;
			next if (/^#/ or /^\s*$/);
			($name, $value) = split( ' ', $_, 2);
			if( $name =~ /^dbisource$/i) {
				$main::config{DBICONNECT}{$connect_name}{SOURCE} = $value;
				&debug("  dbisource $value") if( $main::config_debug);
			}
			elsif( $name =~ /^user$/i) {
				$main::config{DBICONNECT}{$connect_name}{USER} = $value;
				&debug("  user $value") if( $main::config_debug);
			}
			elsif( $name =~ /^password$/i) {
				$main::config{DBICONNECT}{$connect_name}{PASSWORD} = $value;
				&debug("  password $value") if( $main::config_debug);
			}
			else {
				&error("unknown directive in $config_file: $_");
				++$errors;
			}
		}
		close (CONFIG);
	}

	# Get the list of files for selects
	@config_files = &list_files( $select_dir);
	&debug("reading dbi-select configuration") if ($main::config_debug);
	foreach $config_file (@config_files) {

		open (CONFIG, "<$config_file") or do {
			&error("read_config_dbi: can't open $config_file: $!");
			++$errors;
			next;
		};

		$select_name = lc &basename( $config_file);
		undef $select;
		while (<CONFIG>) {
			chomp;
			next if (/^#/ or /^\s*$/);
			if( defined $select) { $select .= ' ' . $_; }
			else { $select = $_; }
		}
		close( CONFIG);
		&debug( "  read dbi-select/$select_name") if( $main::config_debug);
		$main::config{DBISELECT}{$select_name} = $select;
	}

	return $errors;
}

#------------------------------------------------- read_config_environment ---
# All this does is populate the environment of run-facon children with
# the contents of a file.
sub read_config_environment {
	my ($configdir) = @_;
	my $configfile = $configdir .'/environment';
	my %config = ();
	my ($name, $value, $errors);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_environment: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading environment configuration") if ($main::config_debug);

	while (<CONFIG>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		($name, $value) = split(' ',$_,2);
		$ENV{$name} = $value;
	}
	close (CONFIG);

	return $errors;
}

#------------------------------------------------- read_config_run ---
# Read the list of run-stages that run-facon2 will run
sub read_config_run {
	my ($configdir) = @_;
	my $configfile = $configdir .'/run';
	my %config = ();
	my ($line, $name, $value, $errors, $stage, $when);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_run: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading run configuration") if ($main::config_debug);

	while ($line = <CONFIG>) {
		chomp $line;
		next if ($line =~ /^#/ or $line =~ /^\s*$/);
		if( $line =~ /^\s*(\S+)(\s+([A-Z,]+))?$/) {
			($stage, $when) = ($1, $3);
			&debug("  $stage", (defined $when) ? ' ' . $when : '')
				if( $main::config_debug);
			$when = '' unless( defined $when);
			push @{$main::config{RUN}}, [ $stage, $when ];
		}
	}
	close (CONFIG);

	# We really do need this
	unless (defined $main::config{RUN}) {
		&error("read_config_run: missing config-file");
		++$errors;
	}

	return $errors;
}

#------------------------------------------------- read_config_run_stages ---
# Read the run-stage definitions
sub read_config_run_stages {
	my ($configdir) = @_;
	my $config_subdir = $configdir .'/run-stages';
	my %config = ();
	my ($name, $value, $errors, $async, $frequency, $command, $instance, $line,
		@files, $stage, $configfile);
	$errors = 0;

	&debug("") if ($main::config_debug);
	&debug("reading run-stages configuration") if ($main::config_debug);

	@files = &list_files( $config_subdir);

	foreach $configfile (@files) {
		$stage = &basename($configfile);
		open( CONFIG, "<$configfile") or do {
			&error("can't open $configfile: $!");
			++$errors;
			next;
		};
		&debug("opened $configfile...") if( $main::config_debug);

		while( $line = <CONFIG>) {
			chomp $line;
			next if ($line =~ /^#/ or $line =~ /^\s*$/);
			($name, $async, $frequency, $command) = split(' ',$line,4);
			
			# Async or not?
			if( $async =~ /^(1|y|yes|true)$/) { $async = 1; }
			elsif( $async =~ /^(0|n|no|false)$/) { $async = 0; }
			else {
				&error("bad async flag ($async) in: $line");
				++$errors;
				next;
			}

			# How often, in seconds
			if( $frequency =~ /^(\d+)$/) { $frequency = $1; }
			else {
				&error("bad frequency ($frequency) in: $line");
				++$errors;
				next;
			}

			# Save them away all neatly parsed
			$main::config{RUNSTAGE}{$stage}{$name}{ASYNC} = $async;
			$main::config{RUNSTAGE}{$stage}{$name}{FREQUENCY} = $frequency;
			$main::config{RUNSTAGE}{$stage}{$name}{COMMAND} = $command;
			&debug("  $stage: $name $async $frequency $command")
				if( $main::config_debug);

		}
		close (CONFIG);
	}

	unless (defined $main::config{RUNSTAGE}) {
		&error("read_config_run_stages: missing config-file");
		++$errors;
	}

	return $errors;
}

#------------------------------------------------- read_config_extra ---
# To clone a new config section (33 lines starting one line up)
sub read_config_extra {
	my ($configdir) = @_;
	my $configfile = $configdir .'/extra';
	my %config = ();
	my ($line, $name, $value, $errors);
	$errors = 0;

	open (CONFIG, "<$configfile") or do {
		&error("read_config_extra: can't open $configfile: $!");
		return 1;
	};
	&debug("") if ($main::config_debug);
	&debug("reading extra configuration") if ($main::config_debug);

	while ($line = <CONFIG>) {
		chomp $line;
		next if ($line =~ /^#/ or $line =~ /^\s*$/);
		($name, $value) = split(' ',$line,2);
	}
	close (CONFIG);

	unless (defined $main::config{EXTRA}) {
		&error("read_config_extra: missing config-file");
		++$errors;
# if optional, use the next line instead to the two above
		&error("read_config_extra: missing config-file; skipped");
	}

	return $errors;
}

#----------------------------------------------------------- basename ---
sub basename {
	my ($path) = @_;
	my @temp = split('/', $path);
	my $name = pop @temp;
	return $name;
}

#------------------------------------------------------------- do_subs ---
sub do_subs {
	my ($rrdfile, $realrrd, $wildpart, $host, $ip, $graph, $graphtime, 
		@args) = @_;
	my ($shorthost, @temp, %map, $sub);
	&debug("do_subs: start args:\n". join("\n", @args)) if ($main::debug>2);

# Optimization hack for constant stuff
	unless (defined %main::constant_subs) {
		$main::constant_subs{HTMLURL} = $main::config{HTMLURL};
		$main::constant_subs{HTMLDIR} = $main::config{HTMLDIR};
		$main::constant_subs{CGIURL} = $main::config{CGIURL};
		$main::constant_subs{CGIDIR} = $main::config{CGIDIR};
		$main::constant_subs{WEBMASTER} = $main::config{WEBMASTER};
		$main::constant_subs{THUMBHEIGHT} = $main::config{THUMBHEIGHT};
		$main::constant_subs{THUMBWIDTH} = $main::config{THUMBWIDTH};
		$main::constant_subs{DATADIR} = $main::config{DATADIR};

		foreach $sub (keys %{$main::config{COLOR}}) {
			$main::constant_subs{$sub} = $main::config{COLOR}{$sub};
		}
	}
	%map = %main::constant_subs;

# Preparation
	if (defined $host) {
		@temp = split('\.', $host);
		$shorthost = shift @temp;
		if ($shorthost =~ /^(www|ftp|mail)\d*$/) {
			$shorthost = shift @temp;
		}
	}

# Volatile substitutions
	$map{DB} = $rrdfile if (defined $rrdfile);
	$map{RRD} = $realrrd if (defined $realrrd);
	$map{HOST} = $host if (defined $host);
	$map{SHORTHOST} = $shorthost if (defined $shorthost);
	$map{HOSTDATADIR} = $main::config{DATADIR} . '/' . $host
		if( defined $host);
	$map{IP} = $ip if (defined $ip);
	$map{GRAPH} = $graph if (defined $graph);
	$map{GRAPHTIME} = $graphtime if (defined $graphtime);
	$map{WILDPART} = $wildpart if (defined $wildpart);
	$map{HOSTDESC} = $main::config{HOST}{$host}{DESC} 
		if (defined $host and defined $main::config{HOST}{$host}{DESC});
	$map{RRDDESC} = $main::config{HOST}{$host}{RRDDESC}{$realrrd} 
		if (defined $host and defined $realrrd and 
		defined $main::config{HOST}{$host}{RRDDESC}{$realrrd});
	$map{EXTRA} = $main::config{HOST}{$host}{EXTRA}{$realrrd}
		if (defined $host and defined $realrrd and
			defined $main::config{HOST}{$host}{EXTRA}{$realrrd});

# This will be the IP# if it's defined, or the hostname if not.
	if (defined $ip) { $map{IPORHOST} = $ip; }
	elsif (defined $host) { $map{IPORHOST} = $host; }

	@args = map{s/##([A-Z0-9]+)##/(defined $map{$1}) ? $map{$1} :
		'##'.$1.'##'/ge; $_} @args;

	&debug("do_subs: finish args:\n". join("\n", @args)) if ($main::debug>2);
	return @args;
}

#-------------------------------------------------------------- get_rrd ---
sub get_rrd {
	my ($realrrd) = @_;
	my ($wildrrd, $wildpart, $fixedrrd);

	if (defined $main::config{RRD}{$realrrd}) {
		$wildrrd = $realrrd;
	}
	else {
		if ($realrrd =~ /^([^-]+)-(\S+)$/) {
			$wildrrd = $1 . '-*';
			$wildpart = $2;
			unless (defined $main::config{RRD}{$wildrrd}) {
				&error("get_rrd: can't find wild rrd for '$realrrd'");
				return ();
			}
		}
		else {
			&error("get_rrd: can't find wild rrd for '$realrrd'");
			return ();
		}
	}

	$fixedrrd = &to_filename($realrrd);

	return ($wildrrd, $wildpart, $fixedrrd, $realrrd);
}

#------------------------------------------------------------- make_array ---
sub make_array {
	my ($string) = @_;
	my @array = ();

#	&debug("make_array: passed '$string'") if ($main::debug>2);
	while (length($string) > 0) {
		if ($string =~ /^'([^']+)'\s*(.*)/) {
			push @array, $1;
			$string = $2;
		}
		elsif ($string =~ /^"([^"]+)"\s*(.*)/) {
			push @array, $1;
			$string = $2;
		}
		elsif ($string =~ /^(\S+)\s*(.*)/) {
			push @array, $1;
			$string = $2;
		}
		else { &abort("make_array is broken; internal error"); }
		$string =~ s/^\s*//;
	}
#	&debug("make_array: returned:\n\t" . join("\n\t",@array) . "\n")
#		if ($debug>2);
	return @array;
}

#---------------------------------------------------------------- get_ip ---
sub get_ip {
	my ($hostname) = @_;
	my ($ip);

# Read the ip_cache if we haven't already
	unless (defined %main::ip_cache) {
		&read_ip_cache();
		$main::ip_cache_changed = 0;
	}

# Have we heard of this host?
	if (!defined $main::config{HOST}{$hostname}) {
		&debug("unknown host $hostname; attempting to continue") 
			if ($main::debug);
	}

# Have we got its IP number already?
	if (defined $main::ip_cache{HOST}{$hostname}) {
		$ip = $main::ip_cache{HOST}{$hostname};
		&debug("get_ip: got ip from cache: $hostname is $ip")
			if ($main::debug);
	}

# Is the IP number defined (old-style) on the host?  Cache it.
	elsif (defined $main::config{HOST}{$hostname}{IP}) {
		$ip = $main::config{HOST}{$hostname}{IP};
		$main::ip_cache{HOST}{$hostname} = $ip;
		$main::ip_cache{IP}{$ip} = $hostname;
		$main::ip_cache_changed = 1;
		&debug("get_ip: got ip from config: $hostname is $ip")
			if ($main::debug);
	}

# Look it up.
	else {
		$ip = gethostbyname($hostname);
		if (defined $ip) {
			$ip = inet_ntoa($ip);
			$main::ip_cache{HOST}{$hostname} = $ip;
			$main::ip_cache{IP}{$ip} = $hostname;
			$main::ip_cache_changed = 1;
			&debug("get_ip: got ip from gethostbyname: $hostname is $ip")
				if ($main::debug);
		}
	}

	unless (defined $ip) {
		&error("get_ip: couldn't find IP number for $hostname");
	}
	return $ip;
}

#--------------------------------------------------------------- get_host ---
sub get_host {
	my $ip = shift @_;
	my $do_dns = shift @_;
	unless( defined $do_dns) { $do_dns = 1; }
	my $host;

	# Read the ip_cache if we haven't already
	unless( defined %main::ip_cache) {
		&read_ip_cache();
		$main::ip_cache_changed = 0;
	}

	# Have we got an IP# at all?
	if( ! defined $ip) {
		&error('get_host called with undef ip number?');
	}

	# Have we got it in the cache?
	elsif( defined $main::ip_cache{IP}{$ip}) {
		$host = $main::ip_cache{IP}{$ip};
	}

	# Don't know what else to do but look it up in DNS
	else {
		return undef unless( $do_dns);
		my $iaddr = inet_aton( $ip);
		# Need this, because there are some ethernet addresses scattered
		# among the IP addresses.
		if( defined $iaddr) {
			$host = gethostbyaddr( $iaddr, AF_INET);
			if( defined $host) {
				$main::ip_cache{IP}{$ip} = $host;
#				$main::ip_cache_changed = 1;
			}
		}
	}

	return $host;
}

#---------------------------------------------------------------- testout ---
sub testout {
	print STDERR 'TEST: ', @_, "\n";
}

#------------------------------------------------------------- make_a_dir ---
sub make_a_dir {
	my ($dir) = @_;

	if (defined $main::testonly and $main::testonly) {
		&testout("make_a_dir $dir not done; test-mode");
		return 1;
	}

	if (mkdir $dir, 0775) {
		return 1;
	}
	else {
		&error("make_a_dir: can't mkdir $dir: $!");
		return 0;
	}
}

#---------------------------------------------------------- put_status ---
sub put_status {
	my ($host, $file, $value) = @_;
	my $dir;
	
print "Por entrar put_stats ".$main::config{DATADIR}."\n";
	if (defined $main::testonly and $main::testonly) {
		&testout("put_status($host, $file, $value) skipped; test-mode");
		return 0;
	}
	$dir .= $main::config{DATADIR} . '/' . $host;
	unless (-d $dir) {
		&error("put_status: directory $dir is missing; skipped");
		return;
	}

	$file = $dir . '/' . $file;
	if (defined $value) {
		open (STATUS, ">$file.new") or do {
			&error("put_status: Can't open status-file $file.new: $!");
			return;
		};
		print STATUS $value or do {
			&error("put_status: can't write $file.new: $!");
			return;
		};
		close(STATUS) or do {
			&error("put_status: can't close $file.new: $!");
			return;
		};
		rename $file . '.new', $file or do {
			&error("put_status: can't rename $file.new to $file");
			return;
		};
	}

	# Put undef means remove the file
	else {
		unlink $file; # and I don't care if unlink fails
		&error("unlinked $file");
	}

}

#--------------------------------------------------------- get_status ---
sub get_status {
	my ($host, $file) = @_;
	my ($value, $stale);
	$file = $main::config{DATADIR} . '/' . $host . '/' . $file;

	if (!-f $file) { $value =  'MISSING'; $stale=0; }
	else {
		if (((-M $file)*24*60*60) > $main::config{STALETIME}) {
			$stale = (-M $file)*24*60*60;
		}
		else { $stale = 0; }
		if( open (STATUS, "<$file")) {
			$value = <STATUS>;

			# This can happen if you run graph-writer while a collector
			# is updating a status file.
			if (defined $value) { chomp $value; }
			else { $value = 'EMPTY'; }
			close (STATUS);
		}
		else {
			&error("get_status: can't open $file: $!");
			$value = 'ERROR';
		}
	}
	if (wantarray) { return ($value, $stale); }
	else { return ($stale) ? $value.' (STALE)' : $value; }
}

#------------------------------------------------------------- to_filename ---
sub to_filename {
	my ($name) = @_;
	
	if (defined $name) {
		$name =~ tr#/A-Z :#-a-z_.#;
		$name =~ tr#!'"?<>\[\]\{\}\\\|/\$\~\^\&\*\(\)##d; # we don't need no stinkin' grot
	}
	return $name;
}

#--------------------------------------------------------------- siunits ---
# Make big numbers fit into smaller, more comprehensible display
sub siunits {
	my ($num) = @_;
	my $string;

	my ($whole, $fraction) = split('\.',$num);
	if (defined $fraction) { $num = $whole .'.'. substr($fraction,0,2); }
	else { $num = $whole; }

	if ($num >= 1000000000000) { $string = int($num/100000000000+.5)/10 . 'T'; }
	elsif ($num >= 1000000000) { $string = int($num/100000000+.5)/10 . 'G'; }
	elsif ($num >= 1000000) { $string = int($num/100000+.5)/10 . 'M'; }
	elsif ($num >= 1000) { $string = int($num/100+.5)/10 . 'K'; }
	else { $string = $num; }
$string;
}

#--------------------------------------------------------------- timestamp ---
sub timestamp {
	my ($secs) = @_;
	my $string;

	unless (defined $secs) { $secs = time; }
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime($secs);
	$string = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
		$year+1900, $mon+1, $mday, $hour, $min, $sec);

	return $string;
}

#--------------------------------------------------------------- timestamp2 ---
sub timestamp2 {
	my ($secs) = @_;
	my $string;

	unless (defined $secs) { $secs = time; }
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime($secs);
	$string = sprintf("%04d%02d%02d-%02d%02d%02d",
		$year+1900, $mon+1, $mday, $hour, $min, $sec);

	return $string;
}


#------------------------------------------------------------- sec_to_dhms ---
sub sec_to_dhms {
        my ($secs) = @_;
	unless (defined $secs) { $secs = 0; }
        my ($string, $sec, $min, $hour, $day, $temp);

        $sec = int($secs % 60);
        $temp = int(($secs - $sec) / 60);
        $min = $temp % 60;
        $temp = ($temp - $min) / 60;
        $hour = $temp % 24;
	$day = ($temp - $hour) / 24;
	$string = sprintf("%dd%02d:%02d:%02d", $day, $hour, $min, $sec);

	return $string;
}

#----------------------------------------------- logit ---
sub logit {
	my ($class, $host, $rrdname, $varname, $value, $msg) = @_;
	my $now = time;
	my ($mday, $mon) = (localtime($now))[3,4];
	++$mon;
	if ($mon < 10) { $mon = '0' . $mon; }
	if ($mday < 10) { $mday = '0' . $mday; }

	unless (-d $main::config{LOGDIR}) {
		&error("logit: log directory '$main::config{LOGDIR}' doesn't exist");
		return;
	}

	unless (defined $main::log_opened and $main::log_opened) {
		my ($logfile) = $main::config{LOGDIR} .'/'. $mon . $mday .'.log';
		if ($logfile =~ /^(.*)$/) {
			$logfile = $1; # untaint it
		}
		open (LOG, ">>$logfile") or
			(&error("logit: can't open log $logfile: $!") and return);
		$main::log_opened = 1;
	}

	if (!defined $class or $class eq '') { $class = '-'; }
	if (!defined $host or $host eq '') { $host = '-'; }
	if (!defined $rrdname or $rrdname eq '') { $rrdname = '-'; }
	if (!defined $varname or $varname eq '') { $varname = '-'; }
	if (!defined $value or $value eq '') { $value = '-'; }
	if (!defined $msg or $msg eq '') { $msg = '-'; }

	print LOG &timestamp($now) .' '. $class .' '. $host .' '. $rrdname .
		' '. $varname .' '. $value .' '. $msg ."\n";
	&debug("logged $now $class $host $rrdname $varname $value $msg")
		if ($main::debug);

# What's going on with the garbage in the logs?
	if (-f $main::config{'TEMPDIR'}.'/faconlog.log') {
		open (LOGLOG, ">>$main::config{'TEMPDIR'}/faconlog.log") 
			or die "$main::prog: can't open /tmp/faconlog.log: $!\n";
		print LOGLOG $main::prog .': '. &timestamp($now) .' '. $class 
			.' '. $host .' '. $rrdname .
			' '. $varname .' '. $value .' '. $msg ."\n";
		close (LOGLOG);
	}
}

#------------------------------------------------------ log_reboot ---
sub log_reboot {
	my ($host, $uptime, $who) = @_;

	my ($old_uptime) = &get_status( $host, 'UPTIME');
	&debug("log_reboot: host=$host, uptime=$uptime, old=$old_uptime")
		if ($main::debug>2);
	if ($uptime =~ /^(\d+)$/) { $uptime = $1; }
	else {
		&error("log_reboot: bad uptime for $host: '$uptime'");
		return;
	}

	if ($old_uptime eq 'MISSING') {
		&logit( 'NEWHOST', $host, undef, undef, undef, "detected by $who");
	}
	elsif ($old_uptime !~ /^\d+$/) {
		&error("bad old uptime for $host: '$old_uptime'");
		return;
	}
# This is almost guaranteed to cause multiple log entries for one re-boot, 
# reverting to old
#	elsif ( $uptime < $main::config{UPTIMEALERT} ) { #SRF
# This one can miss multiple re-boots if they occur within the sample 
# interval, but it will note at least one of these, which is the main thing.
	elsif ($old_uptime > $uptime) {
		my $boottime = time - $uptime;
		&logit( 'BOOT', $host, undef, undef, $boottime, 'at '. 
			&timestamp($boottime));
	}
}

#--------------------------------------------------------- get_uphosts ---
sub get_uphosts {
	my $file = $main::config{'TEMPDIR'} .'/uphosts';
	my %uphosts = ();
	
	open (UP, "<$file") or do {
		&error("can't open $file: $!; not using uphosts");
		$main::use_uphosts = 0;
		return;
	};
	while (<UP>) {
		chomp;
		$uphosts{$_} = 1;
	}
	close (UP);

	return %uphosts;
}

#-------------------------------------------------- add_group_if_missing ---
sub add_group_if_missing {
	my ($newgroup) = @_;

	my $file = $main::config_dir .'/groups';
	open (GROUPS, "+<$file") or &abort("can't open $file: $!");
	while (<GROUPS>) {
		chomp;
		next if (/^#/ or /^\s*$/);
		s/^\s+//;
		s/\s+$//;
		if ($newgroup eq $_) {
			close (GROUPS);
			return;
		}
	}
	print GROUPS "$newgroup\n";
	close (GROUPS);
}

#------------------------------------------------------ list_files ---
# list all the non-dot files in the specified directory
sub list_files {
	my ($dir, $pattern) = @_;
	my $file;
	my @files = ();
	&debug("list_files: dir=$dir". 
		((defined $pattern) ? ", pattern=$pattern" : '')) 
		if ($main::config_debug);

# In case some-one specified a wildcard, like a glob arg
	if ($dir =~ m'(.*)/\*$') { $dir = $1; }

	opendir(DIR, $dir) or do {
		&error("can't opendir $dir: $!");
		return ();
	};
	while ($file = readdir(DIR)) {
		&debug("  file $file") if ($main::config_debug);
		next if ($file =~ /^\./ or $file =~ /^IGNORE/ or
			$file =~ /\~$/);
		if (defined $pattern and $file =~ /$pattern/) {
			push @files, $dir .'/'. $file;
			&debug("  keeping it") if ($main::config_debug);
		}
		elsif (!defined $pattern) {
			push @files, $dir .'/'. $file;
			&debug("  keeping it") if ($main::config_debug);
		}
	}
	closedir(DIR);
	@files = sort @files;

	return @files;
}

#------------------------------------------------- read_ip_cache ---
sub read_ip_cache {
	return if( $main::dont_use_ip_cache);
	my ($cache_file, $host, $ip, $how);

# Create the cache if it's not there
	$cache_file = $main::config{DATADIR} .'/IP_CACHE';
	unless (-f $cache_file or -l $cache_file) {
		if( $main::ip_cache_readonly) {
			%main::ip_cache = ();
			return;
		}
		&debug("read_ip_cache: creating ip cache") if ($main::debug>3);
		open (CACHE, ">$cache_file") or 
			&abort("can't create $cache_file: $!");
		close(CACHE);
		%main::ip_cache = ();
		return;
	}

# Read it
	&debug("read_ip_cache: reading file") if ($main::debug>3);
	if( $main::ip_cache_readonly) { $how = ''; }
	else { $how = '+'; }
	open (CACHE, "$how<$cache_file") or &abort("can't update $cache_file: $!");
	while (<CACHE>) {
		chomp;
		next if (/^\s*#/ or /^\s*$/);
		($host, $ip) = split(' ', $_);
		$host = lc $host;
		&debug("  $host $ip") if ($main::debug>3);
		$main::ip_cache{HOST}{$host} = $ip;
		$main::ip_cache{IP}{$ip} = $host;
	}
	$main::ip_cache{HOST}{'_facon_'} = '127.0.0.1';
# purposefully not closed
}

#------------------------------------------------ write_ip_cache ---
sub write_ip_cache {
	return if( $main::dont_use_ip_cache);
	if( $main::ip_cache_readonly) { close(CACHE);  return; }
	return unless ($main::ip_cache_changed);
	my $cache_file = $main::config{DATADIR} .'/IP_CACHE';

# Make sure we pick up any other updates
	&read_ip_cache;
	flock( CACHE, LOCK_EX) or &abort("can't lock $cache_file: $!");
	seek( CACHE, 0, 0) or &abort("can't rewind $cache_file: $!");

	print CACHE "# updated by $main::prog at ". scalar(localtime) ."UTC\n\n";
	foreach my $host (sort keys %{$main::ip_cache{HOST}}) {
		next if ($host eq '_facon_');
		print CACHE $host .' '. $main::ip_cache{HOST}{$host} ."\n";
	}
	close(CACHE);
}

#---------------------------------------------------- remove_lockfile ---
sub remove_lockfile {
	my $lockfile = shift @_;

	unless( defined $lockfile) {
		&abort("remove_lockfile called with undefined name for file");
	}

	# Use default dir and prefix unless the name has a '/' in it
	unless( $lockfile =~ m#/#) {
		$lockfile = $main::config{TEMPDIR} . '/LOCK-' . $lockfile;
	}

	unlink $lockfile or &error("can't remove $lockfile: $!");
	return 1;
}

#------------------------------------------------------ make_lockfile ---
sub make_lockfile {
	my ($lockfile, $max_stale_time, $max_retries, $sleep_time) = @_;
	my ($tries, $tmplock);

	# Make sure that args make sense
	unless (defined $lockfile) {
		&abort("make_lockfile called with undefined name for file");
	}
	unless( $lockfile =~ m#/#) {
		$lockfile = $main::config{TEMPDIR} . '/LOCK-' . $lockfile;
	}
	unless( defined $max_stale_time) { $max_stale_time = -1; }
	unless( defined $max_retries) { $max_retries = 0; }
	unless( defined $sleep_time) { $sleep_time = 10; }

	# Make a temporary lock file
	$tmplock = $lockfile .'.'. $$;
	open (LOCK, ">$tmplock") or do {
		&error("make_lockfile: can't open $tmplock: $!");
		return 0;
	};
	print LOCK $$, "\n";
	close (LOCK);
	&debug("made temp-lock '$tmplock'") if( $main::debug);

	$tries = 0;
	while( $tries++ <= $max_retries) {

		# Break stale locks
		if( ($max_stale_time > 0) and -e $lockfile) {
			if ((-M $lockfile)*24*60*60 >$max_stale_time) {
				&error("breaking stale lockfile $lockfile");
				unlink $lockfile or &abort("can't unlink $lockfile: $!");
			}
		}

		# Lock by linking the temp file to the lockfile
		if( link $tmplock, $lockfile) {
			unlink $tmplock;
			&debug("locked '$lockfile'") if( $main::debug);
			return $lockfile;
		}
		
		# Link failed (i.e. lock failed, try some more
		&debug("make_lockfile: can't link $tmplock to $lockfile: $!")
			if( $main::debug);;

		# Sleep between tries
		sleep $sleep_time if( $tries > 0);
	}

	# Give up
	unlink $tmplock;
	&debug("failed to make lock $lockfile after $tries tries") 
		if( $main::debug);
	return 0;
}

#------------------------------------------------------ check_collect_time ---
# Check whether it's time to collect data for a specific rrd #TVE
#-----------------------------------------------------------------------------
sub check_collect_time {
	my ($host, $wildrrd, $fixedrrd) = @_;
	my ($rrdfile, $timelast, $err, $timenow, $rrd_step, $collect, $diff,
		$modtime, $moddiff );

	# First get the RRDfilename
	$rrdfile = $main::config{DATADIR} . '/' . $host . '/' . $fixedrrd . '.rrd';
	unless (-f $rrdfile) {
		&error("missing RRD $rrdfile; can't check update time");
		return 0;
	}

	# What time is it now?  Need the int() in case Time::HiRes is in effect.
	$timenow = int(time());

	# And when was the file modified?
	$modtime = $ + (-M $rrdfile) * 24 * 60 * 60;

	# Now do a last to get the last update time
	$timelast = RRDs::last $rrdfile;
	$err = RRDs::error();
	if ($err) {
		&error("error reading RRD $rrdfile: $err");
		return 0;
	}

	# Make sure the last update isn't in the future
	if( $timelast > $timenow) {
		&error("timewarp: last update in future ($timelast > $timenow) ", 
			"for $host $rrdfile");
		return 0;
	}

	# What's the RRD's step?
	$rrd_step = $main::config{RRD}{$wildrrd}{STEP};
	unless( defined $rrd_step) {
		$rrd_step = 300;
		&error("no step defined for $wildrrd; 300 used");
	}

	# Take a sample if we crossed an RRD sample boundary since we
	# last took a sample.

# This *ought* to be correct, but it doesn't work correctly.
#	$diff = $timenow - ( $timelast + $rrd_step);
	$diff = $timenow - $timelast;
	$moddiff = $timenow - $modtime;

	if( $diff >= 0) { $collect = 1; }
	else { $collect = 0; }

	&debug("check_collect_time: rrd=$fixedrrd($wildrrd) last=$timelast" .
	   " now=$timenow step=$rrd_step diff=$diff collect=$collect")
		if( $main::debug);
	
#	&append_to_file( $main::config{TEMPDIR} . '/check-collect-time.' . $$,
#		$host . ':' . $fixedrrd . ' step=' . $rrd_step . ' now=' . $timenow .
#		' last=' .  $timelast . ' now-last=' . $diff . ' mod=' . $modtime .
#		' now-mod=' . $moddiff .  ' collect=' . $collect );
	
	return $collect; }

#------------------------------------------------------ do_escapes ---
sub do_escapes {
	my $string = shift @_;

	$string =~ s/\\n/\n/g;
	$string =~ s/\\r/\r/g;
	$string =~ s/\\t/\t/g;

	return $string;
}

#-------------------------------------------------------- show_uptime ---
sub show_uptime {
	my ($uptime, $text_only) = @_;
	my $html;

	if (defined $uptime) {
		$html = &sec_to_dhms($uptime);
		if ($uptime < $main::config{MINUPTIME} and not $text_only) {
			$html = '<span style="background-color: red">' . $html . '</span>';
		}
		$html .= ' (up at ' . &timestamp(time() - $uptime) . ')';
	}
	else { $html = 'unknown'; }

	return $html;
}

#--------------------------------------------------- hosts_with_key ---
# Return a list of hosts which have the specified key
sub hosts_with_key {
	my $key = shift @_;
	my @hosts = ();
	foreach my $host (keys %{$main::config{HOST}}) {
		if( $main::config{HOST}{$host}{KEY}{$key}) {
			push @hosts, $host;
		}
	}
	return sort @hosts;
}

#------------------------------------------------------- rrds_with_key ---
sub rrds_with_key {
	my $key = shift @_;
	my @rrds = ();
	for my $wildrrd ( keys %{$main::config{RRD}}) {
		if( $main::config{RRD}{$wildrrd}{KEY}{$key}) {
			push @rrds, $wildrrd;
		}
	}
	return sort @rrds;
}

#---------------------------------------------------- make_uptime_flag ---
# This creates a custom uptime flag if $main::config{HTML}UPTIMEFLAG}
# contains a %s.  If it does, then the %s is replaced with the uptime 
# passed in.
#-------------------------------------------------------------------------
sub make_uptime_flag {
	my $uptime = shift @_;
	my $string = $main::config{HTML}{UPTIMEFLAG};
	if( $string =~ /^(.*)%s(.*)$/) {
		$string = $1 . $uptime . $2;
	}
	return $string;
}

#------------------------------------------------------ select_hosts ---
# This makes a list of hosts from the passed list of hosts and/or groups.
# First, @hosts, @groups or the lack of either selects a list of hosts.
# If both @hosts and @groups are specified, the resultant list will be
# the union of the two.
#-----------------------------------------------------------------------
sub select_hosts(\@\@\@) {
	my @hosts = (defined $_[0]) ? @{$_[0]} : undef;
	my @groups = (defined $_[1]) ? @{$_[1]} : undef;
	my @keys = (defined $_[2]) ? @{$_[2]} : undef;
	my %selected = ();
	my ($host, $group, $key, $found);
	
	# Give the selected hosts
	if( @hosts) {
		foreach $host (@hosts) { $selected{$host} = 1; }
	}

	# Give the hosts in the selected groups
	if( @groups) {
		foreach $group (@groups) {
			foreach $host (@{$main::config{GROUP}{$group}}) {
				$selected{$host} = 1;
			}
		}
	}

	# Give all the hosts, if they haven't specified any
	unless( scalar( keys %selected)) {
		foreach $host (keys %{$main::config{HOST}}) {
			$selected{$host} = 1;
		}
	}

	# Now filter by key, any of the keys will do
	if( @keys) {
		my ($found, $combine);

		# How to deal with multiple keys.  "And" means that a host must
		# have all the keys to qualify.  "Or" means that one match is
		# good enough.
		if( $keys[0] =~ /^and$/i) {
			$combine = 'and';
			shift @keys;
		}
		elsif( $keys[0] =~ /^or$/i) {
			$combine = 'or';
			shift @keys;
		}
		else {
			$combine = 'or';
		}

		foreach $host (keys %selected) {
			$found = 0;
			foreach $key (@keys) {
				if( $main::config{HOST}{$host}{KEY}{$key}) {
					$found++;
				}
			}
			if( $combine eq 'and') {
				unless( $found == @keys) { delete $selected{$host}; }
			}
			elsif( $combine eq 'or') {
				unless( $found) { delete $selected{$host}; }
			}
			else {
				&abort("INTERNAL: unknown key-combination type '$combine'");
			}
		}
	}

	return sort keys %selected;
}

#---------------------------------------------------- host_collected_by ---
sub host_collected_by {
	my( $host, $collector) = @_;
	return defined $main::config{COLLECTOR}{$collector}{HOST}{$host};
}

#---------------------------------------------------- rrd_collected_by ---
sub rrd_collected_by {
	my( $wildrrd, $collector) = @_;
	unless( defined $collector) { $collector = $main::collector; }
	return defined $main::config{COLLECTOR}{$collector}{RRD}{$wildrrd};
}

#------------------------------------------------------ host_has_key ---
sub host_has_key {
	my( $host, $key) = @_;

	if( defined $main::config{HOST}{$host} &&
			defined $main::config{HOST}{$host}{KEY}{$key}) {
		return 1;
	}
	else { return 0; }
}

#----------------------------------------------------- rrd_has_key ---
sub rrd_has_key {
	my( $wildrrd, $key) = @_;

	if( defined $main::config{RRD}{$wildrrd} &&
			defined $main::config{RRD}{$wildrrd}{KEY}{$key}) {
		return 1;
	}
	else { return 0; }
}

#----------------------------------------------------------- si_to_number ---
sub si_to_number {
	my $si_string = shift @_;
	my $number = 0;

	# Does it look like a number plus an SI prefix letter?
	if( $si_string =~ 
			/^\s*([-+]?(\d+\.\d+|\d+\.?|\.\d+))\s*([kKmMgGtT])?\s*$/) {
		$number = $1 + 0;

		# Have we got an SI prefix letter?
		my $prefix = uc $3;
		if( defined $prefix and length($prefix) > 0) {
			if( $prefix eq 'K') { $number *= 1000; }
			elsif( $prefix eq 'M') { $number *= 1000000; }
			elsif( $prefix eq 'G') { $number *= 1000000000; }
			elsif( $prefix eq 'T') { $number *= 1000000000000; }
			else {
				&debug("unknown SI prefix letter '$prefix' ignored")
					if( $main::debug);
			}
		}
	}

	# Not a number plus SI prefix
	else {
		&debug("SI string '$si_string' doesn't match; zero used")
			if( $main::debug);
		$number = 0;
	}
	return $number;
}

#--------------------------------------------------------------- put_error ---
# Note collection errors for the graph page headers.
#-----------------------------------------------------------------------------
sub put_error {
	my( $host, $fixedrrd, $msg) = @_;
	unless( defined $host and defined $fixedrrd and defined $msg) {
		&error("put_error: called with undef: $host, $fixedrrd, $msg");
		return;
	}
	my $file = 'ERROR-' . $fixedrrd;
	&put_status( $host, $file, $msg);
}

#------------------------------------------------------------- clear_error ---
# Clear the error reported by put_error, so you only see the error until it
# is no longer happening.
#-----------------------------------------------------------------------------
sub clear_error {
	my( $host, $fixedrrd) = @_;
	my $file = 'ERROR-' . $fixedrrd;
	put_status( $host, $file, '');
}

#--------------------------------------------------------- check_stop_file ---
# Checks for the existence of TEMPDIR/STOP-$main::prog and returns true if it
# is found.
#-----------------------------------------------------------------------------
sub check_stop_file {
	my $file = $main::config{TEMPDIR} . '/STOP-' . $main::prog;
	my $status = -f $file;
	if( $status) {
		&error("$main::prog stopped by $file");
	}
	return $status;
}

#---------------------------------------------------------- append_to_file ---
sub append_to_file {
	my( $file, $string) = @_;

	print "Por enetrar append_to_file\n";
	open(APPEND, ">>$file") or do {
		&error("can't open $file for append: $!");
		return 0;
	};
	print APPEND $string, "\n" or do {
	        print "Por llamar  error\n";
		&error("can't write $file: $!");
	        print "Por salir  error\n";
		return 0;
	};
	close(APPEND);
	return 1;
}

#----------------------------------------------------------- EOF ---

# - - -   Say good-night, Dick   - - -

1;

