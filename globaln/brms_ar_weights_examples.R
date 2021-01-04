# Example model in BRMS with temporal autocorrelation

set.seed(410)
year <- 1:50
# x is random walk
x <- cumsum(rnorm(n=50, mean=1, sd=3))
y <- 2 * x + 10 + rnorm(n=50, mean=0, sd=5)

# Weights set to increase linearly over time (stupid)
weights <- 1:50

library(brms)  

fakedata <-  data.frame(year=year,x=x, y=y, w=weights)

# Fit with no weights, no autocorrelation
# No priors. Assume Gaussian distribution (all defaults)
fit_noweight_noautocorr <- brm(y ~ x, data = fakedata, chains = 2, iter = 1000)

# Fit with no weights, yes autocorrelation (AR1)
fit_noweight_ar1 <- brm(y ~ x + ar(time = year, p = 1), data = fakedata, chains = 2, iter = 1000)

# Fit with yes weights, yes autocorrelations
fit_weight_ar1 <- brm(y | weights(w) ~ x + ar(time = year, p = 1), data = fakedata, chains = 2, iter = 1000)

### Look at the coefficient estimates of the different models
summary(fit_noweight_noautocorr)
summary(fit_noweight_ar1)
summary(fit_weight_ar1)

# Ugly default plots
mcmc_plot(fit_noweight_noautocorr)
mcmc_plot(fit_noweight_ar1)
mcmc_plot(fit_weight_ar1)

# Plot the coefficients (slope and intercept estimates, should be 2 and 10)
# Use tidybayes to get out the results

library(tidybayes)
library(tidyverse)


model_fixefs <- list(linear_fit = fit_noweight_noautocorr, noweight_ar1 = fit_noweight_ar1, weighted_ar1 = fit_weight_ar1) %>%
  map_dfr(~ spread_draws(., b_Intercept, b_x), .id = 'model') %>%
  pivot_longer(c(b_Intercept, b_x), names_to = 'parameter') %>%
  group_by(model, parameter) %>%
  summarize(q025 = quantile(value, 0.025), q50 = quantile(value, 0.5), q975 = quantile(value, 0.975))

ggplot(model_fixefs, aes(x = model, ymin = q025, y = q50, ymax = q975)) +
  facet_wrap(~ parameter, labeller = labeller(parameter = c(b_Intercept = 'intercept', b_x = 'slope')), nrow = 2, scales = 'free_y') +
  geom_pointrange() +
  theme_minimal()
  