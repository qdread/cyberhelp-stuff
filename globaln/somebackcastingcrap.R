library(forecast)

ts.weight.function <- function(x) {10 / (1 + exp(-x))} # Sigmoidal
ts.weights <- data.frame(trend = sapply(seq(-13, 14, length.out = 27), ts.weight.function))
ts.input <- ts(c(23957, 46771, 60767, 73284, 60296, 73122, 78304, 87154, 80459, 76885, 56479, 18809, 13453, 13951, 25140, 12035, 11920, 20683, 30357, 35019, 37732, 46150, 47856, 41931, 20985, 32526, 27283), frequency = 1)
ts.model <- tslm(formula = ts.input ~ log(trend), weights = unlist(ts.weights))


y <- ts(rnorm(120,0,3) + 1:120 + 20*sin(2*pi*(1:120)/12), frequency=12)
fit1 <- tslm(y ~ trend + season)
fit2 <- tslm(y ~ trend + season, weights = 1:120)
plot(forecast(fit1, h=20)) # Forecasts 20 time points into the future.
plot(forecast(fit2, h=20))

# Backcasting
# https://robjhyndman.com/hyndsight/backcasting/
# Newer version : https://otexts.com/fpp2/backcasting.html

# You have to reverse time.
rev_y <- ts(rev(rnorm(120,0,3) + 1:120 + 20*sin(2*pi*(1:120)/12)), frequency = 12)
fc_rev <- plot(forecast(tslm(rev_y ~ trend + season, weights = 1:120), h = 20))

h=20
f=12

# Reverse time again
fc_rev$mean <- ts(rev(fc_rev$mean),end=tsp(y)[1] - 1/f, frequency=f)
fc_rev$upper <- fc_rev$upper[h:1,]
fc_rev$lower <- fc_rev$lower[h:1,]
fc_rev$x <- y
# Plot result
plot(fc_rev, xlim=c(tsp(y)[1]-h/f, tsp(y)[2]))

#### Write script to make some fake data, with weights, and both forecast and backcast the values.
fakedata <- c(23957, 46771, 60767, 73284, 60296, 73122, 78304, 87154, 80459, 76885, 56479, 18809, 13453, 13951, 25140, 12035, 11920, 20683, 30357, 35019, 37732, 46150, 47856, 41931, 20985, 32526, 27283)
ts_input <- ts(fakedata, frequency = 1)
# Extremely fake weights
ts_weights <- (1:27)/27

ts_model <- tslm(ts_input ~ I(log(trend)), weights = ts_weights)

plot(forecast(ts_model, h = 10))

# Backcast.
ts_input_rev <- ts(rev(ts_input), frequency = 1)
ts_model_rev <- tslm(ts_input_rev ~ I(log(trend)), weights = rev(ts_weights))

ts_plot_rev <- plot(forecast(ts_model_rev, h = 10))

# Reverse time again
f <- 1 # Frequency
h <- 10 # N to predict
ts_plot_rev$mean <- ts(rev(ts_plot_rev$mean),end=tsp(ts_input)[1] - 1/f, frequency=f)
ts_plot_rev$upper <- ts_plot_rev$upper[h:1,]
ts_plot_rev$lower <- ts_plot_rev$lower[h:1,]
#ts_plot_rev$x <- ts_input
# Plot result
plot(ts_plot_rev, xlim=c(tsp(ts_input)[1]-h/f, tsp(ts_input)[2]))


### New try
# Function to reverse time
reverse_ts <- function(y)
{
  ts(rev(y), start=tsp(y)[1L], frequency=frequency(y))
}
# Function to reverse a forecast
reverse_forecast <- function(object)
{
  h <- length(object[["mean"]])
  f <- frequency(object[["mean"]])
  object[["x"]] <- reverse_ts(object[["x"]])
  object[["mean"]] <- ts(rev(object[["mean"]]),
                         end=tsp(object[["x"]])[1L]-1/f, frequency=f)
  object[["lower"]] <- object[["lower"]][h:1L,]
  object[["upper"]] <- object[["upper"]][h:1L,]
  return(object)
}

library(ggplot2)

# Backcast example
ts_rev <- ts_input %>%
  reverse_ts()
tslm(ts_rev ~ I(log(trend)), weights = rev(ts_weights)) %>%
  forecast() %>%
  reverse_forecast() -> bc
autoplot(bc) +
  ggtitle(paste("Backcasts from",bc[["method"]]))

# Forecast
tslm(ts_input ~ I(log(trend)), weights = ts_weights) %>%
  forecast() -> fc
autoplot(fc) +
  ggtitle(paste("Forecasts from",bc[["method"]]))

### Fake data with x and y
x_data <- as.numeric(ts_input) / 5 - 1000 + rnorm(27, 0, 50)

Arima(y = ts_input, xreg = x_data, weights = ts_weights)
