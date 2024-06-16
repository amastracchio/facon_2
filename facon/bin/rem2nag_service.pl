#!/usr/bin/perl

use Data::Dumper;

# hostfile -> service
# ARGV[0] = hostfile



$ARGV[0] =~ /(\w+$)/;
my $host = $1;
my $ip;





# Template por cada servicio
my $template = <<EOF;

define service{
        use                             local-service         ; Name of service template to use
        host_name                       ##HOST##
        service_description             ##SERVICE##
        active_checks_enabled           0
        check_freshness                 1
        freshness_threshold             600         ; 26 hour threshold, since backups may not always finish at the same time
        check_command                   sin_resultado        ; this command is run only if the service results are "stale"
        obsess_over_service             1
        }


EOF


my $tem_host = <<EOF;


define host{
        use                     linux-server            ; Name of host template to use
                                                        ; This host definition will inherit all variables that are defined
                                                        ; in (or inherited by) the linux-server host template definition.
        host_name               ##HOST##
        alias                   ##HOST##
        address                 ##IP##
        }



EOF




open FILE, $ARGV[0];


while (<FILE>) {


        if (/^ip\s*(\d*\.\d*\.\d*\.\d)/){ 

		$ip =  $1;
		$tem_host =~ s/##HOST##/$host/g;
		$tem_host =~ s/##ALIAS##/$host/g;
		$tem_host =~ s/##IP##/$ip/g;
		print $tem_host;

	}
	next unless /^rrd/;

	my @rem_serv = split(/(\s+|\t+)/);

	my $serv = $template;

	$serv =~ s/##HOST##/$host/g;
	$serv =~ s/##SERVICE##/$rem_serv[2]/g;

	print $serv;

	print "\n";
	
}


close FILE;
