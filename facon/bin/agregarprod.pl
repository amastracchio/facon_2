

my $prod = "64-1-19";


my $temp = "<<EOF

data    VARIABLE=*:VARIABLE:preclista GAUGE:1200:0:U
data    VARIABLEd=&grandeacentavos(*:VARIABLE:preclista) DERIVE:1200:0:U
data    VARIABLEuno=*:VARIABLE:precpromouno GAUGE:1200:0:U
data    VARIABLEunod=&grandeacentavos(*:VARIABLE:precpromouno) DERIVE:1200:0:U
data    VARIABLEdos=*:VARIABLE:precpromodos GAUGE:1200:0:U
data    VARIABLEdosd=&grandeacentavos(*:VARIABLE:precpromodos) DERIVE:1200:0:U

	DEF:VARIABLE=##DB##:VARIABLE:AVERAGE
        DEF:VARIABLEuno=##DB##:VARIABLEuno:AVERAGE
        DEF:VARIABLEdos=##DB##:VARIABLEdos:AVERAGE

        'LINE2:VARIABLE###COLOR4##:Coto'
        'LINE2:VARIABLEuno###COLOR5##:Coto puno'
        'LINE2:VARIABLEdos###COLOR6##:Coto pdos'
	

	'GPRINT:VARIABLE:LAST:Yaguar last=%.1lf'
	'GPRINT:VARIABLEuno:LAST:Yaguar puno last=%.1lf'
	'GPRINT:VARIABLEdos:LAST:Yaguar pdos last=%.1lf'
EOF
";

$temp =~ s/VARIABLE/$prod/g;

print $temp;


