pkgs <- c('stars', 'sf', 'raster', 'SpaDES', 'gdalUtils', 'MASS', 'leaps', 'kableExtra',
          'caret', 'tmap', 'plyr', 'tidyverse', 'spdep', 'nortest', 'ez',
          'doParallel', 'foreach', 'rcompanion', 'cowplot', 'lme4', 'lmerTest',
          'car', 'gridExtra', 'grid', 'cowplot', 'mFilter', 'janitor', 'scales')
install_load_pkg <- function(pkg){
  new_pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new_pkg))
    install.packages(new_pkg, dependencies = TRUE)
  sapply(pkg, function(x) suppressPackageStartupMessages(require(x, character.only = TRUE)))
}
invisible(install_load_pkg(pkgs))
sapply(pkgs, function(x) try(library(x, character.only=T)))