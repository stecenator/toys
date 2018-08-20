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
use lib '/home/marcinek/prog/toys/lib';
#use Gentools;
#use LNXtools;
#use AIXtools;
#use ISPtools;
# Zmienne globalne 
our $debug = 1;
our $verbose = 1;
# main
