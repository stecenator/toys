package LNXtools;
use strict;
use warnings;
use Exporter qw(import);
 
our @EXPORT_OK = qw(get_fc_adapters get_tape_drvs $debug $verbose);
our ($debug, $verbose);
$debug=0;
$verbose=0;

sub dbg($$)
# Komunikat do wyświetlenia, jesli jest włączony tryb debug.
{
	print "$_[0]:\t$_[1]" if $debug;
}

sub verbose($)
# Komunikat do wyświetlenia, jesli jest włączony tryb debug.
{
	print "$_[0]" if $verbose or $debug;
}

sub get_drv($)				# Buduje hash z atrybut->wartość dla zadanego napedu
{
	my %drv=();
	my $line = qx(ls -l /dev/lin_tape/by-id/$_[0]);
        $drv{"name"} = $_[0];
        #print "get_drv:\t name: $_[0]\n" if $debug;
	$line =~ /(IBMtape\d+$)/ or return %drv;	# sprawdzam tylko napędy bez "n" na końcu
	my $real_name = $1;
        $drv{"real_name"} = $real_name;
	#print "get_drv:\t real name: $real_name\n" if $debug;
	$drv{"real_name"} = $real_name;
	$line = qx(ls -l /dev/$real_name);
	(undef,undef,undef,undef,undef,my $drv_no, undef) = split($line);
	$drv{"drv_no"} = $drv_no;
        open(ATTRS, "/usr/sbin/udevadm info --attribute-walk --name /dev/$real_name|") or die "Nie mogę uruchmić udevadm na urządzeniu $real_name.\n";
        while(($line=<ATTRS>) !~ /ww_node_name}=="0x(\w+)"/ )
        {
                next;                   # pomijanie pierwszych kilku linijek, aż trafię na ww_node_name
        }
        $line =~ /ww_node_name}=="0x(\w+)"/;    # bo while nie ustawił $1
        #print "get_drv:\t WWNN: $1\n" if $debug;
        $drv{"WWNN"} = $1;
        $line = <ATTRS>;                # tu się spodziwam seriala
        $line =~ /serial_num}=="(\w+)"/;
        #print "get_drv:\t Serial: $1\n" if $debug;
        $drv{"serial"} = $1;
        $line = <ATTRS>;                # alt pathing
        $line =~ /primary_path}=="(\w+)"/;
        #print "get_drv:\t alt_pathing: $1\n" if $debug;
        $drv{"alt_path"} = $1;
        $line = <ATTRS>;                # WWPN
        $line =~ /ww_port_name}=="0x(\w+)"/;
        #print "get_drv:\t WWPN: $1\n" if $debug;
        $drv{"WWPN"} = $1;
        while(($line=<ATTRS>) !~ /rev}=="(\w+)"/ )
        {
                next;                   # pomijanie kolejnych kilku linijek, aż trafię na ww_node_name
        }
        $line =~ /rev}=="(\w+)"/;       # wersja firmłeru
        #print "get_drv:\t FW: $1\n" if $debug;
        $drv{"FW"} = $1;
        while(($line=<ATTRS>) !~ /model}=="(\S+) *"/ )
        {
                next;                   # pomijanie kolejnych kilku linijek, aż trafię na ww_node_name
        }
        $line =~ /model}=="(\S+) *"/;   # model napędu
        #print "get_drv:\t model: $1\n" if $debug;
        $drv{"model"} = $1;
        close(ATTRS);
	return %drv;
}

sub get_tape_drvs()			# Buduje hash of hash
# drvs{SERIAL}
#	alt_pathing - 1|0
#	FW - firmware
#	WWNN - wwnn
#	names - (nazwa_pri, nazwa_alt1, nazwa_alt2, ...)
#	drv_no - (numer_pri, numer_alt1, ...)
#	elems - (elem_pri, elem_alt1, ...)
#	WWPN - (WWPN_pri, WWPN_alt1, ...)
{
	my %drvs;
        my %drv;
	open(DRVS, "ls /dev/lin_tape/by-id/|") or die "Nie mogę otworzyć listy napędów.\n";
	while(<DRVS>)
	{
		chomp;
		# print "get_tape_drvs:\t Napęd: $_\n" if $debug;
		%drv = get_drv($_);
		if(%drv) 		# dostałem pustego hasha
		{
                        $drvs{"$_"} = %drv;
                        print "get_tape_drvs:\tNazwa napędu: $drv{'name'}\n"
		}
                else
                {
                        print "get_tape_drvs:\t Urządzenie $_ nie jest napędem taśmowym?\n" if $debug;
                        if($drv{'alt_pathing'} eq "Primary")
                        {
 
                        }
                        next;
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
