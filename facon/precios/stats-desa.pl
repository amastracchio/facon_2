#!/usr/bin/perl

use YAML;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";
my $url = 'http://192.168.0.115:82/cgi-bin/stats.pl';


my $com = $ej . " " . $url;

unlink("/tmp/senado_get.txt");
my $ret = system($ej,$url,"-k","-o","/tmp/senado_get.txt");

open(FILE, "/tmp/senado_get.txt");


my $string = do { local $/; <FILE> };

close FILE;

#$string =~ s/\n//g;

$string =~ s/,\l\s+\}/   }/g;
#print $string;
my %h;
$h = YAML::Load $string;


print "cont ".$h->{CONT}."\n";
print "contx ".$h->{CONT}."\n";
print "runtime ".int($h->{RUNTIME_ACC})."\n";
print "sizeacc ".int($h->{SIZE_ACC})."\n";
print "dos ".$h->{RES_CODE}->{200}."\n";
print "noespanol ".$h->{NOESPANOL}."\n";
print "noespanolx ".$h->{NOESPANOL}."\n";
print "noespadel ".$h->{NOESPANOLDEL}."\n";


my $url_vat = "http://m.vatican.va";
my $url_vato = "https://www.vatican.va";
my $url_vati = "http://www.vatican.va";
my $url_press = "http://press.vatican.va";

my $vat_sum = $h->{$url_vat};

$vat_sum = $vat_sum +  $h->{$url_vato};
$vat_sum = $vat_sum +  $h->{$url_vati};
$vat_sum = $vat_sum +  $h->{$url_press};
# print "vatican ".$h->{$str}."\n";
print "vatican ".$vat_sum."\n";



my $str = "https://www.enticonfio.org";
print "enticon ".$h->{$str}."\n";

my $str = "https://www.infocatolica.com";
print "infocat ".$h->{$str}."\n";

#die Dumper $h;

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

