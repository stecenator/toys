package Gentools;
use strict;
use warnings;
use Term::ANSIColor qw(:constants);						# Żeby debug był kolorowy
use Exporter qw(import);
our $debug = 0;                 						# do rozjechania przez Gentools::debug=1 w module wołającym
our $verbose=0;
our @EXPORT_OK = qw(chkos get_hostname show_drv print_hash $verbose $debug dbg verb yes_no key_for_val_like error print_hash_human check_proc chk_usr_proc);

sub error($$$)
# Komunikat o błędzie, na STDERR. Jeśli ma niezerowy kod wyjścia 
# Argumenty
# $_[0] - Kto zgłasza" - moduł::procedura
# $_[1] - Treść błędu" 
# $_[2] - Kod wyjścia - jesli nie 0 to zakończy program z podanym kodem.
{
	print STDERR RED, "$_[0]:"." $_[1]", RESET;
	
	exit $_[2] if ( $_[2] != 0 );
}

sub dbg($$)
# Komunikat do wyświetlenia, jesli jest włączony tryb debug.
{
	print YELLOW, "$_[0]:\t$_[1]", RESET if $debug;
}

sub verb($)
# Komunikat do wyświetlenia, jesli jest włączony tryb debug.
{
	print "$_[0]" if $verbose;
}

sub yes_no($$)
# Zadaje pytanie typu tak/nie podane jako pierwszy argument z defaultem podanym w drugim
# Zwraca:
#    1 - na tak
#    0 - na nie.
{
	my $answer;
	my $ret;
	print "$_[0]\n";
	while(1)
	{
		print "Tak/Nie [$_[1]]: ";
		$answer = <>;
		$answer = "$_[1]" if $answer eq "\n";
		chomp($answer);
		dbg("Gentools::yes_no", "Odpowiedź: $answer.\n");
		if($answer =~ /(^[TtYy])/)					# Jestem na tak
		{
			$ret = 1;
			last;
		}
		elsif($answer =~ /(^[Nn])/)					# Jestem na nie
		{
			$ret = 0;
			last;
		}
	}
	return $ret;
}

sub show_drv(%)                 # debugowa funkcja wyświetlająca hasha pojedynczego napędu
{
        (my %drv) = @_;
        foreach my $key (keys %drv)
        {
                print "show_drv:\t $key\t=\t ".$drv{"$key"}."\n" if $debug;
        }
}

sub chkos() {
	(my $os, my $rest) = split(" ", qx/uname -a/);
        return "$os";
}

sub get_hostname 
{
  my $hostname = qx/hostname -s/;
  chomp($hostname);
	return $hostname;
}

sub print_array_hash(%)
{
	(my %disks) = @_;
        foreach my $key (keys %disks)
        {
                print "$key,",join(",",(@{$disks{"$key"}}))."\n";
                #~ dbg("print_hash", "Klucz: $key\n");
        }
}

sub print_hash(%)
{
	error("Gentools:print_hash", "nieparzysta ilość lementów w tablicy argumentów. To prawdopodobnie nie jest hash!\n", 100) if (scalar @_ % 2) != 0; 
	(my %hash) = @_;	
        foreach my $key (keys %hash)
        {
		#~ dbg("Gentools::print_hash", "Klucz: $key\n");
                print "$key = ".$hash{"$key"}."\n";
        }
}

sub print_hash_csv(\%$;$);					# prototyp, bo bez tego perl gubi się przy rekurencji
sub print_hash_csv(\%$;$)
# Wypisuje hash z @_  w formie stanzowej. W razie potrzeby woła się rekurencyjnie
# Argumenty:
# \%hash_ref - refrencja do wypisywanego hasha
# $delim - deliminator do CSV - uwaga, listy w polach są na sztywno deliminowane ";"
# $level - opcjonalny, oznaczający poziom zagnieżdzenie rekurencji 
{	
	my $hash_ref = shift;
	my $level = shift;					# liczba \t przed wypisanymi wartościami
	my $line;						# do sklejania array
	
	if( !$level )
	{
		dbg("Gentools::print_hash_csv", "Nie podano poziomu zagłębienia rekurencji. Domyslne: 0.\n");
		$level = 0;
	}
	
        foreach my $key (keys %{$hash_ref})
        {
		if ( ref ${$hash_ref}{"$key"} eq "HASH" )	# wartością dla klucza jest kolejny hash
		{
			print "\t"x$level."$key:\n";
			print_hash_human( %{${$hash_ref}{$key}}, $level + 1 );
		}
		elsif ( ref ${$hash_ref}{$key} eq "ARRAY" )	# wartością dla klucza jest tablica
		{
			$line = join ', ', @{${$hash_ref}{$key}};
			print "\t"x$level."$key:\t$line\n";
		}
		else 						# Pod $key siedzi zwykły skalar albo jest pusty
		{
			print "\t"x$level."$key:\t";
			print "${$hash_ref}{$key}" if ${$hash_ref}{$key}; # Żeby ładnie reagował na klucz bez wartości
			print "\n";
		}
	}
}

sub print_hash_human(\%;$);					# prototyp, bo bez tego perl gubi się przy rekurencji
sub print_hash_human(\%;$)
# Wypisuje hash z @_  w formie stanzowej. W razie potrzeby woła się rekurencyjnie
# Argumenty:
# \%hash_ref - refrencja do wypisywanego hasha
# $level - opcjonalny, oznaczający poziom zagnieżdzenie rekurencji 
{	
	my $hash_ref = shift;
	my $level = shift;					# liczba \t przed wypisanymi wartościami
	my $line;						# do sklejania array
	
	if( !$level )
	{
		dbg("Gentools::print_hash_human", "Nie podano poziomu zagłębienia rekurencji. Domyslne: 0.\n");
		$level = 0;
	}
	
        foreach my $key (keys %{$hash_ref})
        {
		if ( ref ${$hash_ref}{"$key"} eq "HASH" )	# wartością dla klucza jest kolejny hash
		{
			print "\t"x$level."$key:\n";
			print_hash_human( %{${$hash_ref}{$key}}, $level + 1 );
		}
		elsif ( ref ${$hash_ref}{$key} eq "ARRAY" )	# wartością dla klucza jest tablica
		{
			$line = join ', ', @{${$hash_ref}{$key}};
			print "\t"x$level."$key:\t$line\n";
		}
		else 						# Pod $key siedzi zwykły skalar albo jest pusty
		{
			print "\t"x$level."$key:\t";
			print "${$hash_ref}{$key}" if ${$hash_ref}{$key}; # Żeby ładnie reagował na klucz bez wartości
			print "\n";
		}
	}
}

sub key_for_val_like($%)
# Zwraca tablicę kluczy dla wartośći pasujących do wzorca podanego na $_[0]
{
	my $pat = shift;
	my %hash = @_;
	foreach my $k (keys %hash)
	{
		print $k, $hash{"$k"}, "\n";
		if ($hash{"$k"} =~ $pat)
		{
			dbg("Gentools::key_for_val_like", "Znaleziono dopasowanie wzorca $pat do warości $hash{$k} dla klucza $k.\n");
			print "$k\n";
		}
	}
} 

sub init_module()
# Ogólny stuff inicjalizacyjny.
{
	dbg("Gentools::init_module", "inicjalizacja zmiennych modułu.\n");
	return 0;
}

sub check_proc($)
# check_proc($nazwa) - sprawdza czy proces o danej nazwie jest uruchomiony
{
        if( `ps -C $_[0]` )
        {
                return 1;
        }
        else
        {
                return 0;
        }
}

sub chk_usr_proc($$)
# chk_usr_proc($user, $komenda) - sprawdza, czy $user ma proces $komenda
{
	my @line = qx/ps -C $_[1] -f/;
	my $rc = $? >> 8;
	dbg("Gentools::chk_usr_proc", "RC z ps = $rc, output: $line[1]\n");
	
	return 0 if ($rc != 0);			# nie ma procesu o tej nazwie
	
	(my $user, my $pid, undef) = split(" ", $line[1]);
	
        if( "$user" eq $_[0] )			# User jest właścicielem procesu
        {
                return $pid;
        }
        else
        {
                return 0;
        }
}

1;		# Bo tak kurwa ma być
