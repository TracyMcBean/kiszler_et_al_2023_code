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

# On cierzo or hegoa
cd /work/

# Data bases:
# cloud net obs data
CN_OBS_BASEDIR=/data/
# hatpro data
HATPRO_BASEDIR=/data/
# parsivel precip data
PARSIVEL_BASEDIR=/data/
# ceilometer data
CL51_BASEDIR=/data/
# model data
ICON_LEM_BASEDIR=/data/

YEAR="2020" #
MONTH="08"  # 

# Set number of days manually
DAYS=( "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" )
#DAYS=( "01" )

for d in ${DAYS[@]}
do

  # Parsivel data
  #PARSIVEL_FILE=${PARSIVEL_BASEDIR}${YEAR}/${MONTH}/${d}/parsivel_nya_${YEAR}${MONTH}${d}.nc
  PARSIVEL_FILE=${PARSIVEL_BASEDIR}${YEAR}/${MONTH}/${d}/sups_nya_*${YEAR}${MONTH}${d}.nc
  
  # Cloudnet from obs
  CN_OBS_FILE=${CN_OBS_BASEDIR}${YEAR}/${YEAR}${MONTH}${d}_ny-alesund_classification.nc 

  # Ceilometer data
  CL51_FILE=${CL51_BASEDIR}${YEAR}/${MONTH}/${d}/${YEAR}${MONTH}${d}_ny-alesund_cl51.nc
  
  # ICON-LEM data
  ICON_LEM_FILE=${ICON_LEM_BASEDIR}${YEAR}${MONTH}${d}_r600m_f2km/METEOGRAM_patch001_${YEAR}${MONTH}${d}_awipev.nc
   
  # HATPRO data
  HATPRO_FILES=${HATPRO_BASEDIR}${YEAR}/${MONTH}/${d}
  LWP_HATPRO=${HATPRO_FILES}/sups_nya_mwr00_l2_clwvi_*
  IWV_HATPRO=${HATPRO_FILES}/sups_nya_mwr00_l2_prw_*  
  # Bernhards flags for hatpro
  SPEC_FLAG_FILE=/data/obs/site/nya/nyhat/tbx_ret/data/${YEAR}/${MONTH}/${YEAR}${MONTH}${d}_tbx_ret_nyhat.nc

  if [ ! -f ${ICON_LEM_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${ICON_LEM_FILE}"
  elif [ ! -f ${PARSIVEL_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${PARSIVEL_FILE}"
  elif [ ! -f ${CL51_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${CL51_FILE}"
  elif [ ! -f ${LWP_HATPRO} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${LWP_HATPRO}"
  elif [ ! -f ${IWV_HATPRO} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${IWV_HATPRO}"
  else
    MISSING_FILE=0
  fi

  echo "Processing hatpro data from ${HATPRO_FILES}"
    
  cdo -selhour,3/23 -selname,clwvi,clwvi_err,flag ${LWP_HATPRO} tmp_lwp_hatpro.nc 
  # zwei befehle daraus machen
  cdo -selhour,3/23 -selname,prw,prw_err ${IWV_HATPRO} tmp_iwv_hatpro.nc 
  cdo -selhour,3/23 -selname,flag_tbx ${SPEC_FLAG_FILE} tmp_spec_flag_file.nc

  cdo merge tmp_lwp_hatpro.nc tmp_iwv_hatpro.nc tmp_spec_flag_file.nc tmp_hatpro.nc
  
  #echo "Set parsivel timeaxis ${PARSIVEL_FILE}"
  # Add reference time (this is a bit iffy) which has to be done twice
  #cdo -r setreftime,${YEAR}-${MONTH}-${d},00:00:00,1minute ${PARSIVEL_FILE} tmp_parsivel_time.nc 
  #cdo -r setreftime,${YEAR}-${MONTH}-${d},00:00:00,1minute tmp_parsivel_time.nc tmp_parsivel_reftime.nc 
  # Here I have to set the timeaxis as it is missing as dimension
  #cdo settaxis,${YEAR}-${MONTH}-${d},00:00:00,1minute tmp_parsivel_reftime.nc tmp_parsivel_settaxis.nc
    
  
  echo "Selecting data..."
 # cdo selname,base1,base2,base3 ${CL51_FILE} tmp_cl51.nc &
 # cdo -selhour,3/23 -selname,precipitation_amount tmp_parsivel_settaxis.nc tmp_parsivel.nc  
  cdo -selhour,3/23 -selname,TQV,TQC ${ICON_LEM_FILE} tmp_icon_intvals.nc
 # cdo -selhour,3/23 -selname,RAIN_GSP,SNOW_GSP,RAIN_CON,SNOW_CON ${ICON_LEM_FILE} tmp_icon_precip.nc 
 # cdo selname,hbas_con ${ICON_LEM_FILE} tmp_icon_cbase.nc
 # cdo selname,cloud_base_height,cloud_top_height tmp_cn_obs.nc
  
  echo "Interpolating all data to 1 Minute steps..."
  cdo inttime,${YEAR}-${MONTH}-${d},03:01:00,1minute tmp_hatpro.nc tmp_hatpro_inttime.nc
  #cdo inttime,${YEAR}-${MONTH}-${d},00:01:00,1minute tmp_cl51.nc tmp_cl51_inttime.nc
  #cdo inttime,${YEAR}-${MONTH}-${d},03:01:00,1minute tmp_parsivel.nc tmp_parsivel_inttime.nc
  #cdo inttime,${YEAR}-${MONTH}-${d},00:01:00,1minute tmp_cn_obs.nc tmp_cn_obs_inttime.nc
  cdo inttime,${YEAR}-${MONTH}-${d},03:01:00,1minute tmp_icon_intvals.nc tmp_icon_intvals_inttime.nc
 # cdo inttime,${YEAR}-${MONTH}-${d},03:01:00,1minute tmp_icon_precip.nc tmp_icon_precip_inttime.nc
  #cdo inttime,${YEAR}-${MONTH}-${d},00:01:00,1minute tmp_icon_cbase.nc tmp_icon_cbase_inttime.nc 
  
  # select ICON day because this also can include the 00:00:00 timestamp of next day
  #cdo selday,${d} tmp_icon_precip_inttime.nc tmp_icon_precip_selday.nc
  #cdo selday,${d} tmp_parsivel_inttime.nc tmp_parsivel_selday.nc
  #cdo selday,${d} tmp_icon_cbase_inttime.nc tmp_icon_cbase_selday.nc 
  cdo selday,${d} tmp_icon_intvals_inttime.nc tmp_icon_intvals_selday.nc
  
  echo "Merging data 1. IWV&LWP, 2. precip parsivel"
  cdo merge tmp_hatpro_inttime.nc tmp_icon_intvals_selday.nc tmp_merged_intvals.nc 
  #cdo merge tmp_cl51_inttime.nc tmp_cn_obs.nc tmp_icon_cbase_selday.nc tmp_merged_cbase.nc
  #cdo merge tmp_parsivel_selday.nc tmp_icon_precip_selday.nc tmp_merged_precip.nc
  
  echo "Renaming variables..."
  #cdo chname,RAIN_GSP,accum_rain_icon,SNOW_GSP,accum_snow_icon,precipitation_amount,accum_precip_parsivel tmp_merged_precip.nc tmp_renamed_precip.nc
  #cdo chname,hbas_con,cloud_base_icon,base1,cloud_base1_cl51,base2,cloud_base2_cl51,base3,cloud_base3_cl51,cloud_base_height,cloud_base_cn, tmp_merged_cbase.nc tmp_renamed_cbase.nc
  cdo chname,TQV,IWV_icon,TQC,LWP_icon,clwvi,LWP_hatpro,clwvi_err,LWP_err_hatpro,prw,IWV_hatpro,prw_err,IWV_err_hatpro,flag,flag_hatpro tmp_merged_intvals.nc tmp_renamed_intvals.nc
  
  
  #rm tmp_parsivel_settaxis.nc tmp_cl51.nc tmp_parsivel.nc tmp_icon_lem.nc tmp_hatpro.nc tmp_merged_data.nc
  cdo cat tmp_renamed_intvals.nc nyalesund_icon_hatpro_${YEAR}${MONTH}.nc
  #cdo cat tmp_renamed_cbase.nc nyalesund_obs_model_cbase_${YEAR}${MONTH}.nc
  #cdo cat tmp_renamed_precip.nc nyalesund_obs_model_precip_${YEAR}${MONTH}.nc
    
  rm  tmp_*

done
