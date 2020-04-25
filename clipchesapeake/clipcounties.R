# Load a lookup table of FIPS codes and get only the ones in the Chesapeake Bay watershed.
library(sf)
library(readxl)

counties <- st_read('/nfs/urbanwoodlands-data/Datasets/Boundaries/MergedCounties.shp') # county shapefile
county_lookup <- read_xls('/nfs/public-data/Chesapeake_Conservancy_landcover/ChesapeakeBay_Population_1790_2007.xls') # has all counties in watershed

counties_chesapeake <- subset(counties, FIPS %in% county_lookup$FIPS) # subset shapefile by the lookup table
counties_chesapeake <- st_union(counties_chesapeake) # merge into a single polygon

# Projection of the raster to be clipped is Albers. Set the polygon's projection to this also. Hopefully this will speed up the clipping.
counties_chesapeake <- st_transform(counties_chesapeake, crs = '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs ')

# Write the new counties object to a geopackage
st_write(counties_chesapeake, dsn = '/nfs/public-data/Chesapeake_Conservancy_landcover/counties_chesapeake_watershed.gpkg', layer = 'counties')