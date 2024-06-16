#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

my $url = "https://mercados.ambito.com//riesgopais/variacion-ultimo";

my $com = $ej . " " . $url;

my $ret = system($ej,$url,"-o","/tmp/dolarpro");

open(FILE, "/tmp/dolarpro");

my $string = <FILE>;

close FILE;

$string .= "\n";
my %h;
$h = decode_json $string;

my $venta = $h->{ultimo};
my $compra = $h->{buy};

$venta =~ s/,/./;
$compra =~ s/,/./;

print "riesgo $venta\n";

