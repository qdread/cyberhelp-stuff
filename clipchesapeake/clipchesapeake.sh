#!/bin/bash

gdalwarp -multi -co NUM_THREADS=8 -wo NUM_THREADS=8 --config GDAL_CACHEMAX 1000 -wm 1000 -crop_to_cutline -overwrite -dstnodata NULL \
  -cutline  /nfs/public-data/Chesapeake_Conservancy_landcover/counties_chesapeake_watershed.gpkg \
  /nfs/public-data/Chesapeake_Conservancy_landcover/Baywide_13Class_20132014.tif \
  /nfs/urbanwoodlands-data/Datasets/Chesapeake_Conservancy_landcover/ClipToMergedCounties_13class_20132014.tif
