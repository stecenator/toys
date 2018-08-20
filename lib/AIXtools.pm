package AIXtools;
use strict;
use warnings;
 
use Exporter qw(import);
 
our @EXPORT_OK = qw(get_fc_adapters get_tape_drvs $debug $verbose get_disks);
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
			dbg("get_disk_serial","Serial dysku $_[0]: $ret\n");
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

sub get_tape_drvs()
{
	my %drvs;
	return %drvs
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
