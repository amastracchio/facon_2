#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# seven up
my $url = 'https://news.agrofy.com.ar';

# seven up 2.25l 7791813423522

my $com = $ej . " " . $url;

my $precio; my $preciopromuno; my $preciopromdos;

print "Por ejecutar: $ej $url\n";
my $ret = system($ej,$url,"-o","pro1.html","-A","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.112");

#  lynx --dump ./pro.html >pro1 
my $ret = system("/usr/bin/lynx --dump ./pro1.html >pro2");

open(FILE, "pro2");


#my $lin = do { local $/; <FILE> };

my $valor;

while ($lin = <FILE>){
# if ($lin =~ /Pizarra - Rosario.+?\$<\/span> (.+?)<\/span>/s) {
if ($lin =~ /Pizarra - Rosario/) {
		$valor = substr($lin,index($lin,"\$")+2,20);
		$valor =~ s/,.+//g;
		$valor =~ s/\.//g;
		# print $lin;
		#$valor = $1;
		#$valor =~ s/\.//;
	#$valor =~ s/,//;
	#	$valor = $valor /100;
		print "sojanac $valor\n";
		exit;
}

}

close FILE;



