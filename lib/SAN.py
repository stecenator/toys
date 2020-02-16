#!/usr/bin/env python3

"""This module defines classess used to manupilate Brocade SAN switches"""

import os
import re
import sys
sys.path.append("../lib")
import Gentools

def setDebug(dbg):
	""" Sets debug mode for this module. """
	Gentools.debug = dbg

class cfgFileError(Exception):
	""" 
	Invalid config file error. Raised by all classes dealing with switch commands output loaded from files.
	Attributes:
		cfgFile:	Config file that failed to load
		reason:		Reason why. IE permissions, non existent file or syntax.
	"""
	def __init__(self, cfgFile, reason):
		self.cfgFile = cfgFile
		self.reason = reason

class cfgZoningError(Exception):
	"""
	General zoning error class.
	Attributes:
		objName:	Object rising exception
		reason:		Reason why.
	"""
	
	def __init__(self, objName, reason):
		self.objName = objName
		self.reason = reason
	
class Alias:
	""" Class representing FOS Alias object. """
	def __init__(self,name):
		""" Create Alias object with given name. 
		Args:
			name:	string
		"""
		self.name = name
		self.members = []
		
	def addMember(self, member):
		""" Adds WWPN member to an alias. 
		Args:
			member:	string, representing WWPN
			
		To do:
		Add some sanity checks to WWPN format.
		"""
		self.members.append(member)
		
	def getAliCreate(self):
		""" Return alicreate FOS statement with current Alias attributes. """
		ret = f"alicreate {self.name}, \"dupa;dupa\"" 
		return ret

class Zone:
	""" Zone - class representing FOS Zone object. """
	def __init__(self,name):
		""" Create Zone oject with given name. """
		self.name = name
		self.members = []
		
	def addMember(self, member):
		""" Appends member to self.members array. """ 
		self.members.append(member)
		
	def getZoneCreate(self):
		""" Returns zonecreate FOS statement with current Zone attributes. """
		ret = f"zonecreate {self.name}, \"dupa;dupa\""
	
	def getName(self):
		""" Returns zone name. """
		return self.name

class Cfg:
	""" Cfg - class representing FOS config object. """
	def __init__(self,name):
		""" Create Cfg object with given name.
		Args:
			name:	string
		"""
		self.name = name
		self.zones=[]
		self.aliases=[]
		
	@classmethod
	def fromCfgActvShowFile(cls, cfgActvShowFile):
		""" Loads FOS cfgactvshow text file output, stores it into a list. 
		Then calls another @classmethod: fromList which creates Cfg object.
		"""
		raw_cfg=[]
		try:
			infile = open(cfgActvShowFile, "r")
		except IOerror:
			raise cfgFileError(cfgActvShowFile, "Unable to read file.")
		else:
			with infile:
				raw_cfg = infile.readlines()
				
		return cls.fromList(raw_cfg)
		
	@classmethod
	def fromList(cls, lst):	
		""" Creates Cfg object based on raw cfgactvshow command output stored in lst list. 
		It can be either from the text file (see fromCfgActvShowFile method, or taken direectly from ssh session, 
		typically created by Switch.sshExec() method.
		"""
		
		idx = 0	
		l = ""
		cfgName = ""
		
		while not ("cfg:" in l) and len(lst) > 0:
			l = lst.pop(0)
		
		if len(lst) == 0:
			print("Cfg.fromList:\tNo cfg found. Exiting.", file=sys.stderr)
			exit(1)
		
		cfgName = l.split(":")[1].strip()
		
		ret = cls(cfgName)
		
		z = None
		
		while len(lst) > 0:
			l = lst.pop(0)
			if "zone:" in l:	# Got zone name here!
				if z is not None:	# there is a ready zone to add
					ret.addZone(z)
				
				z = Zone(l.split(":")[1].strip())

			else:			# l is WWPN
				try:		# Should not happen!
					z.addMember(l.strip())
					Gentools.dbg("Cfg.fromList", "Adding {z.getName()} zone to {ret.name} config.")
				except NameError:
					print(f"Cfg.fromList:\tInput error. Got WWPN not associated with Zone. Config name: {ret.name}", file=sys.stderr)
		return ret		
				
	def addZone(self, zone):
		"""
		Adds zone object to Cfg internal zone list. 
		Raises cfgZoningError exception if zone by that name already exists in config
		"""
		
		for z in self.zones:
			if z.getName() == zone.getName():
				raise cfgZoningError(self.name, f"{zname} already exists in config.")
				return
		
		self.zones.append(zone)
		
		
class Port:
	""" 
	Switch port.
	Attributes are columns from switchshow command.
	
	index:	Port index.
	port:	Port number. For small switches the same as index.
	addr:	Port address.
	media:	No idea.
	speed:	port speed.
	proto:	Protocol used
	topo:	Topology.
	WWPNS:	List of WWPNS connected. 
	NPIV:	Is port NPIV (Bool)
	LD:	Is Long distance? (Bool)
	ISL:	Is it ISL? (Bool)
	trunk:	Is it a part of trunk? (Bool)
	trunkPeer:	Peer trunk port index.
	info:	Additional port information, ie all text after WWPN in switchshow output. (string)
	"""
	
	def __init__(self, idx, port, addr, media="id", speed="N8", state="No_Light", proto="FC", topo = "", WWPNS = "", 
		NPIV = False, LD = False, ISL = False, trunk = False, trunkPeer = -1, info=""):
		"""
		Mandatory arguments are: idx, port, addr.
		"""
		self.index = idx
		self.port = port
		self.addr = addr
		self.media = media
		self.speed = speed
		self.state = state
		self.proto = proto
		self.topo = topo
		self.WWPNS = WWPNS
		self.NPIV = NPIV
		self.LD = LD
		self.ISL = ISL
		self.trunk = trunk
		self.trunkPeer = trunkPeer
		self.info = info
		
	@classmethod
	def fromList(cls, lst):
		"""
		Port Factory. Produces Port object based on list split from switchshow output.
		"""
		
		idx = lst[0]
		port = lst[1]
		addr = int(lst[2], 16)
		med = lst[3]
		speed = lst[4]
		state = lst[5]
		proto = lst[6]
		topo = ''
		WWPNS = []
		ISL = False
		info = ''
		npiv = False
		ld = False
		trunk = False
		trunkPeer = -1
		
		
		if state == 'Online':
			topo, rem = re.split(r'\s+', lst[7], 1)
			
			# ~ print(f'##### topo: {topo}, remaining1: {rem}')
			inf = re.split(r'\s+', rem, 1)
			if re.match(r"\w\w:\w\w:\w\w:\w\w:\w\w:\w\w:\w\w:\w\w", inf[0]):	# WWPN found
				WWPNS.append(inf[0])
				inf.pop(0)
				
			if len(inf) > 0:
				s = " "
				info = s.join(inf)
				npiv = True if re.search('NPIV', info) else False		# found NPIV port that requires further drilling
				if re.search('stream', info):					# ISL Port
					ISL = True
		
		return cls(idx, port, addr, med, speed, state, proto, topo, WWPNS, npiv, ld, ISL, trunk, trunkPeer, info)
		
	def printSummary(self):
		"""
		Prints port summary: index, port, Alias or WWPN.
		"""
		print(f"{self.index}\t{self.port}\t")
		
class Switch:
	""" 
	Represents Brocade switch.
	Attributes:
		name:	Switch name (string)
		fabric:	Fabric name (string)
		user:	default admin (string)
		passwd:	password, default passw0rd (string)
		dom:	Switch Domain, default 1 (int))
		info:	Other info in form of dictionary
		ports:	List [array] of Port objects
		
	Internal variables:
		_complete:	Is switch information complete? Typically switchshow command does not provide complete information.
	"""
	
	def __init__(self, name, fabric, ip, user="admin", passwd="passw0rd", dom=1):
		""" 
		Arguments:
			name, fabric, ip, user, pass
		user and pass are not mandatory.
		"""
		self.name = name
		self.fabric = fabric
		self.user = user
		self.passwd = passwd
		self.ip = ip
		self.dom = dom
		self.info = {}						# Other info in a form of dictionary
		self.ports = []						# list of ports (Port object class)
		self._complete = False					# is switch info coplete, ie NPIV host lists, fabrics itd.
	
	@classmethod
	def fromSwitchShow(cls, switchShowFile):
		""" Returns Switch object instance based on Brocade's switchshow command output loaded from switchShowFile argument."""
		if not os.path.isfile(switchShowFile):
			raise cfgFileError(switchShowFile, "No such file.")
			
		with open(switchShowFile, "r") as _infile:
			line = _infile.readline()
			if re.search(r"switchshow$", line):		# skip first line if it contains switchshow command it's self
				line = _infile.readline()
				
			if re.match("switchName:", line):		# first line is switchName: name
				_, _raw_name = line.split(':')
				_name = _raw_name.lstrip().rstrip()	# remove leading whitespace and trailing \n
				_ret = cls(_name, "A", "127.0.0.1")		# Switch name is known. then let's create an object.
			else:
				raise cfgFileError(switchShowFile, "Unable to determine switch name. Is it really switchshow output?")
			
			for line in _infile:
				line = _infile.readline()
				# ~ key, val = re.split('\W', line)
				lst = re.split(r':\W*', line)
				if len(lst) == 2:			# key: value line
					key = lst[0]
					val = lst[1].strip()
					_ret.addInfo(key, val)
				elif re.match("===", line):
					break				# beginning of ports section in switchshow file. let's start another loop to parse it
			ports=[]
			for line in _infile:
				lst = re.split(r'\W+', line.strip(), 7)
				# ~ print(lst)
				port = Port.fromList(lst)
				_ret.addPort(port)
		
		_infile.close()
		
		return _ret
	
	def addPort(self, port):
		"""
		Adds port object to internal ports array of a Switch object.
		"""
		self.ports.append(port)

	def addInfo(self, key, val):
		"""
		Adds key - value pair to internal info doctionary of a Switch object.
		"""
		self.info[key] = val

	def printSummary(self):
		"""
		Prints to stdout Switch object summary. No port information.
		"""
		prt = Gentools.DictPrinter()
		prt.addPair("Switch name",self.name)
		prt.addPair("Fabric",self.fabric)
		prt.addPair("IP/FQDN",self.ip)
		prt.addPair("Domain",self.dom)
		prt.addDict(self.info)
		prt.printCentered()
		
	def printPorts(self):
		"""
		Prints ports information to stdout.
		"""
		for port in self.ports:
			port.printSummary()

	def sshExec(self, cmd):
		"""
		Executes a cmd on a switch and rerns it's output as a list of srings.
		"""
		return ""
