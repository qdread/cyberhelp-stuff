# Demo script for running INLA on the Slurm cluster

library(INLA)
library(rslurm)

N = 10000 
x = rnorm(N, mean=6,sd=2)
y = rnorm(N, mean=x,sd=1) 
data = list(x=x,y=y,N=N)

##### Single function call, local. Takes 30 seconds to run
inla_model1 <- inla(y~x, family = c("gaussian"), data = data, control.predictor=list(link=1)) 

##### Single function call, run on slurm cluster
inla_job <- slurm_call(inla, params = list(formula = y~x, family = c("gaussian"), data = data, control.predictor = list(link = 1)))

get_job_status(inla_job) # Run this as many times as you need, while the job is in progress, to check on it.

# Run this on
inla_model2 <- get_slurm_out(inla_job) # Get output of the slurm job from the folder where it is saved.
class(inla_model2) <- "inla" # rslurm did not recognize the class of the output.

cleanup_files(inla_job) # Do this to delete the intermediate files.

##### Example of using slurm_apply to fit multiple INLA models in parallel

# Define a function
fit_inla_model <- function(mu_x, sigma_x) {
  N <- 1000
  x <- rnorm(N, mean = mu_x, sd = sigma_x)
  y <- rnorm(N, mean = x, sd = 1)
  data <- list(x = x, y = y, N = N)
  
  modelfit <- inla(y~x, family = c("gaussian"), data = data, control.predictor=list(link=1))
}

# Define a data frame of parameters. There are 9 models to fit.
model_params <- expand.grid(mu_x = c(2,4,6), sigma_x = c(1, 2, 3))

inla_job_parallel <- slurm_apply(fit_inla_model, model_params, global_objects = "mydata",
                                 jobname = 'inla_parallel', nodes = 2, cpus_per_node = 4)

get_job_status(inla_job_parallel)

inla_models_parallel <- get_slurm_out(inla_job_parallel)

cleanup_files(inla_job_parallel) 

##### Additional example

# reading a CSV and passing the data frame to each job
# Also write fitted values from each model fit to a CSV within the job

my_data <- read.csv('fake_data.csv') # Read CSV

# Assume my_data has a column called year with values from 1991 to 2020.

years <- data.frame(year = 1991:2020)

# Define a function
fit_model_holdout_year <- function(year) {
    
    data <- my_data[my_data$year != year, ] # Hold out the year provided as an argument
    
    modelfit <- inla(y~x, family = c("gaussian"), data = data, control.predictor=list(link=1))
    
    # Write the fitted values to a CSV named with the year that's held out.
    output_file_name <- paste0('fitted_values_holdout_', year, '.csv')
    write.csv(modelfit$summary.fitted.values, file.path('/nfs/infectiousdiseases-data/blablabla', output_file_name))
}

# Run the job for each of the years.
inla_job_byyear <- slurm_apply(fit_model_holdout_year, years, global_objects = "my_data",
                               jobname = 'inla_parallel', nodes = 2, cpus_per_node = 4)

# To check status while job is running:
get_job_status(inla_job_byyear)

# You don't need to get_slurm_out because the relevant output was written to CSV
# Clean up internal job files when job is done:
cleanup_files(inla_job_byyear)
