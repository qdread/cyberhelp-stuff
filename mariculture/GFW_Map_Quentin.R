# Script for plotting raster layers over OSM basemap
# web resources used: 
# https://slcladal.github.io/maps.html 
# https://www.linkedin.com/pulse/plot-over-openstreetmap-ggplot2-abel-tortosa-andreu 
# https://datacarpentry.org/r-raster-vector-geospatial/02-raster-plot/


# set working directory to gulf suitability folder if not already there
# getwd()
# setwd("./Gulf_Suitability")

# load OSM library and other libraries needed
library(OpenStreetMap)
library(raster)
library(viridis)
library(ggplot2)

# load in data
## mariculture siting raster (ssm)
load("Gulf_Suitability/Input_Data/effort_sum.rda")
## fishing effort raster (gfw)
load("Gulf_Suitability/Input_Data/ssm_rc.rda")


# Load Florida boundaries -------------------------------------------------

library(sf)
library(USAboundaries)
fl <- us_states(resolution = 'high', states = 'FL')

# Project Florida boundaries to raster's projection
flproj <- st_transform(fl, st_crs(effort_sum))


# DIAGNOSTICS -------------------------------------------------------------

# Plot
plot(st_geometry(flproj))
plot(effort_sum, add = T)
plot(ssm_rc, add = T)

# Zoom in on upper region of effort_sum which seems to be the one that may overlap land.
# Based on this map all pixels are at least partly in the water.
plot(effort_sum, xlim = c(-82, -80), ylim = c(28, 30.5))
plot(st_geometry(flproj), add = TRUE)

# If we want to create partial pixels we need to convert each pixel to a polygon, then clip each polygon to the "difference" between it and the Florida coast.
effort_polygons <- rasterToPolygons(effort_sum) %>% 
  st_as_sf %>%
  st_difference(flproj)

plot(st_geometry(flproj), xlim = c(-82, -80), ylim = c(28, 30.5))
plot(effort_polygons['layer'], add = TRUE)


# CREATE MAP --------------------------------------------------------------

### Convert rasters to polygon layers
### Clip them to not intersect with FL coast

effort_polygons <- effort_sum %>%
  rasterToPolygons %>%
  st_as_sf %>%
  st_difference(flproj)

ssm_polygons <- ssm_rc %>%
  rasterToPolygons %>%
  st_as_sf %>%
  st_difference(flproj)

# viridis options: https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html 
# Unfortunately nps is not available here but other options are available.

ggplot() +
  annotation_map_tile(type = 'cartolight', zoom = 7) +
  geom_sf(data=effort_polygons, aes(fill=layer),alpha=0.5) +
  geom_sf(data=ssm_polygons, aes(fill=almacojack_OA_allyrs_yearlyavg),colour="#009E73") +
  viridis::scale_fill_viridis(option="inferno")+
  theme(legend.position="none")

### note: all ssm_rc = 1 or NA
