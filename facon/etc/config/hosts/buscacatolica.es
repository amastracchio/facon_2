# hosts/_remstats_ - remstats self-monitoring
#
desc	The linux  machine
ip	92.205.7.53
group	prod
tools	availability status
#rrd	snmpuptime
#rrd	snmpif-eth1
#rrd     pscount-ed857416
#rrd     pscount-wspheraa
#rrd     pscount-root
#rrd	load
#rrd	process
#rrd	memory
#rrd     pssum-ed857416
#rrd     pssum-wspheraa
#rrd     pssum-root
# rrd	bamac-neolane ssh mzpneo01@yval1760  " . /soft/universe/fileso/profile; export DATE=`perl -e '($h,$mi,$d, $m, $y) = (localtime(time - (120*3600)))[2,1,3,4,5]; $y = $y + 1900; print \"$d/\".++$m.\"/$y,\".sprintf (\"%.2d\",$h). sprintf (\"%.2d\",$mi);' `; /soft/universe/PSAV43/exec/uxlst ctl ses=* since=\$DATE"  | /var/remstats/bin/bamac2rem1.pl neolane-yval1760
#rrd	df-/
#rrd	df-/grade
#alert	df-/opt percent < 84 84 84
#rrd	df-/db
#alert	df-/db percent < 84 84 84
#rrd	df-/home
#alert	df-/home percent < 84 84 84
#rrd	df-/var
#alert	df-/var percent < 84 84 84
#rrd	df-/opt/ibm
#alert	df-/opt/ibm percent < 84 84 84
#rrd	df-/tmp
#alert	df-/tmp percent < 84 84 84
#rrd	df-/usr
#alert	df-/usr percent < 84 84 84
##rrd     df-/users17
##alert   df-/users17 percent < 84 84 84
#rrd     cftlog-LOGENVOI-cft_0ev_pl.log  /users/login/mzpneo01/3p/logs/cft_0ev_pl.log
#rrd     cftlog-LOGDISPO-cft_0md_pl.log  /users/login/mzpneo01/3p/logs/cft_0md_pl.log
#rrd     cftlog-LOGRECEPT-cft_0rc_pl.log /users/login/mzpneo01/3p/logs/cft_0rc_pl.log
#rrd     cftlog-LOGRECUP-cft_0ma_pl.log  /users/login/mzpneo01/3p/logs/cft_0ma_pl.log
#rrd     syslog-/users/neo00/log/default/log/watchdog.log /users/neo00/log/default/log/watchdog.log
#rrd     syslog-/users/neo00/log/default/log/web.log /users/neo00/log/default/log/web.log
#
# es normal que use mas memoria porque corre el sfserver
#alert	pssum-ed857416 procsmemk  < 3000000 5000000 10000000
#alert	pssum-wspheraa procsmemk  < 3000000 5000000 10000000
#alert	pssum-root procsmemk  < 3000000 5000000 10000000
#alert	process ready < 1 1 1
#rrd     tcpstates
#alert   tcpstates timewait < 200
#rrd     wslog-nodeagent-native_stderr.log /opt/IBM/AACoRN_WebSphere60/profiles/RSAppC112/logs/nodeagent/native_stderr.log
#rrd     wssyslog-nodeagent-systemout.log /opt/IBM/AACoRN_WebSphere60/profiles/RSAppC112/logs/nodeagent/SystemOut.log
#rrd     testiglog-log /tmp/testig.log
#rrd      if-eth1
#rrd	 procnetdev-eth1
#rrd	 dirsize-/grade/tomografias
#rrd	 dirsize-/grade/ERGOMETRIA
#rrd	 dirsize-/grade/HOLTER
#rrd	 dirsize-/grade/PEC
#rrd	 dirsize-/grade/soft/mysql/data
#rrd	iostat-sda
#rrd	iostat-sdb
#rrd	iostat-sdc
#rrd	iostat-md127
#rrd	temp-/root/3p/bin/get_mother.pl /root/3p/bin/get_mother.pl
#rrd	smbdprocs
#rrd	riesgopais
#rrd     riesgopais /root/precios/get_rava_riesgopais.pl
#rrd     dolarmep /root/precios/get_rava_dolar_mep.pl
#rrd     dolarccl /root/precios/get_rava_dolar_ccl.pl
#rrd     dolarrava /root/precios/get_rava_dolar_rava.pl
rrd     search /root/precios/search.pl
rrd     htdig /root/precios/stats.pl
rrd     sitios /root/precios/stats.pl
#rrd     mem /root/precios/mem.pl
rrd     io /root/precios/mem.pl
rrd     totdoc /root/precios/totales-prod.pl

