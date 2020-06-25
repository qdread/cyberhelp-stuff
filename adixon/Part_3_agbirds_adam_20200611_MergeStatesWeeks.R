  #This code is to generate all merged states for each crop and week
#Part 3 of the code process. There are no external functions.

library(gdalUtils)
#library(rgdal)


#Run this to generate output VRTS
#list with image date order wanted
cropstates<-list.files("/nfs/agbirds-data/June2020/outputs", full.names = T)  #set input folder location here
for (i in 1:52) {
  crop<-"soybeans" #just a char vector to put in output file name
  #Full file path
  cropstates<-list.files("/nfs/agbirds-data/June2020/outputs", full.names = T)
  states_at_week<-grep(paste0("Corn_week_",week,"\\.tif$"),cropstates,value=TRUE, perl=TRUE)#set input folder location here
  #Just file name for naming output
  cropstates_name<-list.files("/nfs/agbirds-data/June2020/outputs", full.names = F)
  states_at_week_name<-grep(paste0("Corn_week_",week,"\\.tif$"),cropstates_name,value=TRUE, perl=TRUE)#set input folder location here
  #this builds a vector of the states with the week identified suitable for gdal input
  #The grep function searches the outputs folder and get all the "Corn_week" files. Change to Soybeans when ready for that.
  gdalbuildvrt(states_at_week, output.vrt = paste0("/nfs/agbirds-data/June2020/outputs_vrt/all_states_",crop,"_week_",week,".vrt")) #set output location here.
}



######Runs faster in parallel maybe?

parallel_vrt<-function(week){
  library(gdalUtils)
  crop<-"soybeans" #just a char vector to put in output file name
  #Full file path
  cropstates<-list.files("/nfs/agbirds-data/June2020/outputs", full.names = T)
  #Corn, Soybeans, or WinterWheat
  states_at_week<-grep(paste0("Soybeans_week_",week,"\\.tif$"),cropstates,value=TRUE, perl=TRUE)#set input folder location here
  #Just file name for naming output
  cropstates_name<-list.files("/nfs/agbirds-data/June2020/outputs", full.names = F)
  states_at_week_name<-grep(paste0("Soybeans_week_",week,"\\.tif$"),cropstates_name,value=TRUE, perl=TRUE)#set input folder location here
  #this builds a vector of the states with the week identified suitable for gdal input
  #The grep function searches the outputs folder and get all the "Corn_week" files. Change to Soybeans when ready for that.
  gdalbuildvrt(states_at_week, output.vrt = paste0("/nfs/agbirds-data/June2020/outputs_vrt/all_states_",crop,"_week_",week,".vrt")) #set output location here.
}

###########PARALLEL
library(parallel)

#Setting to use as many cores as states running. Each state should process at one core.

ncores<-detectCores(logical = F)
cl<-makeCluster(ncores-1)
week_order<-seq(1,52,1) #!!!!!!!!make sure and change seq based on number of states being analyzed!!!!!!!!
clusterApply(cl, week_order, parallel_vrt)
stopCluster(cl)
######################################
######################################

#see the output
library(raster)
crop_ras<-raster("/nfs/agbirds-data/June2020/outputs_vrt/all_states_corn_week_30.vrt")
plot(crop_ras)

# put US boundaries so I can see what is going on
usa <- getData('GADM', country='United States', level=0)
plot(usa)

usa_trans <- spTransform(usa, CRSobj = proj4string(crop_ras))

plot(crop_ras)
plot(usa_trans, add = TRUE)


# Attempt to debug --------------------------------------------------------

# This code that I ran on the command line confirms that all tifs in the outputs folder have the same nodata value
# Just looks at week 1
for tif in *week_1.tif; do gdalinfo -approx_stats $tif | grep "NoData"; done

# Look at just one Iowa raster
iowa_ras<-raster("/nfs/agbirds-data/June2020/outputs/Iowa_Soybeans_week_1.tif")
plot(iowa_ras)
# Look at a different one
illinois_ras<-raster("/nfs/agbirds-data/June2020/outputs/Illinois_Soybeans_week_1.tif")
plot(illinois_ras)
nebraska_ras<-raster("/nfs/agbirds-data/June2020/outputs/Nebraska_Soybeans_week_1.tif")
plot(nebraska_ras)

gdalbuildvrt(states_at_week, 
             srcnodata = 255,
             output.vrt = paste0("/nfs/agbirds-data/June2020/outputs_vrt/all_states_",crop,"_week_",week,".vrt"))

# Make a pdf with the three plots in it
pdf('~/temp/soybeansweek1.pdf')
plot(iowa_ras, main = 'Iowa')
plot(illinois_ras, main = 'Illinois')
plot(nebraska_ras, main = 'Nebraska')
dev.off()


# Use his function to make another raster vrt.
# Also debugged this , but not sure whether he actually meant for it to do that

parallel_vrt<-function(week, crop){
  library(gdalUtils)
  #Full file path
  cropstates<-list.files("/nfs/agbirds-data/June2020/outputs", full.names = T)
  #Corn, Soybeans, or WinterWheat
  states_at_week<-grep(paste0(crop,"_week_",week,"\\.tif$"),cropstates,value=TRUE, perl=TRUE)#set input folder location here
  #Just file name for naming output
  cropstates_name<-list.files("/nfs/agbirds-data/June2020/outputs", full.names = F)
  states_at_week_name<-grep(paste0(crop, "_week_",week,"\\.tif$"),cropstates_name,value=TRUE, perl=TRUE)#set input folder location here
  #this builds a vector of the states with the week identified suitable for gdal input
  #The grep function searches the outputs folder and get all the "Corn_week" files. Change to Soybeans when ready for that.
  gdalbuildvrt(states_at_week, output.vrt = paste0("~/temp/all_states_",crop,"_week_",week,".vrt"), srcnodata = '255') #set output location here.
}

parallel_vrt(week = 30, crop = 'Corn')

corn30_all <- raster('~/temp/all_states_corn_week_30.vrt')
corn30_three <- raster('~/temp/three_states_Corn_week_30.vrt')
