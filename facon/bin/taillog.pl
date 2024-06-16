#!/usr/bin/perl

use File::Basename;
use Getopt::Std;

%opt = ();




getopts('d:', \%opt);


# Make sure some of the specified log-files actually exist
unless ($#ARGV >= 0) { &usage; } # no return
@logs = ();


my @rra = @opt{d};

print $rra[0];


my $dir  = dirname $opt{d};
my $files = basename $opt{d};

my $c_p = "taillog-";
my $c_d = "/var/tmp/tailog";

my $pos;

print $opt{d} . "\n";

#$debug = 1;

opendir(DIR, $dir) or die "can't opendir $dir: $!";


foreach my $file (@ARGV) {



	# Make sure the context directory exists
	unless (-d $c_d) {

        	mkdir ($c_d, 0700) or
                &abort("can't mkdir $c_d: $!\n");
	}



	# Make sure we have some context
	($c_f = $file) =~ tr#/#_#;

	$c_f = $c_d . "/" . $c_p . $c_f;


	# si file es un file
	next unless (-f $file);

	# Get the current log-file position
	if ( -f $c_f) {

	        $pos= &get_context( $c_f);
	        &abort("can't open existing context $c_f") unless( defined $pos);
	        &debug("got $position from context $c_f") if ($main::debug);

		# Has the log-file been rolled-over since last time?
	        if ((! defined $pos) or ($pos> -s $logfile)) {

	                &debug("logfile rolled over; starting from beginning") if ($main::debug);

	                $pos= 0;
	        }
	} else {


		#  Crea el context file
        	&debug("no context; skipping data this time") if ($main::debug);
        	&put_context( $c_f, -s $file);
	}



	# Skip the records we've already seen
	open (LOG, "<$file") or &abort("can't open $file: $!");
	seek (LOG, $pos, 0) or &abort("can't seek $file: $!");

	while (my $lin = <LOG>){

		print $lin;
	}

	# Remember where we left off
	$pos = tell(LOG);
	&debug("eof at $pos") if ($main::debug);
	close (LOG);
	&put_context($c_f, $pos);

	die "OK";


}



closedir(DIR);






#----------------------------------------------------------------- debug ---
sub debug {
        print STDERR 'DEBUG: ', @_, "\n";
}

#--------------------------------------------------------------- abort ---
sub abort {
        print STDERR 'ABORT: ', @_, "\n";
        exit 1;
}


#--------------------------------------------------------------- error ---
sub error {
        print STDERR 'ERROR: ', @_, "\n";
}

#---------------------------------------------------------- put_context ---
sub put_context {
        my ($file, $string) = @_;

        open (PUTCONTEXT, ">$file") or &abort("can't open $file: $!");
        print PUTCONTEXT $string or &abort("can't write $file: $!");
        close (PUTCONTEXT) or &abort("can't close $file: $!");
        &debug("saved context $string in $file") if ($main::debug);
}

#--------------------------------------------------------- get_context ---
sub get_context {
        my $file = shift @_;
        my( $string);

        &debug("get context from $file");

        open( GETCONTEXT, "<$file") or do {
                &error("can't open $file: $!");
                return undef;
        };
        defined( $string = <GETCONTEXT>) or do {
                &error("can't read $file or is empty: $!");
                return undef;
        };
        chomp $string;
        close(GETCONTEXT);

        &debug("value of $file context $string ");
        return $string;
}



#---------------------
sub usage {

	die ("uso: $0 -d directorio con logs (regular expression)" ) ;
}
