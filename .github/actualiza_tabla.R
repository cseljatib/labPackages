## Update the date cell of a package row in the README.org table.
## Usage:  Rscript .github/actualiza_fecha.R <package>
## The README.org is located relative to this script, so the working
## directory does not matter. The date is written in UTC, with the hour.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1)
    stop("usage: Rscript actualiza_fecha.R <package>")
pkg <- args[1]

this.file <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
root <- dirname(dirname(normalizePath(this.file)))
readme <- file.path(root, "README.org")

l <- readLines(readme, warn = FALSE)
i <- grep(paste0("^\\| *", pkg, " *\\|"), l)
if (length(i) != 1)
    stop("the row of '", pkg, "' was not found in ", readme)

fecha <- format(Sys.time(), "%Y-%m-%d %H:%M", tz = "UTC")
l[i] <- sub("\\|[^|]*\\|$", paste0("| ", fecha, " UTC |"), l[i])
writeLines(l, readme)
cat("row of '", pkg, "' dated ", fecha, " UTC\n", sep = "")
