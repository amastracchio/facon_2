#!/usr/bin/perl

use JSON;
use Data::Dumper;
use Time::HiRes qw( time );


my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";

#my $url = 'http://192.168.0.115:82/cgi-bin/htbusca.cgi?config=htdig&restrict=&exclude=&method=and&format=builtin-long&sort=score&words=francisco';
my $url = 'http://192.168.0.115:82/cgi-bin/buscahyper.pl?config=%24%26%28CONFIG%29&restrict=%24%26%28RESTRICT%29&exclude=%24%26%28EXCLUDE%29&phrase=francisco&sort=%40score+inumd';
my $com = $ej . " " . $url;

my $start = time();
my $ret = system($ej,$url,"-k","-o","/tmp/search.txt");
my $end = time();
my $dif = $end - $start;
my $dif = int($dif *1000);

print "demhtbu $dif\n";
open(FILE, "/tmp/search.txt");


my $string = do { local $/; <FILE> };

close FILE;

#$string =~ s/\n//g;

$string =~ s/,\l\s+\}/   }/g;
#print $string;

$string =~ /(\d+) encontrados/s ;
my $encontrados = $1;

if ($string =~/No fue encontrado/){
	$encontrados = 1;
}


print "reshtbu $encontrados\n";


# search.pl cache

my $url = 'http://192.168.0.115:82/cgi-bin/search.pl?config=htdig&restrict=&exclude=&method=and&format=builtin-long&sort=score&words=francisco';
my $com = $ej . " " . $url;

unlink "/tmp/search.txt";

my $start = time();
my $ret = system($ej,$url,"-k","-o","/tmp/search.txt");
my $end = time();
my $dif = $end - $start;
my $dif = int($dif *1000);


print "demseca $dif\n";
open(FILE, "/tmp/search.txt");


my $string = do { local $/; <FILE> };

close FILE;


#$string =~ s/\n//g;

$string =~ s/,\l\s+\}/   }/g;
#print $string;


$encontrados = 0;
if ($string =~ /(\d+) encontrados/s) {
	$encontrados = $1;
}



if ($string =~/No fue encontrado/){
	$encontrados = 1;
}


print "resseca $encontrados\n";


# search.pl NO CACHE

my $url = 'http://192.168.0.115:82/cgi-bin/search.pl?config=htdig&restrict=&exclude=&method=and&format=builtin-long&sort=score&words=francisco&force_regenerate=true&FACONFACON';
my $com = $ej . " " . $url;


my $start = time();
my $ret = system($ej,$url,"-k","-o","/tmp/search.txt");
my $end = time();
my $dif = $end - $start;
my $dif = int($dif *1000);


print "demsenc $dif\n";
open(FILE, "/tmp/search.txt");





my $string = do { local $/; <FILE> };

close FILE;

#$string =~ s/\n//g;

$string =~ s/,\l\s+\}/   }/g;
#print $string;

$string =~ /(\d+) encontrados/s ;

$encontrados = 0;

if ($string =~/No fue encontrado/){
	$encontrados = 1;
}


print "ressenc $encontrados\n";




1;

