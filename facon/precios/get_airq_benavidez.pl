#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";
my $url = "https://ws1.smn.gob.ar/v1/forecast/location/10645";
my $url = "https://www.accuweather.com/es/ar/tigre/7333/air-quality-index/7333";

my $com = $ej . " " . $url;


#curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" https://www.accuweather.com/es/ar/tigre/7333/current-weather/7333 -H "Connection: keep-alive" -H "Accept-Encoding: gzip, deflate" | gzip -d - > pro
#
#
my $ret = system($ej,$url,"-H","User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0","-H","Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8","-H","Connection: keep-alive","-H","Accept-Encoding: gzip, deflate","-o","/tmp/temp_smn.gz");

system("/usr/bin/gzip -df /tmp/temp_smn.gz");

open(FILE, "/tmp/temp_smn");

my $lin = do { local $/; <FILE> };




my $aqi;

#<div class="aq-number">
#                                76
#                                                        </div>
#                                                                                <
if ($lin =~ /aq-number">.+?(\d+).+?<\/div>/s) {
	$aqi = $1;
	print "aqi $aqi\n";
}
exit 0;

#<div class="detail-item spaced-content">
#                                        <div>Humedad</div>
#                                                                                <div>54&#xA0;%</div>
#                                                                                                                </div>
if ($lin =~ /Humedad<\/div>.+?<div>(\d*)\&/s) {
	$hum = $1;
	print "hum $hum\n";
}

#<div class="detail-item spaced-content">
#                                        <div>&#xCD;ndice UV m&#xE1;x.</div>
#                                                                                <div>1 Bajo</div>

if ($lin =~ /;x.<\/div>.+?<div>(\d*) /s) {
	$uvin = $1;
	print "uvin $uvin\n";
}

#<div class="detail-item spaced-content">
#                                        <div>Punto de roc&#xED;o</div>
#                                                                                <div>18&#xB0; C</div>
if ($lin =~ /xED;o<\/div>.+?<div>(\d*)\&/s) {
	$dewpt = $1;
	print "dewpt $dewpt\n";
}

#<div class="detail-item spaced-content">
#                                        <div>Nubosidad</div>
#                                                                                <div>35&#xA0;%</div>
#                                                                                                                </div>
if ($lin =~ /Nubosidad<\/div>.+?<div>(\d*)\&\#/s) {
	$nub = $1;
	print "nub $nub\n";
}
#<div class="detail-item spaced-content">
#                                        <div>Techo de nubes</div>
#                                                                                <div>12200 m</div>
#                                                                                                                </div>
if ($lin =~ /Techo de nubes<\/div>.+?<div>(\d*) m/s) {
	$techo = $1;
	print "techo $techo\n";
}
close FILE;


die;


my $wind = $h->{wind};
print "wind ".$wind->{speed}."\n";
print "vis ".$h->{visibility}. "\n";
print "pres ".$h->{pressure}. "\n";
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

