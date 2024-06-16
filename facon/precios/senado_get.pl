#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";
my $url = "https://www.senado.gov.ar/micrositios/DatosAbiertos/ExportarListadoBoletinNovedades/json";

my $com = $ej . " " . $url;

my $ret = system($ej,$url,"-k","-o","/tmp/senado_get.txt");

open(FILE, "/tmp/senado_get.txt");


my $string = do { local $/; <FILE> };

close FILE;

#$string =~ s/\n//g;

$string =~ s/,\l\s+\}/   }/g;
#print $string;
my %h;
$h = decode_json $string;


print $h;

die Dumper $h;

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

