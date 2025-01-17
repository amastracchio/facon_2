#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# leches
my $url = "https://d3e6htiiul5ek9.cloudfront.net/prod/comparativa?array_sucursales=10-1-183,23-1-6204,15-1-116,12-1-197&array_productos=7793940448003,7790742145406";


# gallaticas bonafide
my $url = "https://d3e6htiiul5ek9.cloudfront.net/prod/comparativa?array_sucursales=10-1-183,23-1-6204,15-1-116,12-1-197&array_productos=7793940448003,7792360071525";

# seven up
my $url = "https://d3e6htiiul5ek9.cloudfront.net/prod/comparativa?array_sucursales=12-1-197&array_productos=7791813423522";

# seven up 2.25l 7791813423522

my $com = $ej . " " . $url;

my $precio; my $preciopromuno; my $preciopromdos;

print "Por ejecutar: $com\n";
my $ret = system($ej,$url,"-o","pro");

open(FILE, "pro");

my $string = <FILE>;

close FILE;

$string .= "\n";
my %h;
$h = decode_json $string;

my @a = $h;

print "ARI\n";
print "Total Productos: ".$h->{totalProductos} . "\n";
print "Total Sucursales: ".$h->{totalSucursales} . "\n";
my $a = $h->{sucursales};
foreach my $suc (@$a) {
			print "-"x80;
			print "\n";
			print $suc->{banderaDescripcion} . "\t".$suc->{sucursalNombre}. "\t".$suc->{localidad} . "\t".$suc->{id}."\n";;
			print "Acualizado Hoy: ".$suc->{actualizadoHoy} ."\n";
			print "Total Productos: ".$suc->{totalProductos} ."\n";
			print "Total Sugeridos: ".$suc->{totalSugeridos} ."\n";
			print "Suma Lista Precio Total: ".$suc->{sumaPrecioListaTotal} ."\n";
			my $p = $suc->{productos};

			my $lin;
			foreach my $productos (@$p) {

				$precio = $productos->{precioLista};

#				print Dumper $productos; 
				$lin = "Unidad_venta: ".$productos->{unidad_venta}  if $productos->{unidad_venta} ;
				$lin .= "\t";
				$lin .= "PrecioLista: ".$productos->{precioLista} if $productos->{precioLista} ;
				$lin .= "\t";
				$lin .= "PrecioUnitarioconvIva: ".$productos->{precio_unitario_con_iva} if $productos->{precio_unitario_con_iva} ;
				$lin .= "\t";

				# Parse de promos
				$hpromdos = $productos->{promo2};
				$hpromuno = $productos->{promo1};

				if  ($hpromdos->{descripcion}) {
				        	
					$preciopromdos = $hpromdos->{precio};

					$lin .= "promo2.precio: ". $hpromdos->{precio} if $hpromdos->{precio} ;
					$lin .= "\t";
					$lin .= "promo2.precio_unitario_con_iva: ". $hpromdos->{precio_unitario_con_iva} if $hpromdos->{precio_unitario_con_iva} ;
					$lin .= "\t";
					$lin .= "promo2.precio_unitario_sin_iva: ". $hpromdos->{precio_unitario_sin_iva}  if $hpromdos->{precio_unitario_sin_iva} ;
					$lin .= "\t";
					$lin .= "promo2.descripcion: ". $hpromdos->{descripcion}  if $hpromdos->{descripcion} ;
					$lin .= "\t";
				};

				if  ($hpromuno->{descripcion}) {

					$preciopromuno = $hpromuno->{precio};

					$lin .= "promo1.precio: ". $hpromuno->{precio} if $hpromuno->{precio} ;
					$lin .= "\t";
					$lin .= "promo1.precio_unitario_con_iva: ". $hpromuno->{precio_unitario_con_iva} if $hpromuno->{precio_unitario_con_iva} ;
					$lin .= "\t";
					$lin .= "promo1.precio_unitario_sin_iva: ". $hpromuno->{precio_unitario_sin_iva}  if $hpromuno->{precio_unitario_sin_iva} ;
					$lin .= "\t";
					$lin .= "promo1.descripcion: ". $hpromuno->{descripcion}  if $hpromuno->{descripcion} ;
					$lin .= "\t";
				};

				

				$lin .= "PrecioUnitariosinIva: ".$productos->{precio_unitario_sin_iva} if $productos->{precio_unitario_sin_iva} ;
				$lin .= "\t";
			

			
				$lin .=  $productos->{id} . " ". $productos->{id_string}. " ". $productos->{marca}." ".$productos->{presentacion}." ".$productos->{nombre}."\n";
				print $lin;
			}
		}

#print   Dumper $a[0];

print "cotoprecio ".$precio ."\n"; 
print "cotopuno ".$preciopromuno. "\n";
print "cotopdos ".$preciopromdos . "\n";


