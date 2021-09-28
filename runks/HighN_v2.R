# Read Slurm array ID environment variable and use to determine which rows will be processed by this job
task_id <- as.numeric(Sys.getenv('SLURM_ARRAY_TASK_ID'))
N <- 90574
n_tasks <- 4
cutoffs <- round(seq(0, N, length.out=n_tasks + 1))
start_row <- cutoffs[task_id]+1
end_row <- cutoffs[task_id+1]

library(sp)
library(raster)
library(rgdal)

setwd("/nfs/runks-data/MODIS_CHIRPS_SQRT")

Modis.filtered <- brick("/nfs/runks-data/MODIS_CHIRPS/MODIS.filtered_2019_notcropped.grd")

bb<-extent(37.03601,37.9,-2.78,-2.168649)
Modis.filtered<-crop(Modis.filtered, bb, snap='near')

ndvi7 <- getValues(Modis.filtered[[1:442]])
MOD <-Modis.filtered[[1]]

load("chirpy.RData")

vals <- read.csv("/nfs/runks-data/MODIS_CHIRPS/RDOYlist2019.csv", header=TRUE, sep=",")
dataList=list(vals$list)
loopy <- as.numeric(unlist(dataList))

#iterates through 1 to 120 days of antecedent rainfall 
library(future.apply)
options(future.globals.maxSize= 10e9)
plan(cluster(workers = 8))
chirpy6 <- future_lapply(start_row:end_row, function(k) {
  chirpy5<-numeric()
  for(j in 1:120){
    chirpy4<-numeric()
    for(i in loopy){
      chirpy1 <- chirpy[k,]
      chirpy2<-chirpy1[(i-j):i]
      chirpy3<-sum(chirpy2)
      chirpy4<-c(chirpy4,chirpy3)
    }
    chirpy5<-c(chirpy5,chirpy4)
  }
  chirpy5
})
chirpy7 <- do.call(rbind, chirpy6)
save(chirpy7, file = paste0("chirpy7_", task_id, ".RData")) # Save file with suffix for the task ID.
