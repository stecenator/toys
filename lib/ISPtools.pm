package ISPtools;
use strict;
use warnings;
use lib qw(./ ../toys/lib);
use Gentools qw(chkos error verb dbg chk_usr_proc);
 
use Exporter qw(import);
our $debug = 0;                 						# do rozjechania przez Gentools::debug=1 w module wołającym
our $verbose=0;
our @EXPORT_OK = qw(init_module get_process_list start_ISP is_ISP_active stop_ISP);
our ($admin, $pass, $host);
my $cmd="dsmadmc ";

sub is_ISP_active($)
# is_ISP_active($user) - sprawdza, czy $user ma proces dsmserv
{
	my @lines = qx/ps -C dsmserv -f/;
	my $rc = $? >> 8;
	
	return 0 if ($rc != 0);			# nie ma prosu o tej nazwie
	
	(my $user, my $pid, undef) = split(" ", $lines[1]);			# Bo w pierwszej linii są nagłówki
	
	dbg("ISPtools::is_ISP_active", "Proces dsmserv znaleziony u użyszkodnika $user\n");
	
        if( "$user" eq $_[0] )			# User jest właścicielem procesu
        {
                return $pid;
        }
        else
        {
                return 0;
        }
}

sub start_ISP($$)
# Startuje instancję serwera ISP na użytkowniku $_[0] z katalogiem instancji $_[1]
# Zwrotki:
#	0 - jeśli nie udało się wystartować
#	<PID> - pid procecu dsmserv 
{
	my $cmd = "";
	my $OS = chkos();
	my $instuser = shift;
	my $instdir = shift;
	
	# sprawdzenie, czy user jest poprawny
	#~ my $uid = getpwnam("$instuser")
	my $uid = getpwnam("$instuser");
	my $pid = -1;
	
	if (!$uid)
	{
		error("ISPtools::start_ISP", "Użytkownik instancji $instuser nie istnieje.\n", 17);
	}
	
	dbg("ISPtools::start_ISP", "UID użyszkodnika instancji $uid.\n");
	
	if ("$OS" eq "Linux")
	{
		$cmd = "systemctl start $instuser";
		dbg("ISPtools::start_ISP", "Komenda do uruchomienia na Linuxie: $cmd\n");
	}
	elsif ("$OS" eq "AIX")
	{
		dbg("ISPtools::start_ISP", "AIX - durnostojka.\n");
		return 1;
	}
	else
	{
		exit 17;							# Start TSM nieudany (kody opisane w ISP_Startup.pl)
	}
	
	my @out = qx($cmd 2>/dev/null);
	my $rc = $? >> 8;
	
	dbg("ISPtools::start_ISP", "Kody wyjścia z \"$cmd\" = $rc\n");
	
	sleep 20;
	$pid = chk_usr_proc("$instuser", "dsmserv");
	
	if($pid <= 0 )								# Serwer jednak żyje
	{
		error("\nISPtools::start_ISP", "Kod powrotu z \"$cmd\" = $rc\n", 17);
	}
	
	dbg("ISPtools::start_ISP", "PID serwera = $pid.\n");
	
	return $pid;
}

sub stop_ISP()
# Stopuje instancję serwera ISP na użytkowniku $_[0] z katalogiem instancji $_[1]
# Zwrotki:
#	1 - jeśli udało się zatrzymać serwer
#	0 - nie udało się 
{
	my $tmp_cmd=$cmd."halt";
	my %ret = ();
	my @out = qx/$tmp_cmd/;
	my $rc = $? >> 8;
	
	dbg("ISPtools::stop_ISP", "Wywołanie: $tmp_cmd zakończone z kodem wyjścia $rc\n");
	dbg("ISPtools::stop_ISP", "Prewencyjne spanie przez 60s, żeby ISP zdążył się poskładać.\n");
	sleep 60;
	
	return (1) if $rc == 0;						# TSM się poskładał
	
	if ($rc != 0)							# Coś poszło nie tak
	{
		dbg("ISPtools::stop_ISP", "Wykonanie $tmp_cmd: $rc\n");
		return (0);
	}
}

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

sub init_module($$;$$$)
# Funkcja inicjalizacji zmiennych modułu: $debug, $verbose, $admin, $pass, $host
#   Konstruuje zmienną $cmd które zawiera część wspólną do wywałoania dsmamdc (Uwierzytelnienie, dataonly, itd)
#   Zwrotka - brak. W razie błędu zatrzyma program.
{
	my $tmp_cmd="";			# Bo nie wiadomo, czy będzie se=cośtam czy nie
	$debug = $_[0];
	$verbose = $_[1];
	$admin = $_[2] if ($_[2]);
	$pass = $_[3] if ($_[3]);
	$host = $_[4] if ($_[4]);
	
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
	
	if( $host )			# Podano jakiś serwer TSM
	{
		$tmp_cmd = "-se=$host ";
		dbg("ISPtools::init_module", "Alias serwera ISP: $host.\n");
	}
	else
	{
		dbg("ISPtools::init_module", "Nie ustawiono aliasu serwer ISP. Zostani użyty domślny serwer z dsm.opt.\n");
	}
	
	$cmd=$cmd.$tmp_cmd." -id=$admin -pa=$pass -dataonly=yes -tab ";
	dbg("ISPtools::init_module","Komenda do zarządzania ISP: $cmd.\n");
}

1;		# Bo tak kurwa ma być
