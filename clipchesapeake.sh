gdalwarp -crop_to_cutline -overwrite -dstnodata NULL \
  -cutline  /nfs/urbanwoodlands-data/Datasets/Boundaries/MergedCounties.shp \
  /nfs/public-data/Chesapeake_Conservancy_landcover/Baywide_13Class_20132014.tif \
  /nfs/urbanwoodlands-data/Datasets/Chesapeake_Conservancy_landcover/ClipToMergedCounties_13class_20132014.tif
