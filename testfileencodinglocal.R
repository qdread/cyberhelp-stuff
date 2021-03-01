# Brute force test all encodings
# Follows https://stackoverflow.com/questions/4806823/how-to-detect-the-right-encoding-for-read-csv

codepages <- setNames(iconvlist(), iconvlist())

filename <- "~/Documents/temp/taxonomy_table2020Oct14.csv"

# Loop through all possible encodings and read the csv with all of them.
x <- list()

for (i in 1:length(codepages)) {

  x[[i]] <- try(read.csv(filename,
                         fileEncoding=codepages[[i]])) # you get lots of errors/warning here
}

unique(do.call(rbind, sapply(x, dim)))

# The result should have 9737 rows, 18 columns
maybe_ok <- sapply(x, function(x) isTRUE(all.equal(dim(x), c(9737, 18))))
codepages[maybe_ok]
x_maybe_ok <- x[maybe_ok] # There are 67 possible encodings that are correct.


# Diff the vector of names from each encoding with the other one
taxtable <- read.csv('~/Documents/temp/taxonomy_table.csv')

diffs <- lapply(x_maybe_ok, function(x) sort(setdiff(x$user_supplied_name, taxtable$user_supplied_name)))
n_diffs <- sapply(diffs, length) # the fewest is 1

codepages_maybe_ok <- codepages[maybe_ok]
codepages_maybe_ok[n_diffs == min(n_diffs)]
