# Installs / updates the 'datana' and 'biometrics' R packages
# from https://github.com/cseljatib/labPackages
#
# For each package:
#   1. Checks whether it is already installed.
#   2. If not installed, installs it from CRAN first.
#   3. Downloads the CURRENT zip file from the GitHub repo (auto-detected,
#      not hardcoded) and installs it with type = "win.binary".

# Use the "0-Cloud" CRAN mirror as the default repo (avoids any interactive
# mirror-selection prompt when installing from CRAN below).
options(repos = c(CRAN = "https://cloud.r-project.org"))

api_url  <- "https://api.github.com/repos/cseljatib/labPackages/contents"
json_file <- file.path(tempdir(), "labpackages_listing.json")

message("Looking up package files on GitHub...")
download.file(
  api_url,
  destfile = json_file,
  mode     = "wb",
  quiet    = TRUE,
  method   = "libcurl",
  headers  = c(
    "User-Agent" = "labpackages-installer",
    "Accept"     = "application/vnd.github.v3+json"
  )
)
json_text <- paste(readLines(json_file, warn = FALSE), collapse = " ")

find_pkg <- function(name_pattern, text) {
  full_pattern <- paste0(
    '"name":\\s*"(', name_pattern, ')"[^}]*?"download_url":\\s*"([^"]+)"'
  )
  mt <- regexpr(full_pattern, text, perl = TRUE)
  if (mt == -1) return(NULL)
  m <- regmatches(text, mt)
  name <- sub(paste0('.*"name":\\s*"(', name_pattern, ')".*'), '\\1', m, perl = TRUE)
  url  <- sub('.*"download_url":\\s*"([^"]+)".*', '\\1', m, perl = TRUE)
  list(name = name, url = url)
}

# Pick the right archive type / install type for the current platform:
# Windows -> .zip installed as a win.binary; Linux/Mac -> .tar.gz installed from source.
is_windows   <- .Platform$OS.type == "windows"
ext_pattern  <- if (is_windows) '\\.zip' else '\\.tar\\.gz'
install_type <- if (is_windows) "win.binary" else "source"

datana_info     <- find_pkg(paste0('datana_[^"]+', ext_pattern), json_text)
biometrics_info <- find_pkg(paste0('biometrics_[^"]+', ext_pattern), json_text)

if (is.null(datana_info))     stop("Could not find a matching datana_* archive in the repository listing.")
if (is.null(biometrics_info)) stop("Could not find a matching biometrics_* archive in the repository listing.")

pkgs <- list(
  datana     = list(zip_url = datana_info$url,     zip_name = datana_info$name),
  biometrics = list(zip_url = biometrics_info$url, zip_name = biometrics_info$name)
)

for (pkg_name in names(pkgs)) {
  info <- pkgs[[pkg_name]]

  if (!requireNamespace(pkg_name, quietly = TRUE)) {
    message("Installing ", pkg_name, " from CRAN first...")
    install.packages(pkg_name)
  } else {
    message(pkg_name, " is already installed.")
  }

  dest <- file.path(tempdir(), info$zip_name)
  message("Downloading ", info$zip_name, " ...")
  download.file(info$zip_url, destfile = dest, mode = "wb", quiet = TRUE)

  message("Installing ", info$zip_name, " ...")
  install.packages(dest, repos = NULL, type = install_type)
}

message("Done: datana and biometrics installed/updated.")
