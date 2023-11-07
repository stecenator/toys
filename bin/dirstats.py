import os
import sys
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

# Grupy liczników. 
# UWAGA: Muszą być posortowane rosnąco, a ostani limit dołoży się sam i będzie się nazywać "above"

FileTiers = {
    
    "under128K": {
        "limit": 131072,
        "color": colors.FAIL,
        "count": 0,
        "size" : 0
    },
    "under10M": {
        "limit": 4194304,
        "color": colors.OKCYAN,
        "count": 0,
        "size" : 0
    }
}

FilesCount = 0  # Licznik znalezionych plików  i linków do liczenia procentów
DirsCount = 0   # Licznik znalezionych katalogów
TotalBytes = 0  # Całkowita suma wielkości znalezionych plików

def print_dir_stats(totalSize, tiers=FileTiers, fCount = FilesCount):
    """
    Wypisuje wartość hasha tiers, domyślnie FileTiers.
    Pomysł - dopisać padding, żeby ładnie drukował.
    """
    cols, rows = os.get_terminal_size()
    line = "_" * cols

    # Padding. Kiedyś będę to wyliczać z liczby kolumn terminala.
    tier_pad = 20
    cnt_pad = 20
    pct_pad = 20
    size_pad = 20
    header = "Grupa rozmiarowa:".rjust(tier_pad+1) + "Licz. plików:".rjust(cnt_pad) + "% licz. plików:".rjust(pct_pad) + "Rozmiar grp.:".rjust(size_pad) + "% rozm. całk.:".rjust(pct_pad)
    print(header)
    print(line)
    for tier in tiers:
        size = tiers[tier]["size"]
        size_str = bytes2human(size)
        cnt = tiers[tier]["count"]
        cnt_str = str(cnt)
        pct_cnt = str(round(cnt / fCount * 100, 2)) + "%"       # Wyliczanie procent z liczby wszystkich plików
        pct_size = str(round( size / totalSize * 100, 2)) + "%"   # Wyliczanie procent z wiekości całego filesystemu
        col = tiers[tier]["color"]
        print(f'{ col }{ tier.rjust(tier_pad) }:{ cnt_str.rjust(cnt_pad) }{ pct_cnt.rjust(pct_pad) }{ size_str.rjust(size_pad) }{ pct_size.rjust(pct_pad) }{ colors.ENDC }')
        # print(f'{col}{tier.rjust(20)}:\t{ cnt_str.rjust(11, " ") }\t{ pct.rjust(5, " ") }%\t{ size.rjust(15, " ") }{ colors.ENDC }')

    print(line)

def upd_tier(size,tiers=FileTiers):
    """
    Aktualizuje wskazaną kategorię licznika w zlaeżności od rozmiaru
    Korzysta z faktu, że hashe przekazywane jako argument funkcji są przez referencję, a nie przez wartość. 
    """

    for tier in tiers:
        if size <= tiers[tier]["limit"]:
            tiers[tier]["count"] += 1
            tiers[tier]["size"] += size
            return

    # jeśli sterowanie tu doszło, to size jest większy niż wszystkie limity.
    # Sprawdzić czy istnieje klucz "above" i w razie potrzeby go dodaj.

    if tiers.get("above"):
        tiers["above"]["count"] += 1
        tiers["above"]["size"] += size
        # print(f'Trafiłem w dużego: { size }.')
    else:
        big_file = {
            "limit": -1,
            "color": colors.OKBLUE,
            "count": 0,
            "size": size
        }
        tiers["above"]= big_file

def dir_file_stats(depth, path="."):
    """
    Zwraca statystyki zliczonych plików według grup rozmiarów zdefiniowanych w zmiennej FileTiers.
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
                    upd_tier(stat_info.st_size,FileTiers)
                    myFileCount += 1
                    mySize += stat_info.st_size
                elif entry.is_dir():                                                            # no to rekursja. Na wszelki wypadek badam głębokość
                    returned_depth, childFileCount, childDirCount, failedSubDirs, childSize = dir_file_stats(depth+1, entry.path)        # Path może być dość długie. Być możę trba będzie przejść na cwd i name.
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


# Main
start = timer()
# może dostałem parametr?
if len(sys.argv) == 2:
    directory = sys.argv[1]
else:
    directory = "."
if os.path.isdir(directory):       # parametr to katalog do zbadania
    depth, FilesCount, DirsCount, FailedDirs, TotalBytes = dir_file_stats(0, directory)
    print("\n")
    print_dir_stats(TotalBytes, FileTiers, FilesCount)
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