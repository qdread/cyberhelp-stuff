# Script to demonstrate 10-fold cross validation on a mixed effects model with lme4

# Procedure: 
# 1. Split data into ten "folds," or randomly chosen subsets of the data, all with roughly the same size
# 2. Fit the mixed effects model on the data 10 times. Each time, hold out one of the folds. (So each model is fit with ~90% of the data)
# 3. For each of the 10 fits, predict the y values for the unused 10% of the data from the fold that was held out.
# 4. Now that you have a predicted and true value for all the data points, calculate the root mean squared error. 

# This tells you how well the model did at predicting values from out-of-sample data (meaning data that were not used to fit the model)

#### Example with fake data

# Create some fake data -- with block as random effect, x1 and x2 as fixed effects, and y as outcome
set.seed(2)
n <- 1234 
x1 <- 1:n + rnorm(n, mean=0, sd=5)
x2 <- 10 + rnorm(n, mean=0, sd=5)
block <- rep_len(letters[1:10], n)
y <- 2 * x1 + -1 * x2 + rnorm(n, mean=0, sd=2)

dat <- data.frame(y=y, x1=x1, x2=x2, block=block)

### 1. Assign each data point to one of ten folds
fold_ID <- sample(rep_len(1:10, nrow(dat)))
table(fold_ID) # As you can see these are as evenly divided as possible.

dat$fold <- fold_ID

### 2. Fit the mixed effects model 10 times, each time holding out one fold.
# We will do this with a for loop. Each time through the for loop, we will fit a few different models and compare them.

model_fits <- list() # Initialize empty list

library(lme4)

for (i in 1:10) {
  dat_holdout <- subset(dat, !fold_ID == i) # Hold out fold i.
  
  # Fit models
  null_model <- lmer(y ~ (1 | block), data = dat_holdout) # Null model with no fixed effects
  model1 <- lmer(y ~ x1 + (1 | block), data = dat_holdout) # Only x1 as fixed effect
  model2 <- lmer(y ~ x2 + (1 | block), data = dat_holdout) # Only x2 as fixed effect
  model3 <- lmer(y ~ x1 + x2 + (1 | block), data = dat_holdout) # x1 and x2 as fixed effect
  model4 <- lmer(y ~ x1 + x2 + x1:x2 + (1 | block), data = dat_holdout) # x1, x2, and interaction effect, as fixed effect
  
  # Save model results in list
  model_fits[[i]] <- list(null_model = null_model, model1 = model1, model2 = model2, model3 = model3, model4 = model4)
}

### 3. Use the model to predict the holdout values for each model, and calculate the squared error for each data point.

squared_errors <- list() # Initialize empty list

for (i in 1:10) {
  dat_to_predict <- subset(dat, fold_ID == i) # Get the 10% of data in fold i.
  
  # Predicted values for each data point for each of the models.
  predicted_values_i <- data.frame(null_model = predict(model_fits[[i]]$null_model, dat_to_predict, type = 'response'),
                                   model1 = predict(model_fits[[i]]$model1, dat_to_predict, type = 'response'),
                                   model2 = predict(model_fits[[i]]$model2, dat_to_predict, type = 'response'),
                                   model3 = predict(model_fits[[i]]$model3, dat_to_predict, type = 'response'),
                                   model4 = predict(model_fits[[i]]$model4, dat_to_predict, type = 'response'))
  
  # Calculate the difference between predicted and true value for each model.
  # The following line of code subtracts the column of observed values (y) from each column of the predicted values dataframe.
  errors_i <- sweep(predicted_values_i, 1, dat_to_predict$y, `-`)
  
  # Take the square of the errors and save it in the list
  squared_errors[[i]] <- errors_i^2
  
}

# 4. Combine the prediction error values for each fold into one data frame, then calculate root mean squared error (RMSE) for each model.

squared_errors_all <- do.call(rbind, squared_errors) # Combines the list of 10 squared error dataframes into one dataframe

# Calculate root mean squared error for each column.
apply(squared_errors_all, 2, function(x) sqrt(mean(x)))

# This result shows that the model with only x2 as predictor does not improve the null model. (I set up the fake data on purpose to show this) -- model2 has about the same RMSE as null model.
# However if you add x1 as predictor, it does a lot better (model1). If you add x1 and x2 together, it does even better (model3).
# But adding the interaction effect on top of the two separate predictors does not improve the RMSE. (model3 and model4 have about the same RMSE -- I also set up the fake data on purpose to do this!)