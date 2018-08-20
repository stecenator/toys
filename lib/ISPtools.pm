package ISPtools;
use strict;
use warnings;
 
use Exporter qw(import);
our $debug = 0;                 						# do rozjechania przez Gentools::debug=1 w module wołającym
our $verbose=0;
our @EXPORT = qw(init_ISPtools get_process_list);
our ($admin, $pass, $host);
my $cmd="dsmadmc ";

sub get_process_list()
# Zwraca hash indeksowany numerami procesów. Wartością jest typ procesu.
# Pusty hash jest zwracany gdy nie ma procesów
{
	my $tmp_cmd=$cmd."q pr";
	my %ret = ();
	my @out = qx/$tmp_cmd/;
	my $rc = $? >> 8;
	
	dbg("ISPtools::get_process_list", "Wywołanie: $tmp_cmd zakończone z kodem wyjścia $rc\n");
	
	return () if $rc == 11;						# Database manager powiedział, że nie ma aktywnych baz
	
	if ($rc != 0)							# Coś poszło nie tak
	{
		dbg("ISPtools::get_process_list", "Wykonanie $tmp_cmd: $rc\n");
		return ();
	}
	else
	{
		foreach my $line (@out)
		{
			chomp $line;
			(my $key, my $val) = split("\t", $line);
			$ret{"$key"} = $val;
			dbg("ISPtools::get_process_list", "Nr Procesu: $key, Typ: $val\n"); 
		}
	}
	return %ret;
}

sub init_ISPtools($$$$$)
# Funkcja inicjalizacji zmiennych modułu: $host, $admin, $pass, $debug, $verbose
#   Konstruuje zmienną $cmd które zawiera część wspólną do wywałoania dsmamdc (Uwierzytelnienie, dataonly, itd)
#   Zwrotka - brak. W razie błędu zatrzyma program.
{
	my $tmp_cmd="";			# Bo nie wiadomo, czy będzie se=cośta czy nie
	$host = $_[0];
	$admin = $_[1];
	$pass = $_[2];
	$debug = $_[3];
	$verbose = $_[4];
	
	unless( $debug != 0 || $debug != 1)
	{
		print STDERR "ISPtools: Błędny tryb debug. Dozwolone wartości: 1 lub 0, podano $debug.\n";
		exit 1;
	}
	
	unless( $verbose != 0 || $verbose != 1)
	{
		print STDERR "ISPtools: Błędny tryb verbose. Dozwolone wartości: 1 lub 0, podano $verbose.\n";
		exit 1;
	}
	
	if($host ne "")			# Podano jakiś serwer TSM
	{
		$tmp_cmd = "-se=$host ";
	}
	
	$cmd=$cmd.$tmp_cmd." -id=$admin -pa=$pass -dataonly=yes -tab ";
	dbg("ISPtool::init_ISPtools","Komenda do zarządzania ISP: $cmd.\n");
}

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

1;		# Bo tak kurwa ma być
