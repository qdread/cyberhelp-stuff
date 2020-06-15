# Convert all 255 nodata values to 0
for tif in *_Soybeans_week_20.tif
do 
	gdal_calc.py -A $tif --outfile=$tif --overwrite --calc="A*(A!=255) + 0*(A==255)" --co=COMPRESS=LZW --co=NUM_THREADS=8
done

# Build the VRT
gdalbuildvrt /nfs/agbirds-data/Quentin_test_output/vrts/all_states_Soybeans_week_20.vrt /nfs/agbirds-data/Quentin_test_output/*_Soybeans_week_20.tif
