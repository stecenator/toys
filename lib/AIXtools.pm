package AIXtools;
use strict;
use warnings;
 
use Exporter qw(import);
use Cwd  qw(abs_path);
use lib '../lib';
# Moduły do dołączenia w razie potrzeby. Powinny być zlokalizaowane w ../lib względem katalogu z którego jest uruchamiany skrypt
use Gentools qw(dbg verb);
 
our @EXPORT_OK = qw(get_fc_adapters get_tape_drvs get_disks);
my $debug=0;
my $verbose=0;

sub init_module($)
# $_[0] - debug
# Inicjalizacja zmiennych modułu
{
	$debug = shift;
	dbg("AIXtools::init_module", "Inicjalizacja zmiennych modułu.\n");
	return 0;
}

sub get_disk_serial($)
# Zwraca serial LUNu z lscfg
{
	my $ret="None";
	my @result = qx/lscfg -vl $_[0]/;
	my $rc = $? >> 8;
	if ($rc != 0)			# Coś poszło nie tak
	{
		dbg("get_disks", "Wykonanie lspv: $rc\n");
		exit 1;
	}
	foreach my $line (@result)
	{
		chomp($line);
		if( $line=~/Serial Number...............(.*)/ )
		{
			$ret=$1;
			dbg("AIXtools::get_disk_serial","Serial dysku $_[0]: $ret\n");
			last;
		}
	}
	return $ret;
}

sub get_disks()
# Zwraca hasha z dyskami hdiskX => (serial, pvid, vg)
{
	my %ret=();
	my @result = qx/lspv/;
	my $rc = $? >> 8;
	if ($rc != 0)			# Coś poszło nie tak
	{
		dbg("get_disks", "Wykonanie lspv: $rc\n");
		exit 1;
	}
	foreach my $line (@result)
	{
		chomp($line);
		dbg("get_disk", "linia: $line\n");
		(my $hdisk, my $pvid, my $vg, my $active) = split(" ",$line);
		my $serial = get_disk_serial("$hdisk");
		dbg("get_disks","$hdisk $serial $pvid $vg\n");
		@{$ret{"$hdisk"}} = ($pvid, $serial, $vg);
	}
	return %ret;
}

sub get_drv($)				# Buduje hash z atrybut->wartość dla zadanego napedu
{
	my $d = shift;
	my %drv= ( "name" => "$d" );
	
	#~ my $line = qx(lsattr -El $_[0]);
	open(DRV, "lsattr -El $d -F attribute,value |") or die "Nie można pobrać atrybutów napędu $d.\n";
	
	while(<DRV>)
	{
		chomp;
		(my $attr, my $val) = split /,/;
		
		if( $attr eq "alt_pathing" )
		{
			$drv{"$attr"} = substr $val, 0, 1;
		}
		elsif ( $attr eq "primary_device" ) 
		{
			$drv{"real_name"} = $val;
		}
		elsif ( $attr eq "ww_name" ) 
		{
			$drv{"WWPN"} = substr $val, 2;
		}
		elsif ( $attr eq "node_name" ) 
		{
			$drv{"WWNN"} = substr $val, 2;
		}
	}
	
	close(DRV);
	
	open (DRV, "lscfg -vl $d|") or die "Nie można wykonać lscfg -vl $d.\n";
	
	while(<DRV>)
	{
		if ( /Serial Number...............(.*)$/ )
		{
			$drv{"serial"} = "$1";
		}
		elsif ( /Device Specific.\(FW\)........(.*)$/ )
		{
			$drv{"FW"} = $1;
		}
		elsif ( /Machine Type and Model......(.*)$/ )
		{
			$drv{"model"} = $1;
		}
	}
	
	close(DRV);
	
	return %drv;
}

sub get_tape_drvs()
# drvs{SERIAL}
#	alt_pathing - y|n
#	FW - firmware
#	WWNN - wwnn
#	name - primary name
#	alt_names - (nazwa_alt1, nazwa_alt2, ...)
#	drv_no - (numer_pri, numer_alt1, ...)
#	elems - (elem_pri, elem_alt1, ...) --- Tego nie ma 
#	WWPN - (WWPN_pri, WWPN_alt1, ...)
{
	my %drvs;
	my %drv;
	open(DRVS, "lsdev -Cc tape|") or die "Nie mogę otworzyć listy napędów.\n";
	
	while(<DRVS>)
	{
		(my $d, undef,undef,undef,undef,undef,undef,undef,undef) = split;
		%drv = get_drv($d);
		if(%drv) 		# Dostałem napęd
		{
			my $serial = $drv{"serial"};		# zbędne ale łatwiej
			
			if( grep /^$serial$/, keys(%drv) )	# Sprawdzam, czy już mam napęd o takiej nazwie, bo jeśli tak to może złapałem kojeną scieżkę do niego ? 
			{
				dbg("AIXtools:get_tape_drvs", "Napęd $serial już jest na lisćie. Dodawanie nowej ścieżki.\n");
				#~ $drvs{"$serial"}{"alt_pathing"} = "y";
			}
			else				# Napędu jeszcze nie widziałem. Dodawanie unikalnych atrybutów
			{
				dbg("AIXtools::get_tape_drvs", "Dodawanie nowego napędu $serial do listy.\n");
				$drvs{"$serial"}{"alt_pathing"} = $drv{"alt_pathing"};
				$drvs{"$serial"}{"WWNN"} = $drv{"WWNN"};
				$drvs{"$serial"}{"name"} = $drv{"name"};
				$drvs{"$serial"}{"FW"} = $drv{"FW"};
				$drvs{"$serial"}{"model"} = $drv{"model"};
			}
			
			# dodawanie wspólnych atrybutów zarówno dla nowego jak i istniejącego na liscie napędu
			push @{$drvs{"$serial"}{"real_names"}}, $drv{"real_name"};
			push @{$drvs{"$serial"}{"WWPN"}}, $drv{"WWPN"};
		}
	}
	return %drvs;
}
 
sub get_fc_adapters() 		# Buduje hasha adapter_fc -> WWPN
{		
	my %fcs;
	open(FC, "lscfg -vl fcs*|") or die "Nie mogę znaleźć lscfg.\n";
	while (<FC>) 
	{
		if(/^  (fcs\d+) /) 
		{
			my $fc = $1;
			my $wwn = "dupa";
			my $offset = 0;
			<FC>;						# pomijam pusta linię
			my $line=<FC>;				# na tej powinien być Network Address
			if($line =~ /Network Address\.*(\w+)/) {
				$wwn = "$1";
			}
			for( my $i=2; $i<=14; $i += 2) 
			{
				substr($wwn, $i+$offset, 0) = ':';	# wstawianie : co dwie cyferki
				$offset++;
			}
			$fcs{"$fc"} = $wwn;
		}
	}
	close(FC);
	return %fcs;
}
 
1;				# Bo tak kurwa ma być
