from subprocess import Popen, PIPE
from math import pow
import os
import re
import sys

class TiffParser(object):
	def __init__(self):
			
			""" Read tiff file info via gdalinfo command."""
			 
			# store file name
			self.fileName = ""
			
			# coords list [upleft, lowerleft, upright, lowerright, center]
			self.projCoords = list()
			self.deciCoords = list() 
			
			# number of x and y pixels
			self.nPixelX = 0
			self.nPixelY = 0
	def getDecimalCoords(self):
		return self.deciCoords

	def getProjCoords(self):
		return self.projCoords

	def getName(self): 
		return self.fileName	
		
	def loadTiff(self, tiffFile):
			""" Read dem file info via gdalinfo command."""
			
			# store file name
			self.fileName = tiffFile.split('.tif')[0]
			
			# initialize daymetR package

			cmdInfo = ['gdalinfo', tiffFile]
			
			# Regular experssions for upper left coords extraction
			ulCoords = re.compile(r"""Upper\s+Left\s+\(\s*(\-?\d+\.\d+),\s(-?\d+\.\d+)\)\s+\(-?(\d+)d\s*(\d+)\'(\s?\d+\.\d+)\"W,
								 \s-?(\d+)d\s*(\d+)\'(\s?\d+\.\d+)\"N""", re.X | re.I) 
			
			# Regular experssions for lower right coords extraction
			lrCoords = re.compile(r"""Lower\s+Right\s+\(\s*(\-?\d+\.\d+),\s(-?\d+\.\d+)\)\s+\(-?(\d+)d\s*(\d+)\'(\s?\d+\.\d+)\"W,
								 \s-?(\d+)d\s*(\d+)\'(\s?\d+\.\d+)\"N""", re.X | re.I) 
			# Execute the command
			process = Popen(cmdInfo, stdout=PIPE, shell=False)
			output, err = process.communicate()
			 
			if process.returncode != 0:
				raise RuntimeError("%r failed, status code %s stdout %r stderr %r" % \
									(cmdInfo, process.returncode, output, err))
			
			# Process gdalinfo output by lines
			output = output.split('\n')
			for i in xrange(len(output) - 1, -1, -1):
				if output[i].startswith("Size is"):
					# Extract # of pixels along X,Y axis
					self.nPixelX = int(output[i].split(' ')[2][:-1])
					self.nPixelY = int(output[i].split(' ')[3])
					break

				match = lrCoords.search(output[i])
				if match:
					self.projCoords.append((match.group(1), match.group(2)))
					lat = 0.0
					lon = 0.0
					# caculate lon & lat in decimal
					for j in range(3):
						lon -= float(match.group(j + 3)) / pow(60, j)
						lat += float(match.group(j + 6)) / pow(60, j)
					self.deciCoords.append((lat, lon))
					
					# upper left is three lines above
					match = ulCoords.search(output[i-3])
					self.projCoords.append((match.group(1), match.group(2)))
					lat = 0.0
					lon = 0.0
					for j in range(3):
						lon -= float(match.group(j + 3)) / pow(60, j)
						lat += float(match.group(j + 6)) / pow(60, j)
					self.deciCoords.append((lat, lon))
	def read_meta(dem):
		"""
		Uses gdalinfo output to determine the projection zone and region of the original data.
		Then passes this information to convert_opentopo() to convert the data to Daymet's projection.
		"""

		# Try opening the file and searching
		proj_info = dict()

		# Add the filenames to the end of the list
		command = ['gdalinfo', dem]

		# Execute the gdalwarp command
		process = Popen(command, stdout=PIPE, shell=False)

		# Check for errors
		stdout, stderr = process.communicate()

		if process.returncode != 0:
			print stderr
			print 'Failed to get original projection information from input data. Aborting'
			sys.exit(1)

		stdout = stdout.split('\n')

		for line in stdout:
			# Zone Information
			if line.startswith('PROJCS'):
				# Remove the punctation and break the individual words apart
				line = line.translate(None, ',[]"/')
				line = line.split()
				line = line[-1]
				# Remove the last character for North
				proj_info['zone'] = line[:-1]


			# Region Information
			elif line.startswith('    AUTHORITY'): 
				# Strip out the punctuation and split into space separated words
				line = ' '.join(re.split('[,"]', line))
				line = line.split()
				proj_info['region'] = line[-2]

		# Convert the DEMs to Daymet's projection
		print 'Converting OpenTopography DEMs to Daymet\'s projection.'
		#convert_opentopo(proj_info)

		print 'Finished warping OpenTopography.\n' 
	def convert_opentopo(proj_info):
		"""
		Creates another .tif file with the name .converted.tif for every .tif file located
		in the passed directory.The converted.tif file is supposed to be converted into the Daymet
		custom projection. Depends on theread_meta() method executing correctly. It doesn't check
		for the converted files before executing. Once the files are generated, script will call
		gdalinfo and try to parse the new coordinates from the output. The corner coordinates are
		returned in a list. Since everything is related to Daymet, it assumes the data is in the
		North and West hemispheres.
		"""

		# Command string to convert the DEM files from Open Topography to DAYMET's projection
		command = ['gdalwarp', '-s_srs', 'EPSG:' + proj_info['region'], '-overwrite', '-t_srs',
				   "+proj=lcc +lat_1=25 +lat_2=60 +lat_0=42.5 +lon_0=-100 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs",
				   '-r', 'bilinear', '-of', 'GTiff', '-tr', '10', '-10']

		# Need to execute for each .tif file from OpenTopo
		path = ['pit.tif', 'twi.tif']

		for dem_file in path:

			# Create the output file name
			dem_output = dem_file[:-4] + '_c.tif'

			# Check to see if the file has already been created
			if not os.path.exists(dem_output):

				print "\tCreating %s." % dem_output

				# Add the filenames to the end of the list
				command.append(dem_file)
				command.append(dem_output)

				# Execute the gdalwarp command
				process = Popen(command, stdout=PIPE, shell=False)

				# Check for errors
				stdout, stderr = process.communicate()

				if process.returncode != 0:
					print stderr

				else:
					print '\tSuccessfully created %s.\n' % dem_output

				# Remove the filenames for next iteration
				command.remove(dem_file)
				command.remove(dem_output)

			# File already warped
			else:
				print '\t%s detected. Skipping.\n' % dem_output

	# End convert_opentopo()