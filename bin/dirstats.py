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
    "under4K": {
        "limit": 4096,
        "color": colors.FAIL,
        "count": 0
    },
    "under128K": {
        "limit": 131072,
        "color": colors.FAIL,
        "count": 0
    },
    "under4M": {
        "limit": 4194304,
        "color": colors.OKCYAN,
        "count": 0
    },
    "under128M": {
        "limit": 134217728,
        "color": colors.OKGREEN,
        "count": 0
    }
}

FilesCount = 0  # Licznik znalezionych plików  i linków do liczenia procentów
DirsCount = 0   # Licznik znalezionych katalogów

def print_dir_stats(tiers=FileTiers, fCount = FilesCount):
    """
    Wypisuje wartość hasha tiers, domyślnie FileTiers.
    Pomysł - dopisać padding, żeby ładnie drukował.
    """
    for tier in tiers:
        cnt = tiers[tier]["count"]
        pct = round(cnt / fCount * 100, 2)     # Wyliczanie procentów
        col = tiers[tier]["color"]
        print(f'{col}{tier.rjust(15, " ")}:\t{ cnt }\t{ pct }%{ colors.ENDC }')

def upd_tier(size,tiers=FileTiers):
    """
    Aktualizuje wskazaną kategorię licznika w zlaeżności od rozmiaru
    Korzysta z faktu, że hashe przekazywane jako argument funkcji są przez referencję, a nie przez wartość. 
    """

    for tier in tiers:
        if size <= tiers[tier]["limit"]:
            tiers[tier]["count"] += 1
            return

    # jeśli sterowanie tu doszło, to size jest większy niż wszystkie limity.
    # Sprawdzić czy istnieje klucz "above" i w razie potrzeby go dodaj.

    if tiers.get("above"):
        tiers["above"]["count"] += 1
        # print(f'Trafiłem w dużego: { size }.')
    else:
        big_file = {
            "limit": -1,
            "color": colors.OKBLUE,
            "count": 0
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
    myFailedDirs = 0
    
    with os.scandir(path) as dir_entries:
        for entry in dir_entries:
            try: 
                stat_info = entry.stat(follow_symlinks = False)                 # Tu pewnie trzeba łapać wyjatek, jak nie ma uprawnień.
                if entry.is_file() or entry.is_symlink():                       # Nie łazimy po symlinkach
                    upd_tier(stat_info.st_size,FileTiers)
                    myFileCount += 1
                elif entry.is_dir():                                                            # no to rekursja. Na wszelki wypadek badam głębokość
                    returned_depth, childFileCount, childDirCount, failedSubDirs = dir_file_stats(depth+1, entry.path)        # Path może być dość długie. Być możę trba będzie przejść na cwd i name.
                    myFileCount += childFileCount
                    myDirCount += childDirCount
                    measured_max_depth = max(measured_max_depth, returned_depth)
                    myFailedDirs += failedSubDirs
            except OSError:
                myFailedDirs += 1

    return measured_max_depth, myFileCount, myDirCount, myFailedDirs

# Main
start = timer()
# może dostałem parametr?
if len(sys.argv) == 2:
    directory = sys.argv[1]
else:
    directory = "."
if os.path.isdir(directory):       # parametr to katalog do zbadania
    depth, FilesCount, DirsCount, FailedDirs = dir_file_stats(0, directory)
    print_dir_stats(FileTiers, FilesCount)
    print(f'Pliki i symlinki:'.rjust(20) + f'\t{ FilesCount }.')
    print(f'Katalogi:'.rjust(20) + f'\t{ DirsCount }.')
    print(f'Brak dost.:'.rjust(20) + f'\t{ FailedDirs }.')
    print(f'Maksymana osiągnięta głębokość rekursji: { depth }.')
    end = timer()
    print(f'Czas wykonania { round(end - start, 2) }s.')
else:
    print(f'Prametr { directory } nie wygląda na katalog ¯\_(ツ)_/¯')
    exit(1)