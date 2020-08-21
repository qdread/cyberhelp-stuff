#Load plots and buffer
Plot <- st_read(dsn = '/nfs/urbanwoodlands-data/Datasets/Forests_raw/NYC NAC EA Data/UF_EA_Full_Dataset.gdb',
                    layer = 'Upland_Forest_EA_Plots_2013_2014') 

Plot_final <- sf::st_transform(Plot,("+init=epsg:4326")) #change to WGS 1984

Plot_buff <- st_buffer(Plot_final, 0.00898311174)%>% 
mutate(row = row_number())

#Add road length

Roads <- st_read('/nfs/urbanwoodlands-data/Datasets/LULC/Road density/MjrHighways.shp') #

Plot_road<-sf::st_intersection(Roads, Plot_buff) 

Rd_length<-tapply(st_length(Plot_road), Plot_road$PLOT_ID,sum) 

Rd_length_df <- data.frame(PLOT_ID = names(Rd_length), road_length = Rd_length)

merged <- merge(Plot_buff, Rd_length_df, by.x = "PLOT_ID",by.y = "PLOT_ID")
