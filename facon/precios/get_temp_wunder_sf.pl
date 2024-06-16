#!/usr/bin/perl

use JSON;
use Data::Dumper;

my $uvin = 0;
my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";
my $url = "https://ws1.smn.gob.ar/v1/forecast/location/10645";
my $url = "https://www.accuweather.com/es/ar/tigre/7333/current-weather/7333";
my $url = "https://www.wunderground.com/dashboard/pws/INAVARRO2";
my $url = "https://www.wunderground.com/dashboard/pws/ISANFERN22";
#my $url = "https://www.wunderground.com/dashboard/pws/ITIGRE10";

my $com = $ej . " " . $url;


#curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" https://www.accuweather.com/es/ar/tigre/7333/current-weather/7333 -H "Connection: keep-alive" -H "Accept-Encoding: gzip, deflate" | gzip -d - > pro
#
#
my $ret = system($ej,$url,"-H","User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0","-H","Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8","-H","Connection: keep-alive","-H","Accept-Encoding: gzip, deflate","-o","/tmp/temp_smn.html.gz");

system("/usr/bin/gzip -df /tmp/temp_smn.html.gz");


#  lynx --dump ./pro.html >pro1
my $ret = system("/usr/bin/lynx --dump /tmp/temp_smn.html >pro1");
#
#  open(FILE, "pro1");

#open(FILE, "/tmp/temp_smn");
open(FILE, "pro1");

my $lin = do { local $/; <FILE> };




my $temp;
my $pres;
my $wind;
my $gust;
my $hum;
my $dewpt;
my $prerat;
# nubosidad %
my $nub;
# techo de nubes
my $techo;
	        # (34425) Precio por 1 Litro/kilo : $299.00
		#         if ($lin =~ /\((\d*)\) .*?: \$(.+?)$/) {
		#                         print $lin;
		#                                         print " match ! $1 - $2\n";
		# <span class="header-temp">28&#xB0;<span class="unit">C</span></span>
#if ($lin =~ /<span class="header-temp">.+?(\d*)\&/s) {
#   Current Conditions
#      85.9 F
#       
#if ($lin =~ /Current Conditions.+?(.?) F/s) {
if ($lin =~ /Current Conditions.+?(\d+)(?:\.(\d+))* F/s) {
	$temp =  $1. ".". $2;
	$temp = int(($temp -32) * 5/9);
	print "temp $temp\n";
}
# <div>&#x2193; 1010 mbar</div>
if ($lin =~ /; (\d*) mbar/) {
	$pres = $1;
	print "pres $pres\n";
}

#  Viento</div>
#                                         <div>17 km/h</div>
#if ($lin =~ /; (\d*) mbar/) {

if ($lin =~ /Viento<\/div>.+?<div>(\d*) km/s) {
	$wind = $1;
	print "wind $wind\n";
}

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
}

#<div class="detail-item spaced-content">
#                                        <div>Punto de roc&#xED;o</div>
#                                                                                <div>18&#xB0; C</div>
#if ($lin =~ /xED;o<\/div>.+?<div>(\d*)\&/s) {
#	$dewpt = $1;
#	print "dewpt $dewpt\n";
#}
#
#   DEWPOINT
#      51.0 F
#       
if ($lin =~ /DEWPOINT.+?(\d+)(?:\.(\d+))* F/s) {
	$dewpt =  $1. ".". $2;
	$dewpt = int(($dewpt -32) * 5/9);
	print "dewpt $dewpt\n";
}

#   HUMIDITY
#      28 %
#       
if ($lin =~ /HUMIDITY.+?(\d+) %/s) {
	$hum =  $1;
	print "hum $hum\n";
}

#   PRECIP RATE
#      0.00 in/hr
#       

if ($lin =~ /PRECIP RATE.+?(\d+)(?:\.(\d+))* in/s) {
	$prerat =  $1. ".". $2;
	$prerat = int($prerat * 25.4);
	print "prerat $prerat\n";
}
#    PRECIP ACCUM
#       0.00 in
#        
if ($lin =~ /PRECIP ACCUM.+?(\d+)(?:\.(\d+))* in/s) {
	$preacc =  $1. ".". $2;
	$preacc = int($preacc * 25.4);
	print "preacc $preacc\n";
}

#    PRESSURE
#       29.81 in
#        
if ($lin =~ /PRESSURE.+?(\d+)(?:\.(\d+))* in/s) {
        $pres =  $1. ".". $2;
        $pres = int($pres /0.029530);
        print "pres $pres\n";
}

# parte de wind
#   WIND & GUST
#      0.0  / 0.0 mph
#if ($lin =~ /WIND & GUST.+?(\d+)(?:\.(\d+))*  \/ (\d+)(?:\.(\d+))* mph/s) {
if ($lin =~ /WIND & GUST.+?(\d+)(?:\.(\d+))*  \//s) {
        $wind =  $1. ".". $2;
	$wind = int($wind * 1.609344);
        print "wind $wind\n";
}

# parte de GUST (rafagas)
#   WIND & GUST
#      0.0  / 0.0 mph
#if ($lin =~ /WIND & GUST.+?(\d+)(?:\.(\d+))*  \/ (\d+)(?:\.(\d+))* mph/s) {
if ($lin =~ /WIND & GUST.+? \/ (\d+)(?:\.(\d+))* mph/s) {
        $gust =  $1. ".". $2;
	$gust = int($gust * 1.609344);
        print "gust $gust\n";
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


exit 0;


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
