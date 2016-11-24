#!/bin/bash

IFS=$'\n'
scenes=()

in_array() {
    local haystack=${1}[@]
    local needle=${2}
    for i in ${!haystack}; do
        if [[ ${i} == ${needle} ]]; then
            return 0
        fi
    done
    return 1
}

for bandfile in `find *.TIF`
do
	OIFS="$IFS"
	IFS='_' read -a Parts <<< "${bandfile}"
	IFS="$OIFS"
	
	scenes+=("${Parts[0]}")
done

singleScenes=()

for scene in "${scenes[@]}"
do
	in_array singleScenes "${scene}" || singleScenes+=($scene)
done

echo "${#singleScenes[@]}"

set GDAL_CACHEMAX=1000

for scenename in "${singleScenes[@]}"
do
	echo "$scenename.vrt"
	gdalbuildvrt -separate "$scenename.vrt" "$scenename""_B5.TIF" "$scenename""_B4.TIF" "$scenename""_B3.TIF"
	gdal_translate -of "GTiff" "$scenename.vrt" "$scenename-UTM.tif"
	gdalwarp -t_srs "EPSG:4326" "$scenename-UTM.tif" "$scenename-WGS84.tif"
	echo "$scenename-WGS84.tif OK!"
done

gdalbuildvrt -srcnodata 0 -vrtnodata 0 landsat5-mt.vrt *-WGS84.tif
gdaladdo --config COMPRESS_OVERVIEW DEFLATE -r average landsat5-mt.vrt 2 4 6 8 -ro

exit 0
