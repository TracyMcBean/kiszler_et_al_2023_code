#!/bin/bash

# Create monthly file containing only the 11UTC values of hatpro
#
# Modifications: 2021.03.24 TK, Copied from entire file merging set. 

# On cierzo or hegoa
cd /work/tkiszler/data/

# Data bases:
HATPRO_BASEDIR=/data/obs/site/nya/nyhat/l2/

YEAR="2020" #
MONTH="12"  # 

# Set number of days manually
DAYS=( "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" )
#DAYS=( "01" )

for d in ${DAYS[@]}
do
  
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
  cdo -selhour,11 -selname,clwvi,clwvi_err,flag ${LWP_HATPRO} tmp_lwp_hatpro.nc
  cdo -selhour,11 -selname,prw,prw_err ${IWV_HATPRO} tmp_iwv_hatpro.nc
  cdo -selhour,11 -selname,flag_tbx ${SPEC_FLAG_FILE} tmp_spec_flag_file.nc

  cdo merge tmp_lwp_hatpro.nc tmp_iwv_hatpro.nc tmp_spec_flag_file.nc tmp_hatpro.nc

  cdo cat tmp_hatpro.nc nyalesund_hatpro_${YEAR}${MONTH}_11UTC.nc
    
  rm tmp_*hatpro*

done
