# How to parallelize for-loops in R

# the for loop is, by default, a serial construction. 
# Read this to see how to parallelize: 
# https://www.jottr.org/2019/01/11/parallelize-a-for-loop-by-rewriting-it-as-an-lapply-call/

### SERIAL VERSION WITH FOR LOOP

#iterates through 1 to 120 days of antecedent rainfall 
chirpy6<-numeric()
for(k in 1:102752){
  dates<-ndvi8[k,]
  rm(chirpy5)
  chirpy5<-numeric()
  for(j in 1:120){
    rm(chirpy4)
    chirpy4<-numeric()
    for(i in dates){
      h<-vals[i,1]
      chirpy1 <- chirpy[k,]
      chirpy2<-chirpy1[(h-j):h]
      chirpy3<-sum(chirpy2)
      chirpy4<-c(chirpy4,chirpy3)
    }
    chirpy5<-c(chirpy5,chirpy4)
  }
  chirpy6<-rbind(chirpy6,chirpy5)
}

### STEP 1. CONVERT FOR LOOP TO APPLY STATEMENT
# Now instead of a for loop, this statement applies the function to each of the values 1-102752.
# This does nothing different than the serial version above, because lapply uses a for loop 
# Note: I also took the liberty of initializing the empty data structures with the correct length ahead of time. This saves memory.
# Now chirpy6 is a list and at the end we can rbind it to a matrix

#iterates through 1 to 120 days of antecedent rainfall 
chirpy6 <- lapply(1:102752, function(k) {
  dates<-ndvi8[k,]

  chirpy5<-numeric(120)
  
  for(j in 1:120){

    chirpy4<-numeric(length(dates))
	
    for(i in dates){
      h<-vals[i,1]
      chirpy1 <- chirpy[k,]
      chirpy2<-chirpy1[(h-j):h]
      chirpy3<-sum(chirpy2)
      chirpy4[i]<-chirpy3
    }
    chirpy5[j] <- chirpy4
  }
  chirpy5
})

# Combine list into a matrix by rbinding all elements of the list by row.
chirpy6 <- do.call(rbind, chirpy6)


### STEP 2. PARALLELIZE THE APPLY STATEMENT
# This is made easy by the fact that the parallel libraries require some kind of apply statement which we already made.
# So after we load the future.apply library and initialize the cores, all we do is change lapply() to future_lapply().

library(future.apply)
availableCores() # Just to confirm that there are eight cores on a Slurm node
plan(multicore(workers = 8))

#iterates through 1 to 120 days of antecedent rainfall 
chirpy6 <- future_lapply(1:102752, function(k) {
  dates<-ndvi8[k,]

  chirpy5<-numeric(120)
  
  for(j in 1:120){

    chirpy4<-numeric(length(dates))
	
    for(i in dates){
      h<-vals[i,1]
      chirpy1 <- chirpy[k,]
      chirpy2<-chirpy1[(h-j):h]
      chirpy3<-sum(chirpy2)
      chirpy4[i]<-chirpy3
    }
    chirpy5[j] <- chirpy4
  }
  chirpy5
})

# Combine list into a matrix by rbinding all elements of the list by row.
chirpy6 <- do.call(rbind, chirpy6)

## STEP 3. SEND TO SLURM

# Because your script is long and complex with many places where parallelization occurs, I think it is less work to
# use the slurm cluster "manually" rather than with the rslurm cluster. So that means we need to write a submission
# script which will look like this:

#!/bin/bash
#SBATCH job-name=segmentedanalysis
#SBATCH --nodes=1
#SBATCH --ntasks=8

Rscript --vanilla /research-home/runks/blah/blahblah.R


# Save the submit script, for example to /research-home/runks/submitseganalysis.sh
# Run

sbatch submitseganalysis.sh

# This will run the script. The writeRaster() commands in your script will write the output at the end then the
# job will terminate. A logfile will write to the same directory that you send your submit script from.

# Many other options can be set for the job but we will not really need to go into them here.