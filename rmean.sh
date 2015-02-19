#!/bin/bash


#Read options
ARGS=`getopt -o D: --long directory: -n 'rmean.sh' -- "$@"`

if [ $? -ne 0 ]; then
    echo "Incorrect usage"
    exit 1
fi

eval set -- "$ARGS"

while true; do
    case "$1" in
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
MONTH=$1; shift
WORKING_DIR=$RANDOM 
LOCATION=${DIRECTORY}/sol_data/tmp_${WORKING_DIR}/PERMANENT
GRASSRC=${DIRECTORY}/.grassrc_${WORKING_DIR}

export GISRC=${GRASSRC}


###############################################################################
#OPTIONS PARSED =>  START SETUP
###############################################################################

#Create output structure
if [ ! -e ./global ]; then
    mkdir global
fi
if [ ! -e ./insol ]; then
    mkdir insol
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

###############################################################################
#SETUP COMPLETE => START GRASS OPERATIONS
###############################################################################

#Create new projection info
g.proj -c georef=$1

#Import Dems
g.mremove -f "*"
echo "IMPORTING"
#Need to grab and import every tif
while (( "$#" )); do
    echo $1 > temp
    NAME=`cut -d'.' -f1 temp`
    echo $NAME > temp
    NAME=`cut -d'/' -f2 temp`

    r.in.gdal input="./"${1} output=$NAME
    shift
done
rm temp

#Compute average for global irradiation
r.series input="`g.mlist pattern='total_sun_day_*' sep=,`" output=total_sun_${month}_average method=average
r.series input="`g.mlist pattern='insol_time_day_*' sep=,`" output=insol_time_${month}_average method=average


r.out.gdal -c createopt="TFW=YES,COMPRESS=LZW" input=total_sun_${MONTH}_average output=total_sun_${MONTH}_average.tif
r.out.gdal -c createopt="TFW=YES,COMPRESS=LZW" input=insol_time_${MONTH}_average output=insol_time_${MONTH}_average.tif

###############################################################################
#GRASS OPERATIONS COMPLETE => CLEAN UP FILES
###############################################################################
rm -rf ${DIRECTORY}/sol_data/tmp_${WORKING_DIR}/
rm $GRASSRC
