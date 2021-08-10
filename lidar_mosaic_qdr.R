library(gdalUtils)
library(raster)
tif.dir =  "/nfs/forestbirds-data/processed/gamelands_lidar_metrics"
# retrieve names of files in the directory-- a total of 48300
file.names <- list.files(path = tif.dir, pattern = ".tif", full.names = TRUE, recursive = TRUE)
# saves each raster stack as a .tif file
mosaic_lidar_file_firstbelow5m_2 <- function(file.names) {
  
# stack.names = c("MeanAngle", "MedAngle", "MaxAngle", "NoPoints", "IQR", "VCI", "Entropy", "FHD", "VDR", "Top Rugosity", "MOCH", "Skewness", "FirstBelow1m", "FirstBelow2m", "FirstBelow5m", 
#                 "Below1m", "Below2m", "Below5m", "p10", "p25", "p75", "p90", "p95", "SDIntensity", "MeanIntensity")
# 

gdalbuildvrt(gdalfile = file.names, # uses all tiffs in the current folder
             b = 10, # band 10 is top.rugosity
             output.vrt = "PA_lidar_first_below5m.vrt")
# Then, copy the virtual raster to a actual physical file:
  
gdal_translate(src_dataset = "PA_lidar_first_below5m.vrt", 
                 dst_dataset = "PA_lidar_first_below5m.tif", 
                 output_Raster = FALSE, # returns the raster as Raster*Object
                 # if TRUE, you should consider to assign 
                 # the whole function to an object like dem <- gddal_tr..
                 options = c("BIGTIFF=YES", "COMPRESS=LZW"))
  
}
# Parallelize with rslurm
slurm_job <- slurm_map(as.list(file.names), mosaic_lidar_file_firstbelow5m_2, jobname = 'mosaic_lidar_below5m_2', 
                       nodes = 6, cpus_per_node = 8, slurm_options = list(partition = 'sesync'))
# After job is run, you can either manually delete the temporary job folder in your working directory
# which will be called _rslurm_process_lidar, or delete it this way:
# cleanup_files(slurm_job)
# saves each raster stack as a .tif file
mosaic_lidar_file_p10_2 <- function(file.names) {
  
  # stack.names = c("MeanAngle", "MedAngle", "MaxAngle", "NoPoints", "IQR", "VCI", "Entropy", "FHD", "VDR", "Top Rugosity", "MOCH", "Skewness", "FirstBelow1m", "FirstBelow2m", "FirstBelow5m", 
  #                 "Below1m", "Below2m", "Below5m", "p10", "p25", "p75", "p90", "p95", "SDIntensity", "MeanIntensity")
  # 
  
  gdalbuildvrt(gdalfile = file.names, # uses all tiffs in the current folder
               b = 19, # band 10 is top.rugosity
               output.vrt = "PA_lidar_first_p10.vrt")
  #Then, copy the virtual raster to a actual physical file:
  
 gdal_translate(src_dataset = "PA_lidar_p10.vrt", 
                 dst_dataset = "PA_lidar_p10.tif", 
                 output_Raster = TRUE, # returns the raster as Raster*Object
                 # if TRUE, you should consider to assign 
                 # the whole function to an object like dem <- gddal_tr..
                 options = c("BIGTIFF=YES", "COMPRESS=LZW"))

  
}
# Parallelize with rslurm
# You can modify the slurm_options, number of nodes, and cpus per node if desired.
# 6 is a good number of nodes to use because your job will run fast enough but it will leave some for other people to use.
# You have to pass the myMetrics object to the environment on the slurm node using the global_objects argument
# partition='sesync' is not strictly necessary but will ensure your job can run for more than 14 days (likely overkill!)
slurm_job <- slurm_map(as.list(file.names), mosaic_lidar_file_p10_2, jobname = 'mosaic_lidar_p10_2', 
                       nodes = 6, cpus_per_node = 8, slurm_options = list(partition = 'sesync'))
# ras <- raster("PA_lidar_top_rugosity.tif")
# plot(ras)