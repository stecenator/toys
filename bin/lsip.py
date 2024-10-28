#!/usr/bin/env python3
# import argparse
import psutil

addrs = psutil.net_if_addrs()
for interface in addrs.keys():
    for if_attrs in addrs[interface]:
        if if_attrs[0] == 2 or if_attrs[0] == 10:
            print(f'{ interface }: { if_attrs[1] }')