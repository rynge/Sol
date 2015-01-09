import os
import sys 
import re 
from math import pow
from subprocess import Popen, PIPE
class Tiff:
    def __init__(self, path,filename):
        self.filename=filename
        self.location=path
        self.filepath=os.path.join(self.location,self.filename)
        self.nPixelX=0
        self.nPixelY=0
        self.projCoords=list()
        self.deciCoords=list()
    def loadTiff(self):
        if not os.path.isfile(self.filepath):
            sys.exit("File does not exist, or permissions are incorrect")
        cmdInfo = ['gdalinfo', self.filepath]
        
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
    
    def mergeTiff(self,other,path,output):
        if not os.path.isfile(other):
            sys.exit("File " + other + " does not exist")
        if not os.path.exists(output):
        ##--Generate Command
            command = ['gdalwarp','-overwrite']
            command.append(self.filepath)
            command.append(other.filepath)
            command.append(output)
        ##--Execute
            process = Popen(command, stdout=PIPE, shell=False)
            stderr=process.communicate()
            if process.returncode != 0:
                print stderr
            else:
                print "Finished merging " + output + ".\n"
            new_tiff=Tiff(path,output)
            return new_tiff
        else:
            print "File " + output + " already exists. Exiting"       