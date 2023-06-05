#!/bin/bash

# Concatenate the model level icon output and/or selected Meteogram variables
#
# 19.02.2021, TK
# 14.04.2021, TK
# Modifications: 04.08.2021, TK: Added selected model meteogram variables


YEAR=2020
MONTHS=( "08" "09" "10" "11" "12" )
DAYS=( "01" "02"  "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" )

# meteogram files location
EXP_PATH=""
#current working path
WORK_PATH=""

cd ${WORK_PATH}

for m in ${MONTHS[@]}
do
    for d in ${DAYS[@]}
    do
        #ML_FILE=${EXP_PATH}/${YEAR}${m}${d}_r600m_f2km/624_DOM01_ML_${YEAR}${m}${d}T000000Z.nc
	METEOGRAM=${EXP_PATH}/${YEAR}${m}${d}_r600m_f2km/METEOGRAM_patch001_${YEAR}${m}${d}_awipev.nc

	# select total cloud cover
	cdo -selhour,3/23 -selname,CLCT ${METEOGRAM} tmp_meteogram.nc
	cdo inttime,${YEAR}-${m}-${d},03:01:00,1minute tmp_meteogram.nc tmp_meteogram_inttime.nc

	cdo cat tmp_meteogram_inttime.nc nyalesund_icon_totalcloudcover_CLCT.nc
	#cdo cat ${ML_FILE} ${WORK_PATH}nyalesund_icon_ML_${m}.nc
        echo ${METEOGRAM}
    done

done	
