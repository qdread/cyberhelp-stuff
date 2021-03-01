
library(raster)
r <- raster(matrix(runif(100), 10))
cells <- c(34,22,50,10)

r = boliv; cells = 1:ncell(boliv)

nc <- ncol(r)
nbrs <- c(0, -nc-1, -nc, -nc+1, -1, +1, +nc-1, +nc, +nc+1) 
#ad <- t(sapply(cells, adj, rr=raster(r), ngb=nbrs, global=FALSE))   
#ad <- t(sapply(cells, function(x) x + nbrs))
ad <- sapply(nbrs, function(x) cells + x)
ad[ad < 1] <- NA
colnames(ad) <- c("center", "NW", "N", "NE", "W", "E", "SW", "S", "SE")

ad2<-ad
ad2[] <- extract(r, as.vector(ad))

ad[ad<1]<-NA
advalues <- t(apply(ad, 1, function(idx) getValues(r)[idx]))

#######################################################################
cells <- 1:ncell(boliv)
col_index <- colFromCell(boliv, cells) # Get the column index of each cell in the raster.
b_values <- getValues(boliv) # Get the values of the raster.
nc <- ncol(boliv) # Get the number of columns in the raster.

# For each cell, the same adjustment is used to find the index of its neighbors.
nbrs <- c(0, -nc-1, -nc, -nc+1, -1, +1, +nc-1, +nc, +nc+1) 

ad <- sapply(nbrs, function(x) cells + x) # Add that adjustment value to every cell index.
colnames(ad) <- c("center", "NW", "N", "NE", "W", "E", "SW", "S", "SE") # This is not necessary but just FYI to see what direction each index goes to.

# these three lines deal with edge issues, replacing the appropriate neighbor index values for cells that are on the edge of the raster with NA
ad[col_index == 1, c(2, 5, 7)] <- NA
ad[col_index == nc, c(4, 6, 9)] <- NA
ad[ad<1] <- NA

# For each cell, get the values corresponding to the indices of its neighbors.
advalues <- t(apply(ad, 1, function(idx) b_values[idx]))

# For each of the sets of neighbor values, calculate the percent different from the focal cell.
perc_diff <- apply(advalues, 1, function(x) {
  x <- x[!is.na(x)]
  sum(x!=x[1])/(length(x)-1)*100
})

# Function taking the raster as input
percent_different_neighbors <- function(r) {
  
  cells <- 1:ncell(r) # Get the number of cells in the raster.
  col_index <- colFromCell(r, cells) # Get the column index of each cell in the raster.
  r_values <- getValues(r) # Get the values of the raster.
  nc <- ncol(r) # Get the number of columns in the raster.
  
  # For each cell, the same adjustment is used to find the index of its neighbors.
  nbrs <- c(0, -nc-1, -nc, -nc+1, -1, +1, +nc-1, +nc, +nc+1) 
  
  ad <- sapply(nbrs, function(x) cells + x) # Add that adjustment value to every cell index.
  colnames(ad) <- c("center", "NW", "N", "NE", "W", "E", "SW", "S", "SE") # This is not necessary but just FYI to see what direction each index goes to.
  
  # these three lines deal with edge issues, replacing the appropriate neighbor index values for cells that are on the edge of the raster with NA
  ad[col_index == 1, c(2, 5, 7)] <- NA
  ad[col_index == nc, c(4, 6, 9)] <- NA
  ad[ad<1] <- NA
  
  # For each cell, get the values corresponding to the indices of its neighbors.
  advalues <- t(apply(ad, 1, function(idx) r_values[idx]))
  
  # For each of the sets of neighbor values, calculate the percent different from the focal cell and return the result.
  apply(advalues, 1, function(x) {
    x <- x[!is.na(x)]
    sum(x!=x[1])/(length(x)-1)*100
  })
  
}