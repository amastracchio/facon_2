
my %cachos;


$cachos{PDG} = <<END;


<h3>PDG</h3>

<VIEW::GRAPH pyah14 bamac-pdg value-* day>
<VIEW::GRAPH pyah14 bamac-pdg value-* yesterday>
<VIEW::GRAPH pyah14 bamac-pdg value-* week>
<VIEW::INCLUDE /tmp/pdg-pyah14.html>
<VIEW::GRAPH pyah14 fileage-/users2/bmd00/exploit/data/bmdevtdu.lst age day>




<hr/>

END


$cachos{UK} = <<END;


<h3>UK</h3>

<VIEW::GRAPH pyah14 bamac-uk value-* day>
<VIEW::GRAPH pyah14 bamac-uk value-* yesterday>
<VIEW::GRAPH pyah14 bamac-uk value-* week>
<VIEW::INCLUDE /tmp/uk-pyah14.html>
<VIEW::GRAPH pyah14 fileage-/users2/bmk00/exploit/data/bmkevtdu.lst age day>
<hr/>

END


$cachos{PPA} = <<END;

<h3>PPA</h3>

<VIEW::GRAPH pyah14 bamac-ppa value-* day>
<VIEW::GRAPH pyah14 bamac-ppa value-* yesterday>
<VIEW::GRAPH pyah14 bamac-ppa value-* week>
<VIEW::INCLUDE /tmp/ppa-pyah14.html>
<VIEW::GRAPH pyah14 fileage-/users2/bml00/exploit/data/bmlevtdu.lst age day>
<hr/>


END

$cachos{PAI} = <<END;
<h3>PAI</h3>

<VIEW::GRAPH pyahg8 bamac-pai value-* day>
<VIEW::GRAPH pyahg8 bamac-pai value-* yesterday>
<VIEW::GRAPH pyahg8 bamac-pai value-* week>
<VIEW::INCLUDE /tmp/pai-pyahg8.html>
<VIEW::GRAPH pyahg8 fileage-/users/bmi00/exploit/data/bmievtdu.lst age day>
<hr/>

END

$cachos{PNE} = <<END;

<VIEW::GRAPH pyahg8 bamac-pne value-* day>
<VIEW::GRAPH pyahg8 bamac-pne value-* yesterday>
<VIEW::GRAPH pyahg8 bamac-pne value-* week>
<VIEW::INCLUDE /tmp/pne-pyahg8.html>
<VIEW::GRAPH pyahg8 fileage-/users/bmn00/exploit/data/bmnevtdu.lst age day>
<hr/>

END

$cachos{PSU} = <<END;

<h3>PSU</h3>

<VIEW::GRAPH pyahg8 bamac-psu value-* day>
<VIEW::GRAPH pyahg8 bamac-psu value-* yesterday>
<VIEW::GRAPH pyahg8 bamac-psu value-* week>
<VIEW::INCLUDE /tmp/psu-pyahg8.html>
<VIEW::GRAPH pyahg8 fileage-/users/bmb00/exploit/data/bmbevtdu.lst age day>
<hr/>


END

$cachos{FR} = <<END;

<h3>FR</h3>

<VIEW::GRAPH pyahha bamac-fr value-* day>
<VIEW::GRAPH pyahha bamac-fr value-* yesterday>
<VIEW::GRAPH pyahha bamac-fr value-* week>
<VIEW::INCLUDE /tmp/fr-pyahha.html>
<VIEW::GRAPH pyahha fileage-/users/bmf00/exploit/data/bmfevtdu.lst age day>
<hr/>

END

$cachos{CDAG} = <<END;
<h3>CDAG</h3>

<VIEW::GRAPH yvas4180 bamac-cdag value-* day>
<VIEW::GRAPH yvas4180 bamac-cdag value-* yesterday>
<VIEW::GRAPH yvas4180 bamac-cdag value-* week>
<VIEW::INCLUDE /tmp/cdag-yvas4180.html>
<VIEW::GRAPH yvas4180 fileage-/users/bm100/exploit/data/bm1evtdu.lst age day>
<VIEW::GRAPH yvas4180 fileage-/users/bm100/exploit/data/bm1fpmsf.dat age day>

<hr/>

END

$cachos{ACP} = <<END;

<h3>ACP</h3>

<VIEW::GRAPH pyahfb bamac-acp value-* day>
<VIEW::GRAPH pyahfb bamac-acp value-* yesterday>
<VIEW::GRAPH pyahfb bamac-acp value-* week>
<VIEW::INCLUDE /tmp/acp-pyahfb.html>
<VIEW::GRAPH pyahfb fileage-/users/bm200/exploit/data/bm2evtdu.lst age day>
<hr/>

END

$cachos{CIS} = <<END;
<h3>CIS</h3>


<VIEW::GRAPH yvas4180 bamac-cis value-* day>
<VIEW::GRAPH yvas4180 bamac-cis value-* yesterday>
<VIEW::GRAPH yvas4180 bamac-cis value-* week>
<VIEW::INCLUDE /tmp/cis-yvas4180.html>
<VIEW::GRAPH yvas4180 fileage-/users/bm300/exploit/data/bm3evtdu.lst age day>
<VIEW::GRAPH yvas4180 fileage-/users/bm300/exploit/data/bm3fpmsf.dat age day>

<hr/>

END

$cachos{ACE} = <<END;


<h3>ACE</h3>

<VIEW::GRAPH pyahfb bamac-ace value-* day>
<VIEW::GRAPH pyahfb bamac-ace value-* yesterday>
<VIEW::GRAPH pyahfb bamac-ace value-* week>
<VIEW::INCLUDE /tmp/ace-pyahfb.html>
<VIEW::GRAPH pyahfb fileage-/users/bm400/exploit/data/bm4evtdu.lst age day>
<hr/>

$cachos{PBL} = <<END;


<h3>PBL</h3>

<VIEW::GRAPH yvas4180 bamac-pbl value-* day>
<VIEW::GRAPH yvas4180 bamac-pbl value-* yesterday>
<VIEW::GRAPH yvas4180 bamac-pbl value-* week>
<VIEW::INCLUDE /tmp/pbl-yvas4180.html>
<VIEW::GRAPH yvas4180 fileage-/users/bmh00/exploit/data/bmhevtdu.lst age day>
<VIEW::GRAPH yvas4180 fileage-/users/bmh00/exploit/data/bmhfpmsf.dat age day>

<hr/>


$cachos{BMC} = <<END;


<h3>BAMAC COMUN</h3>

<VIEW::GRAPH yvas4180 bamac-com value-* day>
<VIEW::GRAPH yvas4180 bamac-com value-* yesterday>
<VIEW::GRAPH yvas4180 bamac-com value-* week>
<VIEW::INCLUDE /tmp/com-yvas4180.html>

<hr/>


END


$cachos{NEOLANE} = <<END;

<h3>Neolane</h3>

<VIEW::GRAPH yval1760 bamac-neolane value-* day>
<VIEW::GRAPH yval1760 bamac-neolane value-* yesterday>
<VIEW::GRAPH yval1760 bamac-neolane value-* week>
<VIEW::INCLUDE /tmp/neolane-yval1760.html>


</UL>


END



# start

my $infile = "/var/remstats/etc/config/view-templates/bamacdelivery";
# my $pais_mas = "UK";
my $pais_menos = "UK";

open(F, "+< $infile")       or die "can't read $infile: $!";
$out = '';

while (<F>) {

   $out .= $_;

}




if ($pais_menos) {

       my $busc = $cachos{$pais_menos};


       if ($out =~ s/$busc/XX/g){

	   print "OK BORRADO!\n";
       }
}
   
if ($pais_mas) {


       if ($out =~ s/<UL> /<UL> $cachos{$pais_mas}/i) {

	   print "OK!!\n";
       }
}



seek(F, 0, 0)               or die "can't seek to start of $infile: $!";
print F $out                or die "can't print to $infile: $!";
truncate(F, tell(F))        or die "can't truncate $infile: $!";
close(F)                    or die "can't close $infile: $!";



