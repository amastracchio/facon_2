#!/cygdrive/c/Perl/bin/perl -w
# nt-status-server - return interesting information about an NT host
# CVS $Id: nt-status-server.pl,v 1.35 2003/05/20 19:28:05 facon Exp $
# from facon @@VERSION@@
# Copyright 1999 - 2003 (c) Thomas Erskine <@@AUTHOR@@>
# See the COPYRIGHT file with the distribution.

# N.B.: It is purposefully single-threaded since I couldn't get it
# to work more than once with multiple processes, and also because 
# I couldn't see a reason to support multiple simultaneous connects.
# Later: there is a reason: debugging.  I don't consider it sufficient.

# - - -   Configuration   - - -

use strict;

# The name of this program for file-names and error-messages
$main::prog = 'nt-status-server';
# Where we listen by default
$main::port = 1957;
# Where is the NT Resource Kit installed
$main::ntreskit_dir = 'c:\\ntreskit\\';
# Where is psinfo (to get physical memory size
$main::psinfo_prog = 'psinfo.exe';
# Debugging anyone?
$main::debug = 0;
# Where to store server debugging messages (current directory)
$main::debug_file = 'DEBUG.txt';
# Run service with debugging?
$main::debug_service = 0;
# What to call this when it's a service
$main::service_name = 'facon-nt-statusANDA';
# Run as a service?
$main::as_service = 1;
# Where is perl
$main::perl = 'c:\perl\bin\perl.exe';
# How long to wait for polling state waiting for start
$main::wait_for_start = 10;
# Show all the available performance counters
$main::show_all = 0;
# Which hosts do I trust?
%main::trusted_hosts = ('127.0.0.1' => 1, '10.82.128.99' =>1);
# Should we send the cookie at the start?
$main::send_cookie = 0;
# show state with debugging off
$main::state_debug = 1;
# How often to re-exec itself?
$main::re_exec_after = 0; # should be OK

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.35 $'))[1];

# - - -   Setup   - - -

use Socket;
use Carp;
use Getopt::Std;
use Win32::Daemon;
use Win32::PerfLib;
use IO::Handle; # thousands of lines for autoflush
use Time::Local;

&stop_me;

# no anda ari $main::re_exec_command = $0 .' '. join(' ', @ARGV);
# $main::re_exec_command = '/cygdrive/c/Perl/bin/perl -w /root/3p/facon/bin/nt-status-server.pl -d 999 -p 9001 -s';
$main::re_exec_command = 'c:\perl\bin\perl -w c:\cygwin1\var\facon\bin\nt-status-server.pl -d 999 -p 9002 -s';
&debug("re-exec cmdline: $main::re_exec_command") if ($main::debug);

# Parse the command-line
my %opt = ();
getopts('ad:hip:r:st:Tu', \%opt);
if (defined $opt{'h'}) { &usage; }
if (defined $opt{'a'}) { $main::show_all = ! $main::show_all; }
if (defined $opt{'d'}) { $main::debug = $opt{'d'}; }
if (defined $opt{'i'}) { &install_service; }
if (defined $opt{'p'}) { $main::port = $opt{'p'}; }
if( defined $opt{'r'}) { $main::re_exec_after = $opt{'r'}; }
if (defined $opt{'s'}) { $main::as_service = 0; }
if (defined $opt{'t'}) {
    foreach my $ip (split(',', $opt{'t'})) {
        $main::trusted_hosts{$ip} = 1;
    }
}
if (defined $opt{'T'}) { $main::show_title = 1; }
else { $main::show_title = 0; }
if (defined $opt{'u'}) { &uninstall_service; }

# Debugging for service
if ($main::as_service and $main::debug_service) {
    $main::debug = $main::debug_service 
        unless ($main::debug > $main::debug_service);
}

# Start up
&debug2("====== loaded $main::prog ======") if ($main::debug);
if ($main::as_service) {
    &debug2("readying service...") if ($main::debug);
    Win32::Daemon::StartService();
    &debug2("service ready, waiting for start...") if ($main::debug);
    while (SERVICE_START_PENDING != ($main::state = Win32::Daemon::State())) {
		&debug2("waiting for service start...") if( $main::debug);
        sleep $main::wait_for_start;
    }
    Win32::Daemon::State(SERVICE_RUNNING);
    &debug2("service started") 
        if ($main::debug);
    &debug2("SERVICE_STOPPED = ". SERVICE_STOPPED ) 
        if ($main::debug);
    &debug2("SERVICE_RUNNING = ". SERVICE_RUNNING ) 
        if ($main::debug);
    &debug2("SERVICE_PAUSED = ". SERVICE_PAUSED ) 
        if ($main::debug);
    &debug2("SERVICE_START_PENDING = ". SERVICE_START_PENDING ) 
        if ($main::debug);
    &debug2("SERVICE_STOP_PENDING = ". SERVICE_STOP_PENDING ) 
        if ($main::debug);
    &debug2("SERVICE_CONTINUE_PENDING = ". SERVICE_CONTINUE_PENDING ) 
        if ($main::debug);
    &debug2("SERVICE_PAUSE_PENDING = ". SERVICE_PAUSE_PENDING ) 
        if ($main::debug);
#    &debug2("SERVICE_INTEROGATE = ". SERVICE_INTEROGATE ) 
#        if ($main::debug);
}

# Get the socket ready
my $proto = getprotobyname('tcp');
$main::port = $1 if ($main::port =~ /^(\d+)$/); # untaint
socket( Server, PF_INET, SOCK_STREAM, $proto) or &abort("socket: $!");
setsockopt( Server, SOL_SOCKET, SO_REUSEADDR, pack("l",1)) or 
    &abort("setsockopt: $!");
bind( Server, sockaddr_in( $main::port, INADDR_ANY)) or &abort("bind: $!\n");
listen( Server, SOMAXCONN) or &abort("listen: $!");
&debug2("started; waiting for connection on $main::port") 
    if ($main::debug);
&title( "waiting for connection on $main::port") if ($main::show_title);

# Performance counter keys
%main::perf_keys = (
'System' => {
    'File Read Operations/sec' => 1, # gauge
    'File Write Operations/sec' => 1, # gauge
    'File Control Operations/sec' => 1, # gauge
    'File Read Bytes/sec' => 1, # gauge
    'File Write Bytes/sec' => 1, # gauge
    'File Control Bytes/sec' => 1, # gauge
    'Context Switches/sec' => 1, # gauge
	'Processor Queue Length' => 1, # rawcount?
    'System Calls/sec' => 1, # gauge
    '% Total Processor Time' => 1,
    '% Total User Time' => 1,
    '% Total Privileged Time' => 1,
    'Total Interrupts/sec' => 1, # gauge
    'System Up Time' => 1,
},

'Memory' => {
    'Available Bytes' => 1, # gauge
    'Committed Bytes' => 1, # gauge
    'Commit Limit' => 1,     # gauge (max for committed bytes)
    'Page Faults/sec' => 1, # gauge
    'Write Copies/sec' => 1, # gauge
    'Pages Input/sec' => 1, # gauge
    'Page Reads/sec' => 1, # gauge
    'Pages Output/sec' => 1, # gauge
    'Page Writes/sec' => 1, # gauge
},

#'PhysicalDisk' => {
#    'Current Disk Queue Length' => 1, # gauge
#    '% Disk Read Time' => 1,
#    '% Disk Write Time' => 1,
#    'Disk Reads/sec' => 1, # gauge
#    'Disk Writes/sec' => 1, # gauge
#    'Disk Read Bytes/sec' => 1, # gauge
#    'Disk Write Bytes/sec' => 1, # gauge
#},

'LogicalDisk' => {
    '% Free Space' => 1, # gauge
    'Free Megabytes' => 1, # gauge
    '% Disk Read Time' => 1,
    '% Disk Write Time' => 1,
    'Avg. Disk Read Queue Length' => 1,
    'Avg. Disk Write Queue Length' => 1,
    'Disk Reads/sec' => 1, # gauge
    'Disk Writes/sec' => 1, # gauge
    'Disk Read Bytes/sec' => 1, # gauge
    'Disk Write Bytes/sec' => 1, # gauge
},

'Objects' => {
    'Processes' => 1, # gauge
    'Threads' => 1, # gauge
    'Events' => 1, # gauge
},

'Redirector' => {
    'Bytes Received/sec' => 1, # gauge
    'Packets Received/sec' => 1, # gauge
    'Read Bytes Network/sec' => 1, # gauge
    'Bytes Transmitted/sec' => 1, # gauge
    'Packets Transmitted/sec' => 1, # gauge
    'Write Bytes Network/sec' => 1, # gauge
    'Network Errors/sec' => 1, # gauge
    'Server Sessions' => 1, # gauge
    'Server Reconnects' => 1, # gauge
    'Current Commands' => 1, # gauge
},

'Server' => {
    'Bytes Received/sec' => 1, # gauge
    'Bytes Transmitted/sec' => 1, # gauge
    'Files Open' => 1, # gauge
    'Server Sessions' => 1, #gauge
},

'Network Interface' => {
    'Packets Sent Unicast/sec' => 1, # "counter counter" == gauge?
    'Packets Sent Non-Unicast/sec' => 1, # "counter counter" == gauge?
    'Packets Received Unicast/sec' => 1, # ditto
    'Packets Received Non-Unicast/sec' => 1, # ditto
    'Bytes Received/sec' => 1, # ditto
    'Bytes Sent/sec' => 1, # ditto
    'Packets Received Errors' => 1, # counter rawcount == counter?
    'Packets Received Unknown' => 1, # ditto
    'Packets Received Discarded' => 1, # ditto
    'Packets Outbound Errors' => 1, # counter rawcount == counter?
    'Packets Outbound Discarded' => 1, # ditto
},

);

$main::do_re_exec_now = 0;

# - - -   Mainline   - - -

my ($paddr, %do, $inport, $iaddr, $name, %hosts, $server_debug, $iip,
    $cookie);
$server_debug = $main::debug;

$main::loops = 0;
&title("waiting for connection");
while ($paddr = accept(Client, Server)) {
    
    unless ($main::state = &do_state()) { exit 0; }
    Client->autoflush(1);

    %do = ();
    ($inport, $iaddr) = sockaddr_in( $paddr);
    $name = gethostbyaddr( $iaddr, AF_INET);

# We won't talk to just anybody
    $iip = inet_ntoa($iaddr);
    &debug("connection from $name [$iip] from port $inport at ".
        scalar(time) ) if ($main::debug);
    unless (defined $main::trusted_hosts{$iip}) {
        &error("un-trusted host $iip; dropped");
        Client->close();
        next;
    }
    &title( "connection from $name [$iip] at ". scalar(time)) 
        if ($main::show_title);

# To secure "dangerous" commands (not implemented yet)
    $cookie = int(int(rand(100000000))/2)*2+1;
    print Client time(), ' cookie ', $cookie, "\n"
        if ($main::send_cookie);

# Read all the commands first
    %hosts = ();
    while(<Client>) {
        unless ($main::state = &do_state()) { exit 0; }
        next unless (defined $_);
        tr/\015\012//d;
        &debug("raw command: $_") if ($main::debug>1);

        if (/^DEBUG(\s+(\d+))?$/) {
            $main::debug = (defined $2) ? $2+0 : 1;
            &debug("$main::prog version $main::version");
            &debug("debugging enabled at $main::debug");
        }
        elsif (/^GO$/) { last; }
        elsif (/^QUIT$/) { %do = (); last; }
        elsif (/^HELP$/) { &do_help(); }
		elsif( /^RE-EXEC$/) {
			$main::do_re_exec_now = 1;
			&check_re_exec();
		}

        elsif (/^SRVINFO(\s+(\S+))?$/) {
            if (defined $2) { $hosts{'SRVINFO'}{$2} = 1; }
            else { $hosts{'SRVINFO'}{''} = 1; }
            $do{'SRVINFO'} = 1;
        }

        elsif (/^PERFCOUNTERS(\s+(\S+))?$/) {
            if (defined $2) { $hosts{'PERFCOUNTERS'}{$2} = 1; }
            else { $hosts{'PERFCOUNTERS'}{''} = 1; }
            $do{'PERFCOUNTERS'} = 1;
        }

        elsif (/^PSINFO(\s+(\S+))?$/) {
            if (defined $2) { $hosts{'PSINFO'}{$2} = 1; }
            else { $hosts{'PSINFO'}{''} = 1; }
            $do{'PSINFO'} = 1;
        }

        elsif (/^PULIST(\s+(\S+))?$/) {
            if (defined $2) { $hosts{'PULIST'}{$2} = 1; }
            else { $hosts{'PULIST'}{''} = 1; }
            $do{'PULIST'} = 1;
        }

        elsif (/^MSDRPT$/) {
            $do{'MSDRPT'} = 1;
        }

		elsif (/^TIME\s+(\d+)(\s+(\S+))?$/) {
		    if (defined $2) { $hosts{'TIME'}{$3} = $1; }
		    else { $hosts{'TIME'}{''} = $1; }
		    $do{'TIME'} = 1;
		}

        elsif (/^USRSTAT(\s+(\S+))?$/) {
            if (defined $2) { $hosts{'USRSTAT'}{$2} = 1; }
            else { $hosts{'USRSTAT'}{''} = 1; }
            $do{'USRSTAT'} = 1;
        }

        elsif (/^NETVIEW$/) {
            $do{'NETVIEW'} = 1;
        }

        else { &error("unknown command '$_'"); }

    }
    &debug("beginning data acquistition") if ($main::debug);

# Do what they asked for, in our order, in case it matters
    if (defined $do{'PSINFO'}) { &do_psinfo(keys %{$hosts{'PSINFO'}}); }
    unless ($main::state = &do_state()) { exit 0; }

    if (defined $do{'PERFCOUNTERS'}) {
		&do_perfcounters(keys %{$hosts{'PERFCOUNTERS'}});
	}
    unless ($main::state = &do_state()) { exit 0; }

    if (defined $do{'PULIST'}) { &do_pulist(keys %{$hosts{'PULIST'}}); }
    unless ($main::state = &do_state()) { exit 0; }

    if (defined $do{'USRSTAT'}) { &do_usrstat(keys %{$hosts{'USRSTAT'}}); }
    unless ($main::state = &do_state()) { exit 0; }

    if (defined $do{'NETVIEW'}) { &do_net_view(); }
    unless ($main::state = &do_state()) { exit 0; }

    if (defined $do{'TIME'}) { &do_time(%{$hosts{'TIME'}}); }
    unless ($main::state = &do_state()) { exit 0; }

	# These ones can be *slow*
    if (defined $do{'SRVINFO'}) { &do_srvinfo(keys %{$hosts{'SRVINFO'}}); }
    unless ($main::state = &do_state()) { exit 0; }

    if (defined $do{'MSDRPT'}) { &do_msdrpt(); }
    unless ($main::state = &do_state()) { exit 0; }

}

# Always do this, even on next
continue {

# Reset debugging in case the client turned it on
    $main::debug = $server_debug;
    &title("waiting for connection");

    unless ($main::state = &do_state()) { exit 0; }

	&check_re_exec();
    &stop_me();
    Client->close();
}

#----------------------------------------------------- check_re_exec ---
sub check_re_exec {
	return unless( $main::re_exec_after == 0 or
		$main::loops >= $main::re_exec_after or
		$main::do_re_exec_now);
	&debug("re-exec: $main::re_exec_command") if( $main::state_debug);
	Client->close();
	exec $main::re_exec_command or &abort("can't exec: $!");
}

#------------------------------------------------------------ do_help ---
# GO QUIT DEBUG SRVINFO PERFCOUNTERS PULIST RE-EXEC
sub do_help {
    print Client <<"EOD_HELP";
$main::prog version $main::version
Commands are:
  HELP                show this help
  GO                  execute the sections requested
  QUIT                exit without executing requested sections
  DEBUG nnn           set debugging output to level 'nnn'
  SRVINFO [hhh]       run srvinfo and re-format the output
  PERFCOUNTERS [hhh]  show performance counters
  NETVIEW ddd        show hosts in NT domain 'ddd'
  PULIST [hhh]        show list of processes
  TIME ttt [hhh]      show time and difference from collector
  USRSTAT ddd         show users in NT domain 'ddd'
  MSDRPT              (obsolete un-needed)
  PSINFO [hhh]        get host info (including physical memory size)
Note: things in [brackets] are optional. 'ddd' means a NT domain-name.
  'hhh' means an NT host-name.
EOD_HELP
}

#---------------------------------------------------------- logdebug ---
sub logdebug {
    my $msg = shift @_;
    open (DEBUG, ">>$main::debug_file") or return;
    print DEBUG "$$: $msg\n";
    close (DEBUG);
}

#----------------------------------------------------------- debug2 ---
sub debug2 {
    my ($sec, $min, $hour) = localtime;
    my $now = sprintf("%02d:%02d:%02d", $hour, $min, $sec);
    &logdebug('DEBUG: ' . $now . ': ' . join('', @_));
    print STDERR 'DEBUG: ', $now, ': ', @_, "\n";
}

#----------------------------------------------------------- debug ---
sub debug {
    &debug2(@_);
    print Client 'DEBUG: ', @_, "\n";
}

#----------------------------------------------------------- error ---
sub error {
    &logdebug('ERROR: ', join('', @_));
    print STDERR 'ERROR: ', @_, "\n";
    print Client 'ERROR: ', @_, "\n";
}

#-------------------------------------------------------------- abort ---
sub abort {
    &logdebug('ABORT: ', join('', @_));
    print STDERR 'ABORT: ', @_, "\n";
    print Client 'ABORT: ', @_, "\n";
    if ($main::as_service) {
        Win32::Daemon::StopService();
    }
    close(STDIN);
    close(STDOUT);
    close(STDERR);
    close(Client);
    exit 1;
}

#-------------------------------------------------------- usage ---
sub usage {
    print STDERR <<"EOD_USAGE";
$main::prog version $main::version from facon nose
usage: $main::prog [options]
where options are:
    -a      show all available performance counters
    -d ddd  enable debugging at level 'ddd' [$main::debug]
    -h      show this help message
    -i [ppp sss] install this as an NT service, using 'ppp' as
            as perl and 'sss' as this script.  Defaults to
                perl=$main::perl 
                script=$0
    -p ppp  run server on port 'ppp' [$main::port]
    -s      run stand-alone, i.e. not as a service
    -t ttt  trust hosts 'ttt' (comma-separated) [127.0.0.1]
    -T      show where we are in window-title
    -u      un-install this service
N.B.: Just running this script will cause it to run as a service,
and when it stops, it will properly stop as a service.
EOD_USAGE
    exit 0;
}

#------------------------------------------------------- do_srvinfo ---
sub do_srvinfo {
    my @hosts = @_;
    
    my ($file, $os_name, $os_version, $os_release, $domain, $hardware,
        $status, $service, $host, $cmd, $prefix, $interface, $type, $ip,
	$in_drives, $drive, $filesys, $size, $free);

# Where is srvinfo.exe?
    $file = $main::ntreskit_dir . 'SRVINFO.EXE';
    unless (-f $file) {
        &error( "missing $file; skipped");
        return;
    }

    if ($#hosts == -1) { push @hosts, ''; }

# Run it for each indirect host
    foreach $host (@hosts) {
        &debug("do_srvinfo: starting $host") if ($main::debug);
        $cmd = $file .' '. (($host eq '') ? '' : '\\\\'. $host);
        &debug("  cmd=$cmd") if ($main::debug);
        open (PIPE, "$cmd|") or do {
            &error("can't open pipe from $cmd: $!");
            next;
        };

        undef $hardware;
        if ($host eq '') { $prefix = ''; }
        else { $prefix = $host . ' '; }
        &title( "doing SRVINFO for $host") if ($main::show_title);

        while(<PIPE>) {
            chomp;
            &debug("  RAW: $_") if ($main::debug>1);

# NT Workstation or Server
            if (/^NT Type:\s*(.*)/) {
                $os_name = $1;
                print Client $prefix, time(), ' os_name ', $os_name, "\n";
            }

# NT version
            elsif (/^Version:\s*(\d+\.\d+),\s+Build\s+=\s+(\S+),\s+CSD\s+=\s+(.*)/){
                $os_release = $1;
                $os_version = $2 .' '. $3;
                print Client $prefix, time(), ' os_release ', 
                        $os_release, "\n",
                    $prefix, time, ' os_version ', $os_version, "\n";
            }
			elsif (/^Version:\s*(\d+\.\d+)\s*$/) {
				$os_release = $1;
				print Client $prefix, time(), ' os_release ', $os_release, "\n";
			}
			elsif (/^Build:\s+(\d+),\s+(.*)$/) {
				$os_version = $1 .' '. $2;
                print Client $prefix, time(), ' os_version ', $os_version, "\n";
			}

# We get the IP address on some new ones
			elsif (/^IP Address:\s+(\S+)/) {
				$ip = $1;
				print Client $prefix, time(), ' ip_address ', $ip, "\n";
			}

# NT domain name
            elsif (/^Domain:\s*(.*)/) {
                $domain = $1;
                print Client $prefix, time(), ' domain ', $domain, "\n";
            }

# CPU type (could be multiple lines, so collect here, print at end)
            elsif (/^CPU\[(\d+)\]:\s+(.*)/) {
                if (defined $hardware) {
                    $hardware .= "<BR>CPU $1: $2";
                }
                else {
                    $hardware .= "CPU $1: $2";
                }
            }

# System Up Time: 142 Hr 55 Min 26 Sec
            elsif (/^System Up Time:\s+(.*)/) {
                if ($1 =~ /^(\d+)\s+Days?,?\s+(\d+)\s+Hr,?\s+(\d+)\s+Min,?\s+(\d+)\s+Sec/) {
					my $uptime = $1*24*60*60 + $2*60*60 + $3*60 + $4;
					print Client $prefix, time(), ' uptime ', $uptime, "\n";
				}
                elsif ($1 =~ /^(\d+)\s+Hr,?\s+(\d+)\s+Min,?\s+(\d+)\s+Sec/) {
                    my $uptime = $1*60*60 + $2*60 + $3;
                    print Client $prefix, time(), ' uptime ', $uptime, "\n";
                }
                else {
                    &error("${prefix}uptime format unknown for: $_");
                }
            }

# Network Card [0]: Intel 8255x-based PCI Ethernet Adapter (10/100)
# Network interface types
            elsif (/^Network Card \[(\d+)\]:\s+(.*)/) {
                $interface = $1;
                $type = $2;
                if (defined $type and $type !~ /^\s*\r?\n?$/) {
                    print Client $prefix, time(), ' interface:', $interface,
                        ' ', $type, "\n";
                }
            }

# Drive:  [FileSys]  [ Size ]  [ Free ]  [ Used ]
#   C$      NTFS        3499       793      2706
#   D$      NTFS        5248      1939      3309
# Services:
			elsif( /^Drive:/) { $in_drives = 1; }
			elsif( /^Services:/) { $in_drives = 0; }
			elsif( $in_drives) {
				($drive, $filesys, $size, $free) = split(' ', $_);
				$drive =~ tr/\$//d;
				print Client $prefix, time(), ' drive-filesys:', $drive,  ' ', $filesys, "\n";
				print Client $prefix, time(), ' drive-size-meg:', $drive,  ' ', $size, "\n";
				print Client $prefix, time(), ' drive-free-meg:', $drive,  ' ', $free, "\n";
			}

# Running services
            elsif (/^\s+\[([^\]]+)\]\s+(.*)/) {
                $status = $1;
                $service = $2;
                if ($status =~ /^Stopped$/i) { $status = 2; }
                elsif ($status =~ /^Running$/i) { $status = 1; }
                elsif ($status =~ /^Paused$/i) { $status = 3; }
				elsif ($status =~ /^Start Pending$/i) { $status = 4; }
				elsif ($status =~ /^Stop Pending$/i) { $status = 5; }
                else {
                    &error("${prefix}unknown status '$status' for '$service'");
                    $status = 6;
                }
                $service =~ tr#-A-Za-z0-9#_#c;
                print Client $prefix, time(), ' service:', $service, 
                    ' ', $status, "\n";
			}
            else {
                &debug("unknown line ignored: $_") if ($main::debug>1);
            }
        }
        close (PIPE);

# This is done, because multi-CPU boxen have multiple lines
        if (defined $hardware) {
            print Client $prefix, time(), ' machine ', $hardware, "\n";
        }
        &debug("do_srvinfo: done $host") if ($main::debug);
    }
}

#-------------------------------------------------------- install_service ---
# This installs the service, but does not start it
sub install_service {
    my %hash = ( 
        'name' => $main::service_name,
        'display' => 'Remstats NT StatusANDA',
        'path' => $main::perl,
        'user' => '',
        'pwd' => '',
        'parameters' => $0,
    );

# Allow them to override the paths
    my ($path, $parameters) = @ARGV;
    if (defined $path && $path ne '-') { $hash{'path'} = $path; }
    if (defined $parameters && $parameters ne '-') {
        $hash{'parameters'} = $parameters;
    }

# Make sure that there is a file where they said there was.
    unless (-f $hash{'path'}) {
        die "$main::prog: perl isn't where you said: $hash{'path'}\n";
    }
    unless (-f $hash{'parameters'}) {
        die "$main::prog: this script isn't where you said: $hash{'parameters'}\n";
    }

# Install the service
    print STDERR "installing service with:\n".
        "\tName:       $hash{'name'}\n".
        "\tDisplay:    $hash{'display'}\n".
        "\tPath:       $hash{'path'}\n".
        "\tParameters: $hash{'parameters'}\n";
    if (Win32::Daemon::CreateService( \%hash)) {
        print STDERR "Service created. Use Control Panel to start/stop it.\n";
    }
    else {
        &abort( 'Failed to create service: '. &errmsg());
    }
    exit 0;
}

#----------------------------------------------- uninstall_service ---
sub uninstall_service {
    if( Win32::Daemon::DeleteService( $main::service_name )) {
        print STDERR "Service removed.\n";
    }
    else {
        &abort( "Failed to remove service: ". &errmsg());
    }
    exit 0;
}

#----------------------------------------------------- do_state ---
sub do_state {
    &debug("do_state: entering state polling loop") if ($main::debug);
    return 1 unless ($main::as_service);

    my $result;

    my $last_state = $main::state;
    while (SERVICE_RUNNING != ($main::state = Win32::Daemon::State()) ) {
        &debug("do_state: state is now $main::state") if ($main::state_debug);
        if ($main::state == SERVICE_STOPPED or
                $main::state == SERVICE_PAUSED) {
            &debug("   waiting in state $main::state") if ($main::state_debug);
            sleep $main::wait_for_start;
        }
        elsif ($main::state == SERVICE_START_PENDING) {
                &debug("   Service started") if ($main::state_debug);
                $main::state = Win32::Daemon::State(SERVICE_RUNNING);
        }
        elsif ($main::state == SERVICE_STOP_PENDING) {
            &debug("do_state: Service stopped") if ($main::state_debug);
            Win32::Daemon::StopService();
            $main::state = Win32::Daemon::State(SERVICE_STOPPED);
            return 0;
        }
        elsif ($main::state == SERVICE_CONTINUE_PENDING) {
            &debug("   Service resumed") if ($main::state_debug);
            $main::state = Win32::Daemon::State(SERVICE_RUNNING);
        }
        elsif ($main::state == SERVICE_PAUSE_PENDING) {
            &debug("   Service paused") if ($main::state_debug);
            $main::state = Win32::Daemon::State(SERVICE_PAUSED);
        }
#        elsif ($main::state == SERVICE_INTEROGATE) {
#            &debug("   Service interrogated: $last_state") 
#                if ($main::state_debug);
#            $main::state = Win32::Daemon::State($last_state);
#        }
        else {
            &debug("do_state: unknown state: $main::state; ignored") 
                if ($main::state_debug);
            $main::state = Win32::Daemon::State($last_state);
            &debug("   State set to $last_state") 
                if ($main::state_debug);
        }
        $last_state = $main::state;
    }
    &debug("do_state: leaving state polling loop; state=$main::state")
        if ($main::debug);
}

#--------------------------------------------------- errmsg ---
sub errmsg {
    my $msg = Win32::FormatMessage( Win32::Daemon::GetLastError());
	return $msg;
}

#------------------------------------------------------- do_perfcounters ---
sub do_perfcounters {
    my @hosts = @_;

    my (%counter_name, %r_counter_name, $perflib, $section,
        $section_id, $ref, %objects, $obj, $oname, %counters, $counter,
        %this, $name, %instances, %instance, $instance, $instance_name,
        $value, %object, $host, %freespace, $disk_free, $disk_size);

    if ($#hosts == -1) { push @hosts, ''; }
    foreach $host (@hosts) {
        unless ($main::state = &do_state()) { exit 0; }
        &debug("do_perfcounters: starting for $host") if ($main::debug);
        %counter_name = ();
        undef $perflib;
        Win32::PerfLib::GetCounterNames($host, \%counter_name);
        unless (scalar keys %counter_name > 0) {
            &debug("can't get counter-names for $host; skipped: $!")
                if ($main::debug>1);
            next;
        }
        %r_counter_name = map { $counter_name{$_} => $_ } keys %counter_name;

# Create connection to $host
        $perflib = new Win32::PerfLib($host);
        unless (defined $perflib) {
            &error("can't connect to $host; skipped: $!");
            next;
        }
        &title( "doing PERFCOUNTERS for $host") if ($main::show_title);

# - - -   Mainline   - - -

        foreach $section (keys %main::perf_keys){
            $section_id = $r_counter_name{$section};
            &debug("  section $section is $section_id") if ($main::debug);
            $ref = {};
            unless (defined $section_id) {
                &debug("  unknown section_id for $section; skipped");
                $perflib->Close();
                next;
            }

            $perflib->GetObjectList( $section_id, $ref);
            unless (defined $$ref{'Objects'}) {
                &debug("  can't GetObjectList for $section_id; skipped: $!")
                    if ($main::debug>1);
                $perflib->Close();
                next;
            };
            %objects = %{$$ref{'Objects'}};
            foreach $obj (sort keys %objects) {
                $oname = &perfname_fixup($counter_name{$obj});
                %object = %{$objects{$obj}};

                if (defined $object{'Counters'}) {
                    &debug("  doing $oname counters for $host") 
                        if ($main::debug>1);
                    %counters = %{$object{'Counters'}};
                    foreach $counter ( sort keys %counters) {
                        %this = %{$counters{$counter}};
                        $name = $counter_name{$this{'CounterNameTitleIndex'}};

						# Make sure we have something here
                        next unless (defined $name);
                        next unless ($main::show_all || 
                            $main::perf_keys{$section}->{$name});

						# Qualify the name so the collector can find it
                        $name = &perfname_fixup($name);
                        $name = lc ($section) .':'. $name;
                        $name =~ s/\s+/_/g;
                        $value = $this{'Counter'};
                        &debug("    counter $name is $value") 
                            if ($main::debug>1);
                        print Client (($host eq '') ? '' : $host.' '), 
                            time(), ' ', $name,  ' ', $value, "\n";
                    }
                }
        
                if (defined $object{'Instances'}) {
                    &debug("  doing instances for $host") if ($main::debug>1);
                    %instances = %{$object{'Instances'}};
					undef $disk_size;
					undef $disk_free;

                    foreach $instance (sort keys %instances) {
                        %instance = %{$instances{$instance}};
                        $instance_name = &perfname_fixup($instance{'Name'});
                        %counters = %{$instance{'Counters'}};
                        foreach $counter ( sort keys %counters) {
                            %this = %{$counters{$counter}};
                            $name = $counter_name{$this{'CounterNameTitleIndex'}};

							# Make sure we've got something here
                            next unless (defined $name);
                            next unless ($main::show_all || 
                                $main::perf_keys{$section}->{$name});
                            next if ($name eq 'Context Switches/sec');
                            $name = &perfname_fixup($name);

							# The percent_free_space ocurrs twice, once as 
							# free megs, once as disk size in megs.  The 
							# $instance_name _total (at least) ocurrs twice 
							# as well.  This hackery deals with it.
                            if ($name eq 'disk_reads-sec') {
                                $freespace{$instance_name} = 0;
                            }
                            elsif ($name eq 'percent_free_space') {
                                if ($freespace{$instance_name}) {
                                    $name = 'disk_size_meg';
									$disk_size = $this{'Counter'};
                                }
                                else {
                                    $freespace{$instance_name} = 1;
                                    $name = 'disk_free_meg';
									$disk_free = $this{'Counter'};
                                }
                            }

							# Qualify the name so the collector can figure 
							# out what it belongs to
                            $name = lc($section) .':'. $name .':'. 
                                $instance_name;
                            $name =~ s/\s+/_/g;
                            $value = $this{'Counter'};
                            &debug("    counter $name is $value")
                                if ($main::debug>1);
                            print Client (($host eq '') ? '' : $host.' '), 
                                time(), ' ', $name,  ' ', $value, "\n";
							
							# Fake a disk_free_percent
							if( defined $disk_size and defined $disk_free) {
								$name =~ s/(size|free)_meg:/free_percent:/;
								$value = $disk_free / $disk_size * 100;
								undef $disk_size;
								undef $disk_free;
								print Client (($host eq '') ? '' : $host.' '),
									time(), ' ', $name, ' ', $value, "\n";
							}
                        }
                    }
                }
            }
        }

        $perflib->Close();
    }
    $perflib->Close() if (defined $perflib);
    &debug("do_perfcounters: done") if ($main::debug);
}

#-------------------------------------------------------- perfname_fixup ---
sub perfname_fixup {
    my ($name) = @_;

    $name =~ tr#/A-Z #-a-z_#;
    $name =~ s/%/percent/g;
    $name =~ tr/-a-z0-9_//cd;
$name;
}

#----------------------------------------------------------- do_net_view ---
sub do_net_view {

    my $cmd = 'NET VIEW';
    open (PIPE, "$cmd|") or do {
        &error("can't open pipe to '$cmd': $!");
        return;
    };
    &title( "NET VIEW") if ($main::show_title);

    while (<PIPE>) {
        chomp;
        if (/^\\\\(\S+)/) {
            print Client "NETVIEW $1\n";
        }
    }
    close (PIPE);
}

#------------------------------------------------------- do_usrstat ---
sub do_usrstat {
    my @domains = @_;
    
    my ($file, $cmd, $server, $user, $name, $laston, $domain, %user);

# Where is the program
    $file = $main::ntreskit_dir . 'USRSTAT.EXE';
    unless (-f $file) {
        &error( "missing $file; skipped");
        return;
    }

    foreach $domain (@domains) {
        &debug("do_usrstat: starting domain $domain") if ($main::debug);
        $cmd = $file .' '. $domain;

        open (USRSTAT, "$cmd|") or do {
            &error("can't open pipe to $cmd: $!");
            next;
        };
        &title( "USRSTAT for $domain") if ($main::show_title);
        %user = ();
        undef $server;
        while (<USRSTAT>) {
            chomp;
            &debug("RAW: $_") if ($main::debug>1);

            if (/^Users at \\\\(\S+)/) {
                $server = $1;
            }

            elsif (/^\s*(.*?)\s-\s+(.*?)\s-\slogon:\s+(.*)$/) {
                $user = $1;
                $name = $2;
                $laston = $3;
                if ($laston ne 'Never') {
                    $user{$user}{NAME} = $name;
                    $user{$user}{LASTON} = $laston;
                    $user{$user}{SERVER} = $server;
                }
            }
        }
        close(USRSTAT);

# print out what we found
        foreach $user (sort keys %user) {
            ($name = $user{$user}{NAME}) =~ tr/ /_/;
            ($server = $user{$user}{SERVER}) =~ tr/ /_/;
            $laston = $user{$user}{LASTON};
            if (defined $laston) { $laston =~ tr/ /_/;}
            else { $laston = 'Never'; }
            print Client "USRSTAT $user $name $server $laston\n";
        }

        &debug("do_usrstat: done domain $domain") if ($main::debug);
    }

    
}

#---------------------------------------------------- do_msdrpt ---
sub do_msdrpt{
    my ($file, $cmd, $exit_code, $name, $value);

# Where is the program
    $cmd = $main::ntreskit_dir .'winmsdp.exe';
    unless (-f $cmd) {
        &error("missing $cmd; skipped");
        return;
    }

    $exit_code = system( "$cmd /m")>>8;
    if ($exit_code) {
        &error("error running $cmd");
        return;
    }

# It puts the results in msdrpt.txt
    open (FILE, "<msdrpt.txt") or do {
        &error("can't open msdrpt.txt: $!");
        return;
    };
    &debug("reading msdrpt file") if ($main::debug);
    &title("reading msdrpt file") if ($main::show_title);

    while (<FILE>) {
        chomp;
        if (/Total Physical Memory:\s*(\d+)/) {
            $name = 'total-physical-memory';
            $value = $1;
        }
        elsif (/Available Physical Memory:\s*(\d+)/) {
            $name = 'free-physical-memory';
            $value = $1;
        }
        else {
            &debug("ignoring: $_") if ($main::debug>2);
            undef $name;
            undef $value;
        }

        if (defined $name and defined $value) {
            print time(), ' ', $name, ' ', $value, "\n";
        }
    }
    close (FILE);

}

#------------------------------------------------------- do_pulist ---
sub do_pulist {
    my @hosts = @_;
    
    my ($file, $cmd, $prefix, $proc, %procs, $fixed_proc, $host);

# Where is the program
    $file = $main::ntreskit_dir . 'PULIST.EXE';
    unless (-f $file) {
        &error( "missing $file; skipped");
        return;
    }

    if ($#hosts == -1) { push @hosts, ''; }

    foreach $host (@hosts) {
        &debug("do_pulist: starting $host") if ($main::debug);
        %procs = ();
        $cmd = $file .' '. (($host eq '') ? '' : '\\\\'. $host);
        &debug("  cmd=$cmd") if ($main::debug);
        open (PIPE, "$cmd|") or do {
            &error("can't open pipe from $cmd: $!");
            next;
        };
        &title( "PULIST for $host") if ($main::show_title);

# For output formatting
        if ($host eq '') { $prefix = ''; }
        else { $prefix = $host . ' '; }

# Collect the counts of processes
        while(<PIPE>) {
            chomp;
            &debug("  RAW: $_") if ($main::debug>1);
            if (/^\\\\/) { next; }
            elsif (/^Process\s+PID\s*\r?\n?/) { next; }
            elsif (/^_Total/) { next; }
            elsif (/^(\S+)\s+\d+/) {
                $proc = $1;
                if (defined $procs{$proc}) { ++$procs{$proc}; }
                else { $procs{$proc} = 1; }
            }
        }
        close (PIPE);

# Print the results for this host
        foreach $proc (keys %procs) {
            ($fixed_proc = $proc) =~ tr/A-Z/a-z/;
            $fixed_proc =~ tr/-a-z0-9\._#//cd;
            print Client $prefix, time(), ' processes:', $fixed_proc, 
                ' ', $procs{$proc}, "\n";
        }

        &debug("do_pulist: done $host") if ($main::debug);
    }

}

#--------------------------------------------------------- stop_me ---
sub stop_me {
# The re-exec detaches it from the command-line, so this gives a simple
# way to stop it which doesn't involve trying to find its pid.
    if (-f 'STOP-'. $main::prog) {
        print STDERR "stopped by STOP-$main::prog\n";
        exit 0;
    }
}

#----------------------------------------------------------- title ---
sub title {
    my ($msg) = @_;
    system 'title '. $msg;
}

#----------------------------------------------------------------- do_time ---
sub do_time {
	my %hash= @_;
	my ($remote_time, $local_time, $diff, $host, $result, $min, $hour,
		$mday, $month, $year, $cmd, $prefix, $ampm);

	foreach $host (keys %hash) {

# Get the time for that host
		&debug("doing TIME for host $host") if ($main::debug);
		if( $host eq '') {
			$local_time = time();
			$prefix = '';
		}
		else {
			$prefix = $host . ' ';
			$cmd = 'NET TIME \\\\' . $host . ' 2>&1';
			&debug("  cmd='$cmd'") if ($main::debug>1);
			$result = `$cmd`;
			 
			# This is the data format I like, but nobody else seems to bother
			if ($result =~ /Current time at \S+ is (\d\d\d\d)-(\d\d)-(\d\d) (\d?\d):(\d\d)( (A|P)M)?/) {
				($year, $month, $mday, $hour, $min, $ampm) =
					($1, $2, $3, $4, $5, $7);
				if( defined $ampm and $ampm eq 'A') { $hour = $hour + 12; }
				$local_time = timelocal( 0, $min, $hour, $mday, $month -1,
					$year);
			}

			# Default broken American date format
			elsif ($result =~ m#Current time at \S+ is (\d\d)/(\d\d)/(\d\d) (\d?\d):(\d\d)( (A|P)M)?#) {
				($month, $mday, $year, $hour, $min, $ampm) = ( $1, 
					$2, $3, $4, $5, $7);
				if( defined $ampm and $ampm eq 'A') { $hour = $hour + 12; }
				# *BUG*: due to y2k problems with this year format, I have 
				# to hard-code the century.  With luck, I'll still be
				# around to fix it when it breaks next time. :-)
				$local_time = timelocal( 0, $min, $hour, $mday, 
					$month - 1, $year + 2000);
			}

			# Errors
			elsif( $result =~ /^System error/i) { next; }

			# Who knows?  It could be anything, almost.
			else {
				&error("can't parse time for host $host from '$result'");
				next;
			}
		}

# Compare with remote time
		$remote_time = $hash{$host};
		$diff = $local_time - $remote_time;
		print Client <<"EOD_TIME";
$prefix$local_time time $local_time
$prefix$local_time timediff $diff
EOD_TIME
		&debug("TIME $host time=$local_time, diff=$diff") if ($main::debug);
	}
}

#------------------------------------------------------- do_psinfo ---
sub do_psinfo {
    my @hosts = @_;
	my( $host, $cmd, $prefix, $in_hotfixes);
    
# Where is psinfo.exe?
    unless (-f $main::psinfo_prog) {
        &error( "missing $main::psinfo_prog; skipped");
        return;
    }

	# If we've got no hosts to do, just do this one
    if (@hosts == 0) { push @hosts, ''; }

# Run it for each indirect host
    foreach $host (@hosts) {
        &debug("do_psinfo: starting $host") if ($main::debug);
        $cmd = $main::psinfo_prog .' '. (($host eq '') ? '' : '\\\\'. $host);
        &debug("  cmd=$cmd") if ($main::debug);
        open (PIPE, "$cmd|") or do {
            &error("can't open pipe from $cmd: $!");
            next;
        };

        if ($host eq '') { $prefix = ''; }
        else { $prefix = $host . ' '; }
        &title( "doing PSINFO for $host") if ($main::show_title);

        while(<PIPE>) {
            chomp;
            &debug("  RAW: $_") if ($main::debug>1);

			# Uptime in an easy to parse format.  Wow!
			if( /^Uptime:\s+(\d+)\s+days,\s+(\d+)\s+hours,\s+(\d+)\s+minutes,\s+(\d+)\s+seconds/) {
				$main::uptime = $1*24*60*60 + $2*60*60 + $3*60 + $4;
				print Client $prefix, time(), ' uptime ', $main::uptime, "\n";
			}

			# Get the operating system name
			elsif( /^Kernel version:\s+(.*),/) {
				$main::os_name = $1;
			}
			elsif( /^Product type:\s+(.*)/) {
				$main::os_name .= ' ' . $1;
				print Client $prefix, time(), ' os_name ', 
					$main::os_name, "\n";
			}

			# Get the operating system release (what normal people would call
			# the version), the official "number" of this OS
			elsif( /^Product version:\s+(\d+\.\d+)/) {
				$main::os_release = $1;
			}
			elsif( /^Kernel build number:\s+(\d+)/) {
				$main::os_release .= ' build ' . $1;
				print Client $prefix, time(), ' os_release ', 
					$main::os_release, "\n";
			}

			# Get the patch level of this OS
			elsif( /^Service pack:\s+(\d+)/) {
				$main::os_version = 'SP' . $1;
				print Client $prefix, time(), ' os_version ',
					$main::os_version, "\n";
			}

			# Mmmm.  Hardware.
			elsif( /^Processors:\s+(\d+)/) {
				$main::hardware = $1 . ' x ';
			}
			elsif( /^Processor speed:\s+(.*)/) {
				$main::hardware .= $1;
			}
			elsif( /^Processor type:\s+(.*)/) {
				$main::hardware .= ' ' . $1;
				print Client $prefix, time(), ' machine ', 
					$main::hardware, "\n";
			}

			# Finally a way to get physical memory size
			elsif( /^Physical memory:\s+(\d+\s*\S+)/) {
				print Client $prefix, time(), ' memory_size ', $1, "\n";
			}

			# Hotfix information (normal people would call them patches)
			elsif( /^HotFixes:/) { $in_hotfixes = 1; }
			elsif( $in_hotfixes) {
				if( /^\s*(Q\d+):\s+(.*)/) {
					print Client $prefix, time(), ' hotfix:', $1, ' ', $2, "\n";
				}
			}
		}

        close (PIPE);

        &debug("do_psinfo: done $host") if ($main::debug);
    }
}
