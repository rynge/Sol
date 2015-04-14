#!/bin/bash

ROOT_PATH="/iplant/home/tyson_swetnam/DAYMET/"

PROJ_DIR=$1
PARAM=$2
MONTH=$3
YEAR=$4

PARAM_PATH="${ROOT_PATH}${PARAM}_allyrs/"
FILE_PATH="${PARAM_PATH}${PARAM}_${YEAR}_${MONTH}.tif"


echo "iget $FILE_PATH ${PROJ_DIR}/daymet/${PARAM}"
#iget $FILE_PATH ${PROJ_DIR}/daymet/${PARAM}
