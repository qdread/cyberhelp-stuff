# Example model in BRMS with temporal autocorrelation
# Fit model only using the last 10 years of the dataset, and hindcast the missing 10 years
set.seed(410)
n_years <- 20
year <- 1:n_years
# x is random walk
x <- cumsum(rnorm(n=n_years, mean=1, sd=3))
y <- 2 * x + 10 + rnorm(n=n_years, mean=0, sd=5)

# Using these x and y data, simulate random points drawn from normal distributions for each of the x and y.
# Use random sample sizes for each x and y data point
n_x <- rbinom(n_years, 20, 0.2) + 1
n_y <- rbinom(n_years, 25, 0.4) + 1

data_means <- data.frame(year = year, x = x, n_x = n_x, y = y, n_y = n_y)

# Create the "full" dataset by sampling n data points from each x and y value for each year.
# Use a consistent SD.

x_list <- list()
y_list <- list()
for (i in 1:n_years) {
  x_list[[i]] <- rnorm(n = data_means$n_x[i], mean = data_means$x[i], sd = 2)
  y_list[[i]] <- rnorm(n = data_means$n_y[i], mean = data_means$y[i], sd = 1)
}


# Average the data points back together and calculate the weights based on sample sizes.
x_final <- numeric(n_years)
y_final <- numeric(n_years)
for (i in 1:n_years) {
  x_final[i] <- mean(x_list[[i]])
  y_final[i] <- mean(y_list[[i]])
}

data_weighted <- data.frame(year = year, x = x_final, y = y_final, n_x = n_x, n_y = n_y,
                            w = 1/(((1/n_x) + (1/n_y))/2))  # Harmonic mean of sample size will be the weight.

pairs(data_weighted[,1:3])

library(brms)  
library(nlme)
library(boot)

# Fits to averaged data points, with weights
# Note: we are fitting only with years 11:20 and then predicting backwards to the other years
brmsfit_weight_ar1 <- brm(y | weights(w) ~ x + ar(time = year, p = 1), data = data_weighted[11:20, ], chains = 3, iter = 5000)

nlmefit_weight_ar1 <- gls(y ~ x, correlation = corAR1(form = ~ year), weights = varFixed(~ w), data = data_weighted[11:20, ])

# Without weights
brmsfit_noweight_ar1 <- brm(y ~ x + ar(time = year, p = 1), data = data_weighted[11:20, ], chains = 3, iter = 5000)

nlmefit_noweight_ar1 <- gls(y ~ x, correlation = corAR1(form = ~ year), data = data_weighted[11:20, ])

# Compare models by using predict methods

# Get fitted values with interval (credible interval for brms)
brmspred <- predict(brmsfit_weight_ar1, newdata = data_weighted, re_formula = NA)
nlmepred <- predict(nlmefit_weight_ar1, newdata = data_weighted)
brmsprednoweight <- predict(brmsfit_noweight_ar1, newdata = data_weighted, re_formula = NA)
nlmeprednoweight <- predict(nlmefit_noweight_ar1, newdata = data_weighted)

# # To get a confidence interval for nlme, we need to do a bootstrap.
# nlme_predict_boot_fn <- function(data, idx) {
#   fit <- gls(y ~ x, correlation = corAR1(form = ~ year), weights = varFixed(~ w), data = data[idx,])
#   predict(fit, newdata = data_weighted)
# }
# 
# nlmepred_boot <- boot(data_weighted[11:20, ], nlme_predict_boot_fn, R = 999)

# Plot observed and predicted values

library(ggplot2)

# Combine observed and fitted data into a single data frame
data_weighted_withfit <- cbind(data_weighted, brmspred, nlmepred, brmsprednoweight, nlmeprednoweight)
names(data_weighted_withfit) <- c('year', 'x', 'y_observed', 'n_x', 'n_y', 'w', 'y_fitted_brms', 'y_error_brms', 'y_fitted_q025_brms', 'y_fitted_q975_brms', 'y_fitted_nlme', 'y_fitted_brmsnoweight', 'y_error_brmsnoweight', 'y_fitted_q025_brmsnoweight', 'y_fitted_q975_brmsnoweight', 'y_fitted_nlmenoweight')

ggplot(data_weighted_withfit, aes(x = x)) +
  geom_point(aes(y = y_observed)) +
  geom_line(aes(y = y_fitted_brms), col = 'forestgreen') +
  geom_line(aes(y = y_fitted_q025_brms), col = 'forestgreen', linetype = 'dashed') +
  geom_line(aes(y = y_fitted_q975_brms), col = 'forestgreen', linetype = 'dashed') +
  geom_line(aes(y = y_fitted_nlme), col = 'goldenrod') +
  theme_minimal()

ggplot(data_weighted_withfit, aes(x = x)) +
  geom_point(aes(y = y_observed)) +
  geom_line(aes(y = y_fitted_brmsnoweight), col = 'forestgreen') +
  geom_line(aes(y = y_fitted_q025_brmsnoweight), col = 'forestgreen', linetype = 'dashed') +
  geom_line(aes(y = y_fitted_q975_brmsnoweight), col = 'forestgreen', linetype = 'dashed') +
  geom_line(aes(y = y_fitted_nlmenoweight), col = 'goldenrod') +
  theme_minimal()

# Make hierarchical model with all uncertainty ----------------------------


library(rstan)
# I don't know how to do this any other way but just writing the entire model specification out in Stan.

stan_ar1_model <- '
data {
  int<lower=0> N;
  vector[N] y;
}
parameters {
  real alpha;
  real beta;
  real<lower=0> sigma;
}
model {
  for (n in 2:N)
    y[n] ~ normal(alpha + beta * y[n-1], sigma);
}
'

# stan model with just the hierarchical uncertainty part, but no AR1 component
stan_weight_model_spec <- '
data {
  int<lower=0> n_x;     // total number of obs in x
  int<lower=0> n_y;     // total number of obs in y
  int<lower=0> n_years; // number of years
  vector[n_x] x;
  vector[n_y] y;
  int<lower=0> year_x[n_x];   // Indexing vector to match each data point in x to its year   
  int<lower=0> year_y[n_y];   // Indexing vector to match each data point in y to its year
}

parameters {
  real slope;
  real intercept;
  real<lower=0> sigma;      
  real<lower=0> sigma_x_year;
  real<lower=0> sigma_y_year;
  vector[n_years] x_avg;
  vector[n_years] y_avg;
  
}

model {
  // Priors
  // Do not specify for now (totally flat)
  
  // Likelihood
  // Model each observation in x and y as being drawn from a normal with mean equal to the average x or y for that year.
  for (i in 1:n_x) {
    x[i] ~ normal(x_avg[year_x[i]], sigma_x_year); 
  }
  
  for (i in 1:n_y) {
    y[i] ~ normal(y_avg[year_y[i]], sigma_y_year); 
  }
  
  // The actual regression.
  y_avg ~ normal(slope * x_avg + intercept, sigma);
}

generated quantities {
  // Given average x values for the missing years, we fill in the y values.
  for (i in 1:n_x_avgnew) {
    y_new[i] ~ normal(slope * n_x_avgnew[i] + intercept, sigma);
  }
}'


# Compile stan model
stan_model_weights_notemporal <- stan_model(model_name = 'weights_notemporal', model_code = stan_weight_model_spec)

# Convert data to stan format. Must contain n_x, n_y, n_years, x, y, year_x, and year_y.
# Again only use 11 through 20 to fit the model.
fakedata_for_stan <- list(n_x = sum(n_x[11:20]),
                          n_y = sum(n_y[11:20]),
                          n_years = length(11:20),
                          x = unlist(x_list[11:20]),
                          y = unlist(y_list[11:20]),
                          year_x = rep(11:20, n_x[11:20]) - 10,
                          year_y = rep(11:20, n_y[11:20]) - 10)

stan_fit_weights_notemporal <- sampling(stan_model_weights_notemporal, data = fakedata_for_stan, chains = 3, iter = 5000)

stan_summary_weights_notemporal <- summary(stan_fit_weights_notemporal)

# Do this again, using 11 to 20 to fit the model but including "missing" values for y in years 1 through 10. The year and x values are used to predict. So fitting and prediction are all done together.

fakedata_for_stan_withmissingyears <- list(n_x = sum(n_x),
                                           n_y = sum(n_y),
                                           n_years = 20,
                                           x = unlist(x_list),
                                           y = c(rep(NA, sum(n_y[1:10])), unlist(y_list[11:20])),
                                           year_x = rep(1:20, n_x),
                                           year_y = rep(1:20, n_y))

stan_fit_weights_notemporal_predictmissing <- sampling(stan_model_weights_notemporal, data = fakedata_for_stan_withmissingyears, chains = 3, iter = 5000)
