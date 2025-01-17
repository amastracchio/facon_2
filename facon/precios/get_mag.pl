#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";
#my $url = "https://ws1.smn.gob.ar/v1/forecast/location/10645";
my $url = "https://www.mercadoagroganadero.com.ar/dll/hacienda2.dll/haciinfo000013";

my $com = $ej . " " . $url;


#curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" https://www.accuweather.com/es/ar/tigre/7333/current-weather/7333 -H "Connection: keep-alive" -H "Accept-Encoding: gzip, deflate" | gzip -d - > pro
#
#
my $ret = system($ej,$url,"-H","User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0","-H","Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8","-H","Connection: keep-alive","-H","Accept-Encoding: gzip, deflate","-o","/tmp/temp_mag.gz");

system("/usr/bin/gzip -df /tmp/temp_mag.gz");


open(FILE, "/tmp/temp_mag");
#open(FILE, "/tmp/pagina");


my $lin = do { local $/; <FILE> };




my $aqi;

#<div class="aq-number">
#                                76
#                                                        </div>
#                                                                                <
#if ($lin =~ /aq-number">.+?(\d+).+?<\/div>/s) {
#	$aqi = $1;
#	print "aqi $aqi\n";
#}

#<div class="detail-item spaced-content">
#                                        <div>Humedad</div>
#                                                                                <div>54&#xA0;%</div>
#                                                                                                                </div>
#if ($lin =~ /Humedad<\/div>.+?<div>(\d*)\&/s) {
# if ($lin =~ /<TD Align="Right"><B>(.+?)<\/B><\/TD><TD Align="Center">/s) {
#if ($lin =~ /<TR VAlign="Middle" height=14><TD Align="Center">Ma&nbsp;(.+?)<\/TD><TD Align="Right">5.948<\/TD><TD Align="Right">930.261.690,00<\/TD><TD Align="Center">477,555<\/TD><TD Align="Left"><TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0" HEIGHT="6"><TR><TD CLASS="clsCeldaVacia" WIDTH="100%" BGCOLOR="#CC0000">&nbsp;<\/TD><TD CLASS="clsCeldaVacia">&nbsp;<\/TD><\/TR><\/TABLE><\/TD><\/TR>/s) {

# NO FUNCO if ($lin =~ /<TR VAlign="Middle" height=14><TD Align="Center">Ma&nbsp;(.+?)<\/TD><TD Align="Right">(.+?)<\/TD><TD Align="Right">(.+?)<\/TD><TD Align="Center">(.+?)<\/TD><TD Align="Left"><TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0" HEIGHT="6"><TR><TD CLASS="clsCeldaVacia" WIDTH="100%" BGCOLOR="#CC0000">&nbsp;<\/TD><TD CLASS="clsCeldaVacia">&nbsp;<\/TD><\/TR><\/TABLE><\/TD><\/TR>/s) {

if ($lin =~ /<TR height=10><\/TR><TR VAlign="Middle" height=14><TD><B>&nbsp;&nbsp;Totales<\/B><\/TD><TD Align="Right"><B>(.+?)<\/B><\/TD><TD Align="Right"><B>(.+?)<\/B><\/TD><TD Align="Center"><B>(.+?)<\/B><\/TD><TD><\/TD><\/TR>/s) {
	my $fecha = "0";
	my $cab_ingresadas = $1;
	my $importe = $2;
	my $ind_arrem = $3;
	$importe =~ s/\.//g;
	$importe =~ s/,00//g;
#	$ind_arrem =~ s/,/./g;
	$ind_arrem =~ s/\.//g;
	$ind_arrem =~ s/(\d+),//g;
        $ind_arrem = $1;;
	#$hum = $1;
	#print "hum $hum\n";
	print "fec $fecha\n";
	$cab_ingresadas =~ s/\.//g;
	print "cabingre $cab_ingresadas\n";
	print "imp $importe\n";
	print "indarr $ind_arrem\n";
	exit 0;
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

