#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# seven up
# my $url = 'http://www.cotodigital3.com.ar/sitios/cdigi/browse;jsessionid=qpaACR6-XzgnNlw4F0LiR7DPyIug6nTgKlkLRvFFw2IPuY9Y0DJG!1540125458!-1177585494?_dyncharset=utf-8&Dy=1&Ntt=cloro|1004&Nty=1&Ntk=All|product.sDisp_200&siteScope=ok&_D%3AsiteScope=+&atg_store_searchInput=cloro&idSucursal=200&_D%3AidSucursal=+&search=Ir&_D%3Asearch=+&_DARGS=%2Fsitios%2Fcartridges%2FSearchBox%2FSearchBox.jsp';

# my $url = 'http://www.cotodigital3.com.ar/sitios/cdigi/browse/catalogo-frescos-frutas-y-verduras-frutas/_/N-1edtocx?Nf=product.startDate|LTEQ+1.5438816E12||product.endDate|GTEQ+1.5438816E12&Nr=AND%28product.language%3Aespa%C3%B1ol%2COR%28product.siteId%3ACotoDigital%29%29&Nrpp=300&Ntk=product.sDisp_200&Ntt=1004';


# Nrpp clave!



#my $url = 'http://www.cotodigital3.com.ar/sitios/cdigi/browse/catalogo-frescos-l%C3%A1cteos-leches/_/N-1uhue0v?Nf=product.endDate|GTEQ+1.5532992E12||product.startDate|LTEQ+1.5532992E12&No=12&Nr=AND%28product.language%3Aespa%C3%B1ol%2COR%28product.siteId%3ACotoDigital%29%29&Nrpp=100&Ntk=product.sDisp_200&Ntt=1004';

#my $url = 'http://www.cotodigital3.com.ar/sitios/cdigi/browse/catalogo-frescos-l%C3%A1cteos-leches/_/N-zpvqr7?Nf=product.endDate|GTEQ+1.5533856E12||product.startDate|LTEQ+1.5533856E12&No=12&Nr=AND%28product.language%3Aespa%C3%B1ol%2COR%28product.siteId%3ACotoDigital%29%29&Nrpp=200&Ntk=product.sDisp_200&Ntt=1004';


#my $url = 'http://www.cotodigital3.com.ar/sitios/cdigi/browse/catalogo-frescos-l%C3%A1cteos/_/N-zpvqr7?Nf=product.endDate|GTEQ+1.5533856E12||product.startDate|LTEQ+1.5533856E12&Nr=AND%28product.language%3Aespa%C3%B1ol%2COR%28product.siteId%3ACotoDigital%29%29&Nrpp=400&Ntk=product.sDisp_200&Ntt=1004';

my $url = 'https://darksky.net/forecast/-34.4071,-58.6889/ca12/en';
my $url = 'https://darksky.net/forecast/-34.4235,-58.5797/ca12/en';



# seven up 2.25l 7791813423522

my $com = $ej . " " . $url;
my $desc;

my $precio; my $preciopromuno; my $preciopromdos;

print "#Por ejecutar: $com\n";
my $ret = system($ej,$url,"-k","-o","pro.html","-A","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.112");

#  lynx --dump ./pro.html >pro1 
my $ret = system("/usr/bin/lynx --dump ./pro.html >pro1");

open(FILE, "pro1");

my $sku;
my $oferta;
my $otro_desc;
my $temp;
my $hum;
my $pres;
my $vis;
my $uvi = 0;
my $wind;
my $dewpt;
while (my $lin = <FILE>) {
	# (34425) Precio por 1 Litro/kilo : $299.00
	# $lin = '(34425) Precio por 1 Litro : $1,299.00';
	$lin =~ s/,/./g;

	#   Wind: 15 kph �
	#  Humidity: 21%
	#    Dew Pt: 3�
	#     UV Index: 0
	#     Visibility: 16 km
        #     Pressure: 1012 hPa
	#    Dew Pt: 15 kph
	if ($lin =~ /Dew Pt: (.+?)�/) {
				$dewpt = $1;
				print "dewpt $1\n";
	}
	#    Wind: 15 kph
	if ($lin =~ /Wind: (.+?) kph/) {
				$wind = $1;
				print "wind $1\n";
	}

	#    UV Index: 0
	if ($lin =~ /UV Index: (.+?)/) {
				$uvi = $1;
	}
	#    Visibility: 16 km
	if ($lin =~ /Visibility: (.+?) km/) {
				$vis = $1;
				print "vis $1\n";
	}
	#    Pressure: 21 hPa
	if ($lin =~ /Pressure: (.+?) hPa/) {
				$pres = $1;
				print "pres $1\n";
	}
					    
	#    Humidity: 21%
	if ($lin =~ /Humidity: (.+?)%/) {
				$hum = $1;
				print "hum $1\n";
	}
	# temperatura
	if ($lin =~ /Icon (\d*)� /) {
		#print "$lin";
		#if ($lin =~ /Icon (.+?)� /) {
				$temp = $1;
				print "temp $1\n";
	}
	if ($lin =~ /\$(.+?)c\/u/) {

		$oferta =  $1;
		$oferta = int($oferta);
	}

	if ($lin =~ /\((\d+)\)/) {
		$sku = $1;
	}
	if ($lin =~ /    \$(.+?)$/) {

		# otra oferta pedorra
		$otro_desc = $1;
		$otro_desc = int($otro_desc);
	}
	if ($lin =~ /\[\d+\](.+)/){

		$desc = $1;
	}
#	if ($lin =~ /\((\d*)\) .*?: \$(.+?)$/) {
	if ($lin =~ /PRECIO CONTADO \$(.+?)$/) {
		 my $prec = $1;
		 $prec = int($prec);
#		 print $1 . "\n";

		if ($sku >0 ) {
	 		print "#$sku|$desc\n";
			if ($oferta) {
					$prec = $oferta;
			}
			if ($otro_desc) {
					$prec = $otro_desc;
			}
			print "$sku $prec\n" ;
		}
	 	$sku = "" ;
		$oferta = "";
		$otro_desc = "";
	}
#	print $lin;
}

print "uvin $uvi\n";
close FILE;



