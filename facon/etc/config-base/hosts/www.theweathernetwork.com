# hosts/www.theweathernetwork.com - get local weather
# $Id: www.theweathernetwork.com,v 1.2 2002/04/16 15:25:42 remstats Exp $

desc	source of weather data
group	Other Servers
rrd	ping
rrd	weathernetwork
