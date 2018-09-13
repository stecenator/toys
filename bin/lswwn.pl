#!/bin/perl -w
#  _____________________________________________________________________________
# |                                                                             |
# |    SListing WWNów na różne sposoby                                          |
# |_____________________________________________________________________________|
#Standardowa galanteria
use strict;
use warnings;
use Getopt::Std;
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib '../lib';

# Moduły do dołączenia w razie potrzeby. Powinny być zlokalizaowane w ../lib względem katalogu z któ©ego jest uruchamiany skrypt
use Gentools qw(dbg verb get_hostname chkos);
use LNXtools;
#use AIXtools;
#use ISPtools;
# Zmienne globalne 
our $debug = 0;
our $verbose = 0;
our %opts;				# Hash dla getopts
our $my_name = $0;			# Żeby skrypt wiedział jak się nazywa
our $mode = "default";			# tryb wydruku: default, alicreate, nodefind
our $OS;				# Wykryty OS
our %fcs = ();				# Hash na adaptery HBA
our $hostname;				# hostname do aliasów

sub help($)
{
	print "Użycie: $my_name [-v] [-d] [-h] [-a] [-n]\n";
	print " -v: gadatliwie\n";
	print " -d: debug, czyli jeszcze bardziej gadatliwie\n";
	print " -h: Wyświetla pomoc, czyli ten kominikat :-P\n";
	print " -a: Wydruk alicreate.\n";
	print " -a: Wydruk nodefind.\n";
	exit($_[0]);
}

sub setup()
# Ogólne parsowanie wiersza poleceń
# Parmaetry wywołania według opisu w z help();
{
	getopts("vdhan",\%opts) or help(2);
	
	if(defined $opts{"h"})
	{
		help(0);
	}
	
	if(defined $opts{"d"}) 
	{ 
		$debug = 1;
		# Tutaj inicjalizacja $debug we wszystkich włączonych modułach.
		$Gentools::debug = 1;
		dbg("MAIN::setup","Włączono tryb debug.\n");
	}
	
	if(defined $opts{"v"}) 
	{ 
		$verbose =1;
		# Tutaj inicjalizacja $verbose we wszystkich włączonych modułach.
		$Gentools::verbose = 1;
		dbg("MAIN::setup","Włączono tryb verbose.\n");
	}
	
	if(defined $opts{"a"}) 
	{ 
		dbg("MAIN::setup","$my_name: wybrano tryb aliasów.\n");
		$mode = "alicreate";
	}
	
	if(defined $opts{"n"}) 
	{ 
		dbg("MAIN::setup","$my_name: wybrano tryb nodefind.\n");
		$mode = "nodefind";
	}
	
	$hostname = get_hostname();
	$OS = chkos();
}

# main

setup();

if($OS eq "Linux")			# Trick z importem funkcji, ciekawe czy wyjdzie.
{
	%fcs = LNXtools::get_fc_adapters();
}
else
{
	%fcs = AIXtools::get_fc_adapters();
}

foreach my $fc (keys(%fcs)) 
{
	if($mode eq "alicreate")
	{
		print "alicreate $hostname"."_$fc,$fcs{$fc}\n";
	}
	elsif ($mode eq "nodefind" )
	{
		print "$fc\t nodefind $fcs{$fc}\n";
	}
	else
	{
		print "$fc,$fcs{$fc}\n";
	}
	
}
