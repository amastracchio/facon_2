#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# seven up
my $url = 'https://www.cotodigital3.com.ar/sitios/cdigi/browse;jsessionid=qpaACR6-XzgnNlw4F0LiR7DPyIug6nTgKlkLRvFFw2IPuY9Y0DJG!1540125458!-1177585494?_dyncharset=utf-8&Dy=1&Ntt=cloro|1004&Nty=1&Ntk=All|product.sDisp_200&siteScope=ok&_D%3AsiteScope=+&atg_store_searchInput=cloro&idSucursal=200&_D%3AidSucursal=+&search=Ir&_D%3Asearch=+&_DARGS=%2Fsitios%2Fcartridges%2FSearchBox%2FSearchBox.jsp';

# seven up 2.25l 7791813423522

my $com = $ej . " " . $url;
my $desc;

my $precio; my $preciopromuno; my $preciopromdos;

print "#Por ejecutar: $com\n";
my $ret = system($ej,$url,"-k","-o","pro.html","-A","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.112");

#  lynx --dump ./pro.html >pro1 
my $ret = system("/usr/bin/lynx --dump ./pro.html >pro1");

open(FILE, "pro1");

while (my $lin = <FILE>) {
	# (34425) Precio por 1 Litro/kilo : $299.00
	# $lin = '(34425) Precio por 1 Litro : $1,299.00';
	$lin =~ s/,/./g;

	if ($lin =~ /\[\d+\](.+)/){

		$desc = $1;
	}
	if ($lin =~ /\((\d*)\) .*?: \$(.+?)$/) {
#		 print $1 . "\n";
		my $precio = $2;
		$precio = int($precio);
	 	print "#$1|$desc\n";
		print "$1 $precio\n";
	}
#	print $lin;
}

close FILE;



