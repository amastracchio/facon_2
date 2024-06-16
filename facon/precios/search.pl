#!/usr/bin/perl

use JSON;
use Data::Dumper;
use Time::HiRes qw( time );


my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";

# my $url = 'http://buscacatolica.es/cgi-bin/htbusca?config=htdig&restrict=&exclude=&method=and&format=builtin-long&sort=score&words=francisco';

my $url = 'http://buscacatolica.es/cgi-bin/buscahyper.pl?config=%24%26%28CONFIG%29&restrict=%24%26%28RESTRICT%29&exclude=%24%26%28EXCLUDE%29&phrase=francisco&sort=%40score+inumd&force_regenerate=true';


my $com = $ej . " " . $url;

my $start = time();
unlink("/tmp/search.txt");
my $ret = system($ej,$url,"-k","-o","/tmp/search.txt");
my $end = time();
my $dif = $end - $start;
my $dif = int($dif *1000);

print "demhtbu $dif\n";
open(FILE, "</tmp/search.txt");


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

my $url = 'http://buscacatolica.es/cgi-bin/search.pl?config=htdig&restrict=&exclude=&method=and&format=builtin-long&sort=score&words=francisco';
my $com = $ej . " " . $url;


my $start = time();
unlink("/tmp/search.txt");
my $ret = system($ej,$url,"-k","-o","/tmp/search.txt");
my $end = time();
my $dif = $end - $start;
my $dif = int($dif *1000);


print "demseca $dif\n";
open(FILE, "</tmp/search.txt");


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

print "resseca $encontrados\n";


# search.pl NO CACHE

my $url = 'http://buscacatolica.es/cgi-bin/search.pl?config=htdig&restrict=&exclude=&method=and&format=builtin-long&sort=score&words=francisco&force_regenerate=true&FACONFACON';
my $com = $ej . " " . $url;


my $start = time();
unlink("/tmp/search.txt");
my $ret = system($ej,$url,"-k","-o","/tmp/search.txt");
my $end = time();
my $dif = $end - $start;
my $dif = int($dif *1000);


print "demsenc $dif\n";
open(FILE, "</tmp/search.txt");





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


print "ressenc $encontrados\n";



#estraider

#my $url = 'http://buscacatolica.es/cgi-bin/estsearch.cgi?phrase=francisco&max=8&clshow=0&drep=0&sort=score&expr=wild&FACONFACON';

my $url = 'http://buscacatolica.es/cgi-bin/estseek.cgi?phrase=francisco&perpage=10&attr=&order=%40cdate+numa&clip=-1&navi=0&FACONFACON';
my $com = $ej . " " . $url;


my $start = time();
unlink("/tmp/search.txt");
my $ret = system($ej,$url,"-k","-o","/tmp/search.txt");
my $end = time();
my $dif = $end - $start;
my $dif = int($dif *1000);


print "demest $dif\n";
open(FILE, "</tmp/search.txt");



my $string = do { local $/; <FILE> };

close FILE;

#$string =~ s/\n//g;

$string =~ s/,\l\s+\}/   }/g;
#print $string;

my $encontrados;
# 36756</em> hits<
if ($string =~ /(\d+)<\/em> hits/s ){
	$encontrados  =  $1;
}

# about <strong>35974</strong> 
if ($string =~ /about <strong>(\d+)<\/strong>/s ){
	$encontrados  =  $1;
}


if ($string =~/No fue encontrado/){
	                $encontrados = 1;
}


print "resest $encontrados\n";



1;
