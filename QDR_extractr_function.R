# !!!!!!!!! begin function definition
# Improved exact extraction function that uses the classes from the raster and always returns the same number of columns.
# Written by QDR 06 Nov 2020
extractr_extract <- function(poly, ras, classes) {
  ext <- exact_extract(ras, poly)
  tab <- lapply(ext, function(x) sapply(classes, function(class) sum(x$coverage_fraction[x$value == class], na.rm = TRUE)))
  z <- do.call(rbind, tab)
  out <- data.frame(plot_ID = poly$plot_ID, z)
  setNames(out, c('plot_ID', 1:length(classes)))
}
# !!!!!!!! end function definition

# CODE TO TEST FUNCTION:

# In each case use the first 100 rows to save time.

# Test the function on landform.
landform <- raster(file.path('Datasets',
                             'Landforms',
                             'Landform.tif'), RAT = TRUE) 

x_big_landform <- extractr_extract(Plot_buff[1:100,], landform, classes = 1:10) # Works
x_small_landform <- extractr_extract(Plot_buff_FIA[1:100,], landform, classes = 1:10) # Works

# Test the function on NLCD classes.
NLCD_classes <- raster(file.path('Datasets',
                                 'LULC',
                                 'NLCD_2016',
                                 'NLCDClipped1.tif')) 

nlcdvals <- unique(NLCD_classes)
x_big_nlcd <- extractr_extract(Plot_buff[1:100,], NLCD_classes, classes = nlcdvals) # Works
x_small_nlcd <- extractr_extract(Plot_buff_FIA[1:100,], NLCD_classes, classes = nlcdvals) # Works

# Test on a "bad" polygon
# This polygon is outside the boundaries of the raster. (found this on stackoverflow)
my.df <- data.frame(
     Plot = c("A", "A", "A", "A", "A", "B", "B", "B", "B", "B"),
     Easting = c(511830, 512230, 512230, 511830, 511830, 511730, 512130, 512130, 511730, 511730),
     Northing = c(7550903, 7550903, 7550503, 7550503, 7550903, 7550803, 7550803, 7550403, 7550403, 7550803))
fakepoly <- sfheaders::sf_polygon(
     obj = my.df
     , x = "Easting"
     , y = "Northing"
     , polygon_id = "Plot"
) %>% rename(plot_ID = Plot)

extractr_extract(fakepoly, landform, classes = 1:10) # This works. All zeroes are returned!

