package Gentools;
use strict;
use warnings;
 
use Exporter qw(import);
our $debug = 0;                 						# do rozjechania przez Gentools::debug=1 w module wołającym
our $verbose=0;
our @EXPORT_OK = qw(chkos get_hostname show_drv print_hash $verbose $debug dbg verbose yes_no key_for_val_like);



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

sub chkos {
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
	(my %hash) = @_;
        foreach my $key (keys %hash)
        {
                print "$key,".$hash{"$key"}."\n";
                #~ dbg("print_hash", "Klucz: $key\n");
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
	}
} 

1;		# Bo tak kurwa ma być
