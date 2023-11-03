# toys
Useful perl and shell  toys
My perl toys reference

- lsrmt.pl - shows AIX and Linux (IBM Lintape) tapedrives in vrious ways. Useful with IBM Spectrum Protect and persistent names
- repl_kiler.pl - a script used to cancel replicate node TSM processess (as per for now, replicte node command has no duration attribute)
- sanvalidate -Simple Brocade SAN zonning validation tool. It conects to SAN switch gets the running config and reports some usefull information.
- lspv2nmon.py - converts AIX lspv output into `namon -g group-file` compatible file. Usefull with large, multi-disk systems. 
- dirstats.py - recursively scans given directory and prints percentage of predefined FileTiers. Used for sizing HSM settings in GPFS.


Generic modules for handling some aspects of OS and TSM:

- Gentools.pm
- AIXtools.pm
- LNXtools.pm
- ISPtools.pm

## Bash scripts

- bashr_sshagent.sh - template form `.bashrc` file that handles auto starting or attaching already running ssh_agent.

# sanvalidate
_This is only a placeholder for future scrpit!_

Simple Brocade SAN zonning validation tool. It conects to SAN switch gets the running config and reports:

* list of complete zones
* list of incomplete zones (ie missing member)
* list of empty zones (all members missing)
* unused aliases
* WWNPS with no alias (foreign addresses)


## Usage
```bash
# sanvalidate [-u USER] [-p PASSWD] switch_ip 
```

## Requirements
This script requires following packages and libraries:

* paramiko - python SSH client library 

# lspv2nmon
AIX `lspv` converter. Creates nmon disk group file based on lspv output. 
## Usage
```bash
# lspv > file.txt
# lspv2nmon file.txt -p prefix
old_rootvg hdisk0
caavg_private hdisk1
None hdisk2 hdisk115 hdisk116 hdisk117 hdisk118 hdisk119 hdisk120 hdisk121 hdisk122
nkcust1artrvg hdisk3 hdisk4 hdisk5 hdisk6 hdisk31 hdisk32 hdisk33 hdisk34
nkcust1fravg hdisk7 hdisk8 hdisk9 hdisk10 hdisk35 hdisk36 hdisk37 hdisk38
nkcust1redo1vg hdisk11 hdisk12 hdisk13 hdisk14 hdisk39 hdisk40 hdisk41 hdisk42
nkcust1redo2vg hdisk15 hdisk16 hdisk17 hdisk18 hdisk43 hdisk44 hdisk45 hdisk46
nkcust1u01vg hdisk19 hdisk20 hdisk21 hdisk22 hdisk47 hdisk48 hdisk49 hdisk50
nkcust1u02vg hdisk23 hdisk24 hdisk25 hdisk26 hdisk51 hdisk52 hdisk53 hdisk54
nkcust1b01vg hdisk27 hdisk28 hdisk29 hdisk30 hdisk55 hdisk56 hdisk57 hdisk58
nkcust3artrvg hdisk59 hdisk60 hdisk61 hdisk62 hdisk87 hdisk88 hdisk89 hdisk90
nkcust3fravg hdisk63 hdisk64 hdisk65 hdisk66 hdisk91 hdisk92 hdisk93 hdisk94
nkcust3redo1vg hdisk67 hdisk68 hdisk69 hdisk70 hdisk95 hdisk96 hdisk97 hdisk98
nkcust3redo2vg hdisk71 hdisk72 hdisk73 hdisk74 hdisk99 hdisk100 hdisk101 hdisk102
nkcust3u01vg hdisk75 hdisk76 hdisk77 hdisk78 hdisk103 hdisk104 hdisk105 hdisk106
nkcust3u02vg hdisk79 hdisk80 hdisk81 hdisk82 hdisk107 hdisk108 hdisk109 hdisk110
nkcust3b01vg hdisk83 hdisk84 hdisk85 hdisk86 hdisk111 hdisk112 hdisk113 hdisk114
Dnpcust5artrvg hdisk127 hdisk128 hdisk129 hdisk130 hdisk155 hdisk156 hdisk157 hdisk158
Dnpcust5fravg hdisk131 hdisk132 hdisk133 hdisk134 hdisk159 hdisk160 hdisk161 hdisk162
Dnpcust5redo1vg hdisk135 hdisk136 hdisk137 hdisk138 hdisk163 hdisk164 hdisk165 hdisk166
Dnpcust5redo2vg hdisk139 hdisk140 hdisk141 hdisk142 hdisk167 hdisk168 hdisk169 hdisk170
Dnpcust5u01vg hdisk143 hdisk144 hdisk145 hdisk146 hdisk171 hdisk172 hdisk173 hdisk174
Dnpcust5u02vg hdisk147 hdisk148 hdisk149 hdisk150 hdisk175 hdisk176 hdisk177 hdisk178
Dnpcust5b01vg hdisk151 hdisk152 hdisk153 hdisk154 hdisk179 hdisk180 hdisk181 hdisk182
rootvg hdisk200
```

# `lvm2nmon`

# `dirstats.py`

Prints the percentage of files defined in FileTiers hash within given directory:

```bash
$ python ./dirstats.py /home
        under4K:	255943	55.91%
      under128K:	163510	35.72%
        under4M:	28715	6.27%
      under128M:	9524	2.08%
          above:	113	0.02%
   Pliki i symlinki:	457806.
           Katalogi:	32393.
         Brak dost.:	1.
Maksymana osiągnięta głębokość rekursji: 18.
Czas wykonania 4.0s.

```

FileTiers should contain file tiwers to measure needed to tune HSM ang GPFS settings. 

# `wwpn2colon`

# `vdisk2mp` 

Converts `lsvdisk -delim :` to `/etc/multipath.conf` friendly names `multipaths` stanzas. 

Usage:

```bash
 cat ~/work/lsvdisk.txt | ./vdisk2mp -l
multipaths {
	multipath {
		alias: testha_0
		wwid: 60:05:07:68:02:84:80:e1:d8:00:00:00:00:00:00:07
	}
	multipath {
		alias: testha_1
		wwid: 60:05:07:68:02:84:80:e1:d8:00:00:00:00:00:00:08
	}
[ ... ]
```