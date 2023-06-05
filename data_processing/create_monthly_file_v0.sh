#!/bin/bash

#
# Creation of monthly data set containing the awipev station data from 
# the daily icon-lem simulations and observations.
#
# The data is all interpolated to 1minute intervalls to make comparison possible
# This may lead to problems with flags and other integer values.
#
# Modifications: 2020.12.08 TK, original version
#                2021.03.24 TK, Change parsival accum rain to accum precipitation
#

# On local work station
cd /work

# Data bases:
# hatpro data
HATPRO_BASEDIR=/data
# parsivel precip data
PARSIVEL_BASEDIR=/data
# ceilometer data
CL51_BASEDIR=/data/
# ICON LEM model data
ICON_LEM_BASEDIR=/data/

YEAR="2020" #                      |
MONTH="09"  # 

# Set number of days manually
DAYS=( "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" )
#DAYS=( "12" )

for d in ${DAYS[@]}
do

  # Parsivel data
  #PARSIVEL_FILE=${PARSIVEL_BASEDIR}${YEAR}/${MONTH}/${d}/parsivel_nya_${YEAR}${MONTH}${d}.nc
  PARSIVEL_FILE=${PARSIVEL_BASEDIR}${YEAR}/${MONTH}/${d}/sups_nya_*${YEAR}${MONTH}${d}.nc
  

  # Ceilometer data
  CL51_FILE=${CL51_BASEDIR}${YEAR}/${MONTH}/${d}/${YEAR}${MONTH}${d}_ny-alesund_cl51.nc
  
  # ICON-LEM data
  ICON_LEM_FILE=${ICON_LEM_BASEDIR}${YEAR}${MONTH}${d}_r600m_f2km/METEOGRAM_patch001_${YEAR}${MONTH}${d}_awipev.nc
   
  # HATPRO data
  HATPRO_FILES=${HATPRO_BASEDIR}${YEAR}/${MONTH}/${d}
  LWP_HATPRO=${HATPRO_FILES}/sups_nya_mwr00_l2_clwvi_*
  IWV_HATPRO=${HATPRO_FILES}/sups_nya_mwr00_l2_prw_*  
  T_HATPRO=${HATPRO_FILES}/sups_nya_mwr00_l2_ta_*     # temperature profile
  AH_HATPRO=${HATPRO_FILES}/sups_nya_mwr00_l2_hua_*   #absolute humidity
  
  if [ ! -f ${ICON_LEM_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${ICON_LEM_FILE}"
  elif [ ! -f ${PARSIVEL_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${ICON_LEM_FILE}"
  elif [ ! -f ${CL51_FILE} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${ICON_LEM_FILE}"
  elif [ ! -f ${LWP_HATPRO} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${LWP_HATPRO}"
  elif [ ! -f ${LWP_HATPRO} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${IWV_HATPRO}"
  elif [ ! -f ${T_HATPRO} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${T_HATPRO}"
  elif [ ! -f ${AH_HATPRO} ]
  then
    MISSING_FILE=1
    echo "**Error** Missing ${AH_HATPRO}"
  else
    MISSING_FILE=0
  fi

  if [ $MISSING_FILE -eq 0 ]
  then

    echo "Processing hatpro data from ${HATPRO_FILES}"
    
    cdo selname,clwvi,clwvi_err,flag ${LWP_HATPRO} tmp_lwp_hatpro.nc & 
    cdo selname,prw,prw_err ${IWV_HATPRO} tmp_iwv_hatpro.nc &
    cdo selname,ta,ta_err ${T_HATPRO} tmp_temp_hatpro.nc &
    cdo selname,hua,hua_err ${AH_HATPRO} tmp_ah_hatpro.nc
  
    cdo merge tmp_lwp_hatpro.nc tmp_iwv_hatpro.nc tmp_temp_hatpro.nc tmp_ah_hatpro.nc tmp_hatpro.nc
  
    #rm lwp_hatpro_tmp.nc iwv_hatpro_tmp.nc temp_hatpro_tmp.nc ah_hatpro_tmp.nc
  
    
    echo ${PARSIVEL_FILE}
    # Add reference time (this is a bit iffy) which has to be done twice
    cdo -r setreftime,${YEAR}-${MONTH}-${d},00:00:00,1minute ${PARSIVEL_FILE} tmp_parsivel_time.nc
    cdo -r setreftime,${YEAR}-${MONTH}-${d},00:00:00,1minute tmp_parsivel_time.nc tmp_parsivel_reftime.nc
    # Here I have to set the timeaxis as it is missing as dimension
    cdo settaxis,${YEAR}-${MONTH}-${d},00:00:00,1minute tmp_parsivel_reftime.nc tmp_parsivel_settaxis.nc
    
  
    echo "Processing ICON-LEM, parsivel and cl51 data..."
    cdo selname,base1,base2,base3 ${CL51_FILE} tmp_cl51.nc &
    #cdo selname,rain_accum tmp_parsivel_settaxis.nc tmp_parsivel.nc &
    cdo selname,precipitation_amount tmp_parsivel_settaxis.nc tmp_parsivel.nc & 
    cdo selname,U,V,W,T,REL_HUM,RAIN_GSP,SNOW_GSP,T2M,P_SFC,hbas_con,TQV,TQC ${ICON_LEM_FILE} tmp_icon_lem.nc
    #cdo selname,T,REL_HUM,RAIN_GSP,SNOW_GSP,T2M,P_SFC,hbas_con,TQV,TQC tmp_icon_lem_selday.nc tmp_icon_lem.nc
  
    echo "Interpolating all data to 1 Minute steps..."
    cdo inttime,${YEAR}-${MONTH}-${d},00:01:00,1minute tmp_hatpro.nc tmp_hatpro_inttime.nc 
    cdo inttime,${YEAR}-${MONTH}-${d},00:01:00,1minute tmp_cl51.nc tmp_cl51_inttime.nc &
    cdo inttime,${YEAR}-${MONTH}-${d},00:01:00,1minute tmp_parsivel.nc tmp_parsivel_inttime.nc &
    cdo inttime,${YEAR}-${MONTH}-${d},00:01:00,1minute tmp_icon_lem.nc tmp_icon_lem_inttime.nc 
    
    cdo selday,${d} tmp_icon_lem_inttime.nc tmp_icon_lem_selday.nc
  
    echo "Merging data..."
    cdo merge tmp_hatpro_inttime.nc tmp_cl51_inttime.nc tmp_parsivel_inttime.nc tmp_icon_lem_selday.nc tmp_merged_data.nc
  
    echo "Renaming variables..."
    cdo chname,U,U_icon,V,V_icon,W,W_icon,T,T_icon,REL_HUM,rel_hum_icon,RAIN_GSP,accum_rain_icon,SNOW_GSP,accum_snow_icon,T2M,T_2m_icon,P_SFC,P_sfc_icon,hbas_con,cloud_base_icon,TQV,IWV_icon,TQC,LWP_icon,precipitation_amount,accum_precip_parsivel,base1,cloud_base1_cl51,base2,cloud_base2_cl51,base3,cloud_base3_cl51,clwvi,LWP_hatpro,clwvi_err,LWP_err_hatpro,prw,IWV_hatpro,prw_err,IWV_err_hatpro,hua,abs_hum_hatpro,hua_err,abs_hum_err_hatpro,ta,T_hatpro,ta_err,T_err_hatpro,flag,flag_hatpro tmp_merged_data.nc tmp_renamed_data.nc
  
  
    #rm tmp_parsivel_settaxis.nc tmp_cl51.nc tmp_parsivel.nc tmp_icon_lem.nc tmp_hatpro.nc tmp_merged_data.nc
  
    #$first="01"
    if [ $d == "01" ]
    then
      echo "in 01 ${d}"
      mv tmp_renamed_data.nc nyalesund_obs_model_data_${YEAR}${MONTH}.nc
    else
      cdo cat tmp_renamed_data.nc nyalesund_obs_model_data_${YEAR}${MONTH}.nc
    fi
    
    rm tmp_*
  fi #finish file exist if

done
