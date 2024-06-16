#!/usr/bin/perl -Tw

# dataimage.cgi - shows an image with data from RRDs, remstats status
#	files and SNMP OIDs as graphic elements.
# $Id: dataimage.cgi.in,v 1.14 2002/06/24 14:56:44 remstats Exp $
# from remstats 1.0.13a

# Copyright 1999, 2000, 2001, 2002 (c) Thomas Erskine <terskine@users.sourceforge.net>
# See the COPYRIGHT file with the distribution.

# - - -   Configuration   - - -

# What is this program called, for file-names and error-messages.
$main::prog = 'dataimage.cgi';
# So -T will stop whinging.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ed857416/3p/remstats/bin';
# Where is the config dir
$main::config_dir = '/home/ed857416/3p/remstats/etc/config';
# Max amount of nesting in variable expansion
$main::maxloops = 5;
# How wide to make the flow lines, by default
$main::default_flowwidth = 5;
# pi, for trig stuff
$main::pi = 3.14159265;
# How big to make the arrow-heads
$main::arrow_length = $main::default_flowwidth * 8;
# What does a macro-name look like
$main::macroname_pat = '[-0-9a-z_.]+';
# What do macro args look like
$main::macroarg_pat = '[-0-9A-Z_.]+';

# - - -   Version History   - - -

$main::version = (split(' ', '$Revision: 1.14 $'))[1];

# - - -   Setup   - - -

use lib '.', '/home/ed857416/3p/remstats/lib', '/usr/local/rrdtool/lib/perl';
use SNMP_util;
use RRDs;
use Getopt::Std;
use GD;
require "remstats.pl";
require "accessstuff.pl";
require "cgistuff.pl";
require "snmpstuff.pl";
require "alertstuff.pl";
require "datastuff.pl";
require "miscstuff.pl";
require "private.pl";

# Don't try to change ALERTS; can't access from cgi
$main::alerts_readonly = 1;

my %opt = ();
getopts("d:f:hi", \%opt);

if (defined $opt{'h'}) { &usage; } # no return
if (defined $opt{'f'}) { $main::config_dir = $opt{'f'}; }
if (defined $opt{'d'}) { $main::debug = $opt{'d'}; }
else { $main::debug = 0; }
if (defined $opt{'i'}) { $main::imageonly = 1; }
else { $main::imageonly = 0; }

&read_config_dir($main::config_dir, 'general', 'html', 'oids', 'times',
	'rrds', 'groups', 'host-templates', 'hosts');
&snmp_load_oids;

# Initialize some useful variables
%request = &cgi_request;
#$url = 'http://' . &cgi_var("SERVER_NAME") . ':' . &cgi_var('SERVER_PORT')
#	. &cgi_var('SCRIPT_NAME');

$| = 1; # no buffering please
print cgi_fmtrequest(%request) if ($main::debug);

&abort("access prohibited") unless( &access_control( $main::prog));

# Which page are we supposed to show
my $query = &cgi_var(QUERY_STRING);
if (defined $query and length($query) > 0) {
	if ($query =~ /^([-0-9a-zA-Z\._]+)$/) {
		$query = $1;
		if ($query =~ /\.\./) { &abort("Invalid query string: $query"); }
	}
	else { &abort("Bad query string: $query"); }
}
else { &abort("missing query string"); exit 1; }
my $script_file = $main::config{DATAPAGEDIR} .'/'. $query . '.image';
&debug("  looking for script $script_file") if ($main::debug);
unless (-f $script_file) { &abort("unknown query: <b>$query</b>"); }

# Here are the local variables
my ($newhost, $host, $community, $port, $comhost, @oids, $myname, $oidname, 
	$oid, $file, $name, $value, $x1, $y1, $x2, $y2, @lines, $config,
	$linewidth, $colour, $black, $white, $loops, $r, $g, $b, $cmdline, 
	$macroname, $defining_macro, $in_macro, $font, $outfile);

($defining_macro, $in_macro, $font) = (0, 0, gdMediumBoldFont);

# Transfer these so that they're available, since they're very handy
$main::var{htmldir} = $config{HTMLDIR};
$main::var{htmlurl} = $config{HTMLURL};
$main::var{datadir} = $config{DATADIR};

# Don't try to update the IP_CACHE; don't have access from cgi
$main::ip_cache_readonly = 1;

# - - -   Main Line   - - -

# Read the top, configuration part
open (SCRIPT, "<$script_file") or &abort("can't open $script_file: $!");
while (<SCRIPT>) {
	chomp;
	next if(/^#/ or /^\s*$/);
	$config .= $_ . "\n";
}
close (SCRIPT);
@lines = split("\n", $config);

#foreach my $cmdline (@lines) {
while ($cmdline = shift @lines) {

	next if ($cmdline =~ /^\s*$/);

# Deal with macro definition
	if ($defining_macro) {
		unless ($cmdline =~ /^(macroend|endmacro)\s*$/) {
			push @{$macro{$macroname}}, $cmdline;
			next;
		}
	}

# Deal with macro args, if in a macro
	if ($in_macro) {
		$cmdline =~ s#\$\{($macroarg_pat)\}#$main::args{$1}#egm;
		&debug("  macro args sub'd: $cmdline") if ($main::debug>1);
	}

# First, do variable substitutions so the remaining code is simpler
	$loops = 0;
	&debug("initial line is: $cmdline") if ($main::debug>1);
	while ($loops++ < $maxloops and 
			$cmdline =~ s#\$\{([-0-9a-z_.]+)\}#$main::var{$1}#egm) {
		&debug("sub line to: $cmdline") if ($main::debug>1);
	}
	if ($loops >= $maxloops) {
		&error("too much nesting: $cmdline");
	}

# Do the common stuff
	if ($cmdline =~ /^(oid|rrd|status|eval|scale|range|automap|automap_add|automap_clear|alertstatus|alertvalue)\s/) {
		&do_common($cmdline);
	}
	elsif ($cmdline =~ /^debug\s*$/i) { $debug++; }
	elsif ($cmdline =~ /^nodebug\s*$/i) { $debug = 0; }
		

# Now do the graphic elements
# Set the image size and initialize
	elsif ($cmdline =~ /^image\s+((\d+)\s+(\d+)|(\S+))\s*$/) {
		if (defined $main::image) {
			&error("image size already defined");
			next;
		}
		$main::xsize = $2;
		$main::ysize = $3;
		$bgfile = $4;

# If we've got a name, it's the background in a file.  Set the size from it.
		if (defined $bgfile) {
			open (PNG, "<$bgfile") or
				&abort("can't open bgfile $bgfile: $!");
			$main::image = newFromPng GD::Image(PNG) or
				(&error("can't read bgfile $bgfile: $!") and next);
			close PNG;
			($main::xsize, $main::ysize) = $main::image->getBounds();
			&debug("got bgfile from $bgfile") if ($main::debug);
		}
# ... otherwise, it's a bare image
		else {
			$main::image = new GD::Image($main::xsize, $main::ysize);
		}
		$main::var{'xsize'} = $main::xsize;
		$main::var{'ysize'} = $main::ysize;

# Basic image setup and some colours
		$linewidth = 1;
		$main::linebrush = new GD::Image($linewidth,$linewidth);
		$transparent = &make_color('transparent', 0,0,1);
		$black = &make_color('black', 0,0,0);
		$white = &make_color('white', 255,255,255);
		$main::image->transparent($transparent);
		$color = $black;
		unless (defined $bgfile) { $main::image->fill(1,1,$white); }
		&debug("image size set to ($main::xsize, $main::ysize)") if ($main::debug);
	}

# Define a color
	elsif ($cmdline =~ /^colou?rdef\s+([-0-9a-zA-Z_.]+)\s+(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})\s*$/) {
		$name = $1;
		($r, $g, $b) = ($2, $3, $4);
		unless (defined $main::image) { &abort("image must come first"); }
		&make_color($name, $r, $g, $b);
		&debug("color $name defined as ($r,$g,$b)") if ($main::debug);
	}

# Set the active color
	elsif ($cmdline =~ /^colou?r\s+([-0-9a-zA-Z_.]+)\s*$/) {
		$name = $1;
		unless (defined $main::image) { &abort("image must come first"); }
		if (defined $main::colors{$name}) {
			$color = $main::colors{$name};
			&debug("active color set to $name($color)") if ($main::debug);
		}
		else { &error("unknown color-name $name; skipped"); }
	}

# Define an icon
	elsif ($cmdline =~ /^iconfile\s+([-0-9a-zA-Z_.]+)\s+(\S+)\s*$/) {
		$name = $1;
		$file = $2;
		unless (defined $main::image) { &abort("image must come first"); }
		&error("iconfile not implemented");
	}

# Place an icon
	elsif ($cmdline =~ /^icon\s+([-0-9a-zA-Z_.]+)\s+(\d+)\s+(\d+)\s*$/) {
		$name = $1;
		$x1 = $2;
		$y1 = $3;
		unless (defined $main::image) { &abort("image must come first"); }
		&error("icon not implemented");
	}

# Set the line width
	elsif ($cmdline =~ /^linewidth\s+(\d+)\s*$/) {
		$linewidth = $1;
		unless (defined $main::image) { &abort("image must come first"); }
		unless ($linewidth >= 1 and $linewidth <= $main::xsize and $linewidth <= $main::ysize) {
			&error("invalid linewidth; set to 1");
			$linewidth = 1;
			next;
		}

		&debug("linewidth set to $linewidth") if ($main::debug);
	}

# a "flow": a double-ended, bi-colored arrow showing flow between two
# points.
	elsif ($cmdline =~ /^flow\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(\s+(\d+))?\s*$/) {
		$x1 = $1;
		$y1 = $2;
		$x2 = $3;
		$y2 = $4;
		my $outflow = $5;
		my $inflow = $6;
		my $flowwidth = $8;
		unless (defined $flowwidth) { $flowwidth = $default_flowwidth; }
		unless (defined $main::image) { &abort("image must come first"); }

		# Range checks
		if ($x1 < 0) { $x1 = 0; }
		elsif ($x1 > $main::xsize) { $x1 = $main::xsize - 1; }
		if ($y1 < 0) { $y1 = 0; }
		elsif ($y1 > $main::ysize) { $y1 = $main::ysize - 1; }
		if ($x2 < 0) { $x2 = 0; }
		elsif ($x2 > $main::xsize) { $x2 = $main::xsize - 1; }
		if ($y2 < 0) { $y2 = 0; }
		elsif ($y2 > $main::ysize) { $y2 = $main::ysize - 1; }
		if ($outflow < 1) { $outflow = 1; }
		elsif ($outflow > 10) { $outflow = 10; }
		if ($inflow < 1) { $inflow = 1; }
		elsif ($inflow > 10) { $inflow = 10; }
		&debug("flow from ($x1,$y1) to ($x2,$y2) is ($outflow,$inflow)")  
			if ($main::debug);
		
		# Convert to color indices
		unless (defined $main::colors{'flowcolor1'}) {
			&define_flowcolors;
		}
		my $outflow_color = $main::colors{'flowcolor'.$outflow};
		my $inflow_color = $main::colors{'flowcolor'.$inflow};
		&debug("  using colors (out,in) = ($outflow_color,$inflow_color)")
			if ($main::debug>1);

		# Find the other corners of the polygon (tilted rectangle)
		my $dx = $x2 - $x1;
		my $dy = $y2 - $y1;
		my $angle = atan2( -$dx, $dy); # slope of perpendicular line
		my $lineangle = atan2( $dy, $dx); # slope of original line

		# These lines make the flow-bars constant width
#		my $outdx = $flowwidth * cos($angle);
#		my $outdy = $flowwidth * sin($angle);

		# These lines make the flow-lines vary in width by flow volume
		my $outdx = $outflow * cos($angle);
		my $outdy = $outflow * sin($angle);

		# The OUT flow-bar
		my $outpoly = new GD::Polygon;
		$outpoly->addPt($x1, $y1);
		$outpoly->addPt($x2, $y2);
		$outpoly->addPt($x2+$outdx, $y2+$outdy);
		$outpoly->addPt($x1+$outdx, $y1+$outdy);
		$main::image->filledPolygon($outpoly, $outflow_color);

# These lines make the flow-bars constant width
#		my $indx = $flowwidth * cos($angle);
#		my $indy = $flowwidth * sin($angle);
# These lines make the flow-lines vary in width by flow volume
		my $indx = $inflow * cos($angle);
		my $indy = $inflow * sin($angle);

# The IN flow-bar
		my $inpoly = new GD::Polygon;
		$inpoly->addPt($x1, $y1);
		$inpoly->addPt($x2, $y2);
		$inpoly->addPt($x2-$indx, $y2-$indy);
		$inpoly->addPt($x1-$indx, $y1-$indy);
		$main::image->filledPolygon($inpoly, $inflow_color);

# This puts a white line dividing the two flow arrows
#		$main::image->line($x1, $y1, $x2, $y2, $white);

# How far to shift the arrowhead base along the flow-line
		my $shiftx = $dx/2 * 0.3;
		my $shifty = $dy/2 * 0.3;

# The arrow-heads are right-triangles lying along the outer edge of  flow-line.
# The first point is the flow-width out from the centre of the line and 
# shifted in the direction of the flow.
		my $arrow_angle = $angle - $pi/3;
		my $outx1 = int($x1 + $dx/2 + $shiftx + $outdx);
		my $outy1 = int($y1 + $dy/2 + $shifty + $indx);
		my $outx2 = int($outx1 + $arrow_length * cos($arrow_angle));
		my $outy2 = int($outy1 + $arrow_length * sin($arrow_angle));
		my $outx3 = int($x1 + $dx/2 + $shiftx + $outdx - 
			$arrow_length * cos($lineangle)*0.6);
		my $outy3 = int($y1 + $dy/2 + $shifty + $outdy - 
			$arrow_length * sin($lineangle)*0.6);
		&debug(" out_head: ($outx1,$outy1) - ($outx2,$outy2) - ($outx3,$outx3)")
			if ($main::debug>1);

		my $out_head = new GD::Polygon;
		$out_head->addPt($outx1, $outy1);
		$out_head->addPt($outx2, $outy2);
		$out_head->addPt($outx3, $outy3);
		$out_head->addPt($outx1, $outy1);
		$main::image->filledPolygon( $out_head, $outflow_color);

		$arrow_angle = $angle - $pi/3;
		my $inx1 = int($x1 + $dx/2 - $shiftx - $indx);
		my $iny1 = int($y1 + $dy/2 - $shifty - $indx);
		my $inx2 = int($inx1 - $arrow_length * cos($arrow_angle));
		my $iny2 = int($iny1 - $arrow_length * sin($arrow_angle));
		my $inx3 = int($x1 + $dx/2 - $shiftx - $indx + 
			$arrow_length * cos($lineangle)*0.6);
		my $iny3 = int($y1 + $dy/2 - $shifty - $indy + 
			$arrow_length * sin($lineangle)*0.6);
		&debug(" in_head: ($inx1,$iny1) - ($inx2,$iny2) - ($inx3,$inx3)")
			if ($main::debug>1);

		my $in_head = new GD::Polygon;
		$in_head->addPt($inx1, $iny1);
		$in_head->addPt($inx2, $iny2);
		$in_head->addPt($inx3, $iny3);
		$in_head->addPt($inx1, $iny1);
		$main::image->filledPolygon( $in_head, $inflow_color);
#		$main::image->arc($inx1,$iny1, 3,3, 0,360, $red);
#		$main::image->arc($inx2,$iny2, 3,3, 0,360, $green);
#		$main::image->arc($inx3,$iny3, 3,3, 0,360, $blue);
	}

# Draw a line
	elsif ($cmdline =~ /^line\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/) {
		$x1 = $1;
		$y1 = $2;
		$x2 = $3;
		$y2 = $4;
		unless (defined $main::image) { &abort("image must come first"); }

		($x1, $y1) = &checkxy($x1, $y1);
		($x2, $y2) = &checkxy($x2, $y2);

		if ($linewidth == 1) {
			$main::image->line( $x1, $y1, $x2, $y2, $color);
		}
		else {
# Make a new linebrush and copy the colors to it
			my $tempcolor;
			$main::linebrush = new GD::Image($linewidth,$linewidth);
			$tempcolor = $main::linebrush->colorAllocate(0,0,1);
			$main::linebrush->transparent($tempcolor);
			$main::linebrush->fill(1,1,$tempcolor);
			$main::linebrush->colorAllocate(0,0,0);
			$main::linebrush->colorAllocate(255,255,255);
			$name = $main::colors[$color];
			($r, $g, $b) = @{$main::rgb{$name}};
			$tempcolor = $main::linebrush->colorAllocate($r, $g, $b);
#			$main::linebrush->arc($main::xsize/2, $main::ysize/2, $main::xsize, $main::ysize, 0, 360, $tempcolor);
			$main::linebrush->fill(1,1,$tempcolor);
			$main::image->setBrush($main::linebrush);
			$main::image->line( $x1, $y1, $x2, $y2, gdBrushed);
		}
		&debug("line from ($x1,$y1) to ($x2,$y2)") if ($main::debug);
	}

# Draw a rectangle
	elsif ($cmdline =~ /^rectangle\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(\s+filled)?\s*$/i) {
		$x1 = $1;
		$y1 = $2;
		$x2 = $3;
		$y2 = $4;
		($x1, $y1) = &checkxy($x1, $y1);
		($x2, $y2) = &checkxy($x2, $y2);
		$filled = $5;
		unless (defined $main::image) { &abort("image must come first"); }
		if (defined $filled) {
			$main::image->filledRectangle( $x1, $y1, $x2, $y2, $color);
		}
		else {
			$main::image->rectangle( $x1, $y1, $x2, $y2, $color);
		}
		&debug("rectangle from ($x1,$y1) to ($x2,$y2)" . 
			((defined $filled) ? ' filled' : '')) if ($main::debug);
	}

# Make a circle
	elsif ($cmdline =~ /^circle\s+(\d+)\s+(\d+)\s+(\d+)(\s+filled)?\s*$/i) {
		($x1, $y1) = ($1, $2);
		$radius = $3;
		$filled = $4;
		$main::image->arc( $x1, $y1, $radius*2, $radius*2, 0, 360, $color);
		&debug("circle at ($x1, $y1) radius=$radius") if ($main::debug);
		if (defined $filled) {
			$main::image->fillToBorder( $x1, $y1, $color, $color);
			&debug("  filled from ($x1,$y1)") if ($main::debug);
		}
	}

# Fill from a point
	elsif ($cmdline =~ /^fill\s+(\d+)\s+(\d+)(\s+([-0-9a-zA-Z_.]+))\s*/i) {
		($x1, $y1) = ($1, $2);
		$name = $4;
		if (defined $name) {
			unless (defined $main::colors{$name}) {
				&error("color '$name' unknown; skipped fill");
				next;
			}
			$main::image->fill( $x1, $y1, $main::colors{$name});
			&debug("fill from ($x1,$y1) with color $name($main::colors{$name})") if ($main::debug);
		}
		else {
			$main::image->fill($x1, $y1, $color);
			&debug("fill from ($x1,$y1)") if ($main::debug);
		}
	}

# Set the font to use
	elsif ($cmdline =~ /^font\s+(giant|large|mediumbold|medium|small|tiny)\s*$/i) {
		my $fontname = lc $1;
		if ($fontname eq 'giant') { $font = gdGiantFont; }
		elsif ($fontname eq 'large') { $font = gdLargeFont; }
		elsif ($fontname eq 'medium') { $font = gdMediumBoldFont; }
		elsif ($fontname eq 'mediumbold') { $font = gdMediumBoldFont; }
		elsif ($fontname eq 'small') { $font = gdSmallFont; }
		elsif ($fontname eq 'tiny') { $font = gdTinyFont; }
		else {
			&error("unknown font '$fontname'; skipped");
			next;
		}
	}

# Print some text to the image
	elsif ($cmdline =~ /^text\s+(\d+)\s+(\d+)\s+(.*)\s*$/) {
		$x1 = $1;
		$y1 = $2;
		$value = $3;
		unless (defined $main::image) { &abort("image must come first"); }
		$main::image->string($font, $x1, $y1, $value, $color);
		&debug("text at ($x1,$y1) is '$value'") if ($main::debug);
	}

# Macro definition
	elsif ($cmdline =~ /^macro\s+($macroname_pat)\s*(.*)$/) {
		if ($defining_macro) {
			&error("macros can't define macros: $cmdline");
			next;
		}
		$defining_macro = 1;
		$macroname = lc $1;
		$macro_argnames{$macroname} = [split(' ', uc $2)];
		&debug("defining macro $macroname(". 
				join(',',@{$macro_argnames{$macroname}}) .')')
			if ($main::debug);
	}
	elsif ($cmdline =~ /^(macroend|endmacro)\s*$/) {
		unless ($defining_macro) {
			&error("can't end a macro that hasn't begun");
			next;
		}
		$defining_macro = 0;
		&debug("definition of $macroname ended") if ($main::debug);
		undef $macroname;
	}

# Macro invocation
	elsif ($cmdline =~ /^%($macroname_pat)\s*(.*)$/) {
		$macroname = lc $1;
		my @args = split(' ', $2);
		unless (defined $macro{$macroname}) {
			&error("no macro called $macroname; skipped") if ($main::debug);
			next;
		}

		my $argname;
		for (my $i=0; $i<=$#args; ++$i) {
			$argname = uc ${$macro_argnames{$macroname}}[$i];
			$args{$argname} = $args[$i];
			&debug("  $macroname: arg $argname set to '$args[$i]'") if ($main::debug>1);
		}

		unshift @lines, 'endMACROinvocation '. $macroname;
		unshift @lines, @{$macro{$macroname}};
		$in_macro = 1;
		&debug("invoked macro $macroname") if ($main::debug);
	}
	elsif ($cmdline =~ /^endMACROinvocation\s+(\S+)$/) {
		$in_macro = 0;
		&debug("end of macro $1") if ($main::debug);
	}

# script-triggered debugging
	elsif ($cmdline =~ /^debug\s+(\d+)\s*$/) {
		$debug = $1;
	}
	elsif ($cmdline =~ /^nodebug\s*$/) {
		$debug = 0;
	}

# Mark the end, before the end-of-file
	elsif ($cmdline =~ /^\*EOD\*\s*$/) {
		last;
	}

# Stuff to write a file
	elsif ($cmdline =~ /^out\s+(.*)$/) {
		$outline = $1;
		unless (defined $outfile) {
			$outfile = $main::config{TEMPDIR} . '/dataimage/' .
				&basename( $script_file);
			($outfile = $script_file) =~ s/\.image$/.out/;
			$outfile =~ /^(.*)$/ and $outfile = $1; # untaint
			open (OUT, ">$outfile") or &abort("can't open $outfile: $!");
			&debug("opening output file $outfile") if ($main::debug>1);
		}
		&debug("writing out '$outline'") if ($main::debug);
		print OUT $outline ."\n";
	}

# Garbage here
	else {
		&error("unknown line: $cmdline");
	}
}

# Make sure that the output-file get's closed properly
close (OUT) if (defined $outfile);

# Send the image
unless ($main::imageonly) {
	print "content-type: image/png\n\n";
}
binmode STDOUT;
print $main::image->png;

0;

#----------------------------------------------------------------- abort ---
sub abort {
	my $msg = join('', @_);
	print <<"EOD_ABORT";
content-type: text/html

<html>
<head><title>$main::prog Abort</title></header>
<body>
<h1>$main::prog (version $main::version) Abort</h1>
$msg
</body>
</html>
EOD_ABORT
	exit 1;
}

#------------------------------------------------- debug ---
sub debug {
	my $msg = join('', @_);

	print STDERR "DEBUG: $msg\n";
}

#-------------------------------------------------- error ---
sub error {
	my $msg = join('', @_);

	print STDERR "ERROR: $msg\n";
}

#------------------------------------------------- my_get_status ---
sub my_get_status {
	my ($host, $file) = @_;
	my $string = &get_status($host, $file);
	if ($string =~ /^(.*) \(STALE\)\s*$/) {
		$string = $1;
	}
$string;
}

#---------------------------------------------------- my_header ---
sub my_header {
	my ($title) = @_;
	my %indices = &init_indices;
	my $string = &html_header($title, '', %indices);
$string;
}

#----------------------------------------------------- my_graph ---
sub my_graph {
	my ($host, $realrrd, $graph, $graphtime) = @_;
	my $string = &make_rrdcgi_graph( $host, undef, $host, $realrrd, 
		$graph, $graphtime);
$string;
}

#----------------------------------------------------- my_customgraph ---
sub my_customgraph {
	my ($customgraph, $graphtime) = @_;
	my $string = &make_custom_graph( $main::config{HTMLDIR} .'/CUSTOM', 
		undef, $customgraph, $graphtime);
$string;
}

#---------------------------------------------------- usage ---
sub usage {
	print STDERR <<"EOD_USAGE";
$main::prog version $main::version
usage: $prog [options]
where options are:
	-d ddd  set debugging level to 'ddd'
	-f fff  use 'fff' for config-dir [$main::config_dir]
	-h      show this help
	-i      image-only mode, just output raw png
EOD_USAGE
	exit 0;
}

#--------------------------------------------------- make_color ---
sub make_color {
	my ($name, $r, $g, $b) = @_;

	my $color = $main::image->colorAllocate($r, $g, $b);
	$main::linebrush->colorAllocate($r, $g, $b);
	$main::colors{$name} = $color;
	$main::rgb{$name} = [$r, $g, $b];
	push @main::colors, $name;
	&debug("make_color: $name ($r, $g, $b) is color $color") 
		if ($main::debug);
$color;
}

#------------------------------------------------- define_flowcolors ---
sub define_flowcolors {
	&make_color('flowcolor1', 0, 0, 0);			# black
	&make_color('flowcolor2', 152, 25, 192);	# purple
	&make_color('flowcolor3', 0, 0, 240);		# blue
	&make_color('flowcolor4', 0, 230, 230);		# cyan
	&make_color('flowcolor5', 0, 150, 0);		# green
	&make_color('flowcolor6', 154, 205, 50);	# yellow-green
	&make_color('flowcolor7', 250, 255, 0);		# yellow
	&make_color('flowcolor8', 255, 165, 0);		# orange
	&make_color('flowcolor9', 220, 0, 0);		# red
	&make_color('flowcolor10', 255, 150, 150);		# bright red
}

#----------------------------------------------- checkxy ---
sub checkxy {
	my ($x, $y) = @_;

	if ($x < 0) { $x = 0; }
	elsif ($x > $main::xsize) { $x = $main::xsize - 1; }

	if ($y < 0) { $y = 0; }
	elsif ($y > $main::ysize) { $y = $main::ysize - 1; }

	return ($x, $y);
}

#----------------------------------------------------- keep_strict_happy ---
sub keep_strict_happy {
	$main::ip_cache_readonly = 0;
	$main::alerts_readonly = 0;
}
