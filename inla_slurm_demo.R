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
  
  inla(y~x, family = c("gaussian"), data = data, control.predictor=list(link=1))
}

# Define a data frame of parameters. There are 9 models to fit.
model_params <- expand.grid(mu_x = c(2,4,6), sigma_x = c(1, 2, 3))

inla_job_parallel <- slurm_apply(fit_inla_model, model_params,
                                 jobname = 'inla_parallel', nodes = 2, cpus_per_node = 4)

get_job_status(inla_job_parallel)

inla_models_parallel <- get_slurm_out(inla_job_parallel)

cleanup_files(inla_job_parallel) 
