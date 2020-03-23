####Packages####
library(drc)
library(nlstools)
library(tidyverse)
library(broom)
library(tidyr)
library(dplyr)
library(GerminaR)
library(devtools)
library(germinationmetrics)
library(dr4pl)        # fitting curves to germination data
library(reshape2)
library(ggplot2)
library(survival)
library(lme4)         # for Linear Mixed-Effects Models using Eigen and S4
library(nlme)         # for Linear and Nonlinear Mixed Effects Models
library(purrr)
library(multcomp)     # for post-hoc test
library(multcompView) # letters for Tukey pairwise comparisons
library(agricolae)
library(reshape2)     # for reshaping data files
library(plyr)         # for combining data files
library(MASS)         # for box cox transformation
library(arm)          # for std coeffs
library(Hmisc)        # for correlations with significance levels
library(car)          # for correlation scatterplot
library(tibble)
library(cowplot)
library(forecast)     # finding the optimal lambda for boxcox

###### Functions #######
mean_no_na <- function(x) {mean(x, na.rm=T)}
se_no_na <- function(x) {sd(x, na.rm=T)/sqrt(length(na.omit(x)))}
bc <- function(vari,lambda) {return(((vari^lambda)-1)/lambda)}
RootSpline1 <- function (x, y, y0 = 0, verbose = TRUE) {
  ## given (x, y) data, find x where the linear interpolation crosses y = y0
  ## the default value y0 = 0 implies root finding
  ## since linear interpolation is just a linear spline interpolation
  ## the function is named RootSpline1
  if (is.unsorted(x)) {
    ind <- order(x)
    x <- x[ind]; y <- y[ind]
  }
  z <- y - y0
  ## which piecewise linear segment crosses zero?
  k <- which(z[-1] * z[-length(z)] <= 0)
  ## analytical root finding
  # based on y =  mx + b
  xr <- x[k] - z[k] * (x[k + 1] - x[k]) / (z[k + 1] - z[k])
  ## make a plot?
  if (verbose) {
    plot(x, y, "l"); abline(h = y0, lty = 2)
    points(xr, rep.int(y0, length(xr)))
  }
  ## return roots
  max(xr)
}


# GERMINATION DATA -----
### Set up working directory ####
#setwd("~/Dropbox/Plants + salt")
sorghum <- read.csv("sorghum.csv", check.names = FALSE)



# Model fitting ----
## I need to fit an exponential decay model to both the NaCl stress and the PEG stress
#Only working with NaCl stress 

library(tidyverse)
library(nlstools)
library(broom)

sorghum.tofit <- sorghum %>% subset(!(stress == "NaCl"))
sorghum.peg.tofit.avg <- sorghum.tofit %>% 
  group_by(potential) %>% 
  summarize_at(vars(max.germ_perc),
               funs("mean.germ.perc" = mean_no_na,
                    "se.germ.perc" = se_no_na))
sorghum.peg.tofit.avg$mean.germ.perc[sorghum.peg.tofit.avg$mean.germ.perc=="0"] <- 0.00001

#pull out ionic stress and the 2 farms. drop potentials less than -1.1
#ionic.sorg19 <- sorghum.19.LandF %>% subset(!(scenario == "PEG")) %>% filter_at(vars(potential), all_vars(. <1.1))
#ionic.sorg19.avg <- sorghum.19.avg %>% subset(!(scenario == "PEG")) %>% filter_at(vars(potential), all_vars(. <1.1))
#exponential model  y ~ a * exp(-b * x)
# y~yf+(y0 - yf) *exp(-alpha*t)
#y(t)∼yf+(y0−yf)e−αt -- the measured value y starts at y0 and decays towards yf at a rate of alpha
#t is x axis and y is y axis
exp.fit <- nls(mean.germ.perc ~ SSasymp(potential, yf, y0, log_alpha), data = sorghum.peg.tofit.avg)
summary(exp.fit)
exp.fit
#calculating alpha since equation is log alpha
exp(0.2679)
#yf = -7.9315; y0 = 109.7083; log_alpha = 0.2679; alpha = 1.307216
fit.test <- nls(mean.germ.perc ~ yf + (y0 - yf) * exp(-alpha * potential), 
                data = sorghum.peg.tofit.avg,
                start = list(y0=109.7083, yf=-7.9315, alpha = 1.307216))

qplot(potential, mean.germ.perc, data = augment(exp.fit)) + geom_line(aes(y=.fitted))
#creating a sequence of numbers from -4 to 0 in order to have a nicer curved line 
exp.fit.fitted <- seq(from = 0, to = -4, length.out = 1000)
#attempting to calculate CI
sorghum.peg.tofit.avg$pred <- predict(exp.fit)
se = summary(exp.fit)
ci = outer(sorghum.peg.tofit.avg$pred, c(outer(se, c(-1,1), '*'))*1.96, '+')
confint2(exp.fit, level = 0.95, method=c("asymptotic"))
tidy(exp.fit)
#Calculating RSS and AdjSS to calculate R^2
sum(resid(exp.fit)^2) #RSS = 581.4315
with(sorghum.peg.tofit.avg, sum((mean.germ.perc-mean(mean.germ.perc))^2)) #AdjSS = 6417.93
#R-squared calculated from 1-RSS/AdjSS
1-581.4315/6417.93 #r^2 = 0.91
#here's the code to calculate R-squared
with(sorghum.peg.tofit.avg, 1-sum(resid(exp.fit)^2)/sum((mean.germ.perc-mean(mean.germ.perc))^2))

#plotting
sorghum.19.allpts <- ggplot(sorghum.peg.tofit.avg, aes(potential, mean.germ.perc)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymax = mean.germ.perc + se.germ.perc, ymin = mean.germ.perc - se.germ.perc), color = "black", width = 0.2, position=position_dodge(0.1)) +
  geom_smooth(method = "nls", formula = y ~ yf+(y0 - yf) * exp(-alpha*x),
      method.args = list(start = c(yf = -7.9315, y0 = 109.7083, alpha = 1.307216)),
      se = FALSE) +
  #stat_smooth(method = "nls", formula = y ~ yf+(y0 - yf) * exp(-alpha*x),
              #level = 0.95,
              #method.args = list(start = c(yf = -7.9315, y0 = 109.7083, alpha = 1.307216)),
              #se=FALSE)+
  xlab("Water potentials (-MPa)") +
  ylab("Percent germination") 


# Bootstrap to get CI -----------------------------------------------------

# Fit with the full data
exp_fit_full <- nls(max.germ_perc ~ SSasymp(potential, yf, y0, log_alpha), data = sorghum.tofit)

# X values at which to predict y values, based on range of the data 
# We take 100 values so the curve appears smooth, more can be plotted if needed
x_range <- range(sorghum.tofit$potential)
x_pred <- seq(x_range[1], x_range[2], length.out = 100)

library(boot)

# Define a function to bootstrap sample the dataset, fit the model to the bootstrap sample, and get predicted values
get_fitted_values <- function(data, idx) {
  exp.fit <- nls(max.germ_perc ~ SSasymp(potential, yf, y0, log_alpha), data = data[idx, ])
  return(predict(exp.fit, newdata = list(potential = x_pred)))
}

# Run the bootstrap
set.seed(111)
(boot_pred_values <- boot(data = sorghum.tofit, statistic = get_fitted_values, R = 99, sim = 'ordinary'))

# Get the 95% confidence interval using the quantiles of each predicted value
# The values from each bootstrap iteration are the individual rows of boot_pred_values$t
# So each data point is a column.
# "tidy" way of getting the summary statistics for CI

boot_pred_summary <- data.frame(potential = x_pred, t(boot_pred_values$t)) %>%
  gather(iteration, fitted_value, -potential) %>%
  group_by(potential) %>%
  summarize(fitted_median = quantile(fitted_value, 0.5),
            fitted_ci_min = quantile(fitted_value, 0.025),
            fitted_ci_max = quantile(fitted_value, 0.975))

# Plot result

ggplot() +
  geom_line(data = boot_pred_summary, aes(x = potential, y = fitted_median)) +
  geom_line(data = boot_pred_summary, aes(x = potential, y = fitted_ci_min), linetype = 'dotted') +
  geom_line(data = boot_pred_summary, aes(x = potential, y = fitted_ci_max), linetype = 'dotted') +
  geom_point(data = sorghum.tofit, aes(x = potential, y = max.germ_perc))


# Logistic regression -----------------------------------------------------

library(lme4)
library(tidyverse)

# Load data (copied from above)
sorghum <- read.csv("sorghum.csv", check.names = FALSE)
sorghum.tofit <- sorghum %>% subset(!(stress == "NaCl"))
sorghum.peg.tofit.avg <- sorghum.tofit %>% 
  group_by(potential) %>% 
  summarize_at(vars(max.germ_perc),
               funs("mean.germ.perc" = mean_no_na,
                    "se.germ.perc" = se_no_na))
sorghum.peg.tofit.avg$mean.germ.perc[sorghum.peg.tofit.avg$mean.germ.perc=="0"] <- 0.00001


# convert to binary outcome
sorghum_binary <- sorghum.tofit %>%
  group_by(potential, dish.id) %>%
  group_modify(~ data.frame(germ = rep(c(1, 0), times = c(.x$max.germ, 25 - .x$max.germ))))

# Logistic regression with logit link function
logistic_fit <- glm(germ ~ potential, family = binomial(link = 'logit'), data = sorghum_binary)
summary(logistic_fit)

# Better:
# Logistic regression with logit link function and random effect for dish
# "Generalized linear mixed model" or GLMM
# See https://stats.idre.ucla.edu/r/dae/mixed-effects-logistic-regression/
# This models the underlying probability that each individual had of germinating, although we only observe 0 or 1 for each plant.
glmm_logistic_fit <- glmer(germ ~ potential + (1 | dish.id), family = binomial(link = 'logit'), data = sorghum_binary)

summary(glmm_logistic_fit) # The fixed effect term on potential is the slope, so potential has a high negative effect on probability of germinating

# X values at which to predict y values, based on range of the data 
# We take 100 values so the curve appears smooth, more can be plotted if needed
x_range <- range(sorghum.tofit$potential)
x_pred <- seq(x_range[1], x_range[2], length.out = 100)

# For each of these 100 x-values, get the prediction for each individual from each dish, if potential = x.
logistic_fitted_list <- map(x_pred, ~ predict(glmm_logistic_fit, newdata = data.frame(potential = .x, dish.id = sorghum_binary$dish.id), type = 'response'))

# For each of the 100 x-values, get the median value and the 2.5% and 97.5% quantiles (range in which 95% of predicted outcomes fell)
logistic_fitted_values <- map_dfr(logistic_fitted_list, ~ data.frame(fitted_median = quantile(.x, 0.5),
                                                                     fitted_ci_min = quantile(.x, 0.025),
                                                                     fitted_ci_max = quantile(.x, 0.975)))

# Add back in the x-value and plot a line for the median fit, and the upper and lower quantiles, along with the raw data
# Plot each replicate as a small black point, and the mean of the replicates at each potential value as a large red point
logistic_fitted_values <- cbind(potential = x_pred, logistic_fitted_values)

ggplot() +
  geom_line(data = logistic_fitted_values, aes(x = potential, y = fitted_median)) +
  geom_line(data = logistic_fitted_values, aes(x = potential, y = fitted_ci_min), linetype = 'dotted') +
  geom_line(data = logistic_fitted_values, aes(x = potential, y = fitted_ci_max), linetype = 'dotted') +
  geom_point(data = sorghum.peg.tofit.avg, aes(x = potential, y = mean.germ.perc/100), color = 'red', size = 3, pch = 1)# +
 # geom_jitter(data = sorghum.tofit, aes(x = potential, y = max.germ_perc/100), height = 0, width = 0.03)

# Plot with ribbon
ggplot() +
  geom_ribbon(data = logistic_fitted_values, aes(x = potential, ymax = fitted_ci_max, ymin = fitted_ci_min), alpha = 0.5, fill = 'blue') +
  geom_line(data = logistic_fitted_values, aes(x = potential, y = fitted_median)) +
  geom_point(data = sorghum.peg.tofit.avg, aes(x = potential, y = mean.germ.perc/100), color = 'red', size = 3, pch = 1)

# Marginal and conditional r-squared
library(MuMIn)
r.squaredGLMM(glmm_logistic_fit)
