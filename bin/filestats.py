#!/usr/bin/env python3
import os
import sys
import argparse
import re
from timeit import default_timer as timer       # Żeby podać czas trwania skryptu

# Drukowanie w kolorze
class colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

# Rożne sprawy globalne
CaseCheck = True # Czy odróżniać *.JPG od *.jpg
conv = 0        # nie konwertujemy rozszerzeń
FilesCount = 0  # Licznik znalezionych plików  i linków do liczenia procentów
DirsCount = 0   # Licznik znalezionych katalogów
TotalBytes = 0  # Całkowita suma wielkości znalezionych plików
FileStats = {}  # Statystyki plików. Kluczem jest rozszeżenie


def upd_file_stats(file_name, file_size, pattern, conversion = conv, stats = FileStats):
    """
    Aktualizuje statystyki w hashu fileStats. Parametry:
    file_name:  nazwa pliku do "skatalogowania"
    file_size:  rozmiar pliku do statystyk
    pattern:    skompilowany przez re.compile pattern do rozpoznawania rozszerzeń. Może być case insensitive
    """
    f_detail = pattern.findall(file_name)       # To zwaraca listę list
    if len(f_detail) == 0:                      # Plik bez rozszerzenia nie pasuje do wzroca, więć lista f_detail jest pusta
        f_name = file_name
        f_ext = "__NO_EXT__"                    # może nie będzie plików z ttakim rozszerzeniem :-D
    else:
        f_name = f_detail[0][0]                 # NAzwa pliku bez rozszerzenia
        f_ext = f_detail[0][1]                  # Rozszerzenie 

    
    if conversion == 1:                         # Konwersja przed włożęniem do hasha
        extension = f_ext.upper()
    elif conversion == 2:
        extension = f_ext.lower()
    else:
        extension = f_ext

    ext_stat = stats.get(extension, [0,0])      # Jak nie ma to zwracamy [0, 0], a jak jest to własciwą wartość
    ext_stat[0] += 1                             # licznik wystąpień +1
    ext_stat[1] += file_size                    # suma rozmiarów dla danego rozszerzenia
    stats[extension] = ext_stat                 # aktualizacja hasha

def dir_file_stats(depth, path, pattern):
    """
    Zwraca statystyki zliczonych plików według rozszerzeń.
    depth jest parametrem kontrolnym, do badania głębokości rekursji
    """

    measured_max_depth = depth
    # print(f'Nurkuję na { depth }.')
    myFileCount = 0         # Liczba znalezionych plików
    myDirCount = 1          # Liczba przeskanowanych katalogów (w pierwszym jestem)
    myFailedDirs = 0        # Liczba niedostępnych katalogów
    mySize = 0              # Suma zeskanowanych bajtów
    
    with os.scandir(path) as dir_entries:
        for entry in dir_entries:
            try: 
                stat_info = entry.stat(follow_symlinks = False)                 # Tu pewnie trzeba łapać wyjatek, jak nie ma uprawnień.
                if entry.is_file() or entry.is_symlink():                       # Nie łazimy po symlinkach
                    upd_file_stats(entry.name, stat_info.st_size, pattern, conv)
                    myFileCount += 1
                    mySize += stat_info.st_size
                elif entry.is_dir():                                                            # no to rekursja. Na wszelki wypadek badam głębokość
                    returned_depth, childFileCount, childDirCount, failedSubDirs, childSize = dir_file_stats(depth+1, entry.path, pattern)        # Path może być dość długie. Być możę trba będzie przejść na cwd i name.
                    myFileCount += childFileCount
                    myDirCount += childDirCount
                    measured_max_depth = max(measured_max_depth, returned_depth)
                    myFailedDirs += failedSubDirs
                    mySize += childSize
            except OSError:
                myFailedDirs += 1

    return measured_max_depth, myFileCount, myDirCount, myFailedDirs, mySize

def bytes2human(size):
    """
    Zwraca rozmiar podany w bajtach jako string human readable".
    """
    if size > 1099511627776:        # Terabajty
        my_size = round(size / 1099511627776, 3)
        ret = str(my_size) + ' TiB'
    elif size > 1073741824:         # Gigabajty
        my_size = round(size / 1073741824, 3)
        ret = str(my_size) + ' GiB'
    elif size > 1048576:           # Megabajty
        my_size = round(size / 1073741824, 3)
        ret = str(my_size) + ' MiB'
    elif size > 1024:             # Kilobajty
        my_size = round(size / 1024, 3)
        ret = str(my_size) + ' KiB'
    else:                           # bajty
        ret = str(size) + ' B'

    return ret

def print_file_stats(stats):
    """
    Drukuje ładnie podsumowanie zliczonych rozszerzeń plików
    """
    cols, rows = os.get_terminal_size()
    line = "_" * cols
    # Padding
    ext_pad = 20
    cnt_pad = 20
    size_pad = 30

    for key in stats:
        human_size = bytes2human(stats[key][1])
        ext_count = str(stats[key][0])
        print(f'{ key.rjust(ext_pad) }:{ ext_count.rjust(cnt_pad) }{ human_size.rjust(size_pad) }')

def print_file_stats_csv(stats):
    """
    Drukuje ładnie podsumowanie zliczonych rozszerzeń plików
    """
    cols, rows = os.get_terminal_size()
    line = "_" * cols
    # Padding
    ext_pad = 20
    cnt_pad = 20
    size_pad = 30

    for key in stats:
        human_size = bytes2human(stats[key][1])
        ext_count = str(stats[key][0])
        print(f'{ key },{ ext_count },{ human_size }')

# Main
start = timer()
parser = argparse.ArgumentParser(description="Zliczanie plików po rozszerzeniach.")
parser.add_argument('-i', '--ignorecase', help='Ignoruj wielkość liter w nazwie pliku. (Domyślnie: nie)', action='store_true')
parser.add_argument('dir', nargs='?', default='.', help="Katalog do przeliczenia. (Domyslnie: bieżący)")
parser_grp = parser.add_mutually_exclusive_group()
parser_grp.add_argument('-u', '--upper', help="Konwertuj wszystkie rozszerzenia na WIELKIE litery", action="store_true")
parser_grp.add_argument('-l', '--lower', help="Konwertuj wszystkie rozszerzenia na małe litery", action="store_true")
parser.add_argument('-c', '--comma', help='Output w formacie CSV', action='store_true')
args = parser.parse_args()

directory = args.dir

# Kompilowanie patternu tutaj, bo potem będzie szybciej. 
if args.ignorecase:
    ext_pattern = re.compile(r'(.*)\.(\w+)$', re.IGNORECASE)
else:
    ext_pattern = re.compile(r'(.*)\.(\w+)$')

# Konwersja UPPER, lower, brak
if args.upper:
    conv = 1        # integery porównują się szybciej niż stringi
elif args.lower:
    conv = 2
else:
    conv = 0

print(f'Konwersja: { conv }')

if os.path.isdir(directory):       # parametr to katalog do zbadania
    depth, FilesCount, DirsCount, FailedDirs, TotalBytes = dir_file_stats(0, directory, ext_pattern)
    print("\n")
    if args.comma:
        print_file_stats_csv(FileStats)
    else:
        print_file_stats(FileStats)
    print("\n")
    print(f'Pliki i symlinki:'.rjust(20) + f'{ str(FilesCount).rjust(20, " ") }')
    print(f'Katalogi:'.rjust(20) + f'{ str(DirsCount).rjust(20, " ") }')
    print(f'Brak dost.:'.rjust(20) + f'{ str(FailedDirs).rjust(20, " ") }')
    print(f'\n\nMaksymana osiągnięta głębokość rekursji: { depth }.')
    end = timer()
    print(f'Czas wykonania { round(end - start, 2) }s.')
else:
    print(f'Prametr { directory } nie wygląda na katalog ¯\\_(ツ)_/¯')
    exit(1)
