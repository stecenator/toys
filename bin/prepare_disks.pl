#!/usr/bin/perl -w
use strict;
use warnings;
#
#	Prepares given LUNS for for SAP HANA filesystem layout:
#	Assupmtions:
#		- It expects 7 LUNs with following LUN ID's:
#			- 1-4 for /hana/data
#			- 5 for /hana/logs
#			- 6 for /hana/shared
#			- 7 for /usr/sap
#
#	What it does:
#		- Simple validation - checks LUN numbers and if they are already PV's
#		- Creates PVs on each lun
#		- Creates 4 LVs:
#			- datalv - stripesd, composed of 4 PVs/LUNs
#			- loglv
#			- sharedlv
#			- saplv
#		- Formats the LVs with xfs filesystem
#		- Puts proper entries into /etc/fstab they gets mounted upon restart
#
##############################################################################
#
#	Some globals
#
##############################################################################

my $debug = 0;			# run in debug mode
my $verbose = 1;		# be verbose
#my $VG = "hanavg";		# volume group to be created
my @LUNS = ();			# LUN to mpath mapping. LUN-1 number is an array index
my @PVS = ();			# Current PV list
my %FS = ( '/dev/hana-datavg/datalv' => "/hana/data",
			'/dev/hana-logvg/loglv' => "/hana/log",
			'/dev/hana-sharedvg/sharedlv' => "/hana/shared",
			'/dev/hana-sapvg/saplv' => "/usr/sap" );
my $fstab = "/etc/fstab";	# for debuging purposes
my $outfile = "/tmp/prepare_disks.sh";	# commands to preprare filesystems

##############################################################################
#
#	Functions definitions
#
##############################################################################
sub scan_luns()			# fills the @LUNs table with discovered UUIDs
{
	my $mpath;
	my $wwid;
	my $dm;
	my $size;
	
	open(IN, "multipath -ll|") or die "Unable to run mutipath -ll command.\n";
	while(<IN>)
	{
		if( /IBM,2145/ ) 
		{
			if( /\(.*\)/ ) 	# Firendly names are on
			{
				( $mpath, $wwid, $dm ) = split / /;
				$wwid = substr( $wwid, 1, -1 );		# strip the () from wwid
			} 
			else
			{
				( $mpath, $dm ) = split / /;
				$wwid = $mpath
			}
			my $line = <IN>;						# get the size of the LUN
			# parsing line like: size=80G features='1 queue_if_no_path' hwhandler='0' wp=rw
			$line =~ /size=(\d+)G/;					# get the figure digits between = and G
			$size=$1;
			while(my $path=<IN>)
			{
				if( $path =~ /\d+:\d+:\d+:(\d+)/ )
				{
					my $lun = $1;
					print "Debug: scan_luns:\t$mpath,$lun,$wwid,$dm,$size\n" if $debug;
					$LUNS[$lun] = { mpath => $mpath,
							wwid => $wwid,
							dm => $dm,
							size => $size };
					last;
				}
			}
		} 
		else
		{
			next;	
		}
	}
	close(IN);
	if( $verbose )
	{
		for ( my $lun=1; $lun <= $#LUNS; $lun++ ) 	# useable luns are 1-7 
		{
			print "scan_luns:\tLUN:\t$lun\n";
			foreach my $key ( keys $LUNS[$lun] )
			{
				print "scan_luns:\t\t$key\t=>\t$LUNS[$lun]{$key}\n";
			}
		}
	}
}

sub scan_pvs()			# fills the list of exitsting PVs
{
	my $pvs = 0;		# discovered PV count
	open( PVS, "pvs|" ) or die "Unable to create existing PV list.\n";
	while( <PVS> )
	{
		next if( /^  PV / );		# Skipping the header line of pvs
#		if( /\/([-\w]+) / )			# Get just the device name 
#		if( /[ \w\/]*\/([-\w+]) / )	# Get just the device name 
		if( / +(\S+) / )
		{
			print "Debug: scan_pvs:\tDiscovered $1 PV.\n" if $debug;
			push( @PVS, $1 );
			check_pv("$1");
			$pvs++;
		}
	}
	print "Found $pvs PVS.\n" if $verbose;
	close( PVS );
}

sub check_pv($)			# Checks if PV is a member of VG reurns 1 if an argument is a PV
{
	my $pv = shift;		# Fetching PV name from argument list
	if( open(PV, "pvdisplay $pv 2>/dev/null|") )
	{
		close(PV);
		return 0;
	}
	return 1;
}

sub verify_candidates()	# Check if any of the discovered volumes is alread a PV. 
{
	for ( my $lun=1; $lun <= $#LUNS; $lun++ ) 	# useable luns are 1-7 
	{
		my $pv = $LUNS[$lun]{'mpath'};
		print "Debug: verify_candidates:\t Checking $pv.\n" if $debug;
		print "Checking $pv... " if $verbose;
		if( check_pv($pv) ) 
		{
			print "This volume is already a PV! Exiting.\n";
			exit 2;
		} 
		print "OK.\n" if $verbose;
	}
	return 0;
}

sub create_pvs()		# calls pvcreate for each lun from 1 to 7
{
	for ( my $lun=1; $lun <= $#LUNS; $lun++ ) 	# useable luns are 1-7 
	{
		my $pv = $LUNS[$lun]{'mpath'};
		print "Creating PV on $pv... " if $verbose;
		print OUT "pvcreate /dev/mapper/$pv\n";
		if( system( "pvcreate /dev/mapper/$pv > /dev/null 2>&1") )
		{
			print "Failed! Exiting.\n" if $verbose;
			exit 3;
		}
		print "OK.\n" if $verbose;
		$LUNS[$lun] = { pv => "/dev/mapper/$pv" };
	}
	return 0;
}


sub create_vgs()		# puts newly created PV into following VGs: hana-datavg. hana-logvg, hana-sharedvg, hana-sapvg
{
	# creating hana-datavg
	my $cmd="vgcreate hana-datavg ";
	for( my $i=1; $i<=4; $i++ )
	{
		$cmd .= "$LUNS[$i]{'pv'} ";
	}
	print "Debug: create_vgs:\t Command to execute $cmd\n" if $debug;
	print "Volume group hana-datavg created... " if $verbose;
	print OUT "$cmd\n";
	if( system("$cmd > /dev/null") )
	{
		print "Failed! Exiting.\n" if $verbose;
		exit 4;
	}
	print "OK.\n" if $verbose;
	# creating hana-logvg
	$cmd = "vgcreate hana-logvg ".$LUNS[5]{'pv'};
	print "Debug: create_vgs:\t Command to execute $cmd\n" if $debug;
	print "Volume group hana-logvg created... " if $verbose;
	print OUT "$cmd\n";
	if( system("$cmd > /dev/null") )
	{
		print "Failed! Exiting.\n" if $verbose;
		exit 4;
	}
	print "OK.\n" if $verbose;
	# creating hana-sharedvg
	$cmd = "vgcreate hana-sharedvg ".$LUNS[6]{'pv'};
	print "Debug: create_vgs:\t Command to execute $cmd\n" if $debug;
	print "Volume group hana-sharedvg created... " if $verbose;
	print OUT "$cmd\n";
	if( system("$cmd > /dev/null") )
	{
		print "Failed! Exiting.\n" if $verbose;
		exit 4;
	}
	print "OK.\n" if $verbose;
	# creating hana-sapvg
	$cmd = "vgcreate hana-sapvg ".$LUNS[7]{'pv'};
	print "Debug: create_vgs:\t Command to execute $cmd\n" if $debug;
	print "Volume group hana-sapvg created... " if $verbose;
	print OUT "$cmd\n";
	if( system("$cmd > /dev/null") )
	{
		print "Failed! Exiting.\n" if $verbose;
		exit 4;
	}
	print "OK.\n" if $verbose;
}

sub create_lvs()		# Creates LVs within volume groups
{
	# create datalv
	print "Creating datalv volume... " if $verbose;
	print OUT "lvcreate -i 4 -n datalv -l 100%FREE hana-datavg\n";
	if( system( "lvcreate -i 4 -n datalv -l 100%FREE hana-datavg > /dev/null") )
	{
		print "Failed! Exiting.\n";
		exit 5;
	}
	print "OK.\n";
	
	# create loglv
	print "Creating loglv volume... " if $verbose;
	print OUT "lvcreate -n loglv -l 100%FREE hana-logvg\n";
	if( system( "lvcreate -n loglv -l 100%FREE hana-logvg > /dev/null") )
	{
		print "Failed! Exiting.\n";
		exit 5;
	}
	print "OK.\n";
	
	# create sharedlv
	print "Creating sharedlv volume... " if $verbose;
	print OUT "lvcreate -n sharedlv -l 100%FREE hana-sharedvg\n";
	if( system( "lvcreate -n sharedlv -l 100%FREE hana-sharedvg > /dev/null") )
	{
		print "Failed! Exiting.\n";
		exit 5;
	}
	print "OK.\n";
	
	# create saplv
	print "Creating saplv volume... " if $verbose;
	print OUT "lvcreate -n saplv -l 100%FREE hana-sapvg\n";
	if( system( "lvcreate -n saplv -l 100%FREE hana-sapvg > /dev/null") )
	{
		print "Failed! Exiting.\n";
		exit 5;
	}
	print "OK.\n";
}

sub create_fs()			# create xfs filesystems on LVs
{
	my @LVs = ("/dev/hana-datavg/datalv",
			"/dev/hana-logvg/loglv",
			"/dev/hana-sharedvg/sharedlv",
			"/dev/hana-sapvg/saplv" );
	foreach my $fs (@LVs) 
	{
		print "Creating XFS filesystem on $fs... " if $verbose;
		print OUT "mkfs.xfs $fs\n";
		if( system( "mkfs.xfs $fs > /dev/null 2>&1" ) ) 
		{
			print "Failed! Exiting.\n";
			exit 6;
		}
		print "OK.\n";
	}
}	

sub create_mp() 		# create mountpoints and put them into /etc/fstab
{
	while( ( my $lv, my $mp ) = each(%FS) )
	{
		print "Creating mountpoint $mp ..." if $verbose;
		print OUT "mkdir -p $mp\n";
		if( system( "mkdir -p $mp" ) )
		{
			print "Failed! Exiting.\n";
			exit 7;
		}
		print "OK.\n";
		
		print "Adding $mp to /etc/fstab ..." if $verbose;
		print OUT "echo $lv $mp xfs defaults 1 2 >> $fstab\n";
		if( system( "echo $lv $mp xfs defaults 1 2 >> $fstab" ) )
		{
			print "Failed! Exiting.\n";
			exit 7;
		}
		print "OK.\n";
	}
}

sub setup() 
{
	my $dc=0;			# disk count 
	scan_luns;			# Find out disks assigned to the LPAR
	$dc = @LUNS;
	if( $dc != 8 )
	{
		print STDERR "Wrong number of disks available. Found $dc, expected 8. Exiting. \n";
		exit 1;
	}
	print "Found $dc LUNs.\n" if $verbose;
	scan_pvs();
}

##############################################################################
#
#	Main Program
#
##############################################################################
open(OUT, ">$outfile") or die "Unable to open script output file: $outfile. Exiting.\n";
setup();
verify_candidates();
create_pvs();
create_vgs();
create_lvs();
create_fs();
create_mp();
close(OUT);
 
