#!/bin/bash

# Concatenate the Cloudnet files from the observations.
#
# 19.02.2021, TK
# Modifications: 03.08.2021, TK: Concatenate instead of mergetime and switch to hatpro.

cd /work/

YEAR=2020
MONTHS=( "08" "09" "10" "11" "12" )
DAYS=( "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" )

# path where cn classifications are
CN_PATH="classification/${YEAR}"

for m in ${MONTHS[@]}
do
    for d in ${DAYS[@]}
    do
        CN_FILE=${CN_PATH}/${YEAR}${m}${d}_ny-alesund_classification.nc

        cdo selhour,3/23 ${CN_FILE} tmp_cn_file.obs 
	cdo cat tmp_cn_file.obs nyalesund_obs_cn_classification_202008-12_nospinup.nc

	#if [ ${d} == ${DAYS[0]} ] && [ ${m} == ${MONTHS[0]} ]
	#then
	#    cp ${CN_FILE} /nyalesund_obs_cn_classification.nc
	#else
	#    cdo -O mergetime /nyalesund_obs_cn_classification.nc ${CN_FILE} nyalesund_obs_cn_classification.nc
	#fi    
        echo ${CN_FILE}
    done

done	

#cdo selhour,3/23 nyalesund_obs_cn_classification_202008-12.nc nyalesund_obs_cn_classification_202008-12_nospinup.nc
