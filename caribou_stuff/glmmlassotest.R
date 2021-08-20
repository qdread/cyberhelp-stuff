# Implement the glmm lasso

# Run code to generate df.scaled for Western Arctic herd
# potentially could try https://topepo.github.io/caret/using-your-own-model-in-train.html (not used here)

# I think since there are so few values per group we don't necessarily have to worry about blocking the cross-validation folds.

# Load data and modify

load('~/temp/finalDF.rda')

library(glmmLasso)
library(dplyr)
library(stringr)

df2 = finalDF

xvars <- c('tmean_insect' , 'prcp_insect' , 'windspeed_insect' ,
           'ndays.hightemp_insect' , 'ndays.lowwind_insect' ,
           'tmean_summer' , 'prcp_summer' , 'windspeed_summer' ,
           'tmean_fall' , 'prcp_fall' , 'windspeed_fall' ,
           'tmean_winter' , 'prcp_winter' , 'windspeed_winter' ,
           'tmean_spring' , 'prcp_spring' , 'windspeed_spring' ,
           'tmean_migration' , 'prcp_migration' , 'windspeed_migration')

colnames(df2)[which(colnames(df2) %in% colnames(df2 %>% dplyr::select(ends_with('early summer'))))] <-
  str_replace(colnames(df2 %>% dplyr::select(ends_with('early summer'))),'early summer','insect')
colnames(df2)[which(colnames(df2) %in% colnames(df2 %>% dplyr::select(ends_with('late summer'))))] <-
  str_replace(colnames(df2 %>% dplyr::select(ends_with('late summer'))),'late summer','summer')
colnames(df2)
df2 <- df2 %>% dplyr::select(!starts_with('tmax') &! starts_with('tmin'))
getDev <- function(x) x - median(x, na.rm = TRUE)
df2 <- df2 %>% group_by(herd) %>% mutate(calving.deviation = getDev(calving.day))
getScaleDF <- function(df, myherd){
  newdf <- droplevels(na.omit(subset(df, herd == myherd)))
  scaled.covars <- as.data.frame(scale(newdf[,c(15:34)]))
  newdf <- droplevels(na.omit(cbind(as.data.frame(newdf[,c('ID_Year','ID','herd','Year', 'calving.day', 'calving.deviation')]), scaled.covars)))
  return(newdf)
}

df.scaled <- getScaleDF(df2, myherd = 'Western Arctic') # For testing

### Fit model
# Only ID used as random effect here.

full_formula <- formula(paste("calving.day ~", paste(xvars, collapse = "+")))

# Cross validation with different lambdas
lambdas <- c(1, 5, 10, 20, 50, 100, 300)

# For each lambda, do ten ten-fold cross-validation and find the RMSE.

tenfoldcvrmse <- function(lambda) {
  foldid <- sample(1:10, nrow(df.scaled), replace = TRUE)
  err <- c()
  for (fold in 1:10) {
    dat_train <- df.scaled[!(foldid %in% fold), ]
    dat_test <- df.scaled[foldid %in% fold, ]
    fit <- glmmLasso(fix = full_formula, 
              rnd = list(ID = ~ 1),
              data = dat_train,
              lambda = lambda)
    pred <- predict(fit, newdata = dat_test)
    err <- c(err, pred - dat_test$calving.day)
  }
  rmse <- sqrt(mean(err^2))
  message(paste('Completed one iteration of lambda =', lambda))
  return(rmse)
}

set.seed(111)

# For each lambda, do 10-fold CV 100 times and get the CV RMSE for each iteration.
rmses_all <- sapply(lambdas, function(lambda) replicate(100, tenfoldcvrmse(lambda)))

# Get the mean RMSE for each lambda
rmses <- apply(rmses_all, 2, mean)

cv_dat <- data.frame(lambda = lambdas, rmse = rmses)

# The final lambda is the one that minimizes RMSE
(lambda_best <- lambdas[which.min(rmses)])

# The final fit uses that lambda.
fit_final <- glmmLasso(fix = full_formula, 
                 rnd = list(ID = ~ 1),
                 data = df.scaled,
                 lambda = lambda_best)

# Which coefficients are included and excluded

fit_final$coefficients

# Included
names(fit_final$coefficients)[abs(fit_final$coefficients) > 0]

# Excluded
names(fit_final$coefficients)[fit_final$coefficients == 0]