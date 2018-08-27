#  _____________________________________________________________________________
# |                                                                             |
# |    Moduł obsługi systemu Linux w skryptach toys                             |
# |    Kody wyjścia ze skryptu generowane w systuacjach awaryjnych tego API     |
# |    100 - nie znalezione udevadm  ( nie używane, init_tool zwaraca 1 )       |
# |    101 - nie wywołano init_module                                           |
# |_____________________________________________________________________________|

package LNXtools;
use strict;
use warnings;
use Exporter qw(import);
use Cwd  qw(abs_path);
use lib '../lib';

# Moduły do dołączenia w razie potrzeby. Powinny być zlokalizaowane w ../lib względem katalogu z któ©ego jest uruchamiany skrypt
use Gentools qw(dbg verb error);

our @EXPORT_OK = qw(get_fc_adapters get_tape_drvs $debug $verbose init_module);
my $debug=0;
my $verbose=0;
our $udev;
our $distro;				# Distro na jakim działam. Może się przydać.


sub init_module()
# Inicjalizacja rożnych rzeczy które rożnią się pomiędzy dystrybucjami
# Zwrotki:
#	0 - wszystko ok
#	1 - nie udało się znaleźć udevadm
{
	$udev = qx(which udevadm);
	my $rc = $? >> 8;
	my $ret = 0;
	
	dbg("LNXtools::init_module", "Wywołanie: \'which udevadm\' zakończone z kodem wyjścia $rc\n");
	
	$ret = 1 if $rc == 1;		# which nie znalzało udevadm
	chomp $udev;			# Bo się chrzani przy dodaniu argumentów
	return ($ret);
}

sub get_drv($)				# Buduje hash z atrybut->wartość dla zadanego napedu
{
	my %drv=();
	my $line = qx(ls -l /dev/lin_tape/$_[0]);
	
	if($udev eq "")			# Nie wywołano init_module
	{
		error("LNXtools::get_drv", "Nie ustawiono lokalizacji udevadm.\n", 101);
	}
	
        $drv{"name"} = $_[0];
        
	$line =~ /(IBMtape\d+$)/ or return %drv;	# sprawdzam tylko napędy bez "n" na końcu
	my $real_name = $1;
        $drv{"real_name"} = $real_name;
	#print "get_drv:\t real name: $real_name\n" if $debug;
	$drv{"real_name"} = $real_name;
	$line = qx(ls -l /dev/$real_name);
	(undef,undef,undef,undef,undef,my $drv_no, undef) = split($line);
	$drv{"drv_no"} = $drv_no;
	
        open(ATTRS, "$udev info --attribute-walk --name /dev/$real_name|") or die "Nie mogę uruchmić udevadm na urządzeniu $real_name.\n";
        dbg("LNXtools::get_drv", "Pobieranie atrybutów napędu $real_name komendą: $udev info --attribute-walk --name /dev/$real_name\n");
        
        while($line=<ATTRS>) 
        {
		if ( $line =~ /ww_node_name}=="0x(\w+)"/ )	# Znaleziono WWNN
		{
			dbg("LNXtools::get_drv", "Napęd $real_name, WWNN $1\n");
			$drv{"WWNN"} = $1;
		}
		elsif ( $line =~ /serial_num}=="(\w+)"/ )	# Srial napędu
		{
			dbg("LNXtools::get_drv", "Napęd $real_name, Serial $1\n");
			$drv{"serial"} = $1;
		}
		elsif ( $line =~ /primary_path}=="(\w+)"/ )	# alt_pathing
		{
			dbg("LNXtools::get_drv", "Napęd $real_name, alt_path $1\n");
			$drv{"alt_path"} = $1;
		}
		elsif ( $line =~ /ww_port_name}=="0x(\w+)"/ )	# WWPN
		{
			dbg("LNXtools::get_drv", "Napęd $real_name, WWPN $1\n");
			$drv{"WWPN"} = $1;
		}
		elsif ( $line =~ /rev}=="(\w+)"/ )		# Wersja Firmware
		{
			dbg("LNXtools::get_drv", "Napęd $real_name, FW $1\n");
			$drv{"FW"} = $1;
		}
		elsif ( $line =~ /model}=="(\S+) *"/ )		# Model Napędu
		{
			dbg("LNXtools::get_drv", "Napęd $real_name, Model $1\n");
			$drv{"model"} = $1;
		}
		
		next;
	}
       
        close(ATTRS);
        
	return %drv;
}

sub get_tape_drvs()			# Buduje hash of hash z napędami. Indeksem jest SERIAL napędu.
# drvs{SERIAL}
#	alt_pathing - 1|0
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
	open(DRVS, "ls /dev/lin_tape/|") or die "Nie mogę otworzyć listy napędów.\n";
	while(<DRVS>)
	{
		chomp;
		%drv = get_drv($_);
		if(%drv) 		# Dostałem napęd
		{
			my $serial = $drv{"serial"};		# zbędne ale łatwiej
			if( grep /^$serial$/, keys(%drv) )	# Sprawdzam, czy już mam napęd o takiej nazwie, bo jeśli tak to może złapałem kojeną scieżkę do niego ? 
			{
				dbg("LNXtools:get_tape_drvs", "Napęd $serial już jest na lisćie. Dodawanie nowej ścieżki.\n");
				$drvs{"$serial"}{"alt_pathing"} = 1;
			}
			else				# Napędu jeszcze nie widziałem. Dodawanie unikalnych atrybutów
			{
				dbg("LNXtools:get_tape_drvs", "Dodawanie nowego napędu $serial do listy.\n");
				$drvs{"$serial"}{"alt_pathing"} = 0;
				$drvs{"$serial"}{"WWNN"} = $drv{"WNN"};
				$drvs{"$serial"}{"name"} = $drv{"name"};
				$drvs{"$serial"}{"FW"} = $drv{"FW"};
				$drvs{"$serial"}{"model"} = $drv{"model"};
			}
			
			# dodawanie wspólnych atrybutów zarówno dla nowego jak i istniejącego na liscie napędu
			push @{$drvs{"$serial"}{"real_names"}}, $drv{"real_name"};
			push @{$drvs{"$serial"}{"WWPN"}}, $drv{"WWPN"};
		}
	}
	
	close(DRVS);
	return %drvs;
}

sub get_fc_adapters() 			# Buduje hasha adapter_fc -> WWPN
{
	my %fcs;
	open(FC, "ls /sys/class/fc_host/|") or die "Nie mogę załadować listy kart HBA.\n";
	while(<FC>)
	{
		chomp;				# bo ls dodaje koniec linii
		my $fc_host = $_;
		my $fc_no = substr($fc_host,4);
		my $fc = "fc".$fc_no;	# Zamiana hostXX na fcXX
		my $raw_wwnn = qx(cat /sys/class/fc_host/$fc_host/port_name);
		chomp($raw_wwnn);
		my $tmp_wwnn = substr($raw_wwnn, 2);
		my $offset = 0;
		for( my $i=2; $i<=14; $i += 2) 
		{
			substr($tmp_wwnn, $i+$offset, 0) = ':';	# wstawianie : co dwie cyferki
			$offset++;
		}
		$fcs{"$fc"} = $tmp_wwnn;
	}
	close(FC);
	return %fcs;
}
 
1;					# Bo tak kurwa ma być
