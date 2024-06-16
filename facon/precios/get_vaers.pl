#!/usr/bin/perl

use JSON;
use Data::Dumper;


my $ej = "/usr/bin/curl";

# my $url = "https://www.bancogalicia.com/cotizacion/cotizar?currencyId=02&quoteType=SU&quoteId=999";
my $url = "https://ws1.smn.gob.ar/v1/forecast/location/10645";
my $url = "https://www.accuweather.com/es/ar/tigre/7333/current-weather/7333";

my $com = $ej . " " . $url;


#curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" https://www.accuweather.com/es/ar/tigre/7333/current-weather/7333 -H "Connection: keep-alive" -H "Accept-Encoding: gzip, deflate" | gzip -d - > pro
#
#
#my $ret = system($ej,$url,"-H","User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:85.0) Gecko/20100101 Firefox/85.0","-H","Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8","-H","Connection: keep-alive","-H","Accept-Encoding: gzip, deflate","-o","/tmp/temp_smn.gz");

## my $ret = system("curl -k 'https://wonder.cdc.gov/controller/datarequest/D8;jsessionid=D59C5A88973FCD6343C1CF298508' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Referer: https://wonder.cdc.gov/controller/datarequest/D8;jsessionid=2B80A92E4F363A8E06F9C3ACCB7C' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://wonder.cdc.gov' -H 'Connection: keep-alive' -H 'Cookie: TS0121a97c=015d0abe874cd4a45aaac5ed95aed0051d9623364ba75c6144a8f95260a8fa081947a52305cbee808d9fb9bf8941ce1caa3b2004c1; s_fid=336501CF77A72B83-2A36FC2055A8A674; gpv_c54=https%3A%2F%2Fwonder.cdc.gov%2Fcontroller%2Fdatarequest%2FD8%3Bjsessionid%3D2B80A92E4F363A8E06F9C3ACCB7C; s_vnum=1627786800397%26vn%3D1; s_invisit=true; s_lv=1625437595344; s_lv_s=First%20Visit; s_visit=1; s_ppvl=The%2520Vaccine%2520Adverse%2520Event%2520Reporting%2520System%2520%2528VAERS%2529%2520Request%2520Form%2C9%2C100%2C6310%2C1264%2C547%2C1280%2C720%2C1.5%2CL; s_ppv=The%2520Vaccine%2520Adverse%2520Event%2520Reporting%2520System%2520%2528VAERS%2529%2520Results%2520Form%2C24%2C33%2C755%2C1264%2C235%2C1280%2C720%2C1.5%2CL; gpv_v45=The%20Vaccine%20Adverse%20Event%20Reporting%20System%20%28VAERS%29%20Results%20Form; s_ptc=0.00%5E%5E0.00%5E%5E0.00%5E%5E0.00%5E%5E0.87%5E%5E0.70%5E%5E1.88%5E%5E0.00%5E%5E2.77; s_cc=true; _ga=GA1.3.613908912.1625436521; _gid=GA1.3.535638070.1625436521; s_tps=46; s_pvs=44; s_sq=%5B%5BB%5D%5D; _gat_GSA_ENOR0=1' -H 'Upgrade-Insecure-Requests: 1' -H 'Cache-Control: max-age=0' --data 'saved_id=&dataset_code=D8&dataset_label=The+Vaccine+Adverse+Event+Reporting+System+%28VAERS%29&dataset_vintage=6%2F25%2F2021&stage=request&O_javascript=on&M_1=D8.M1&M_2=D8.M2&B_1=D8.V14-level1&B_2=*None*&B_3=*None*&B_4=*None*&B_5=*None*&O_title=&finder-stage-D8.V13=codeset&O_V13_fmode=freg&O_V13_fand_sect=2&O_V13_fand_htreg=codes-div-extra&O_V13_fand_htadv=codes-div-extra2&V_D8.V13=&V_D8.V13_AND2=&V_D8.V13_AND3=&V_D8.V13_AND4=&V_D8.V13_AND5=&F_D8.V13=*All*&I_D8.V13=*All*+%28All+Symptoms%29%0D%0A&finder-stage-D8.V14=codeset&O_V14_fmode=freg&V_D8.V14=&F_D8.V14=COVID19&I_D8.V14=COVID19+%28COVID19+VACCINE%29%0D%0A&V_D8.V6=*All*&V_D8.V25=*All*&V_D8.V24=&V_D8.V12=00&V_D8.V1=*All*&V_D8.V5=*All*&V_D8.V11=DTH&V_D8.V11=LT&V_D8.V11=DBL&V_D8.V11=BD&V_D8.V9=*All*&V_D8.V10=*All*&V_D8.V19=*All*&V_D8.V7=*All*&V_D8.V32=*All*&V_D8.V33=*All*&V_D8.V20=*All*&V_D8.V15=&V_D8.V22=&O_oc-sect1-request=close&V_D8.V26=&V_D8.V27=&V_D8.V28=&V_D8.V29=&V_D8.V30=&V_D8.V31=&finder-stage-D8.V16=codeset&O_V16_fmode=freg&V_D8.V16=&F_D8.V16=*All*&I_D8.V16=*All*+%28All+Dates%29%0D%0A&finder-stage-D8.V2=codeset&O_V2_fmode=freg&V_D8.V2=&F_D8.V2=*All*&I_D8.V2=*All*+%28All+Dates%29%0D%0A&finder-stage-D8.V3=codeset&O_V3_fmode=freg&V_D8.V3=&F_D8.V3=*All*&I_D8.V3=*All*+%28All+Dates%29%0D%0A&finder-stage-D8.V17=codeset&O_V17_fmode=freg&V_D8.V17=&F_D8.V17=*All*&I_D8.V17=*All*+%28All+Dates%29%0D%0A&finder-stage-D8.V18=codeset&O_V18_fmode=freg&V_D8.V18=&F_D8.V18=*All*&I_D8.V18=*All*+%28All+Dates%29%0D%0A&O_show_totals=true&O_precision=2&O_timeout=600&action-Send=Send' -k -o /tmp/vaers.html");

my $ret = system("curl 'https://wonder.cdc.gov/controller/datarequest/D8' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Referer: https://wonder.cdc.gov/vaers.html' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://wonder.cdc.gov' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data-raw 'stage=about&saved_id=&target=about&action-I+Agree=I+Agree' -k -o /tmp/agree.html");



open(FILE, "/tmp/agree.html");
close FILE;

my $lin = do { local $/; <FILE> };



#system("/usr/bin/gzip -df /tmp/temp_smn.gz");

open(FILE, "/tmp/agree.html");

my $jsessionid;

my $lin = do { local $/; <FILE> };

# jsessionid=08BE6F77E38E7AC66D8BF580DD51" n
# if ($lin =~ /<span class="header-temp">(\d*)\&/s) {
if ($lin =~ /jsessionid=(\w+)"/s) {
	print "SI!!\n";
        $jsessionid = $1;
	        print "jsessionid $jsessionid\n";
}


# Enviamos con el jsessionid correcto
my $ret = system("curl 'https://wonder.cdc.gov/controller/datarequest/D8;jsessionid=$jsessionid' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Referer: https://wonder.cdc.gov/controller/datarequest/D8;jsessionid=B7FAA29CF6AC162E956CB91B849D' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://wonder.cdc.gov' -H 'Connection: keep-alive' -H 'Cookie: TS0121a97c=015d0abe8768d974b7585a45846ad7b3716833263b208b062a027f9d168aac5ca1164c9439df0cdd468ac6c940a7297b2bac1c06a1; s_fid=1937DFA40592A3D6-0F2F57F192D9D87E; gpv_c54=https%3A%2F%2Fwonder.cdc.gov%2Fcontroller%2Fdatarequest%2FD8%3Bjsessionid%3DB7FAA29CF6AC162E956CB91B849D; s_vnum=1627786800248%26vn%3D1; s_invisit=true; s_lv=1625610734361; s_lv_s=First%20Visit; s_visit=1; s_ppvl=The%2520Vaccine%2520Adverse%2520Event%2520Reporting%2520System%2520%2528VAERS%2529%2520Request%2520Form%2C11%2C12%2C780%2C1138%2C456%2C1152%2C648%2C1.67%2CL; s_ppv=The%2520Vaccine%2520Adverse%2520Event%2520Reporting%2520System%2520%2528VAERS%2529%2520Results%2520Form%2C27%2C41%2C996%2C1138%2C175%2C1152%2C648%2C1.67%2CL; gpv_v45=The%20Vaccine%20Adverse%20Event%20Reporting%20System%20%28VAERS%29%20Results%20Form; s_ptc=0.00%5E%5E0.00%5E%5E0.00%5E%5E0.00%5E%5E1.17%5E%5E0.71%5E%5E1.47%5E%5E0.00%5E%5E2.65; s_cc=true; _ga=GA1.3.1341714720.1625610111; _gid=GA1.3.1199637923.1625610111; s_tps=116; s_pvs=114; s_sq=%5B%5BB%5D%5D' -H 'Upgrade-Insecure-Requests: 1' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data 'saved_id=&dataset_code=D8&dataset_label=The+Vaccine+Adverse+Event+Reporting+System+%28VAERS%29&dataset_vintage=6%2F25%2F2021&stage=request&O_javascript=on&M_1=D8.M1&M_2=D8.M2&action-Send=Send&B_1=D8.V11&B_2=*None*&B_3=*None*&B_4=*None*&B_5=*None*&O_title=&finder-stage-D8.V13=codeset&O_V13_fmode=freg&O_V13_fand_sect=2&O_V13_fand_htreg=codes-div-extra&O_V13_fand_htadv=codes-div-extra2&V_D8.V13=&V_D8.V13_AND2=&V_D8.V13_AND3=&V_D8.V13_AND4=&V_D8.V13_AND5=&F_D8.V13=*All*&I_D8.V13=*All*+%28All+Symptoms%29%0D%0A&finder-stage-D8.V14=codeset&O_V14_fmode=freg&V_D8.V14=&F_D8.V14=COVID19&I_D8.V14=COVID19+%28COVID19+VACCINE%29%0D%0A&V_D8.V6=*All*&V_D8.V25=*All*&V_D8.V24=&V_D8.V12=00&V_D8.V1=*All*&V_D8.V5=*All*&V_D8.V11=DTH&V_D8.V11=LT&V_D8.V11=DBL&V_D8.V11=BD&V_D8.V9=*All*&V_D8.V10=*All*&V_D8.V19=*All*&V_D8.V7=*All*&V_D8.V32=*All*&V_D8.V33=*All*&V_D8.V20=*All*&V_D8.V15=&V_D8.V22=&O_oc-sect1-request=close&V_D8.V26=&V_D8.V27=&V_D8.V28=&V_D8.V29=&V_D8.V30=&V_D8.V31=&finder-stage-D8.V16=codeset&O_V16_fmode=freg&V_D8.V16=&F_D8.V16=*All*&I_D8.V16=*All*+%28All+Dates%29%0D%0A&finder-stage-D8.V2=codeset&O_V2_fmode=freg&V_D8.V2=&F_D8.V2=*All*&I_D8.V2=*All*+%28All+Dates%29%0D%0A&finder-stage-D8.V3=codeset&O_V3_fmode=freg&V_D8.V3=&F_D8.V3=*All*&I_D8.V3=*All*+%28All+Dates%29%0D%0A&finder-stage-D8.V17=codeset&O_V17_fmode=freg&V_D8.V17=&F_D8.V17=*All*&I_D8.V17=*All*+%28All+Dates%29%0D%0A&finder-stage-D8.V18=codeset&O_V18_fmode=freg&V_D8.V18=&F_D8.V18=*All*&I_D8.V18=*All*+%28All+Dates%29%0D%0A&O_show_totals=true&O_precision=2&O_timeout=600' -k -o /tmp/vaers.html");



open(FILE, "/tmp/vaers.html");


my $lin = do { local $/; <FILE> };


#              <th class="v">Life Threatening</th><td>6,526</td><td>41.75%</td>^M
#              <th class="v">Permanent Disability</th><td>5,233</td><td>33.48%</td>^M
#           <th class="v">Congenital Anomaly / Birth Defect *</th><td>198</td><td>1.27%</td>^M
#           <th colspan="1" class="t">Total</th><td class="t">16,993</td><td class="t">108.71%</td>^M

#<th class="v">Death</th><td>5,036</td><td>32.22%</td>^M
if ($lin =~ /Death<\/th><td>(.+?)<\/td/s) {
        my $death = $1;
	$death =~ s/,//;
	        print "death $death\n";
}


## <th colspan="1" class="t">Total</th><td class="t">16,936</td><td class="t">108.34%</td>^M
#if ($lin =~ /Viento<\/div>.+?<div>(\d*) km/s) {
if ($lin =~ /<td class="t">(.+?)<\/td><td/s) {
        my $total = $1;
	$total =~ s/,//;
	        print "total $total\n";
}

# Life Threatening</th><td>6
if ($lin =~ /Life Threatening<\/th><td>(.+?)<\/td/s) {
        my $riesgom = $1;
	$riesgom =~ s/,//;
	        print "riesgom $riesgom\n";
}

#              <th class="v">Permanent Disability</th><td>5,233</td><td>33.48%</td>^M
if ($lin =~ /Permanent Disability<\/th><td>(.+?)<\/td/s) {
        my $disca = $1;
	$disca =~ s/,//;
	        print "disca $disca\n";
}
#           <th class="v">Congenital Anomaly / Birth Defect *</th><td>198</td><td>1.27%</td>^M
if ($lin =~ /Birth Defect \*<\/th><td>(.+?)<\/td/s) {
        my $bdefect = $1;
	$bdefect =~ s/,//;
	        print "bdefect $bdefect\n";
}

exit 0 ;



my $temp;
my $pres;
my $wind;
my $hum;
my $uvi;
my $dewpt;
# nubosidad %
my $nub;
# techo de nubes
my $techo;
	        # (34425) Precio por 1 Litro/kilo : $299.00
		#         if ($lin =~ /\((\d*)\) .*?: \$(.+?)$/) {
		#                         print $lin;
		#                                         print " match ! $1 - $2\n";
		# <span class="header-temp">28&#xB0;<span class="unit">C</span></span>
if ($lin =~ /<span class="header-temp">(\d*)\&/s) {
	$temp = $1;
	print "temp $temp\n";
}
# <div>&#x2193; 1010 mbar</div>
if ($lin =~ /; (\d*) mbar/) {
	$pres = $1;
	print "pres $pres\n";
}

#  Viento</div>
#                                         <div>17 km/h</div>
#if ($lin =~ /; (\d*) mbar/) {

if ($lin =~ /Viento<\/div>.+?<div>(\d*) km/s) {
	$wind = $1;
	print "wind $wind\n";
}

#<div class="detail-item spaced-content">
#                                        <div>Humedad</div>
#                                                                                <div>54&#xA0;%</div>
#                                                                                                                </div>
if ($lin =~ /Humedad<\/div>.+?<div>(\d*)\&/s) {
	$hum = $1;
	print "hum $hum\n";
}

#<div class="detail-item spaced-content">
#                                        <div>&#xCD;ndice UV m&#xE1;x.</div>
#                                                                                <div>1 Bajo</div>

if ($lin =~ /;x.<\/div>.+?<div>(\d*) /s) {
	$uvin = $1;
	print "uvin $uvin\n";
}

#<div class="detail-item spaced-content">
#                                        <div>Punto de roc&#xED;o</div>
#                                                                                <div>18&#xB0; C</div>
if ($lin =~ /xED;o<\/div>.+?<div>(\d*)\&/s) {
	$dewpt = $1;
	print "dewpt $dewpt\n";
}

#<div class="detail-item spaced-content">
#                                        <div>Nubosidad</div>
#                                                                                <div>35&#xA0;%</div>
#                                                                                                                </div>
if ($lin =~ /Nubosidad<\/div>.+?<div>(\d*)\&\#/s) {
	$nub = $1;
	print "nub $nub\n";
}
#<div class="detail-item spaced-content">
#                                        <div>Techo de nubes</div>
#                                                                                <div>12200 m</div>
#                                                                                                                </div>
if ($lin =~ /Techo de nubes<\/div>.+?<div>(\d*) m/s) {
	$techo = $1;
	print "techo $techo\n";
}
close FILE;


return 0;


my $wind = $h->{wind};
print "wind ".$wind->{speed}."\n";
print "vis ".$h->{visibility}. "\n";
print "pres ".$h->{pressure}. "\n";
print "hum ".$h->{humidity}. "\n";
print "temp ".$h->{temperature}. "\n";

# Es para sacar el "estado" por ejemplo el id 3 es "depejado"
my $weather;
$weather = $h->{weather};

print "estado ".$weather->{id}."\n";
print "estado_descripcion ".$weather->{description}."\n";
exit 0;




my @valores;

@valores = @$h;


my $hash = $valores[4];

my $compra = %$hash->{compra};
my $venta = %$hash->{venta};
$venta =~ s/,/./;
$compra =~ s/,/./;

print "turiscompra ".$compra."\n";
print "turisventa ".$venta."\n";

#die;
#die Dumper @valores;
#my $venta = $h->{sell};
#my $compra = $h->{buy};
#
#$venta =~ s/,/./;
#$compra =~ s/,/./;

#print "venta $venta\n";
#print "compra $compra\n";

