#!/bin/bash

set -e

#Read options
ARGS=`getopt -o d:D: --long day:,directory: -n 'rsun.sh' -- "$@"`
if [ $? -ne 0 ]; then
echo "Incorrect usage"
exit 1
fi
eval set -- "$ARGS"
while true; do
case "$1" in
-d|--day)
shift;
if [ -n "$1" ]; then
DAY=$1
shift
fi
;;
-D|--directory)
shift
if [ -n "$1" ]; then
DIRECTORY=$1
shift;
fi
;;
--)
shift
break
;;
*) echo "Internal Error"; exit 1 ;;
esac
done
DEM=$1
WORKING_DIR=$RANDOM
LOCATION=${DIRECTORY}/sol_data/tmp_${WORKING_DIR}/PERMANENT
GRASSRC=${DIRECTORY}/.grassrc_${WORKING_DIR}
export GISRC=${GRASSRC}
###############################################################################
#OPTIONS PARSED => START SETUP
###############################################################################
#Create output structure
if [ ! -e ./global ]; then
mkdir -p global/daily
mkdir -p global/monthly
mkdir -p global/annual
fi
if [ ! -e ./insol ]; then
mkdir -p insol/daily
mkdir -p insol/monthly
mkdir -p insol/annual
fi
#Create location directory structure
if [ ! -e $LOCATION ]; then
mkdir -p $LOCATION
fi
#Set wind info
if [ ! -e ${LOCATION}/DEFAULT_WIND ]; then
cat > "${LOCATION}/DEFAULT_WIND" << __EOF__
proj: 99
zone: 0
north: 1
south: 0
east: 1
west: 0
cols: 1
rows: 1
e-w resol: 1
n-s resol: 1
top: 1.000000000000000
bottom: 0.000000000000000
cols3: 1
rows3: 1
depths: 1
e-w resol3: 1
n-s resol3: 1
t-b resol: 1
__EOF__
cp ${LOCATION}/DEFAULT_WIND ${LOCATION}/WIND
fi
#Set GRASS settings
echo "GISDBASE: ${DIRECTORY}/sol_data" > $GRASSRC
echo "LOCATION_NAME: tmp_${WORKING_DIR}" >> $GRASSRC
echo "MAPSET: PERMANENT" >> $GRASSRC
echo "GRASS_GUI: text" >> $GRASSRC
STEPSIZE=0.05
INTERVAL=1
###############################################################################
#SETUP COMPLETE => START GRASS OPERATIONS
###############################################################################
#module load unsupported
#module load czo/sol/0.0.1
if [ -e /unsupported/czo/czorc ]; then
    source /unsupported/czo/czorc
fi

echo "Running r.sun for day $DAY"
echo "DEM: $DEM"
#Create new projection info
g.proj -c georef=$DEM
#Import Dem
g.mremove -f "*"
echo "Importing DEM"
r.in.gdal input=$DEM output=dem
#Set Region
g.region -sa rast=dem res=10
#Calculate Slope and Aspect
echo "Running r.slope.aspect"
r.slope.aspect elevation=dem slope=slope_dec aspect=aspect_dec
#Create flat map
echo "Creating Flat Map"
r.mapcalc "zeros=if(dem>0,0,null())"
echo "Running r.sun on Flat Map"
r.sun elevin=dem aspin=zeros slopein=zeros day=$DAY step=$STEPSIZE dist=$INTERVAL glob_rad=flat_total_sun
#Using dem and calculated slope and aspect, generate a solar insulation model
echo "Running r.sun using dem, aspect, slope"
r.sun -s elevin=dem aspin=aspect_dec slopein=slope_dec day=$DAY step=$STEPSIZE dist=$INTERVAL insol_time=hours_sun glob_rad=total_sun
#Output files
echo "Export Total Sun"
r.out.gdal createopt="COMPRESS=LZW" -c input=total_sun output=./global/daily/total_sun_day_${DAY}.tif
echo "Export Flat Total Sun"
r.out.gdal createopt="COMPRESS=LZW" -c input=flat_total_sun output=./global/daily/flat_total_sun_day_${DAY}.tif
echo "Export Hours Sun"
r.out.gdal createopt="COMPRESS=LZW" -c input=hours_sun output=./insol/daily/hours_sun_day_${DAY}.tif
#echo "Export Slope"
#r.out.gdal -c createopt="BIGTIFF=IF_SAFER,COMPRESS=LZW" input=slope output=./slope.tif
#echo "Export Aspect"
#r.out.gdal -c createopt="BIGTIFF=IF_SAFER,COMPRESS=LZW" input=aspect output=./aspect.tif
###############################################################################
#GRASS OPERATIONS COMPLETE => CLEAN UP FILES
###############################################################################
rm -rf ${DIRECTORY}/sol_data/tmp_${WORKING_DIR}/
rm $GRASSRC
