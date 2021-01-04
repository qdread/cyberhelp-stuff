functions { 
  matrix cov_matrix_ar1(real ar, real sigma, int nrows) { 
    matrix[nrows, nrows] mat; 
    vector[nrows - 1] gamma; 
    mat = diag_matrix(rep_vector(1, nrows)); 
    for (i in 2:nrows) { 
      gamma[i - 1] = pow(ar, i - 1); 
      for (j in 1:(i - 1)) { 
        mat[i, j] = gamma[i - j]; 
        mat[j, i] = gamma[i - j]; 
      } 
    } 
    return sigma^2 / (1 - ar^2) * mat; 
  }
} 

data { 
  int<lower=1> n;  // total number of observations 
  vector[n] y;  // response variable
  int<lower=1> nX;
  matrix[n,nX] X;
} 
transformed data {
  vector[n] se2 = rep_vector(0, n); 
} 
parameters { 
  vector[nX] beta;
  real<lower=0> sigma;  // residual SD 
  real <lower=-1,upper=1> phi;  // autoregressive effects 
} 
transformed parameters { 
} 
model {
  matrix[n, n] res_cov_matrix;
  matrix[n, n] Sigma; 
  vector[n] mu = X*beta;
  res_cov_matrix = cov_matrix_ar1(phi, sigma, n);
  Sigma = res_cov_matrix + diag_matrix(se2);
  Sigma = cholesky_decompose(Sigma); 
  
  // priors including all constants
  beta ~ student_t(3,30,30);
  sigma ~ cauchy(0,5);
  y ~ multi_normal_cholesky(mu,Sigma);
} 
generated quantities { 
}