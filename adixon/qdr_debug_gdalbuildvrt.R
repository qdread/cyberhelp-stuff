# Script to debug the masking part of Adam's code, then hopefully the build VRT part.


states_list<-c("Ohio","Texas","Tennessee","Wisconsin","North Dakota","Montana","Kentucky","Michigan","Minnesota","Colorado","New Mexico","Wyoming","Arkansas","Iowa","Kansas","Missouri","Nebraska","Oklahoma","South Dakota","Louisiana","Alabama","Mississippi","Illinois","Indiana")

crops_list<-c("Corn", "Soybeans","Winter Wheat")
crops_id<-c(1,5,24) #24, ##MAKE sure and get the ID right, get from cdl attribute table

library(raster)
library(tidyverse)
cdl<-raster("/nfs/agbirds-data/April2020/April2020/data/2019_30m_cdls(1)/2019_30m_cdls.img")
#cdl_coarse <- aggregate(cdl, fact = 10)

#use attribute table to look up crop ID in cdl
states<-shapefile("/nfs/agbirds-data/April2020/April2020/data/cb_2016_us_state_500k.shp") %>%
  spTransform(CRS = projection(cdl))

#load original cropstate table
crop_table<-read.csv("/nfs/agbirds-data/June2020/inputs/Crop_Data_modified_20200425.csv")

outputs_folder<-"/nfs/agbirds-data/Quentin_test_output/"

testpoint <- SpatialPoints(coords = data.frame(x = -90.5, y = 39.6), proj4string=CRS("+proj=longlat")) %>%
  spTransform(projection(cdl))
raster::extract(cdl, testpoint, buffer = 300) # The data are there, for a random spot in Illinois.

### Source functions 1 and 2 from Part 1 script
### Edit function 3 to only do two chosen weeks as a test (weeks 1 and 2)

create_52weeks_cropstate<-function(ras, weeks) {
  for (i in c(20,30)){
    rcls_mat<-matrix(c(1,weeks[[i]]), nrow= 1, ncol = 2)
    #crop state of interest, export as 1 bit
    #to make sure there are no spaces
    searchString <- ' '
    replacementString <- ''
    crp_rcls<-reclassify(ras, rcl = rcls_mat, format = "GTiff", datatype = "INT1U", filename = paste0(outputs_folder,gsub(searchString,replacementString,state),"_",cropname,"_week_",i))
  }
}

# renamed variable t to ii because of function t()
# Also cut down the number of states to save time (Iowa and all bordering states)
# 7 states x 1 crop x 2 weeks = 14 outputs. Took about 5 minutes per state.
states_list<-c("Iowa", "Illinois", "Nebraska", "Wisconsin", "Missouri", "South Dakota", "Minnesota")
crops_list <- "Soybeans"


for (jj in 1:length(states_list)) {
  for(ii in 1:length(crops_list)) {#MAKE SURE TO CHANGE THIS BASED ON HOW MANY CROPS BEING PROCESSED
    state<-states_list[jj]
    searchString <- ' '
    replacementString <- ''
    cropname<-gsub(searchString,replacementString,crops_list[ii]) #"WinterWheat" #needsto be one word for final output file
    crop_id_to_process<-crops_id[ii]
    #To get just the Spring Wheat
    get_rows<-crop_table%>%
      filter(State == states_list[jj], Crop == crops_list[ii])
    print(get_rows)
    ##Run the two functions made so far
    print(states_list[jj])
    cs<-cropstate_value(get_rows)
    #crop and mask the state
    crop_n_state_of_interest<-crp(state, crop_id_to_process)
    create_52weeks_cropstate(crop_n_state_of_interest, cs)
  }
}


# test whether part 1 and 2 worked ----------------------------------------

illinois20ras <- raster(file.path(outputs_folder, 'Illinois_Soybeans_week_20.tif'))
plot(illinois20ras) # Looks okay.
iowa20ras <- raster(file.path(outputs_folder, 'Iowa_Soybeans_week_20.tif'))
plot(iowa20ras) # Looks okay.

# test part 3 -------------------------------------------------------------

outputs_folder <- "/nfs/agbirds-data/Quentin_test_output/"

#parallel_vrt<-function(week, crop){
  week <- 20
  crop <- "Soybeans"

  library(gdalUtils)
  #Full file path
  cropstates<-list.files(outputs_folder, full.names = T)
  #Corn, Soybeans, or WinterWheat
  states_at_week<-grep(paste0(crop,"_week_",week,"\\.tif$"),cropstates,value=TRUE, perl=TRUE)#set input folder location here
  #Just file name for naming output
  cropstates_name<-list.files(outputs_folder, full.names = F)
  states_at_week_name<-grep(paste0(crop, "_week_",week,"\\.tif$"),cropstates_name,value=TRUE, perl=TRUE)#set input folder location here
  #this builds a vector of the states with the week identified suitable for gdal input
  #The grep function searches the outputs folder and get all the "Corn_week" files. Change to Soybeans when ready for that.
  gdalbuildvrt(states_at_week, output.vrt = file.path(outputs_folder, 'vrts', paste0("all_states_",crop,"_week_",week,".vrt")), srcnodata = '255', vrtnodata = '255') #set output location here.
#}

  
  
soybean20ras <- raster(file.path(outputs_folder, 'vrts', 'all_states_Soybeans_week_20.vrt'))
plot(soybean20ras)


# Test gdal_merge.py ------------------------------------------------------

# It didn't work. If GDAL was built with Python support -- which it was at SESYNC -- you can use gdal_merge.py
#https://gdal.org/programs/gdal_merge.html

# Shell command to run. -v specifies verbose, which can be removed later once debugging done.
gdal_merge.py -o /nfs/agbirds-data/Quentin_test_output/vrts/all_states_Soybeans_week_20.vrt -of VRT -n 255 -v *_Soybeans_week_20.tif
# Try to do with a tif.
gdal_merge.py -o /nfs/agbirds-data/Quentin_test_output/vrts/all_states_Soybeans_week_20.tif -of GTiff -n 255 -v *_Soybeans_week_20.tif
# Also try a compressed tif
cd /nfs/agbirds-data/Quentin_test_output
gdal_merge.py -o ./vrts/all_states_Soybeans_week_20.tif -of GTiff -n 255 -v -co COMPRESS=LZW -co NUM_THREADS=8 *_Soybeans_week_20.tif
# Yet another attempt: gdalwarp also does mosaicking. 
cd /nfs/agbirds-data/Quentin_test_output
gdalwarp -srcnodata 255 -dstnodata 255 *_Soybeans_week_20.tif ./vrts/all_states_Soybeans_week_20.tif

# Another attempt that first uses gdal_edit.py to make the nodata into data, then get minimum value in mosaic, then set 255 to nodata
cd /nfs/agbirds-data/Quentin_test_output
for tif in *_Soybeans_week_20.tif; do gdal_edit.py -unsetnodata $tif; done
gdalwarp -srcnodata 255 -dstnodata 255 *_Soybeans_week_20.tif ./vrts/all_states_Soybeans_week_20.tif

# Do gdalbuildvrt with nodata as zero
gdalbuildvrt -srcnodata 0 -vrtnodata 0 /nfs/agbirds-data/Quentin_test_output/vrts/all_states_Soybeans_week_20.vrt /nfs/agbirds-data/Quentin_test_output/*_Soybeans_week_20.tif

### view the result
soybean20ras <- raster(file.path(outputs_folder, 'vrts', 'all_states_Soybeans_week_20.vrt'))
plot(soybean20ras)


# Bring in each state separately and tabulate -----------------------------

library(purrr)
raster_tabulations <- dir(outputs_folder, pattern = '*_Soybeans_week_20.tif', full.names = TRUE) %>%
  map(function(file) {
    message(file)
    r <- raster(file)
    table(r[])
  })

# All rasters only contain two values, 0 and 2.
raster_sums <- map_int(raster_tabulations, sum)

# See if these sums are the same as the product of the dimensions
raster_dims <- dir(outputs_folder, pattern = '*_Soybeans_week_20.tif', full.names = TRUE) %>% map(~ dim(raster(.)))
raster_prods <- map_dbl(raster_dims, prod)

raster_sums - raster_prods ### Iowa is a discrepancy!!!! WHY
# The other 6 states have values of 0 and 2 that fill the entire bounding box.
# Iowa has values of 0 and 2 only inside the mask. In the rest of the bounding box is nodata.

# Final attempt:
# use gdal_edit or gdaltranslate to convert nodata values to zeroes
# then use gdalbuildvrt

# test with just Iowa
gdal_translate -a_nodata 0 Iowa_Soybeans_week_20.tif Iowa_test.tif

# compare the two Iowa raster tables
iowa_test <- raster(file.path(outputs_folder, 'Iowa_test.tif'))
(iowa_test_table <- table(iowa_test[]))
dim(iowa_test)

for tif in *_Soybeans_week_20.tif; do gdal_edit.py -unsetnodata $tif; done

### another test with Iowa
gdal_edit.py -unsetnodata tmp/Iowa_Soybeans_week_20.tif
gdal_calc.py -A tmp/Iowa_Soybeans_week_20.tif --outfile=tmp/Iowa_Soybeans_week_20.tif --overwrite --calc="A*(A!=255) + 0*(A==255)" --co=COMPRESS=LZW --co=NUM_THREADS=8

### Loop through all the TIFs and overwrite them with a manually reclassified one.
### Then build the VRT.
for tif in *_Soybeans_week_20.tif; do gdal_edit.py -unsetnodata $tif; done