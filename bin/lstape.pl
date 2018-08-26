#!/usr/bin/perl -w
#  _____________________________________________________________________________
# |                                                                             |
# |    Listing urządzeń taśmowych w AIXie i linuxie                             |
# |    Kody wyjścia ze skryptu                                                  |
# |    0 - wszytko ok                                                           |
# |    1 - nie znaleziono taśm                                                  |
# |                                                                             |
# |    Parametry wywołania:                                                     |
# |    -d - debug                                                               |
# |    -v - verbose                                                             |
# |    -c - comma deliminated                                                   |
# |    -t - tab deliminated                                                     |
# |_____________________________________________________________________________|
#Standardowa galanteria
use strict;
use warnings;
use Getopt::Std;
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib '../lib';

# Moduły do dołączenia w razie potrzeby. Powinny być zlokalizaowane w ../lib względem katalogu z któ©ego jest uruchamiany skrypt
use Gentools qw(dbg verbose chkos);
use LNXtools;
use AIXtools;
#use ISPtools;
# Zmienne globalne 
our $debug = 1;
our $verbose = 1;
our %opts;				# Hash dla getopts
our $my_name = $0;			# Żeby skrypt wiedział jak się nazywa
our $os;
our %rmt = ();				# Hash z taśmami
our $mode = "human";			# Tryb drukowania

sub help($)
{
	print "Użycie: $my_name [-v] [-d] [-h] [-p plik]\n";
	print " -v: gadatliwie\n";
	print " -d: debug, czyli jeszcze bardziej gadatliwie\n";
	print " -h: Wyświetla pomoc, czyli ten kominikat :-P\n";
	print " -p plik: Jakiś plik jako parametr\n";
	exit($_[0]);
}

sub setup()
# Ogólne parsowanie wiersza poleceń
# Parmaetry wywołania według opisu w z help();
{
	getopts("vdhfct:",\%opts) or help(2);
	
	if(defined $opts{"h"})
	{
		help(0);
	}
	
	if(defined $opts{"d"}) 
	{ 
		$debug = 1;
		# Tutaj inicjalizacja $debug we wszystkich włączonych modułach.
		$Gentools::debug = 1;
		$AIXtools::debug = 1;
		$LNXtools::debug = 1;
		dbg("MAIN::setup","Włączono tryb debug.\n");
	}
	
	if(defined $opts{"v"}) 
	{ 
		$verbose =1;
		# Tutaj inicjalizacja $verbose we wszystkich włączonych modułach.
		$Gentools::verbose = 1;
		dbg("MAIN::setup","Włączono tryb verbose.\n");
	}
	
	if(defined $opts{"f"}) 
	{ 
		verbose("$my_name: Podano opcję -f ".$opts{"f"}."\n");
		dbg("MAIN::setup","$my_name: Podano opcję -f ".$opts{"f"}."\n");
	}
	
	if(defined $opts{"c"})
	{
		dbg("MAIN::setup", "$my_name: wydruk w trybie comma.\n");
		$mode = "comma";
	}
}


# main
setup();
$os = chkos();
dbg("MAIN","OS = $os\n");

if ($os eq "Linux")
{
	LNXtools::init_module();
	%rmt = LNXtools::get_tape_drvs();
}
elsif ($os eq "AIX")
{
	%rmt = AIXtools::get_tape_drvs();
}

if ( %rmt == ())
{
	dbg("MAIN", "Nie znaleziono żadnych napędów taśmowych.\n");
	exit 1;
}
else
{
	if($mode eq "comma")
	{
		dbg("MAIN", "Wydruk w trybie comma.\n");
	}
	elsif ($mode eq "tab")
	{
		dbg("MAIN", "Wydruk w trybie tab.\n");
	}
	else
	{
		dbg("MAIN", "Wydruk w humen-friendly.\n");
	}
	
	exit 0;
}
