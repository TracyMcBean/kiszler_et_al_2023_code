#!/bin/bash

# Concatenate the Cloudnet files from the model.
#
# 19.02.2021, TK
# Modifications: 04.08.2021, TK: Adapted for model (ICON-LEM) output

cd /work/tkiszler/data/

YEAR=2020
MONTHS=( "08" "09" "10" "11" "12" )
DAYS=( "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" )

# model data path
ICON_LEM_PATH=""

for m in ${MONTHS[@]}
do
    for d in ${DAYS[@]}
    do
        CN_FILE=${ICON_LEM_PATH}/${YEAR}${m}${d}_r600m_f2km/cn_classification${YEAR}${m}${d}.nc

        cdo selhour,3/23 ${CN_FILE} tmp_cn_file.nc 
	cdo cat tmp_cn_file.nc nyalesund_model_cn_classification_202008-12_nospinup.nc

        echo ${CN_FILE}
    done

done	

