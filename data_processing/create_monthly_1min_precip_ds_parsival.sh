#!/bin/bash

#
# Creation of monthly data sets containing the awipev station data from 
# the daily icon-lem simulations and observations. (comment in/out necessary parts)
#
# The data is interpolated to 1minute intervalls to make comparison possible.
# This may lead to problems with integer values.
#
# Modifications: 2021.03.24 TK, Copied from entire file merging set. 
#                2021.03.26 TK, Adding CN cloud top and base height, shouldn't necessarily use this. commented out for now
#                2021.07.09 TK, Changed to only precipitation selection

# On cierzo or hegoa
cd /work/

# Data bases:
# parsivel precip data
PARSIVEL_BASEDIR=/data/
# model data
ICON_LEM_BASEDIR=/data/

YEAR="2020" #
MONTH="12"  # 

# Set number of days manually
DAYS=( "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" )
#DAYS=( "31" )

for d in ${DAYS[@]}
do

  # Parsivel data
  #PARSIVEL_FILE=${PARSIVEL_BASEDIR}${YEAR}/${MONTH}/${d}/parsivel_nya_${YEAR}${MONTH}${d}.nc
  PARSIVEL_FILE=${PARSIVEL_BASEDIR}${YEAR}/${MONTH}/${d}/sups_nya_*${YEAR}${MONTH}${d}.nc
  
  # ICON-LEM data
  ICON_LEM_FILE=${ICON_LEM_BASEDIR}${YEAR}${MONTH}${d}_r600m_f2km/METEOGRAM_patch001_${YEAR}${MONTH}${d}_awipev.nc
   

  if [ ! -f ${ICON_LEM_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${ICON_LEM_FILE}"
  elif [ ! -f ${PARSIVEL_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${PARSIVEL_FILE}"
  fi

#  echo "Set parsivel timeaxis ${PARSIVEL_FILE}"
  # Add reference time (this is a bit iffy) which has to be done twice
 # cdo -r setreftime,${YEAR}-${MONTH}-${d},00:00:00,1minute ${PARSIVEL_FILE} tmp_parsivel_time.nc 
  #cdo -r setreftime,${YEAR}-${MONTH}-${d},00:00:00,1minute tmp_parsivel_time.nc tmp_parsivel_reftime.nc 
  # Here I have to set the timeaxis as it is missing as dimension
  #cdo settaxis,${YEAR}-${MONTH}-${d},00:00:00,1minute tmp_parsivel_reftime.nc tmp_parsivel_settaxis.nc
    
  
  echo "Selecting data..."
  #cdo selname,precipitation_amount tmp_parsivel_settaxis.nc tmp_parsivel.nc  
  cdo selname,RAIN_GSP,SNOW_GSP,RAIN_CON,SNOW_CON ${ICON_LEM_FILE} tmp_icon_precip.nc 
  
  echo "Interpolating all data to 1 Minute steps..."
  #cdo inttime,${YEAR}-${MONTH}-${d},00:01:00,1minute tmp_parsivel.nc tmp_parsivel_inttime.nc
  cdo inttime,${YEAR}-${MONTH}-${d},00:01:00,1minute tmp_icon_precip.nc tmp_icon_precip_inttime.nc
  # select ICON day because this also can include the 00:00:00 timestamp of next day
  cdo selday,${d} tmp_icon_precip_inttime.nc tmp_icon_precip_selday.nc
  #cdo selday,${d} tmp_parsivel_inttime.nc tmp_parsivel_selday.nc
  
  #echo "Merging data..."
  #cdo merge tmp_parsivel_selday.nc tmp_icon_precip_selday.nc tmp_merged_precip.nc
  
  echo "Renaming variables..."
 # cdo chname,RAIN_GSP,accum_rain_icon,SNOW_GSP,accum_snow_icon,precipitation_amount,accum_precip_parsivel tmp_merged_precip.nc tmp_renamed_precip.nc
  
  #rm tmp_parsivel_settaxis.nc tmp_cl51.nc tmp_parsivel.nc tmp_icon_lem.nc tmp_hatpro.nc tmp_merged_data.nc
  #cdo cat tmp_renamed_precip.nc nyalesund_obs_model_precip_${YEAR}${MONTH}.nc
  cdo cat tmp_icon_precip_selday.nc nyalesund_model_precip_${YEAR}${MONTH}.nc 
   
  rm  tmp_*

done
