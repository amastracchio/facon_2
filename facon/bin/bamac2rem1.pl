#!/usr/bin/perl

use Data::Dumper;

my $in;
my @a;
my %s;
my %u;
my $rep;



my $prd = $ARGV[0];



open (FILEIN, ">>/tmp/bamac2rem_in.log");

print FILEIN "iniciando: parametro =  $prd\n";

# La columna 4 es la que tiene el estado
# estados pueden ser INCIDENTE TERMINE HORAIRE_DEPASSE EXECUTION_EN_COURS
#
# Toma el ULTIMO ESTADO DE CADA INTERFAZ!!
# OJOOO

<STDIN>;
while ($in = <STDIN>) {
# toobig 	print FILEIN "input =  $in";
	@a = split(/\s+/, $in);

	my $upr = $a[2];
	my $sta = $a[4];

	$s{$a[4]}++;
        $u{$upr} = $sta;
	$, = ',';
#	unless ($in =~ /TERMINE/) {
#		$rep = $rep . $in;
#        }
	
}
close FILEIN;

my @columns = qw(INCIDENTE HORAIRE_DEPASSE EXECUTION_EN_COURS TERMINE ATTENTE_EVENEMENT);

#
# El orden es importante!!
#


my %s;

# inc o ter o etc unicos por uproc
my $k;
foreach $k (keys %u) {
    my $sta = $u{$k};
    $s{$sta}++;  
    unless ($sta =~/TERMINE/) {
	$rep = $rep .  $k . "\t" . $sta . "\n";
    }
    
}


foreach (@columns) {
     print (defined $s{$_} ? $s{$_} : 0) ;
     print "\n";
}


if ($prd) {

		open (FILE, ">/tmp/$prd.html") || die "no se puede escribir /tmp/$prd.html";

		if ($s{INCIDENTE} || $s{HORAIRE_DEPASSE} || $s{EXECUTION_EN_COURS} || $s{ATTENTE_EVENEMENT}){

			print FILE "<h2>Reporte de eventos no terminados:</h2>";
			print FILE "<pre>";
			print FILE $rep;
			print FILE "</pre>";
		} else {

			# pisamos los datos
		}

		close FILE;

} else {



}


