#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";
my $url = "https://mercados.ambito.com/home/general";

my $com = $ej . " " . $url;

my $ret = system($ej,$url,"-o","/tmp/ambitodolar");

open(FILE, "/tmp/ambitodolar");

my $string = <FILE>;

close FILE;

$string .= "\n";
my %h;
$h = decode_json $string;


my @valores;

@valores = @$h;


my $hash = $valores[0];

my $compra = %$hash->{compra};
my $venta = %$hash->{venta};
$venta =~ s/,/./;
$compra =~ s/,/./;

print "oficompra ".$compra."\n";
print "ofiventa ".$venta."\n";

#die;
#die Dumper @valores;
#my $venta = $h->{sell};
#my $compra = $h->{buy};
#
#$venta =~ s/,/./;
#$compra =~ s/,/./;

#print "venta $venta\n";
#print "compra $compra\n";

