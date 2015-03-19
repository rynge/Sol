#!/bin/bash

#Input Files
DIRECTORY=$1
MONTH=$2
YEAR=$3
DEM=$4
NA_DEM=$5
TMIN=$6
TMAX=$7
VP=$8
PRCP=$9
TWI=$10
TOTAL_SUN=$11
FLAT_SUN=$12
SLOPE=$13
ASPECT=$14

WORKING_DIR=$RANDOM
LOCATION=${DIRECTORY}/sol_data/tmp-${WORKING_DIR}/PERMANENT
GRASSRC=${DIRECTORY}/.grassrc_${WORKING_DIR}

export GISRC=${GRASSRC}

###############################################################################
#START GRASS SETUP
###############################################################################
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
g.proj -c georef=$DEM
#Remove any extraneous files
g.mremove -f "*"


#Import DEM
r.in.gdal input=${DEM} output=dem_10m

#Set Region
g.region -s rast=dem_10m

#Import DAYMET Data - tmin,tmax,twi,prcp,vp
r.in.gdal input=${TMIN} output=tmin
r.in.gdal input=${TMAX} output=tmax
r.in.gdal input=${TWI} output=twi
r.in.gdal input=${PRCP} output=prcp
r.in.gdal input=${VP} output=vp

#Import r.sun results
r.in.gdal input=${TOTAL_SUN} output=total_sun
r.in.gdal input=${FLAT_SUN} output=flat_total_sun
r.in.gdal input=${SLOPE} output=slope
r.in.gdal input=${ASPECT} output=aspect

#NA_DEM
r.in.gdal input=${NA_DEM} output=dem_1km

#Locally Corrected Temperature
r.mapcalc "tmin_loc = tmin-0.00649*(dem_10m-dem_1km)"
r.mapcalc "tmax_loc = tmax-0.00649*(dem_10m-dem_1km)"

#Local Potential Evapotranspiration for EEMT-Trad
r.mapcalc "f_tmin_loc = 6.108*exp((17.27*tmin_loc)/(tmin_loc+273.3))"
r.mapcalc "f_tmax_loc = 6.108*exp((17.27*tmax_loc)/(tmax_loc+273.3))"
r.mapcalc "vp_s = (f_tmax_loc+f_tmin_loc)/2"
r.mapcalc "PET = 2.1*((hours_sun/12)^2)*vp_s/((tmax_loc+tmin_loc)/2)"

#Local Solar Insolation
r.mapcalc "total_sun_joules = total_sun*3600"

#Locally Corrected Temperature (accounting for Solar Insolation)
r.mapcalc "S_i = total_sun/flat_total_sun"
r.mapcalc "tmin_topo = tmin_loc+(S_i-(1/S_i))"
r.mapcalc "tmax_topo = tmax_loc+(S_i-(1/S_i))"

#Local Water Balance (accounting for topographic water redistribution)
r.mapcalc "a_i = twi/((max(twi)+min(twi))/2)"

#Potential Evapotranspiration for EEMT-Topo
r.mapcalc "g_psy = 0.001013*(101.*((293-0.00649*dem_10m)/293)^5.26)"
r.mapcalc "m_vp = 0.04145*exp(0.06088*(tmax_topo+tmin_topo/2))"
r.mapcalc "ra = (4.72*(ln(2/0.00137))2)/(1+0.536*5)"
r.mapcalc "vp_loc = 6.11*10(7.5*tmin_topo)/(237.3+tmin_topo)"
r.mapcalc "f_tmin_topo = 6.108*exp((17.27*tmin_topo)/(tmin_topo+237.3))"
r.mapcalc "f_tmax_topo = 6.108*exp((17.27*tmin_topo)/(tmin_topo+237.3))"
r.mapcalc "vp_s_topo = (f_tmax_topo+f_tmin_topo)/2"
r.mapcalc "p_a = 101325*exp(-9.80665*0.289644*dem_10m/(8.31447*288.15))/287.35*((tmax_topo+tmin_topo/2)273.125)"
r.mapcalc "PET = total_sun_joules+p_a*0.001013*(vp_s_topo-vp_loc)/ra))/(2.45*(m_vp+g_psy)"
r.mapcalc "AET = prcp*(1+PET/prcp(1(PET/prcp)2.63)(1/2.63))"

#EEMT-Traditional
r.mapcalc "PET_Trad = (2.1*((hours_sun/12)^2*vp_s/((tmax_loc+tmin_loc)/2)"
r.mapcalc "E_ppt_trad = prcp - PET_Trad"
r.mapcalc "NPP_trad = 3000*(1+exp(1.315-0.119*(tmax_loc+tmin_loc)/2)^-1)"
r.mapcalc "E_bio_trad = NPP_trad*(22*10^6)"
r.mapcalc "EEMT_Trad = E_ppt_trad + E_bio_trad"

#EEMT-Topographical
r.mapcalc "F = a_i*prcp"
r.mapcalc "DT = ((tmax_topo+tmin_topo)/2) - 273.15"
r.mapcalc "N = cos(slope*0.0174532925)*sin(aspect*0.0174532925)"
r.mapcalc "NPP_topo = 0.39*dem_10m+346*N-187"
r.mapcalc "E_bio_topo = NPP_topo*(22*10^6)"
r.mapcalc "E_ppt_topo =F*4185.5*DT*E_bio_topo"
r.mapcalc "EEMT_Topo = E_ppt_topo + E_bio_topo"


r.out.gdal -c createopt="TFW=YES,COMPRESS=LZW" input=EEMT_Trad output=eemt/yearly/${YEAR}/${MONTH}/EEMT_Trad_${MONTH}_${YEAR}.tif
r.out.gdal -c createopt="TFW=YES,COMPRESS=LZW" input=EEMT_Topo output=eemt/yearly/${YEAR}/${MONTH}/EEMT_Topo_${MONTH}_${YEAR}.tif
