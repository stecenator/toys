#!/bin/perl -w
#  _____________________________________________________________________________
# |                                                                             |
# |    Szablon mojego standadowego programu w Perlu                             |
# |_____________________________________________________________________________|
#Standardowa galanteria
use strict;
use warnings;
use Getopt::Std;
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib '../lib';

# Moduły do dołączenia w razie potrzeby. Powinny być zlokalizaowane w ../lib względem katalogu z któ©ego jest uruchamiany skrypt
use Gentools qw(dbg verb key_for_val_like chk_usr_proc);
use LNXtools;
#use AIXtools;
#use ISPtools;
# Zmienne globalne 
my $debug = 1;
my $verbose = 1;
our %opts;				# Hash dla getopts
our $my_name = $0;			# Żeby skrypt wiedział jak się nazywa

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
	getopts("vdhf:",\%opts) or help(2);
	
	if(defined $opts{"h"})
	{
		help(0);
	}
	
	if(defined $opts{"d"}) 
	{ 
		$debug = 1;
		# Tutaj inicjalizacja $debug we wszystkich włączonych modułach.
		$Gentools::debug = 1;
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
		verb("$my_name: Podano opcję -f ".$opts{"f"}."\n");
		dbg("MAIN::setup","$my_name: Podano opcję -f ".$opts{"f"}."\n");
	}
	
}

# main
setup();
my $pid = chk_usr_proc("marcinek", "geany");
print "Geany ma pid $pid\n";

