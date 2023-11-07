# Directory scanner 

This script provides the statisctics about directory subtree. It is useful for estimation file "tiers" for tunning IBM Storage Scale (GPFS) filesystems with IBM Storage Protect for Space Management (HSM).

## Usage:

```
marcinek@otter:~/prog/toys/bin$ python ./dirstats.py ~


    Grupa rozmiarowa:       Licz. plików:     % licz. plików:       Rozmiar grp.:      % rozm. całk.:
_________________________________________________________________________________________________________
           under128K:               12350              95.97%           0.124 MiB              20.55%
            under10M:                 496               3.85%           0.218 MiB              36.22%
               above:                  21               0.16%           0.261 MiB              43.23%
_________________________________________________________________________________________________________

   Pliki i symlinki:               12868
           Katalogi:                1740
         Brak dost.:                   0


Maksymana osiągnięta głębokość rekursji: 10.
Czas wykonania 0.1s.
```

## Customization

If you wat to define your own file tiers, edit the hash `FileTiers`. Follow the simple rules:

- put the tiers in ascending order.
- assign the predefined colors using constants defined in class `colors`.
- last, highest tier called `above` will be added automatically. 

Here is the example of adding additional 4 MiB tier:

```
FileTiers = {
    
    "under128K": {
        "limit": 131072,
        "color": colors.FAIL,
        "count": 0,
        "size" : 0
    },
    "under4M":	{
    	"limit": 4194304,			# 4 * 1024 * 1024 bytes 
    	"color": color.OKGREEN,		# Your favorite color
    	"count": 0,					# Just put 0 here. Holds the number if files scanned. Used to count calculate percentage 
    	"size" : 0 					# Put 0 here. Holds a sum of scanned file sizes. Used to calculate size percentage
    }
    "under10M": {
        "limit": 4194304,
        "color": colors.OKCYAN,
        "count": 0,
        "size" : 0
    }
}
```

## To do and ideas

- **put FileTiers** into external `json` file.
- **translate** - may be NLS enable?
- **use getopt** - add output options: 
	- fancy - like now
	- CSV
	- JSON