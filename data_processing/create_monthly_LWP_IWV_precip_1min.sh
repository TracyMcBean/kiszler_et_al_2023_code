#!/bin/bash

#
# Creation of monthly data sets containing the awipev station data from 
# the daily icon-lem simulations and observations. 
# Files are seperate for IWV&LWP, precipitation and cloud height.
#
# The data is interpolated to 1minute intervalls to make comparison possible.
# This may lead to problems with flags and other integer values.
#
# Modifications: 2021.03.24 TK, Copied from entire file merging set. 
#                2021.03.26 TK, Adding CN cloud top and base height, shouldn't necessarily use this. commented out for now
#                2021.??.?? TK, Added Bernhards spectral flag
#                2021.07.12 TK, Ignore first 3 hours of simulation (So start at 3 UTC to avoid spinup period)
#                2021.07.19 TK, Combine 2km, 600m and hatpro in single file.

# On local workstation
cd /work/

# Data bases:
# model data
ICON_BASEDIR=/data/
# model global data
ICON_13km_BASEDIR=/data/
# hatpro data
HATPRO_BASEDIR=/data/

YEAR="2020" #
MONTH="09"  # 

# Set number of days manually
DAYS=( "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" )
#DAYS=( "01" )

for d in ${DAYS[@]}
do

  
  # ICON 2km data
  ICON_2km_FILE=${ICON_BASEDIR}${YEAR}${MONTH}${d}_r2km_f13km/METEOGRAM_patch001_${YEAR}${MONTH}${d}_awipev.nc
  # ICON 13km data
  #ICON_13km_FILE=${ICON_13km_BASEDIR}/${YEAR}/${MONTH}/meteogram.iglo.h.${YEAR}${MONTH}${d}.nc
  # ICON-LEM data
  ICON_LEM_FILE=${ICON_BASEDIR}${YEAR}${MONTH}${d}_r600m_f2km/METEOGRAM_patch001_${YEAR}${MONTH}${d}_awipev.nc

  # HATPRO data
  HATPRO_FILES=${HATPRO_BASEDIR}${YEAR}/${MONTH}/${d}
  LWP_HATPRO=${HATPRO_FILES}/sups_nya_mwr00_l2_clwvi_*
  IWV_HATPRO=${HATPRO_FILES}/sups_nya_mwr00_l2_prw_*
  # Bernhards flags for hatpro
  SPEC_FLAG_FILE=/data/obs/site/nya/nyhat/tbx_ret/data/${YEAR}/${MONTH}/${YEAR}${MONTH}${d}_tbx_ret_nyhat.nc
 
  if [ ! -f ${ICON_2km_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${ICON_2km_FILE}"
  elif [ ! -f ${ICON_13km_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${ICON_13km_FILE}"
  else
    MISSING_FILE=0
  fi

  echo "Processing hatpro data from ${HATPRO_FILES}"
  cdo -selhour,3/23 -selname,clwvi,clwvi_err,flag ${LWP_HATPRO} tmp_lwp_hatpro.nc
  cdo -selhour,3/23 -selname,prw,prw_err ${IWV_HATPRO} tmp_iwv_hatpro.nc
  cdo -selhour,3/23 -selname,flag_tbx ${SPEC_FLAG_FILE} tmp_spec_flag_file.nc

  cdo merge tmp_lwp_hatpro.nc tmp_iwv_hatpro.nc tmp_spec_flag_file.nc tmp_hatpro.nc

  echo "Selecting data..."
  cdo -selhour,3/23 -selname,TQV,TQC,RAIN_CON,RAIN_GSP,SNOW_CON,SNOW_GSP ${ICON_2km_FILE} tmp_icon_intvals.nc
  cdo -selhour,3/23 -selname,TQV,TQC,RAIN_CON,RAIN_GSP,SNOW_CON,SNOW_GSP ${ICON_LEM_FILE} tmp_icon_intvals_lem.nc
  #cdo -selhour,3/23 -selname,TQV,TQC ${ICON_13km_FILE} tmp_icon_intvals.nc
  
  echo "Interpolating all data to 1 Minute steps..."
  cdo inttime,${YEAR}-${MONTH}-${d},03:01:00,1minute tmp_hatpro.nc tmp_hatpro_inttime.nc
  cdo inttime,${YEAR}-${MONTH}-${d},03:01:00,1minute tmp_icon_intvals_lem.nc tmp_icon_intvals_inttime_lem.nc
  cdo inttime,${YEAR}-${MONTH}-${d},03:01:00,1minute tmp_icon_intvals.nc tmp_icon_intvals_inttime.nc

  # rename and merge 
  cdo chname,TQV,IWV_lem,TQC,LWP_lem,RAIN_CON,RAIN_CON_lem,RAIN_GSP,RAIN_GSP_lem,SNOW_CON,SNOW_CON_lem,SNOW_GSP,SNOW_GSP_lem, tmp_icon_intvals_inttime_lem.nc tmp_icon_intvals_renamed.nc
  cdo chname,TQV,IWV_nwp,TQC,LWP_nwp,RAIN_CON,RAIN_CON_nwp,RAIN_GSP,RAIN_GSP_nwp,SNOW_CON,SNOW_CON_nwp,SNOW_GSP,SNOW_GSP_nwp, tmp_icon_intvals_inttime.nc tmp_icon_intvals_nwp_renamed.nc

  cdo merge tmp_hatpro_inttime.nc tmp_icon_intvals_renamed.nc tmp_icon_intvals_nwp_renamed.nc tmp_merged_intvals.nc
 
  cdo cat tmp_merged_intvals.nc nyalesund_icon_hatpro_precip_intvals_${YEAR}${MONTH}.nc
  #cdo cat tmp_icon_intvals.nc nyalesund_icon_intvals_13km_${YEAR}${MONTH}.nc
    
  rm  tmp_*

done
