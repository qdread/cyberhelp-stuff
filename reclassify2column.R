# Script to test raster reclassification

# Make a fake raster to see if we can reclassify
set.seed(11)
mat <- matrix(sample(0:255, size = 10000, replace = TRUE), nrow = 100)

library(raster)
ras <- raster(mat)

# Reclassify based on Lindsay's scheme
# Use the two column matrix for the rcl argument (see the help documentation for function reclassify)

no_data <- c(0, 14:255)
not_tree <- c(1, 2, 4:9, 13)
tree <- c(3, 10, 11, 12)

old_val <- c(no_data, not_tree, tree)
new_val <- rep(0:2, times = c(length(no_data), length(not_tree), length(tree)))

rcl_table <- cbind(old_val, new_val)

ras_reclass <- reclassify(ras, rcl_table)

plot(ras)
plot(ras_reclass) # Looks like this works.
