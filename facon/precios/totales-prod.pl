#!/usr/bin/perl

use JSON;
use Data::Dumper;
use Time::HiRes qw( time );


my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";

#my $url = 'http://192.168.0.115:82/cgi-bin/htbusca.cgi?config=htdig&restrict=&exclude=&method=and&format=builtin-long&sort=score&words=francisco';
#my $url = 'http://192.168.0.115:82/cgi-bin/buscahyper.pl?force_regenerate=true&config=%24%26%28CONFIG%29&restrict=%24%26%28RESTRICT%29&exclude=%24%26%28EXCLUDE%29&phrase=francisco&sort=%40score+inumd';
my $url = 'http://buscacatolica.es/cgi-bin/buscahyper.pl?force_regenerate=true&config=%24%26%28CONFIG%29&restrict=%24%26%28RESTRICT%29&exclude=%24%26%28EXCLUDE%29&phrase=francisco&sort=%40score+inumd';
my $com = $ej . " " . $url;

my $start = time();
my $ret = system($ej,$url,"-k","-o","/tmp/search.txt");
my $end = time();
my $dif = $end - $start;
my $dif = int($dif *1000);

print "demdoc $dif\n";
open(FILE, "/tmp/search.txt");


my $string = do { local $/; <FILE> };

close FILE;

#$string =~ s/\n//g;

$string =~ s/,\l\s+\}/   }/g;
#print $string;

$string =~ /(\d+) documentos/s ;
my $encontrados = $1;

if ($string =~/No fue encontrado/){
	$encontrados = 1;
}


print "totdoc $encontrados\n";



1;

