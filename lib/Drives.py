#!/usr/bin/env python3
""" Zbieranie informacji o napędach SAN z hostów Linux i AIX """
import sys

class lin_tape_Missing(Exception):
	def __init__(self,name):

class Drive:
	"""Napęd SAN generyczny. Kiedyś rozszerzę tę klasę o LNX_Drive i AIX_Drive"""
	def __init__(self, name, serial="", WWPN1="", WWPN2="", WWNN="", FW="", loc="", parent="", reserve="", scsi_id="", lun_id="", blk_size=0, alt_pathing="" ):
		self.name = name					# Nazwa napędu (rzeczywista. peristent_name to nazwa syboliczna dla napędów linuxowych)
		self.WWNN = WWNN					# WWNN
		self.WWPN1 = WWPN1					# WWPN1 i 2. Jak nie ma wielu portów to tylko WWPN1
		self.WWPN2 = WWPN2
		self.parent = parent				# HBA
		self.serial = serial				# Serial
		self.FW = FW						# Firmware
		self.loc = loc						# DRC index lub adres karty PCI
		self.reserve = reserve				# typ rezerwacji SCSI
		self.scsi_id = scsi_id				# scsi ID
		self.lun_id = lun_id				# lun_id 
		self.blk_size = 0					# rozmiar bloku
		self.alt_pathing = alt_pathing		# Czy jest alt_pathing
		self.persistent_name = ""			# Nazwa stała napędu. (Dla linuxów)
		
	def setWWNN(self, WWNN):
		""" Ustawia WWNN. """
		self.WWNN = WWNN

	def setWWPN(self, WWPN):
		""" Ustawia WWPN. """
		self.WWPN = WWPN
		
	def setSerial(self, serial):
		""" Ustawia serial. """
		self.serial = serial
	
	def setFW(self, FW):
		""" Ustawia Firmware. """
		self.FW = FW
	
	def setLoc(self, loc):
		""" Ustawia DRC Index. """
		self.loc = loc
		
	def setSCSI(self, scsi_id):
		""" Ustawia SCSI ID. """
		self.scsi_id = scsi_id
	
	def setLUN(self, lun_id):
		""" Ustawia LUN ID. """
		self.lun_id = lun_id
		
	def setReserve(self, reserve):
		""" Ustawia typ rezerwacji SCSI. """
		self.reserve = reserve
	
	def getName(self):
		return self.name
		
	def printCSV(self, prefix):
		""" Wypisuje napęd jako CSV."""
		print(f"{prefix},{self.name},{self.serial},{self.WWPN},{self.WWNN},{self.FW},{self.reserve},{self.scsi_id},{self.lun_id},{self.loc},{self.parent}")

class AIX_Drive(Drive):
	""" Reprezentacja napędu taśmowego na AIXie. """
	@classmethod
	def from_lscfg(cls, lscfg):
		""" Tworzy obiekt klasy AIX_Drive z listy linii stdout komendy lscfg.
		Atrybuty:
			- lscfg: lista linii z outputu komendy lscfg -vl napęd
		"""
		m = re.match(r"
			

# ~ class LNX_Drive(Drive):
	# ~ @classmethod
	# ~ def fromName(cls, name):
		# ~ """ Odczytuje informacje z /sys/class/lin_tape i tworzy obiekt klasy LNX_Drive. """
		# ~ # Sprawdzenie czy dostałem napętd peristent
		# ~ if os.path_exists(f"/sys/class/lin_tape/{sys.argv[1]}"):
			# ~ f = open(f"/sys/class/lin_tape/{name}/serial",'r')
			# ~ serial = f.readline()
			# ~ f.close()
			
			# ~ f = open(f"/sys/class/lin_tape/{sys.argv[1]}/primary_path",'r')
			# ~ alt_pathing = f.readline()
			# ~ f.close()
			
		# ~ else:
			
