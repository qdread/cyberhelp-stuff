# Translates spatial waste generation data from maps to probabilities, 
# using a falloff model (exponential decay) 
# It then allows the exponential decay to vary, 
# and bootstraps those numbers to generate uncertainty bounds

##### Dependencies: 
# Data stored in the PlasticEmissions-data/PlasticFutures folder on the SESCYN server (Log in to modify)
# To run this requires the following spatial data: 
# from Laurent's paper: 
# distance to ocean map: distance map global.tif
# spatial layer of waste generation: LebretonAndrady2019_TotalPlasticWaste.tif
# Something that tells you about mismanaged waste??? [another layer from Laurent, based on DWaste]
# world boundaries: TM_WORLD_BORDERS-0.3

##### SETUP

# Libraries
library(raster)
library(rgdal)
library(rgeos)
library(sp)
library(tidyverse)
library(rslurm)

detach("package:RPostgres", unload = TRUE)

setwd("/nfs/PlasticEmission-data/PlasticFutures/")

##### Read in data ########

# load data  --> need a stable hierachical and appropriate paper level data structure
world <- readOGR("./TM_WORLD_BORDERS-0.3", "TM_WORLD_BORDERS-0.3")
# needed to correct metadata for nodatavalue in the distance map global.tif
# in the terminal, ran the code in the next line to set nodatavalue to -99 in metadata and write out new edited .tif
# $ gdal_translate -of GTIFF -a_nodata -99 "distance map global.tif" "distance map global-a_nodata.tif"
drainmap <- raster("./distance map global-a_nodata.tif")  # read in the new .tif
mismap <- raster("./LebretonAndrady2019_TotalPlasticWaste.tif")
          #raster("./LebretonAndrady2019_MismanagedPlasticWaste.tif")

# compare projections
proj4string(world) ; proj4string(mismap) ; proj4string(drainmap)
# rasters and shapefile are in the same coordinate system - 

##########
make_mask <- function(country_name){
             border <- world[which(world@data$NAME == country_name),]  # get the border of the given country
             map_ext <- extent(drainmap)
             border_ext <- extent(border)
             if (border_ext@xmin > map_ext@xmax | border_ext@xmax < map_ext@xmin | border_ext@ymin > map_ext@ymax | border_ext@ymax < map_ext@ymin) return('Country not in drainmap') # This excludes countries not contained in the extent of drainmap.
  
             # first crop, then resample, then mask to improve speed
             mismap_crop <- crop(mismap, extent(border))  # crops the total plastic waste map to the given country
             drainmap_crop <- crop(drainmap, extent(border))  # crops the drainmap with the country border
  
             mismap_rs <- raster::resample(mismap_crop, drainmap_crop, "bilinear")  # create resampled version with same extent
  
             mismap_mask <- mask(mismap_rs, border)  # masks the mismaptemp with the country border
             drainmap_mask <- mask(drainmap_crop, border)  # masks the drainmpatemp with the country border
  
             # make a list of these objects
             tempC_data <- list(country = country_name,
                                mismap_mask = mismap_mask,
                                drainmap_mask = drainmap_mask)
             # return the list
             return(tempC_data)
             }
##########

##########
bootstrap_temp_dat <- function(country, mismap_mask, drainmap_mask){
                      if (!inherits(drainmap_mask), 'RasterLayer') return('Country not in drainmap') # Skips the countries that returned errors earlier.
  
                      # take the output from make_mask function as an input here
                      country <- country[[1]]
                      tempC_mis <- mismap_mask[[1]]  # raster
                      tempC_drain <- drainmap_mask[[1]]  # raster
  
                      do_boot <- function(...){
                                 tempC_log = -1*log((tempC_drain+1)^(1-0.1*runif(1)), 10)+1   # model?  # NOTE: 10 used to be 101 
                                 tempC_emmissions = tempC_log * tempC_mis
                                 tempC_em_value = cellStats(tempC_emmissions, stat = 'sum')
    
                                 temp_dat <- data.frame(country = country)
                                 temp_dat <- cbind(temp_dat, tempC_em_value) 
    
                                 return(temp_dat)  
                                 }
  
                      boot_data <- lapply(1:1000, do_boot)
  
                      suppressMessages(boot_datf <- boot_data %>% purrr::reduce(full_join)) 
  
                      return(boot_datf)   
                      }


##########

country_name <- data.frame(country_name = as.character(world@data$NAME[81:160]), stringsAsFactors = FALSE)  # or if they want all 246 countries use world@data$NAME

#country_masks <- lapply(country_names, make_mask) # crop and mask rasters for each country
country_job <- slurm_apply(make_mask, country_name, jobname = 'country_masks', 
                           add_objects = c("world", "drainmap", "mismap"),
                           slurm_options = list(partition = 'sesyncshared'),
                           nodes = 4)

country_rast <- get_slurm_out(country_job, outtype = 'table')  # this outputs the results of the country_masks slurm_apply()
rownames(country_rast) <- c()



# This code manually does what the get_slurm_out() function does.  Only use it for testing/troubleshooting!!
# res_files <- c("results_0.RDS", "results_1.RDS")
# tmpdir <- ("/nfs/PlasticEmission-data/PlasticFutures/_rslurm_country_masks")
# missing_files <- setdiff(res_files, dir(path = tmpdir))
# res_files <- file.path(tmpdir, setdiff(res_files, missing_files))
# slurm_out <- lapply(res_files, readRDS)
# slurm_out <- do.call(c, slurm_out)
# slurm_out <- as.data.frame(do.call(rbind, slurm_out))

#bs_temp_em_value <- lapply(country_masks, bootstrap_temp_dat) # bootstrap country masks - makes a list of dataframes
bootstrap_job <- slurm_apply(bootstrap_temp_dat, country_rast, jobname = 'bootstrap', 
                             slurm_options = list(partition = 'sesync'),
                             nodes = 4)

bootstrap_em_values <- get_slurm_out(bootstrap_job, outtype = 'table')

# this deletes the temporary files created to submit the job to the cluster
cleanup_files(country_job) ; cleanup_files(bootstrap_job)


##########

# create unique filename for each run
syst <- format(Sys.time(), "%Y-%m-%d") #this gets the timestamp
bootstraplab <- "bootspatial_missman_150_" # this should be the name of the figure you are outputting
fname <- paste0(bootstraplab , syst, ".csv")

# write out the file
readr::write_csv(bootstrap_em_values, paste0("./data/", fname))

##########