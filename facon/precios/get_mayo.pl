#!/usr/bin/perl

use JSON;
use Data::Dumper;

use Getopt::Std;

my $debug;

# nordelta 9-3-138


my $ej = "/usr/bin/curl";
my $output = "/tmp/precios_mayo.txt";
my $html = "/root/3p/ht/htdocs/precios.html";




# minorista
# my $url = "https://d3e6htiiul5ek9.cloudfront.net/prod/comparativa?array_sucursales=9-3-138,10-1-183,23-1-6204,15-1-116,12-1-197&array_productos=";


# 7795184946710&
#
my $url = "https://d3e6htiiul5ek9.cloudfront.net/prod/comparativa?array_sucursales=64-1-19,63-1-2,60-1-0015,65-1-13&entorno=mayoristas&array_productos=";


my $array_productos;
if (@ARGV) {
	$array_productos = join(',',@ARGV);

} else {

	# leche y galletitas bonafide
	# $array_productos = "7793940448003,7792360071525";
	$array_productos = "7790742108807";
}

$url .= $array_productos;



# yerba taragui 7790387113310 
# seven up 7791813423522
# seven up


# seven up 2.25l 7791813423522

my $com = $ej . " " . $url;

open(OUTPUT,">",$output);
open(HTML,">",$html);
print OUTPUT "Por ejecutar: $com\n" ;
my $ret = system($ej,$url,"-o","pro");

open(FILE, "pro");

my $string = <FILE>;

close FILE;

$string .= "\n";
my %h;
$h = decode_json $string;

my @a = $h;

print OUTPUT "Total Productos: ".$h->{totalProductos} . "\n" ;
print OUTPUT  "Total Sucursales: ".$h->{totalSucursales} . "\n" ;

my $a = $h->{sucursales};

print HTML "<table border=1>";
print HTML "<tr><td>prodid</td><td>Unidad</td><td>descripcion</td><td>precioLista</td><td>precio.prom2<td>desc.promo2</td><td>precio.prom1</td><<td>desc.promo1</td></tr>\n";

foreach my $suc (@$a) {
			print OUTPUT "-"x80;
			print  OUTPUT "\n" ;
			print OUTPUT  $suc->{banderaDescripcion} . "\t".$suc->{sucursalNombre}. "\t".$suc->{localidad} . "\t".$suc->{id}."\t".$suc->{sucursalTipo}."\n" ;
			print HTML  "<td colspan=7>".$suc->{banderaDescripcion} . "\t".$suc->{sucursalNombre}. "\t".$suc->{localidad} . "\t".$suc->{id}."\t".$suc->{sucursalTipo}."</td>\n" ;
			print OUTPUT  "Acualizado Hoy: ".$suc->{actualizadoHoy} ."\n" ;
			print OUTPUT   "Total Productos: ".$suc->{totalProductos} ."\n" ;
#			print OUTPUT   "Total Sugeridos: ".$suc->{totalSugeridos} ."\n" ;
			print  OUTPUT  "Suma Lista Precio Total: ".$suc->{sumaPrecioListaTotal} ."\n" ;
			my $p = $suc->{productos};

			print OUTPUT Dumper $p;
			my $lin;


			foreach my $productos (@$p) {
  
				print HTML "<tr>";
				$lin = "";
				
				my $preclista;
				my $prodid = $productos->{id};
				my $precpromouno;
				my $precpromodos;
				my $unidad_venta = $productos->{unidad_venta};

				$unidad_venta = 1 unless  $productos->{unidad_venta};


				$preclista = $productos->{precio_unitario_con_iva} ;

				# print Dumper $productos; 
				$lin = "Unidad_venta: ".$productos->{unidad_venta}  if $productos->{unidad_venta} ;
				$lin .= "\t";
				$lin .= "PrecioLista: ".$productos->{precioLista} if $productos->{precioLista} ;
				$lin .= "\t";
				$lin .= "PrecioUnitarioconvIva: ".$productos->{precio_unitario_con_iva} if $productos->{precio_unitario_con_iva} ;
				$lin .= "\t";



			        print HTML "<td>".$productos->{id} . "</td>" ."<td>".$unidad_venta."</td>"."<td>". $productos->{id_string}." ". $productos->{marca}." ".$productos->{presentacion}." ".$productos->{nombre}."</td>\n" ;


				print HTML "<td>".$preclista."</td>" ;
#				print HTML  "<td>".$productos->{precio_unitario_con_iva} ."</td>";
				

				# Parse de promos
				$hpromdos = $productos->{promo2};
				$hpromuno = $productos->{promo1};

				if  ($hpromdos->{descripcion}) {

					$precpromodos =$hpromdos->{precio_unitario_con_iva};

#					$lin .= "promo2.precio: ". $hpromdos->{precio} if $hpromdos->{precio} ;
					$lin .= "\t";
					$lin .= "promo2.precio_unitario_con_iva: ". $hpromdos->{precio_unitario_con_iva} if $hpromdos->{precio_unitario_con_iva} ;
					$lin .= "\t";
					$lin .= "promo2.precio_unitario_sin_iva: ". $hpromdos->{precio_unitario_sin_iva}  if $hpromdos->{precio_unitario_sin_iva} ;
					$lin .= "\t";
					$lin .= "promo2.descripcion: ". $hpromdos->{descripcion}  if $hpromdos->{descripcion} ;
					$lin .= "\t";


#					print HTML "<td>".$hpromdos->{precio} ."</td>";
					print HTML "<td>".$hpromdos->{precio_unitario_con_iva} ."</td>";
#					print HTML "<td>".$hpromdos->{precio_unitario_sin_iva} ."</td>";
					print HTML "<td>".$hpromdos->{descripcion} ."</td>";
				$lin .= "\t";
				};

				if  ($hpromuno->{descripcion}) {

					$precpromuno =$hpromuno->{precio_unitario_con_iva};

#					$lin .= "promo1.precio: ". $hpromuno->{precio} if $hpromuno->{precio} ;
					$lin .= "\t";
					$lin .= "promo1.precio_unitario_con_iva: ". $hpromuno->{precio_unitario_con_iva} if $hpromuno->{precio_unitario_con_iva} ;
					$lin .= "\t";
					$lin .= "promo1.precio_unitario_sin_iva: ". $hpromuno->{precio_unitario_sin_iva}  if $hpromuno->{precio_unitario_sin_iva} ;
					$lin .= "\t";
					$lin .= "promo1.descripcion: ". $hpromuno->{descripcion}  if $hpromuno->{descripcion} ;
					$lin .= "\t";

				#				print HTML "<td>".$hpromuno->{precio}."</td>";
					print HTML "<td>".$hpromuno->{precio_unitario_con_iva}."</td>";
#					print HTML "<td>".$hpromuno->{precio_unitario_sin_iva}."</td>";
					print HTML "<td>".$hpromuno->{descripcion}."</td>";
				};

				

				$lin .= "PrecioUnitariosinIva: ".$productos->{precio_unitario_sin_iva} if $productos->{precio_unitario_sin_iva} ;
				$lin .= "\t";
			

			
				$lin .=  "id: ".$productos->{id} . " id_string:" . $productos->{id_string}. " marca:". $productos->{marca}." resentacion:".$productos->{presentacion}." nombre:".$productos->{nombre}."\n" ;

				print OUTPUT $lin ;
				print $suc->{id} .":" . $prodid . ":preclista ". $preclista ."\n";
				print $suc->{id} .":" . $prodid . ":precpromouno ". $precpromouno ."\n";
				print $suc->{id} .":"  . $prodid . ":precpromodos ". $precpromodos ."\n";

				# otro formato para que lo tome el updater
				print $prodid .":".$suc->{id}.":preclista ".$preclista."\n";
				print $prodid .":".$suc->{id}.":precromouno ".$precpromouno."\n";
				print $prodid .":".$suc->{id}.":precromodos ".$precpromodos."\n";
				
				print HTML "</tr>\n";
			}
			
		}

print HTML "</table>";
#print   Dumper $a[0];
print OUTPUT "lastupdate = ".scalar localtime. "\n";
print OUTPUT join(",",@ARGV);
print OUTPUT Dumper \@ARGV;
print HTML "lastupdate = ".scalar localtime. "\n";
close (OUTPUT);
close (HTML);

