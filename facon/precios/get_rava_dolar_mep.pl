#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";
my $url = "http://www.rava.com/";


my $com = $ej . " " . $url;

my $ret = system("$ej $url -o /tmp/dolarravamep");

# print "Por ejecutar $ej $url -o /tmp/riegorava\n";

open(FILE, "/tmp/dolarravamep");

my $lin = do { local $/; <FILE> };

my $valor;

#  <td style=""><span class="fontsize6" style="font-weight:bold">1.011,00</span></td>
# if ($lin =~ /Pizarra - Rosario.+?\$<\/span> (.+?)<\/span>/s) {
#
#if ($lin =~ /:bold">(.+?),00<\/span>/s) {
if ($lin =~ /DOLAR MEP.+?c1">(.+?)<\/td>/s) {
      $valor = $1;
      $valor =~ s/\.//;
      $valor =~ s/,/./;
#      $valor = $valor /100;
      print "dolarmep $valor\n";
}
#

