#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# seven up
# my $url = 'http://www.cotodigital3.com.ar/sitios/cdigi/browse;jsessionid=qpaACR6-XzgnNlw4F0LiR7DPyIug6nTgKlkLRvFFw2IPuY9Y0DJG!1540125458!-1177585494?_dyncharset=utf-8&Dy=1&Ntt=cloro|1004&Nty=1&Ntk=All|product.sDisp_200&siteScope=ok&_D%3AsiteScope=+&atg_store_searchInput=cloro&idSucursal=200&_D%3AidSucursal=+&search=Ir&_D%3Asearch=+&_DARGS=%2Fsitios%2Fcartridges%2FSearchBox%2FSearchBox.jsp';

my $url = 'https://www.easy.com.ar/tienda/es/easyar/search/para-techos-tirantes';
my $url = 'https://www.easy.com.ar/tienda/es/easyar/search/AjaxCatalogSearchResultContentView?searchTermScope=&searchType=1002&filterTerm=&orderBy=&maxPrice=&showResultsPage=true&langId=-5&beginIndex=1&sType=SimpleSearch&metaData=&pageSize=200&manufacturer=&resultCatEntryType=&catalogId=10051&pageView=image&searchTerm=&minPrice=&categoryId=85659&storeId=10151';

my $url = 'https://www.easy.com.ar/tienda/es/easyar/search/AjaxCatalogSearchResultContentView?searchTermScope=&searchType=1002&filterTerm=&orderBy=&maxPrice=&showResultsPage=true&langId=-5&beginIndex=1&sType=SimpleSearch&metaData=&pageSize=200&manufacturer=&resultCatEntryType=&catalogId=10051&pageView=image&searchTerm=&minPrice=&categoryId=15529&storeId=10151';


# seven up 2.25l 7791813423522

my $com = $ej . " " . $url;

my $precio; my $preciopromuno; my $preciopromdos;

print "# Por ejecutar: $com\n";
my $ret = system($ej,$url,"-o","pro.html","-A","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.112");

print "#url=$url\n";

#  lynx --dump ./pro.html >pro1 
my $ret = system("/usr/bin/lynx --dump ./pro.html >pro1");

open(FILE, "pro.html");

my $precio, $sky, $desc;

while (my $lin = <FILE>) {
	# (34425) Precio por 1 Litro/kilo : $299.00
	# $lin = '(34425) Precio por 1 Litro : $1,299.00';
	#    [86]https://easyar.scene7.com/is/image/EasyArg//1163687
	#       /wcsstore/easyar_CAT_AS/1163687
	#          [87]Pino Cepillado 2x4x2.44 Mts Nc [88]Quick Info
	#
	#
	#             Precio Internet $ 273
	#              
	#$lin =~ s/,//g;
	#if ($lin =~ /\((\d*)\) .*?: \$(.+?)$/) {
	#	# print $lin;
	#	print "$1 $2\n";
	#if ($lin =~ /Pizarra - Rosario.+?\$<\/span> (.+?)<\/span>/s) {
	#if ($lin =~ /https:\/\/easyar.scene7.com\/is\/image\/EasyArg\/\/(\d+})/){
	if ($lin =~ /https:\/\/easyar.scene7.com\/is\/image\/EasyArg\/\/(\d+)/){
		$sku = $1;
	}


	if ($lin =~ /addPrintedSearchPageProduct\(\"(\d+)\"/){
		$sku = $1;
		my $lin = <FILE>;
		if ($lin =~ /, "(.+?)"/){
			$desc = $1;
		}
		my $lin = <FILE>;
		if ($lin =~ /, "(.+?)"/){
			$precio = $1;
			$precio =~ s/\.//g;
		        # sacamos los decimales
			#                 $precio =~ s/,.*//g;
		}
		print "#$sku|$desc\n";
		print $sku . " ". $precio."\n";
	}

#	if ($lin =~ /Precio Internet \$ (.*)/){
#		$precio = $1;
#		print "#$sku|$desc\n";
#		# no imprimimos esperamos un tmas.png (promo)
#		# print $sku . " ". $precio."\n";
#		# leemos la proxima lineas a ver si hay un precio mejor
#		$lin = <FILE>;
#		if ($lin =~ /\[tmas.png\] \$ (.*)/){
#			$precio = $1;
#		}
#		$precio =~ s/\.//g;
#		# sacamos los decimales
#		$precio =~ s/,.*//g;
#		print $sku . " ". $precio."\n";
#
#		undef $precio;
#		undef $sku ;
#		undef $desc ;
##	}
	if ($lin =~ /\](.*)\[\d+]Quick/){
		$desc = $1;
	}
#}
#	print $lin;
}

close FILE;


