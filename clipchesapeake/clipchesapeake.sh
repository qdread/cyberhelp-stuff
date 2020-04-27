#!/bin/bash

path="/nfs/public-data/Chesapeake_Conservancy_landcover"

# Split into two steps, first gdalwarp to a virtual raster with correct boundaries and resolution, then translate to a tif with compression
# Following code found at https://gis.stackexchange.com/questions/89444/file-size-inflation-normal-with-gdalwarp
# Also set some options to speed up performance following answer at https://gis.stackexchange.com/questions/241806/does-gdal-translate-support-multi-thread

# 3 meter resolution output
gdalwarp -tr 3 3 -r mode -of vrt -crop_to_cutline -overwrite -dstnodata NULL \
  -cutline  ${path}/counties_chesapeake_watershed.gpkg ${path}/Baywide_13Class_20132014.tif ${path}/ClipToMergedCounties_13class_20132014_3m.vrt
gdal_translate -co compress=LZW -co NUM_THREADS=8 --config GDAL_CACHEMAX 512 ${path}/ClipToMergedCounties_13class_20132014_3m.vrt ${path}/ClipToMergedCounties_13class_20132014_3m.tif

# 1 meter resolution output (keep in native resolution)
gdalwarp -of vrt -crop_to_cutline -overwrite -dstnodata NULL \
  -cutline  ${path}/counties_chesapeake_watershed.gpkg ${path}/Baywide_13Class_20132014.tif ${path}/ClipToMergedCounties_13class_20132014_1m.vrt
gdal_translate -co compress=LZW -co NUM_THREADS=8 --config GDAL_CACHEMAX 512 ${path}/ClipToMergedCounties_13class_20132014_1m.vrt ${path}/ClipToMergedCounties_13class_20132014_1m.tif
