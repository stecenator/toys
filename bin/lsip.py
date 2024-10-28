#!/usr/bin/env python3
# Bo wkurza mnie greopowanie ip addr i innych ifconfigów
import sys
import argparse
import psutil

parser = argparse.ArgumentParser(description="Wyświetlanie nazw interfejsów i ich adresów.")
proto = parser.add_mutually_exclusive_group()

proto.add_argument('-6', '--ipv6', help='Wyświetl adresy IP v6', action='store_true')
proto.add_argument('-4', '--ipv4', help='Wyświetl adresy IP v4', action='store_true')
proto.add_argument('-m', '--mac', help='Wyświetl MAC', action='store_true')

args = parser.parse_args()
print(f'Argumenty: ipv4: {args.ipv4}, ipv6: {args.ipv6}, MAC: {args.mac}')
addrs = psutil.net_if_addrs()
for interface in addrs.keys():
    for if_attrs in addrs[interface]:
        if args.ipv6 == True and if_attrs.family == 10:      # wyświetlam ipv6
            print(f'{ interface.ljust(15) } { if_attrs.address.rjust(40) }')
        elif args.mac == True and if_attrs[0] == 17:     # Wyświetlam MAC
            print(f'{ interface.ljust(15) } { if_attrs.address.rjust(40) }')
        elif args.ipv4 == True and if_attrs[0] == 2 or len(sys.argv) == 1 and if_attrs[0] == 2:     # Wyświetlam ipv4 albo na prośbę albo z defaulta
            print(f'{ interface.ljust(15) } { if_attrs.address.rjust(40) }') 