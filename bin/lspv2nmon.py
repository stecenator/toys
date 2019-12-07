#!/usr/bin/env python3
import sys
import os
import re

if not os.path.isfile(sys.argv[1]):
	print(f"{sys.argv[1]}: Nie ma takiego pliku.")
	sys.exit(1)
	
dg = {}		# Słownik "vg" => ["hdiskX", "hdiskY", ...]

with open(sys.argv[1],'r') as lspv:
	for line in lspv:
		l = line.split()	# l[0] = hdisk, l[2] = vg
		try:
			dg[l[2]].append(l[0])
		except KeyError:
			dg[l[2]] = [ l[0] ]	# jak nie ma listy pod kluczem to nie można appendować.
		
for k in dg:
	dg_str = k
	for v in dg[k]:
		dg_str = dg_str + " " + v
	
	print(dg_str)		
