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

# Reads the DESCRIPTION file out of a local .zip or .tar.gz package archive
# without fully extracting it, and returns it as a one-row data.frame (via
# read.dcf), or NULL if no DESCRIPTION file is found.
extract_description <- function(archive_path) {
  is_zip <- grepl("\\.zip$", archive_path, ignore.case = TRUE)
  extract_dir <- file.path(tempdir(), paste0("desc_", basename(archive_path), "_extract"))
  dir.create(extract_dir, showWarnings = FALSE, recursive = TRUE)

  if (is_zip) {
    entries <- unzip(archive_path, list = TRUE)$Name
    desc_entry <- entries[grepl("(^|/)DESCRIPTION$", entries)][1]
    if (is.na(desc_entry)) return(NULL)
    unzip(archive_path, files = desc_entry, exdir = extract_dir)
  } else {
    entries <- untar(archive_path, list = TRUE)
    desc_entry <- entries[grepl("(^|/)DESCRIPTION$", entries)][1]
    if (is.na(desc_entry)) return(NULL)
    untar(archive_path, files = desc_entry, exdir = extract_dir)
  }

  desc_path <- file.path(extract_dir, desc_entry)
  if (!file.exists(desc_path)) return(NULL)
  read.dcf(desc_path)
}

# Pulls package names out of the Depends/Imports/LinkingTo fields of a
# DESCRIPTION, stripping version constraints and base/recommended packages
# (which always ship with R and are never installed separately).
get_dependencies <- function(desc) {
  if (is.null(desc)) return(character(0))
  base_pkgs <- c(
    "R", "base", "stats", "methods", "utils", "graphics", "grDevices",
    "datasets", "tools", "parallel", "compiler", "splines", "tcltk", "grid"
  )
  deps <- character(0)
  for (field in c("Depends", "Imports", "LinkingTo")) {
    if (field %in% colnames(desc)) {
      val <- desc[1, field]
      if (!is.na(val) && nzchar(val)) {
        parts <- strsplit(val, ",")[[1]]
        parts <- trimws(gsub("\\(.*\\)", "", parts))
        deps <- c(deps, parts)
      }
    }
  }
  deps <- unique(deps[nzchar(deps)])
  deps[!deps %in% base_pkgs]
}

# Installs any of `deps` that aren't already available.
install_missing_dependencies <- function(deps) {
  if (length(deps) == 0) {
    message("  No extra dependencies to check.")
    return(invisible())
  }
  missing <- deps[!vapply(deps, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) == 0) {
    message("  All dependencies already installed.")
  } else {
    message("  Installing missing dependencies: ", paste(missing, collapse = ", "))
    install.packages(missing)
  }
}

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

  message("Checking dependencies for ", info$zip_name, " ...")
  install_missing_dependencies(get_dependencies(extract_description(dest)))

  message("Installing ", info$zip_name, " ...")
  install.packages(dest, repos = NULL, type = install_type)
}

message("Done: datana and biometrics installed/updated.")
