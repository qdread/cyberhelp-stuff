library(sf)
library(tidyverse)
fakeline <- st_read('/nfs/qread-data/temp/fakemap', layer = 'fakeline')
fakepoly <- st_read('/nfs/qread-data/temp/fakemap', layer = 'fakepoly')

plot(fakepoly)
plot(fakeline, add = TRUE, col = 'red')

fakepoly$name <- c('fakeland', 'fakeistan', 'fakeopolis', 'faketopia')
x <- st_intersection(fakeline, fakepoly)

x %>%
  group_by(name) %>%
  mutate(road_length = sum(st_length(geometry)))

tapply(st_length(x), x$name, sum)

Rd_length <- Plot_road %>%
  group_by(PLOT_ID) %>%
  mutate(road_length = sum(st_length(geometry)))


###
# orig code

Plot_road<-sf::st_intersection(Roads, Plot_buff)

Rd_length<-tapply(st_length(Plot_road), Plot_road$PLOT_ID,sum)