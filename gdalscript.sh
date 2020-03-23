# Install the python package rasterstats (this might not be necessary)
python3 -m pip install rasterstats --user

# Create raster with 1 kilometer resolution (1000 x 1000 meters, you can change this if you want) from a .shp file
gdal_rasterize -a {name of shapefile attribute to be rasterized, it is probably called HUC4 in the HUC4 shapefile} -tr 1000 1000 {path to input shapefile, in this case the HUC4 one} {path to output raster, creates new file}

# Count pixels of each class in the raster within each polygon in another .shp file
python3 {path to where the python script is located}/tabulateraster.py {path to another shapefile, in this case the ecoregions} {path to raster just created} {path to a CSV file, creates new file}