# Old crap below line that doesn't work -----------------------------------

df.scaled$Yearfactor <- factor(df.scaled$Year)

testlasso2 <- glmmLasso(fix = calving.day ~ tmean_insect + prcp_insect + windspeed_insect,
                        rnd = list(ID_Year=~1),
                        data = df.scaled,
                        lambda = 10)

# Try it out with GridLMM instead
library(GridLMM)

full_formula <- formula(paste("calving.day ~", paste(xvars, collapse = "+"), '+ (1|ID) + (1|Year)'))

# Provide single cross-validation breakdown, initially do this randomly, next we can get rid of individuals by ID
set.seed(111)
foldid <- sample(1:10, nrow(df.scaled), replace = TRUE)

# Elastic net grid search linear mixed model
x_data <- as.data.frame(df.scaled[,xvars])
row.names(x_data) <- df.scaled$ID_Year
testgrid <- GridLMMnet(formula = calving.day ~ (1|ID) + (1|Year), X = x_data, X_ID = "ID_Year", data = as.data.frame(df.scaled), alpha = 1, foldid = foldid, verbose = TRUE)
