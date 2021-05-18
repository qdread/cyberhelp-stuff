# Load final dataset from package
load('~/temp/finalDF.rda')

library(caret)
library(glmnet)
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
  newdf <- droplevels(na.omit(cbind(newdf[,c('ID_Year','ID','herd','Year', 'calving.day', 'calving.deviation')], scaled.covars)))
  return(newdf)
}

df.scaled <- getScaleDF(df2, myherd = 'Western Arctic') # For testing

set.seed(410)
# type.measure deviance uses squared error to measure fit.
# alpha = 1 represents the lasso
cv1 <- cv.glmnet(x=as.matrix(df.scaled[,xvars]), y=df.scaled$calving.day, alpha = 1,
                type.measure="deviance", nfolds = 5, lambda = seq(0.001,1,by = 0.001),
                standardize=FALSE)

set.seed(123)

fixed_effects <- paste(xvars, collapse = '+')
random_effects <- '(1|ID) + (1|Year)'
full_formula <- formula(paste('calving.day ~', fixed_effects, '+', random_effects))

model <- train(
  full_formula, data = df.scaled[, c('calving.day', 'ID', 'Year', xvars)], method = "glmnet",
  trControl = trainControl("cv", number = 10),
  tuneLength = 10
)
# Best tuning parameter
model$bestTune

coef(model$finalModel, model$bestTune$lambda)

######################

# stepwise with caret

modelstep <- train(
  calving.day ~ ., data = df.scaled[, c('calving.day', xvars)], method = "lmStepAIC",
)

# model averaging with dredge, only go up to 6
library(MuMIn)

full_formula <- formula(paste("calving.day ~", paste(xvars, collapse = "+")))
dredge_max6 <- dredge(full_formula, data = df.scaled, m.lim = c(0, 6))