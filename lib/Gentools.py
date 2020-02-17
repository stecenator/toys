#!/usr/bin/env python3

"""
Generic Tools
Defines some usefull classes and tools used by other mofules.
"""

debug = False

class txcolors:
	""" Terminal color const definition. """
	HEADER = '\033[95m'
	OKBLUE = '\033[94m'
	OKGREEN = '\033[92m'
	WARNING = '\033[93m'
	FAIL = '\033[91m'
	ENDC = '\033[0m'
	BOLD = '\033[1m'
	UNDERLINE = '\033[4m'

class DictPrinter:
	"""
	Provides methods for printing Python dictionaries in human readable form. 
	this class is initially used by Switch class to print information about Swotch objects.
	"""
	def __init__(self, dictionary = {} ):
		"""
		Just an empty constructor. Optionally sets internal dictionary.
		"""
		self.dict = dictionary
		self._maxKeyLen = 0
		self._maxValLen = 0
		
		if self.dict != {}:		# calculate longest key and value lengths for alignmanet purposes
			for k in keys(self.dict):
				self._maxKeyLen = len(str(k)) if len(str(k)) > self._maxKeyLen else self._maxKeyLen
		
			for v in values(self.dict):
				self._maxValLen = len(str(v)) if len(str(v)) > self._maxValLen else self._maxValLen
		
	def addPair(self, key, val):
		"""
		Adds key - val pair to intenal distionary.
		"""
		self.dict[key] = val		# re-calculate longest key and value lengths for alignmanet purposes
		self._maxKeyLen = len(str(key)) if len(str(key)) > self._maxKeyLen else self._maxKeyLen
		self._maxValLen = len(str(val)) if len(str(val)) > self._maxValLen else self._maxValLen
	
	def addDict(self, dict2):
		"""
		Merges internal dictionary with dictionary specified as an argument.
		Attributes:
			dict2:	Dictionary to update internal dict. Values of dict2 overrides intenal values if keys overlap!
		"""
		self.dict.update(dict2)
		
	def printCSV(self, sep=','):
		"""
		Prints intrnal dictionary as CSV.
		Optional arguments:
			sep:	Field separator (string). default is ','.
		"""
		for k in self.dict:
			print(f"{k}{sep}{self.dict[k]}")

	def printCentered(self, sep=':'):
		"""
		Prints internal dictionary centrally aligned.
		Optional arguments:
			sep:	Field separator (string). default is ':'.
		"""
		for k in self.dict:
			print(f"{k: >{self._maxKeyLen}} {sep} {self.dict[k]}")


# Non-object functions
def dbg(facility, message):
	""" Prints \"facility:\tmesage\" type message if this module global variable debug is set to true. """
	if debug:
		 print(f"{txcolors.WARNING}{facility}:{txcolors.ENDC}\t{message}")

def err(facility, message):
	print(f"{txcolors.FAIL}{facility}:{txcolors.ENDC}\t{message}", file=stderr)
