#!/usr/bin/perl

use JSON;
use Data::Dumper;
# 
#
#{
#    "type": "result",
#    "timestamp": "2024-04-17T22:45:42Z",
#    "ping": {
#        "jitter": 2.550,
#        "latency": 15.352,
#        "low": 13.467,
#        "high": 21.705
#    },
#    "download": {
#        "bandwidth": 35872105,
#        "bytes": 325608599,
#        "elapsed": 9205,
#        "latency": {
#            "iqm": 24.666,
#            "low": 8.313,
#            "high": 248.521,
#            "jitter": 10.023
#        }
#    },
#    "upload": {
#        "bandwidth": 1465741,
#        "bytes": 11261720,
#        "elapsed": 7807,
#        "latency": {
#            "iqm": 14.882,
#            "low": 7.723,
#            "high": 39.151,
#            "jitter": 6.216
#        }
#    },
#    "isp": "TeleCentro",
#    "interface": {
#        "internalIp": "192.168.0.112",
#        "name": "eth1",
#        "macAddr": "08:00:27:58:AA:0E",
#        "isVpn": false,
#        "externalIp": "186.22.108.75"
#    },
#    "server": {
#        "id": 18731,
#        "host": "st-baoeste.cablevisionfibertel.com.ar",
#        "port": 8080,
#        "name": "Telecom Personal",
#        "location": "Caseros",
#        "country": "Argentina",
#        "ip": "181.30.135.138"
#    },
#    "result": {
#        "id": "48e697f2-a773-4667-add3-9a4426d29636",
#        "url": "https://www.speedtest.net/result/c/48e697f2-a773-4667-add3-9a4426d29636",
#        "persisted": true
#    }
#}

my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";
#my $url = 'http://192.168.0.115:82/cgi-bin/status.pl';


unlink "/tmp/speed";
unlink "/tmp/speed.err";

my $com = "/usr/src/speedtest -vvv -f json-pretty  --ca-certificate=/usr/src/cacert.pem >/tmp/speed 2>/tmp/speed.err";

my $ret = system($com );

open(FILE, "/tmp/speed");


my $string = do { local $/; <FILE> };

close FILE;

#print $string;
my %h;
$h = decode_json $string;

my $downbits = $h->{download}->{bandwidth} * 8;
print "downbandw ".$downbits."\n";
print "downlath ".$h->{download}->{latency}->{high}."\n";
print "downlatj ".$h->{download}->{latency}->{jitter}."\n";
print "downlatl ".$h->{download}->{latency}->{low}."\n";
print "downlati ".$h->{download}->{latency}->{iqm}."\n";

my $upbandw = $h->{upload}->{bandwidth}  * 8;
print "upbandw ".$upbandw."\n";
print "uplath ".$h->{upload}->{latency}->{high}."\n";
print "uplatj ".$h->{upload}->{latency}->{jitter}."\n";
print "uplatl ".$h->{upload}->{latency}->{low}."\n";
print "uplati ".$h->{upload}->{latency}->{iqm}."\n";

print "pingh ".$h->{ping}->{high}."\n";
print "pingla ".$h->{ping}->{latency}."\n";
print "pingl ".$h->{ping}->{low}."\n";
print "pingj ".$h->{ping}->{jitter}."\n";
# print $h->{upload}->{bytes};

exit 0;

#$string =~ s/\n//g;

$string =~ s/,\l\s+\}/   }/g;
#print $string;
my %h;



print $string;

my $download;
my $idle_latency;
#if ($string =~ /Techo de nubes<\/div>.+?<div>(\d*) m/s) {
if ($string =~ /Download:.+?(\d+)./s) {
	$download = $1;
	print "SI!!! download = $1\n";
	# die "SI!!! $1";
}
if ($string =~ /Idle Latency:.+?(\d+)./s) {
	$idle_latency = $1;
	die "SI!!! $1";
}

exit 0;

my @valores;

@valores = @$h;


my $hash = $valores[4];

my $compra = %$hash->{compra};
my $venta = %$hash->{venta};
$venta =~ s/,/./;
$compra =~ s/,/./;

print "turiscompra ".$compra."\n";
print "turisventa ".$venta."\n";

#die;
#die Dumper @valores;
#my $venta = $h->{sell};
#my $compra = $h->{buy};
#
#$venta =~ s/,/./;
#$compra =~ s/,/./;

#print "venta $venta\n";
#print "compra $compra\n";

