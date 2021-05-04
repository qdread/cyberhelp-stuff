# Debug slurm_call

library(rslurm)
library(mgcv)

# fake data
n <- 1000
df_model <- data.frame(lon = sample(70:80, size=n, replace = TRUE), lat = sample(30:40, size=n, replace=TRUE), year = sample(2011:2020, size=n, replace=TRUE), outbreak_fix = runif(n, 0, 1), urban_std = sample(1:5, size=n, replace=TRUE), dengue_year = runif(n, 0, 1), population = runif(n, 1000, 10000))


nb_base <- bam(dengue_year ~ s(lon, lat, k = 5) +
                 s(year, k = 2) +
                 ti(lon, lat, year, d = c(2, 1), bs = "tp", k = c(10, 5)) +
                 offset(I(log(population))),
               data = df_model,
               family = nb,
               method = "REML")

# model with less params
nbmodel_base <- slurm_call(bam,
                           params = list(formula = dengue_year ~ s(lon, lat, k = 5) +
                                           s(year, k = 2) +
                                           ti(lon, lat, year, d = c(2, 1), bs = "tp", k = c(10, 5)) +
                                           offset(I(log(population))),
                                         data = df_model,
                                         family = nb,
                                         method = "REML"))
