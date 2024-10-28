#!/usr/bin/env python3
import os
import sys
import argparse
import json


    
def handle_config(cfg_file):
    """
    Wczytuje konfigurację z pliku cfg_file.
    Jeśli go nie znajdzie, to go tworzy i wypełnia wartościami domyślnymi
    Zwraca obiekt config zawierający hasha z ustawieniami.
    """
    default_config = {
        "target_dir": os.path.expanduser('~') + "/workload_test",     # Domyślna lokalizacja to generowania plików
        "max_threads": os.cpu_count(),      # Ilość rownoległych procesów generowania workloadu rowna liczbie dostępnych wątków CPU
        "max_files": 100                    # maxymalna liczba plików do zrobienia

    }

    try:
        cfg_json = open(cfg_file, 'r')
    except OSError:
        # Nie ma pliku konfiguracyjnego, trzeba stworzyć o takiej nazwie i wrzucić defaulty
        print(f"Nie ma pliku { cfg_file }. Tworzenie nowego z domyślnymi wartośćiami.")
        with open( cfg_file, 'w') as cfg_json:
            json.dump(default_config, cfg_json)
            print(f"Nowa konfiguracja zapisana do { cfg_file }")

    with open(cfg_file, "r") as cfg_json:
        config = json.load(cfg_json)
        print(f"Konfiguracja wczytana z { cfg_file }")
    

    print(config)
    return config


# Main
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Generowanie testowych plików do wypełnienia filesystemów.")
    parser.add_argument('-c', '--config', help='Ścieżka do pliku konfiguracyjnego', default="wrkgen.json")

    # parser.add_argument('dir', nargs='?', default='.', help="Katalog do przeliczenia. (Domyslnie: bieżący)")

    # conv_grp = parser.add_mutually_exclusive_group()
    # conv_grp.add_argument('-u', '--upper', help="Konwertuj wszystkie rozszerzenia na WIELKIE litery", action="store_true")
    # conv_grp.add_argument('-l', '--lower', help="Konwertuj wszystkie rozszerzenia na małe litery", action="store_true")

    args = parser.parse_args()

    handle_config(args.config)
