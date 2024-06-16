


open (FILE, $ARGV[0])  or die("$!".$ARGV[0]);

my @todos;

my $step = 900;

my $heartbeat = $step*2;


print "# magicaly create by $0\n";
print <<END



source  unix-status
step    $step



END

;
while (<FILE>){

	my @a = split(/:/);
	my @b = split(/ /,$a[0]);
	push @todos, $b[1];

	#data    mk1dataex=mk1_data_ex:* GAUGE:1200:0:U  bamsql *
	print "data\t".$b[1]."=".$b[1].":* GAUGE:$heartbeat:0:U  bamsql *\n";
	
}

close FILE;


print <<END
archives day-avg week-avg month-avg 3month-avg year-avg
times   day yesterday week month 3month

graph   value-* desc="This is collected by the program-collector.  It works by running the specified program (##WILDPART##) and using the result as the value."
        --title 'Tablespaces ocupado ##HOST## - ##WILDPART## (##GRAPHTIME##)'
        --lower-limit 0
        --vertical-label 'percent'
END

;



foreach (@todos){

	print  "\t DEF:".$_."=##DB##:".$_.":AVERAGE\n";
}

print "      CDEF:missing=".$todos[0].",UN,INF,UNKN,IF\n";
print "        --watermark 'bamac -vc'\n";


my $cont = 1;
foreach (@todos){
        print "\t'LINE2:".$_."###COLOR".$cont."##:".$_."'\n";
	$cont++;
	if ($cont == 15) {
		$cont = 1;
	}


}

print "\t'AREA:missing###MISSING##:missing\\l'\n";

foreach (@todos){

      print "\t'GPRINT:".$_.":LAST:".$_.'         = %.2lf\l\''."\n";

}

