# Original script used to create the hotspot/fire layers M6 and V1 for the annual analytical approach

# Functions, packages, data
source('R/load-packages.R')
source('R/load-functions.R')

#ly lt
ly <- raster('out/lossyear_crop.tif')
names(ly) <- 'LOSSYEAR'

# Cores
UseCores <- detectCores() -1

# Fires M6
firesm6sel <- st_read('out/fire_archive_M6_93308_DR_manually_removed_chimneys_landfills_dates_conf_30_aka_firesm6sel.geojson')
# Patches of forest loss > 1 ha. Fires M6, by year, intersected by patches + 2.5 km buffer
# * Parallel processing
# yearlist <- paste0('year', 1:7)
# yearlist <- paste0('year', 8:14)
# yearlist <- paste0('year', 15)
# yearlist <- paste0('year', 16)
# yearlist <- paste0('year', 17)
yearlist <- paste0('year', 18)
cl <- makeCluster(UseCores)
registerDoParallel(cl)
clusterExport(cl, list('clumpsgreater', 'selectbuffer', 'ly', 'firesm6sel'))
system.time(
  loss1ha_firesm6_2500_byyear <- parSapply(cl, yearlist, function(x) {
    library(tidyverse)
    library(raster)
    library(sf)
    y <- as.numeric(gsub('year', '', x))
    l <- ly == y
    gre1ha <- clumpsgreater(l, threshold = 10000)
    pointssyear <- firesm6sel %>%
      filter(ACQ_DATE>=paste0(2000 + y, '-01-01') & ACQ_DATE<=paste0(2000 + y, '-12-31'))
    sel <- selectbuffer(src = gre1ha, dist = 2500, points = pointssyear)
    return(list(loss1ha=gre1ha, firesselection=sel))
  }, simplify = F, USE.NAMES = T)
)
#   user   system  elapsed 
# 31.774   26.721 1320.473 
#  user  system elapsed 
# 9.633   8.742 710.707 
stopCluster(cl)
loss1ha_firesm6_2500_byyear
# saveRDS(loss1ha_firesm6_2500_byyear, 'out/forest_loss_1ha_firesm6_2500_buffer_by_year_years_1_to_7.RDS')
# saveRDS(loss1ha_firesm6_2500_byyear, 'out/forest_loss_1ha_firesm6_2500_buffer_by_year_years_8_to_14.RDS')
# saveRDS(loss1ha_firesm6_2500_byyear, 'out/forest_loss_1ha_firesm6_2500_buffer_by_year_years_15.RDS')
# saveRDS(loss1ha_firesm6_2500_byyear, 'out/forest_loss_1ha_firesm6_2500_buffer_by_year_years_16.RDS')
# saveRDS(loss1ha_firesm6_2500_byyear, 'out/forest_loss_1ha_firesm6_2500_buffer_by_year_years_17.RDS')
# saveRDS(loss1ha_firesm6_2500_byyear, 'out/forest_loss_1ha_firesm6_2500_buffer_by_year_years_18.RDS')
rm(loss1ha_firesm6_2500_byyear)
gc()
# STOP!!!
lossfiresm6path <- list.files('out', pattern = 'forest_loss_1ha_firesm6.*years_.*RDS$',
                              full.names = T) %>% gtools::mixedsort()
loss1ha_firesm6_2500_byyear <- sapply(lossfiresm6path, readRDS)
loss1ha_firesm6_2500_byyear <- unlist(unlist(loss1ha_firesm6_2500_byyear, recursive = F), recursive = F)
names(loss1ha_firesm6_2500_byyear) <- gsub('out.*RDS.', '', names(loss1ha_firesm6_2500_byyear))
# saveRDS(loss1ha_firesm6_2500_byyear, 'out/forest_loss_1ha_firesm6_2500_buffer_by_year.RDS')
# saveRDS(loss1ha_firesm6_2500_byyear[[2]], 'out/forest_loss_1ha_firesm6_2500_buffer_year_2001.RDS') # For illustration purposes
# rm(loss1ha_firesm6_2500_byyear)
# gc()

# Fires V1
firesv1sel <- st_read('out/fire_archive_V1_93309_DR_manually_removed_chimneys_landfills_dates_conf_n_h_aka_firesv1sel.geojson')
# Patches of forest loss > 1 ha. Fires V1, by year, intersected by patches + 2.5 km buffer
# * Parallel
# yearlist <- paste0('year', 12:15)
# yearlist <- paste0('year', 16:18)
cl <- makeCluster(UseCores)
registerDoParallel(cl)
clusterExport(cl, list('clumpsgreater', 'selectbuffer', 'ly', 'firesv1sel'))
system.time(
  loss1ha_firesv1_2500_byyear <- parSapply(cl, yearlist, function(x) {
    library(tidyverse)
    library(raster)
    library(sf)
    y <- as.numeric(gsub('year', '', x))
    l <- ly == y
    gre1ha <- clumpsgreater(l, threshold = 10000)
    pointssyear <- firesv1sel %>%
      filter(ACQ_DATE>=paste0(2000 + y, '-01-01') & ACQ_DATE<=paste0(2000 + y, '-12-31'))
    sel <- selectbuffer(src = gre1ha, dist = 2500, points = pointssyear)
    return(list(loss1ha=gre1ha, firesselection=sel))
  }, simplify = F, USE.NAMES = T)
)
system('echo "Job finished" | mail -s "Job finished" zoneminderjr@gmail.com')
#   user  system elapsed 
# 15.387  13.342 609.061
#   user   system  elapsed 
# 14.871   13.439 1050.415 
stopCluster(cl)
loss1ha_firesv1_2500_byyear
# saveRDS(loss1ha_firesv1_2500_byyear, 'out/forest_loss_1ha_firesv1_2500_buffer_by_year_years_12_to_15.RDS')
# saveRDS(loss1ha_firesv1_2500_byyear, 'out/forest_loss_1ha_firesv1_2500_buffer_by_year_years_16_to_18.RDS')
# rm(loss1ha_firesv1_2500_byyear)
# gc()
# STOP!!!!
lossfiresv1path <- list.files('out', pattern = 'forest_loss_1ha_firesv1.*years_.*RDS$', full.names = T)
loss1ha_firesv1_2500_byyear <- sapply(lossfiresv1path, readRDS)
loss1ha_firesv1_2500_byyear <- unlist(unlist(loss1ha_firesv1_2500_byyear, recursive = F), recursive = F)
names(loss1ha_firesv1_2500_byyear) <- gsub('out.*RDS.', '', names(loss1ha_firesv1_2500_byyear))
# saveRDS(loss1ha_firesv1_2500_byyear, 'out/forest_loss_1ha_firesv1_2500_buffer_by_year.RDS')
# saveRDS(loss1ha_firesv1_2500_byyear[[2]], 'out/forest_loss_1ha_firesv1_2500_buffer_year_2012.RDS') # For illustration purposes
# rm(loss1ha_firesv1_2500_byyear)