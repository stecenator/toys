#!/usr/bin/env python3
""" Zbieranie informacji o napędach SAN z hostów Linux i AIX """
import sys

class lin_tape_Missing(Exception):
	def __init__(self,name):

class Drive:
	"""Napęd SAN generyczny. Kiedyś rozszerzę tę klasę o LNX_Drive i AIX_Drive"""
	def __init__(self, name, serial="", WWPN="", WWNN="", FW="", loc="", parent="", reserve="", scsi_id="", lun_id="", blk_size=0, alt_pathing="" ):
		self.name = name
		self.WWNN = WWNN
		self.WWPN = WWPN
		self.parent = parent
		self.serial = serial
		self.FW = FW
		self.loc = loc
		self.reserve = reserve
		self.scsi_id = scsi_id
		self.lun_id = lun_id
		self.blk_size = 0
		self.alt_pathing = alt_pathing
		
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

class LNX_Drive(Drive):
	@classmethod
	def fromName(cls, name):
		""" Odczytuje informacje z /sys/class/lin_tape i tworzy obiekt klasy LNX_Drive. """
		if os.path_exists(f"/sys/class/lin_tape/{sys.argv[1]}"):
			f = open(f"/sys/class/lin_tape/{sys.argv[1]}/serial",'r')
			serial = f.readline()
			f.close()
			
			f = open(f"/sys/class/lin_tape/{sys.argv[1]}/primary_path",'r')
			alt_pathing = f.readline()
			f.close()
			
		else:
			
