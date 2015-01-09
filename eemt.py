import sys
import os
import argparse
import getpass
from datetime import date
import datetime
import calendar
from os.path import expanduser
import tarfile
from shutil import copy
from Tiff import Tiff

def main():
    test=Tiff("/home/posideon/professional/CZO/data/south_southern_sierra_snow_off/pitRemove","felp0r0c0.tif")
    print test.filename
    print test.location
    test.loadTiff()
    quit()
##--Default Values 
    base_year=1980
    final_year=date.today().year - 2
    input_dir="./"
    output_dir="./"
    proj_name=getpass.getuser()
    run_dir=os.getcwd();
    files=['pitRemove.tar.gz','TWI.tar.gz']
##--Set up command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--start_year", type=int, default=1980, help="The year in which you would like to start calculating EEMT for. Must be greater than 1980. Defaults to 1980")
    parser.add_argument("-e", "--end_year", type=int, default=final_year, help="The year in which you would like to end calculating EEMT. Must be less than the current year - 1")
    parser.add_argument("-i", "--input", default=input_dir, help="The directory where the input files are stored. Defaults to current directory")
    parser.add_argument("-o", "--output", default=output_dir, help="Directory where the output EEMTs will be stored. Defaults to current directory")
    parser.add_argument("-n", "--name", default=proj_name,help="Project name to use for workqueue and output. Defaults to current username")
    parser.add_argument("-t","--topo",action="store_true" , help="Calculate Topographical EEMT")
    parser.add_argument("-v","--topo_veg",action="store_true" , help="Calculate Topo-Veg EEMT")  
    args = parser.parse_args()
##--Check arguments
    if args.start_year < base_year:
        sys.exit("Start Year must be greater than 1980")
    if args.end_year > final_year:
        sys.exit("End Year must be less than current year - 1")
    if not os.path.isdir(args.input):
        sys.exit("Input directory \"" + args.output + "\" does not exist or does not have correct permissions")
    if not os.path.isdir(args.output):
        sys.exit("Output directory \"" + args.output + "\" does not exist or does not have correct permissions")
##--Confirm values with user
    print "Confirm run EEMT with these settings: "
    print "  Start Year: " + `args.start_year`
    print "  End Year: " + `args.end_year`
    print "  Input Directory: " + args.input
    print "  Output Directory: " + args.output
    print "  Topographical EEMT: " + `args.topo`
    print "  Topo-Veg EEMT: " + `args.topo_veg`
    print "  Project Name: " + args.name
    conf=raw_input("Press [n\N] to cancel or any key to begin")
    if conf=="n" or conf=="N":
        sys.exit("User quit")        
    project_dir = create_temp_directory()
    extract_files(args.input, project_dir, files)
    get_na_dem(args.input, project_dir)
    return
def extract_files(input_dir, project_dir, files):
    print "Extracting OpenTopo DEMS"
    for file_name in files:
        file_path=os.path.join(input_dir,file_name)
        print file_path
        if os.path.isfile(file_path):
            print "  Extracting " + file_name
            tfile=tarfile.open(file_path,'r:gz')
            tfile.extractall(project_dir)
    return
def create_temp_directory():
    print "Creating Project Directory"
    home=expanduser("~")
    temp_dir=home+"/sol_data/"+`datetime.datetime.now().day`+calendar.month_abbr[datetime.datetime.now().month]+`datetime.datetime.now().year`+":"+`datetime.datetime.now().hour`+`datetime.datetime.now().minute`
    if not os.path.isdir(temp_dir):
        os.makedirs(temp_dir)
    print "Project Working Directory is " +temp_dir
    return temp_dir
def get_na_dem(input_dir,project_dir):
    na_dem_path=os.path.join(input_dir,"na_dem.tif")
    na_dem_project_path=os.path.join(project_dir,"na_dem.tif")
    if not os.path.isfile(na_dem_path):
        print "na_dem.tif not found in input directory: " + input_dir + "."
        print "Now downloading na_dem.tif..."
        #TODO
        #DOWNLOAD NA_DEM
        #COPY NA_DEM TO PROJECT DIRECTORY
    else:
        copy(na_dem_path,na_dem_project_path)
    return  
if __name__ == '__main__':
    main()