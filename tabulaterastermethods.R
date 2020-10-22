library(exactextractr)
library(raster)
library(sf)
library(tidyverse)
library(microbenchmark)
library(fasterize)
library(reticulate)



# Define functions for each method.
extractr_extract <- function(poly, ras) {
  ext <- exact_extract(ras, poly)
  # Here, we are going to take the coverage fraction to account for partially covered pixels.
  tab <- lapply(ext, function(x) with(x, tapply(coverage_fraction, value, sum)))
  do.call(rbind, tab)
}

raster_extract <- function(poly, ras) {
  ext <- raster::extract(ras, poly)
  tab <- lapply(ext, function(x) tabulate(x, 3))
  do.call(rbind, tab)
}

rasterize_extract <- function(poly, ras) {
  plot_ras <- rasterize(poly, ras, field = 'plot_ID')
  crosstab(plot_ras, ras)
}

fasterize_extract <- function(poly, ras) {
  plot_ras <- fasterize(poly, ras, field = 'plot_ID')
  crosstab(plot_ras, ras)
}

rasterstats <- import('rasterstats') # Import the Python package that has the fn in it.

python_extract <- function(poly_file, ras_file) {
  ext <- rasterstats$zonal_stats(poly_file, ras_file, categorical = TRUE) # Call the python function
  do.call(rbind, lapply(ext, unlist)) # Convert the list to a matrix
}