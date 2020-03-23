# Test a function to get the arguments for the S3 method(s) of a function, or just the formal arguments if it is not generic

get_args <- function(f) {
    
    f.methods <- try(getS3method(deparse(substitute(f)), "default"), silent=TRUE)
    
    return(class(f.methods))
    
    #return(names(formals(f.methods)))

}
