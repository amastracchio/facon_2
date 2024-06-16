#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";

my $com = $ej . " " . $url;

my $ret = system($ej,$url,"-o","/tmp/dolarpro");

open(FILE, "/tmp/dolarpro");

my $string = <FILE>;

close FILE;

$string .= "\n";
my %h;
$h = decode_json $string;

my $venta = $h->{sell};
my $compra = $h->{buy};

$venta =~ s/,/./;
$compra =~ s/,/./;

print "venta $venta\n";
print "compra $compra\n";
