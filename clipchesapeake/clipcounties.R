# Load a lookup table of FIPS codes and get only the ones in the Chesapeake Bay watershed.
library(rgdal)
counties <- readOGR('/nfs/urbanwoodlands-data/Datasets/Boundaries', layer = 'MergedCounties')
fips <- read.csv('/nfs/qread-data/state_and_county_fips_master.csv')
fips_counties <- subset(fips, fips %in% counties@data$FIPS)
fips_east <- subset(fips_counties, state %in% c('DE','DC','MD','NJ','NY','PA','VA'))
counties_east <- subset(counties, FIPS %in% fips_east$fips)

# Write the new counties object to a geopackage
writeOGR(counties_east, dsn = '/nfs/public-data/Chesapeake_Conservancy_landcover/counties_chesapeake_watershed.gpkg', layer = 'counties', driver = 'GPKG')