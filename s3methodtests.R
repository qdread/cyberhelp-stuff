my_fun <- function(f, params) {

    if (is.null(names(params)) || any(!names(params) %in% names(formals(f)))) {
        stop("names of params must match arguments of f")
    }
    
    do.call(f, params) 
       
}

my_fun(f = caret::train, params = list(x = data.frame(x = 1:10), y = rep(1,10), method = 'rf'))

my_fun(f = caret::train, params = list(x = data.frame(x = 1:10)))

####
# Edward solution
library(caret)
f <- caret::train
f.default <- try(getS3method(deparse(substitute(f)), "default"), silent=TRUE)

if(class(f.default)=="try-error")
    stop("Function f has no default method.")

ff <- formals(f.default)

fargs <- formalArgs(f.default)
pargs <- names(params)

my_fun <- function(f, params) {
    f.default <- try(getS3method(deparse(substitute(f)), "default"), silent=TRUE)
    
    if(class(f.default)=="try-error")
        stop("Function f has no default method.")
    
    ff <- formals(f.default)
    
    fargs <- formalArgs(f.default)
    pargs <- names(params)
    
    excessive.pargs <- setdiff(pargs, fargs)
    
    # Ignore non-optional arguments, including the "..."
    ff.symbol <- lapply(ff, is.symbol)
    ff.symbol$`...` <- FALSE 
    
    fargs <- fargs[unlist(ff.symbol)]
    missing.pargs <- setdiff(fargs, pargs)
    
    if (length(excessive.pargs)>0) 
        stop("You have extra arguments that don't match arguments of f: ", excessive.pargs)
    
    if (length(missing.pargs)>0)
        stop("Some arguments of f are missing with no default: ", missing.pargs)
    
    do.call(f, params) 
}

library(caret)

my_fun(f = train, params = list(x = data.frame(x = 1:10)))
#Error in my_fun(f = train, params = list(x = data.frame(x = 1:10))) : 
#Some arguments of f are missing with no no default:  y

my_fun(f = train, params = list(x = data.frame(x = 1:10), z="Invalid argument"))
#Error in my_fun(f = train, params = list(x = data.frame(x = 1:10), z = "Invalid argument")) : 
#You have extra arguments that don't match arguments of f:  z

my_fun(f = train, params = list(x = data.frame(x = 1:10), y = rep(1,10), method = 'rf'))
# Works


#### Axeman solution

my_fun <- function(f, params, env = parent.frame()) {
    # check for S3 generic
    if (!is.primitive(f) && isS3stdGeneric(f)) {
        s <- deparse(substitute(f))
        dispatch_arg <- formalArgs(f)[1]
        classes_to_check <- c(class(params[[dispatch_arg]]), 'default')
        for (i in seq_along(classes_to_check)) {
            f <- getS3method(s, classes_to_check[i], optional = TRUE, parent.frame(n = 2))
            if (is.function(f)) break
        }
    }
    if (is.null(names(params)) || !all(names(params) %in% formalArgs(f))) {
        stop("names of params must match arguments of f", call. = FALSE)
    }
    do.call(f, params)
}

library(caret)

my_fun(f = train, params = list(x = data.frame(x = 1:10), y = rep(1,10), method = 'rf'))
# works

my_fun(f = train, params = list(x = data.frame(x = 1:10)))
# argument "y" is missing, with no default

my_fun(f = log, params = list(x = 1:10))
