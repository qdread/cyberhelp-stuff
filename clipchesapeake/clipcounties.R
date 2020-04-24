# Load a lookup table of FIPS codes and get only the ones in the Chesapeake Bay watershed.
library(sf)
library(readxl)

counties <- st_read('/nfs/urbanwoodlands-data/Datasets/Boundaries/MergedCounties.shp') # county shapefile
county_lookup <- read_xls('/nfs/public-data/Chesapeake_Conservancy_landcover/ChesapeakeBay_Population_1790_2007.xls') # has all counties in watershed

counties_chesapeake <- subset(counties, FIPS %in% county_lookup$FIPS) # subset shapefile by the lookup table
counties_chesapeake <- st_union(counties_chesapeake) # merge into a single polygon

# Write the new counties object to a geopackage
st_write(counties_chesapeake, dsn = '/nfs/public-data/Chesapeake_Conservancy_landcover/counties_chesapeake_watershed.gpkg', layer = 'counties')