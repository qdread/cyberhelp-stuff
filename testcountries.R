bad <- which(!map_lgl(country_rast$mismap_mask,inherits,what='RasterLayer'))
bad_countries <- names(bad)
masks <- list()
for (country in bad_countries) masks[[length(masks)+1]] <- make_mask(country)

exts <- list()
for (i in 1:length(world)) {
  exts[[i]] <- extent(world[i,])
}

latmins <- map_dbl(exts, ~ .x@ymin)
latmaxes <- map_dbl(exts, ~ .x@ymax)
lonmins <- map_dbl(exts, ~ .x@xmin)
lonmaxes <- map_dbl(exts, ~ .x@xmax)

ed <- extent(drainmap)

dput(as.character(world$NAME[latmins > ed@ymax | latmaxes < ed@ymin | lonmins > ed@xmax | lonmaxes < ed@xmin]))
