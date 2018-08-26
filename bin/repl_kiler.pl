#!/bin/perl -w
#  _____________________________________________________________________________
# |                                                                             |
# |    Skrypt do ubijania procesów replikacji dla TV Puls                       |
# |_____________________________________________________________________________|
#Standardowa galanteria
use strict;
use warnings;
use Getopt::Std;
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib "$ENV{HOME}/prog/toys/lib/";
use Gentools qw(dbg verb print_hash key_for_val_like);		# Żeby mieć funkcie verbose i dbg
#use LNXtools;
#use AIXtools;
use ISPtools;				# Funkcje do dłubania w TSMie
# Zmienne globalne 
our %opts;				# Hash dla getopts
our $my_name = $0;			# Żeby skrypt wiedział jak się nazywa
my $debug = 1;
my $verbose = 1;
our $admin = "admin";
our $pass = "admin";
our $server = "";

sub help($)
{
	print "Użycie: $my_name [-v] [-h] [-d] [-s serwer] [-u użyszkodnik] [-p hasło]\n";
	print " -s serwer: Definicja serwera z dsm.sys. Domyślnie... domyślna z dsm.opt.\n";
	print " -u użytkownik: operator z prawem ubicia procesu. Domyślnie admin.\n";
	print " -p hasło : Hasło operatora. Domyślnie admin.\n";
	print " -v: gadatliwie\n";
	print " -d: debug, czyli jeszcze bardziej gadatliwie\n";
	print " -h: Wyświetla pomoc, czyli ten kominikat :-P\n";
	exit($_[0]);
}

sub setup()
# Ogólne parsowanie wiersza poleceń
# Parmaetry wywołania według opisu w z help();
{
	getopts("vdhu:p:s:",\%opts) or help(2);
	
	if(defined $opts{"h"})
	{
		help(0);
	}
	
	if(defined $opts{"d"}) 
	{ 
		$debug = 1;
		$Gentools::debug = 1;
		dbg("MAIN::setup","Włączono tryb debug.\n");
	}
	
	if(defined $opts{"v"}) 
	{ 
		$verbose =1;
		dbg("MAIN::setup","Włączono tryb verbose.\n");
	}
	
	if(defined $opts{"u"}) 
	{ 
		$admin = $opts{"u"};
		dbg("MAIN::setup","Użytkownik: $admin.\n");
	}
	
	if(defined $opts{"p"}) 
	{ 
		$pass = $opts{"p"};
		dbg("MAIN::setup","Hasło: $pass.\n");
	}
	
	if(defined $opts{"s"}) 
	{ 
		$server = $opts{"s"};
		dbg("MAIN::setup","Serwer ISP: $server.\n");
	}
	
	init_ISPtools("$server", "$admin", "$pass",  $debug, $verbose);
}
# main

my %proc_list=();

setup();

%proc_list = get_process_list();
if(%proc_list) 					# Są jakieś procesy
{
	dbg("MAIN::main", "Znaleziono procesy...\n");
	print_hash(%proc_list);
	key_for_val_like("Dupa", %proc_list);
}
else
{
	print STDERR "Nie było żanych procesów.\n";
	exit 11;
}
