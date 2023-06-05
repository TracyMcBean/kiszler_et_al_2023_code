#!/bin/bash

#
# Creation of monthly data sets for radiosonde data and of icon-lem data seperately. 
#
# Modifications: 2021.04.13 TK, original version
#                2021.08.01 TK, changed to 11 UTC selection for icon
#

# On local work station
cd /work/

# Data bases:
# model data
ICON_LEM_BASEDIR=/data/
# awipev radiosonde data
RS_BASEDIR=/data/

YEAR="2020" #                      |
MONTH="12"  # 

# Set number of days manually
DAYS=( "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" )
#DAYS=( "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" )
#DAYS=( "03" )

for d in ${DAYS[@]}
do
  echo "DATE: ${d}/${MONTH}/${YEAR}"
  # radiosonde data
  RS_FILE=${RS_BASEDIR}/NYA-RS_${YEAR}${MONTH}${d}*
  
  # ICON-LEM data
  ICON_LEM_FILE=${ICON_LEM_BASEDIR}${YEAR}${MONTH}${d}_r600m_f2km/METEOGRAM_patch001_${YEAR}${MONTH}${d}_awipev.nc
  ICON_NWP_FILE=${ICON_LEM_BASEDIR}${YEAR}${MONTH}${d}_r2km_f13km/METEOGRAM_patch001_${YEAR}${MONTH}${d}_awipev.nc
  
  if [ ! -f ${ICON_LEM_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${ICON_LEM_FILE}"
  elif [ ! -f ${RS_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${RS_FILE}"
  else
    MISSING_FILE=0
  fi

  if [ $MISSING_FILE -eq 0 ]
  then
   
    #cdo -selday,${d} -selhour,12 ${ICON_LEM_FILE} tmp_icon_selday.nc
    cdo selhour,11 ${ICON_LEM_FILE} tmp_icon_selhour.nc
    cdo selhour,11 ${ICON_NWP_FILE} tmp_icon_selhour_nwp.nc

    cdo cat tmp_icon_selhour_nwp.nc nyalesund_icon_nwp_${YEAR}${MONTH}_h11.nc
    cdo cat tmp_icon_selhour.nc nyalesund_icon_lem_${YEAR}${MONTH}_h11.nc
    
    #cdo cat ${RS_FILE} nyalesund_RS_${YEAR}${MONTH}.nc

    rm tmp_icon_selhour_nwp.nc tmp_icon_selhour.nc
  fi #finish file exist if

done
