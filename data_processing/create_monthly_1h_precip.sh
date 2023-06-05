#!/bin/bash

# Activate conda environment quickenv.
# Change use of icon_file or icon_lem_file manually.
#
# Creates of monthly data set containing the awipev station pluvio data and 
# the icon accum precip. Both accum for an hour.
#
# Modifications: 2021.03.26 TK, original version
#                2021.04.19 TK, added 2km simulation
#                2021.05.04 TK, save both 600m and 2km data in same nc out file
#                2021.05.07 TK, Adapted september as some meteograms are messed up
# On cierzo and hegoa
cd /work/

# Data bases:
ICON_LEM_BASEDIR=/data/
# obs data base
PLUVIO_BASEDIR=/data/

YEAR="2020" #                      |
MONTH="12"  # 

# Set number of days manually
DAYS=( "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" )
# For september 2020 because in between some cases shouldn't be used.
#DAYS=( "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "23" "24" "25" "26" "28" "29" "30" )
#DAYS=( "03" )

for d in ${DAYS[@]}
do
  echo "DATE: ${d}/${MONTH}/${YEAR}"
  # Pluvio data
  PLUVIO_FILE=${PLUVIO_BASEDIR}/${YEAR}/${MONTH}/${d}/pluvio_nya_accum_corrected_${YEAR}${MONTH}${d}.nc
  
  # ICON data
  ICON_FILE=${ICON_LEM_BASEDIR}${YEAR}${MONTH}${d}_r2km_f13km/METEOGRAM_patch001_${YEAR}${MONTH}${d}_awipev.nc
  # ICON-LEM data
  ICON_LEM_FILE=${ICON_LEM_BASEDIR}${YEAR}${MONTH}${d}_r600m_f2km/METEOGRAM_patch001_${YEAR}${MONTH}${d}_awipev.nc
  
  if [ ! -f ${ICON_LEM_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${ICON_LEM_FILE}"
  elif [ ! -f ${PLUVIO_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${PLUVIO_FILE}"
  else
    MISSING_FILE=0
  fi

  if [ $MISSING_FILE -eq 0 ]
  then

    # For ICON the selection is only so that it can be filled up later, the actual values are computed in the python script.
    cdo selname,accum_1h_pluv,accum_1h_kochendorfer,accum_1h_wolff,accum_1h_forland ${PLUVIO_FILE} tmp_pluvio.nc  
    cdo selname,RAIN_GSP,SNOW_GSP,RAIN_CON ${ICON_LEM_FILE} tmp_icon_lem.nc   
    cdo selname,RAIN_GSP,RAIN_CON,SNOW_GSP ${ICON_FILE} tmp_icon.nc 

    cdo selday,${d} tmp_icon.nc tmp_icon_selday.nc  
    cdo selday,${d} tmp_icon_lem.nc tmp_icon_lem_selday.nc

    # Create dummy ncfile to enter icon values
    cdo hoursum tmp_icon_selday.nc tmp_icon_hoursum.nc 
    cdo hoursum tmp_icon_lem_selday.nc tmp_icon_lem_hoursum.nc
  
    # Fill dummy file
    python /compute_1h_precip.py ${ICON_FILE} "tmp_icon_hoursum.nc"
    
    cdo chname,RAIN_GSP,accum_rain_nwp,RAIN_CON,accum_precip_nwp,SNOW_GSP,accum_snow_nwp tmp_icon_hoursum.nc tmp_renamed_icon.nc
    
    python /compute_1h_precip.py ${ICON_LEM_FILE} "tmp_icon_lem_hoursum.nc"

    echo "Renaming variables..."
    cdo chname,RAIN_GSP,accum_rain_lem,RAIN_CON,accum_precip_lem,SNOW_GSP,accum_snow_lem tmp_icon_lem_hoursum.nc tmp_renamed_icon_lem.nc

    cdo merge tmp_renamed_icon.nc tmp_renamed_icon_lem.nc tmp_pluvio.nc tmp_merged.nc

    # Remove first 3 hours (spinup time)
    cdo -selhour,3/23 tmp_merged.nc tmp_selhour.nc
  
    cdo cat tmp_selhour.nc nyalesund_precip_nwp_lem_pluvio_1h_${YEAR}${MONTH}.nc
    
    rm tmp_*
  fi #finish file exist if

done
