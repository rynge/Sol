from glob import glob
from subprocess import Popen, PIPE
from math import pow
from math import floor
#from rpy2.robjects.packages import importr
import os
import re
import sys
from tiffparser import TiffParser

def getDaymetData(tiffName, ulLat, ulLon, lrLat, lrLon, startYear=2013, endYear=2013, option='tmin'):

    """
    Download Daymet gridded data for the dem file
    startYear & endYear specify the period
    option is the measurement wanted from Daymet
    tiffName is the name of converted tiff file
    """
    
    if not os.path.exists('daymet'):
        os.makedirs('daymet')
    
    stLat = 50
    stLon = -132
    stTile = 12625
    
    # Download Daymet data for the dem region
    #daymetR = importr("DaymetR")
    #daymetR.get_Daymet_tiles(ulLat, ulLon, lrLat, lrLon, startYear, endYear, option)
    # For test only
    # lrLat -= 2
    # lrLon += 2 
    daymetCoords = dict()
    ulLat = stLat + floor((ulLat - stLat) / 2) * 2
    ulLon = stLon + floor((ulLon - stLon) / 2) * 2
    
    lrLat = stLat + floor((lrLat - stLat) / 2) * 2
    lrLon = stLon + floor((lrLon - stLon) / 2) * 2
    
    ulTile = int(stTile + ((ulLat - stLat) / 2) * 180 + (ulLon - stLon) / 2)
    lrTile = int(stTile + ((lrLat - stLat) / 2) * 180 + (lrLon - stLon) / 2)
    
    baseURL = 'http://thredds.daac.ornl.gov/thredds/fileServer/ornldaac/1219/tiles/'
    outPath = './daymet/%d_%d' % (ulTile, lrTile)
    
    if not os.path.exists(outPath):
        os.makedirs(outPath)

    for i in range(int((ulLat - lrLat) / 2) + 1):
        for j in range(int((lrLon - ulLon) / 2) + 1):
            tarTile = ulTile - i * 180 + j
            for year in range(startYear, endYear + 1):
                os.system('wget %s/%d/%d_%d/%s.nc -O %s/%d_%d_%s.nc' % \
                          (baseURL, year, tarTile, year, option, outPath, tarTile, year, option))
    
    cmdTrans = ['gdal_translate', '-of', 'GTiff', '-a_ullr','','','','',\
                '-a_srs', '+proj=lcc +datum=WGS84 +lat_1=25 n +lat_2=60n \
                +lat_0=42.5n +lon_0=100w','','']

    # convert downloaded nc file to geotiff
    for ncFile in glob('%s/*%s.nc' % (outPath, option)):
        print ncFile
        hint = ncFile.split('%s' % outPath)[1][1:]
        
        tile = int(hint.split('_')[0])
        year = int(hint.split('_')[1])
        print hint, tile, year 
        # Regular experssions for coords extraction
        if len(daymetCoords) == 0:
            
            cmdInfo = ['gdalinfo', 'NETCDF:"%s":lat' % ncFile]
            
            lrCoords = re.compile(r"""Lower\s+Right\s+\(\s?(-?\d+\.\d+),\s(-?\d+\.\d+)\)""",\
                                    re.X | re.I) 
            ulCoords = re.compile(r"""Upper\s+Left\s+\(\s?(-?\d+\.\d+),\s(-?\d+\.\d+)\)""",\
                                    re.X | re.I) 
            # Execute the command
            process = Popen(cmdInfo, stdout=PIPE, shell=False)
            output, err = process.communicate()
     
            if process.returncode != 0:
                raise RuntimeError("%r failed, status code %s stdout %r stderr %r" % \
                                  (cmdInfo, process.returncode, output, err))
    
            # Check each line of ouput from end
            output = output.split('\n')
            for i in xrange(len(output) - 1, -1, -1):
                # match left right first
                match = lrCoords.search(output[i])
                if match:
                    print match.group()
                    daymetCoords['LR'] = (match.group(1), match.group(2))
                    # then match upper left
                    match = ulCoords.search(output[i - 3])
                    print match.group()
                    daymetCoords['UL'] = (match.group(1), match.group(2))
        
        # Transfer nc to geotiff
        cmdTrans[4] = daymetCoords['UL'][0] 
        cmdTrans[5] = daymetCoords['UL'][1] 
        cmdTrans[6] = daymetCoords['LR'][0]
        cmdTrans[7] = daymetCoords['LR'][1]
        cmdTrans[-2] = 'NETCDF:"%s":%s'%(ncFile, option)
        cmdTrans[-1] = '%s/%d_%d_%s.tif' %(outPath, tile, year, option)

        #print cmdTrans
        process = Popen(cmdTrans, stdout=PIPE, shell=False)
        output, err = process.communicate()
        if process.returncode != 0:
            raise RuntimeError("%r failed, status code %s stdout %r stderr %r" % \
                                (cmdTrans, process.returncode, output, err))
        
        cmdClear = ['rm','-y', '%s' % ncFile]
        print '%s' % ncFile
        process = Popen(cmdTrans, stdout=PIPE, shell=False)
        output, err = process.communicate()
        if process.returncode != 0:
            raise RuntimeError("%r failed, status code %s stdout %r stderr %r" % \
                                (cmdClear, process.returncode, output, err))
    
    # Combine all tiles in target region for the year range
    if ulTile != lrTile:
        for year in range(startYear, endYear + 1):
            suffix = '%d_%s' % (year, option)
            cmdComb = ['gdalwarp', '-dstnodata', '-9999',\
                       '{0}/*_{1}.tif'.format(outPath, suffix),
                       '{0}/all_{1}.tif'.format(outPath, suffix)
                       ]
            os.system('gdalwarp -dstnodata -9999 {0}/*_{1}.tif {0}/all_{1}.tif'.format(outPath, suffix))
            """
            process = Popen(cmdComb, stdout=PIPE, shell=False)
            output, err = process.communicate()
            if process.returncode != 0:
                raise RuntimeError("%r failed, status code %s stdout %r stderr %r" % \
                                    (cmdComb, process.returncode, output, err))
            """
def projDem(inTiff, ulx, uly, lrx, lry, outTiff):
    
    cmdProj = ['gdal_translate', '-projwin', '%s'%ulx, '%s'%uly, '%s'%lrx, '%s'%lry, \
               '%s'%inTiff, '%s'%outTiff]

    process = Popen(cmdProj, stdout=PIPE, shell=False)
    output, err = process.communicate()
    if process.returncode != 0:
        raise RuntimeError("%r failed, status code %s stdout %r stderr %r" % \
                            (cmdProj, process.returncode, output, err))

def main():
    
    """
    This script examine a default dem file or 
    a user specified dem file
    download data for the area it covered from daymet
    """

    # Default parameters
    inputTiff = 'pit_c.tif'
    params = ['tmin']
    startYr = 2013
    endYr = 2013
    
    supportedParam = ['tmin', 'tmax', 'prcp'];
    
    # allocate user specified parameters
    if len(sys.argv) == 2:
        if not sys.argv[1].endswith('.tif') or not os.path.exists(sys.argv[1]):
            print "File not exist or wrong type"
            sys.exit(1)
        else:
            inputTiff = sys.argv[1]
    elif len(sys.argv) >= 4:
        try:
            if not sys.argv[1].endswith('.tif') or not os.path.exists(sys.argv[1]):
                print "File not exist or wrong type"
                sys.exit(1)
            else:
                inputTiff = sys.argv[1]

            startYr = int(sys.argv[2])
            endYr = int(sys.argv[3])
        except ValueError:
            print "Invalid year parameters"
            sys.exit(1)
        
        if endYr < startYr or endYr > 2013 or startYr < 1980:
            print "Invalid year parameters:[1980 - 2013]"
            sys.exit(1)
        if len(sys.argv) > 4:
            try:
                if not sys.argv[1].endswith('.tif') or not os.path.exists(sys.argv[1]):
                    print "File not exist or wrong type"
                    sys.exit(1)
                else:
                    inputTiff = sys.argv[1]
                    
                startYr = int(sys.argv[2])
                endYr = int(sys.argv[3])
            except ValueError:
                print "Invalid year parameters"
                sys.exit(1)
            
            if endYr < startYr or endYr > 2013 or startYr < 1980:
                print "Invalid year parameters:[1980 - 2013]"
                sys.exit(1)
                
            for opt in sys.argv[4:]:
                if opt == 'all':
                    params = supportedParam
                    break
                elif opt not in supportedParam:
                    print "Invalid measurement parameters"
                    sys.exit(1)
            if params != supportedParam: 
                params = sys.argv[4:]

    # Parse dem file
    demParser = TiffParser()
    demParser.loadTiff(inputTiff)
    
    # get coordinates
    coords = demParser.getDecimalCoords()
    
    # get projection coords
    projs = demParser.getProjCoords()
     
    # get converted name
    tiffName = demParser.getName()
    #print endYr, startYr
    # download daymet data   
    print coords
    for opt in params:
        getDaymetData(tiffName, coords[1][0], coords[1][1], coords[0][0], coords[0][1], \
                      startYr, endYr, opt)
    #print projs
    #print coords
    #projDem('na_dem.tif', projs[1][0], projs[1][1], projs[0][0], projs[0][1],\
    #              tiffName + '_dem.tif')
    """ 
    # Clear netcaf data
    cmdClear = ['rm', '*.nc']

    process = Popen(cmdClear, stdout=PIPE, shell=False)
    output, err = process.communicate()
    if process.returncode != 0:
        raise RuntimeError("%r failed, status code %s stdout %r stderr %r" % \
                          (cmdClear, process.returncode, output, err))
    """
if __name__ == '__main__':
    
    main()
