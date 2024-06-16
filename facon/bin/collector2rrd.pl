use Data::Dumper;

# Archivo indice de SKU
open (SKU , "/root/precios/sku.csv");

# ARchio salida de datos del collector (program)
open (SALIDA, "/root/precios/datos");
my %hash;
my @ar;
my $strfinal;
my @datas;
my $url;

# lineas por grafico
my $limitgraph = 4;

# Carga sku's a memoria
while (my $lin = <SKU>) {

	chop($lin);
	@ar = split('\|',$lin); 
	$hash{$ar[0]} = $ar[1];
}
close SKU;

while (my $lin = <SALIDA>){
	if ($lin =~ /^#url=(.*)/) {
		$url =  $1;
	}
	next if $lin =~ /^#/;
	push(@datas, (split(" ",$lin))[0]);
}


close SALIDA;

my $head = "
#
# Powered by $0
#
source  program
step    300


";

$strfinal = $head;

my $lin;

foreach  $lin (@datas){
		$strfinal .= "data    data$lin=$lin  GAUGE:1200:0:U\n";
		$strfinal .= "data    ddata$lin=$lin  DERIVE:1200:0:U\n";
		$strfinal .= "alert    data$lin delta< 10 10 10 \n";
}

$strfinal .= "data    responsetime=".$datas[0]."-response GAUGE:1200:0:U\n";

$strfinal .= "
archives day-avg week-avg month-avg 3month-avg year-avg
times           day yesterday week month 3month year

";

#foreach  $lin (@datas){
#		$strfinal .= "      DEF:data$lin=##DB##:data$lin:AVERAGE\n";
#}

my $cont;
#foreach  $lin (@datas){
#		$cont++;
#		my $desc = $hash{$lin};
#		$strfinal .= "      'LINE2:data$lin###COLOR$cont##:$desc'\n";
#}

#foreach  $lin (@datas){
#		my $desc = $hash{$lin};
#		$strfinal .= "      'GPRINT:data$lin:LAST:$desc last=%.1lf'\n";
#}
#

my $break =  0;
my $graph_count = 0;

foreach $lin (@datas){

		if ($break ==0 ) {

			$graph_count++;
			$strfinal .= "
graph   value$graph_count-* desc=\"This is collected by the program-collector.  It works by running the specified program (##WILDPART##) $url .\"
	                --title '##HOST## - ##WILDPART## Auto Graph #$graph_count (##GRAPHTIME##)'
		        --watermark 'ariel mastracchio'
		        --vertical-label 'unidades'

";
			$cont = 0;
		}

		$cont++;
		my $desc = $hash{$lin};
		$strfinal .= "      DEF:data$lin=##DB##:data$lin:AVERAGE\n";
		$strfinal .= "      'LINE2:data$lin###COLOR$cont##:$desc SKU $lin ' \n";
	# $strfinal .= "      'GPRINT:data$lin:LAST:$desc last=%.1lf'\n";
		$strfinal .= "      'GPRINT:data$lin:LAST: last=%.1lf\\n'\n";

		$break++;
		if ($break >$limitgraph) {
			$break = 0;
		}

}


$strfinal .= "\n";


print $strfinal;


