#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";
my $url = "https://ws1.smn.gob.ar/v1/forecast/location/10645";
my $url = "https://ws1.smn.gob.ar/v1/weather/location/10645";
my $url_token = "https://www.smn.gob.ar";

my $ret = system($ej,$url_token,"-o","/tmp/token_smn");


open(FILE, "/tmp/token_smn");

my $lin = do { local $/; <FILE> };


my $token;
if ($lin =~ /'token', '(.+)?'\);/s) {
        $token = $1;
}  else {
	die "No puedo obtener el token";
}


my $com = $ej . " " . $url;

#  my $ret = system($ej,$url,"-H","Authorization: JWT eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ3ZWIiLCJzY29wZXMiOiJST0xFX1VTRVJfRk9SRUNBU1QsUk9MRV9VU0VSX0dFT1JFRixST0xFX1VTRVJfSElTVE9SWSxST0xFX1VTRVJfSU1BR0VTLFJPTEVfVVNFUl9NQVAsUk9MRV9VU0VSX1NUQVRJU1RJQ1MsUk9MRV9VU0VSX1dBUk5JTkcsUk9MRV9VU0VSX1dFQVRIRVIiLCJpYXQiOjE2MTM4NTk3MTcsImV4cCI6MTYxMzk0NjExN30.CMfbZU7Xs5HKoMyd7oVcEncuDNVH6NJWepR5rDWRL74","-o","/tmp/temp_smn");

my $ret = system($ej,$url,"-H","Authorization: JWT $token","-o","/tmp/temp_smn");

open(FILE, "/tmp/temp_smn");
my $string = <FILE>;
close FILE;


$string .= "\n";
my %h;
$h = decode_json $string;


my $wind = $h->{wind};
print "wind ".$wind->{speed}."\n";
print "vis ".$h->{visibility}. "\n";
print "pres ".int($h->{pressure}). "\n";
print "hum ".$h->{humidity}. "\n";
print "temp ".$h->{temperature}. "\n";

# Es para sacar el "estado" por ejemplo el id 3 es "depejado"
my $weather;
$weather = $h->{weather};

print "estado ".$weather->{id}."\n";
print "estado_descripcion ".$weather->{description}."\n";
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

