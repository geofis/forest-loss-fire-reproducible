# Original script used to compute zonal statistics for annual approach grid

# Functions, packages, data
source('R/load-packages.R')
source('R/load-functions.R')
# Cutline
source('R/load-cutline.R')
# Grid
hexsf <- readRDS('out/honeycomb_grid_sf.RDS') #Empty grid, no zonal statistics yet
# Patches of forest loss > 1 ha. Fires M6, by year, intersected by forest-loss patches >1ha + 2.5 km buffer
loss1ha_firesm6_2500_byyear <- readRDS('out/forest_loss_1ha_firesm6_2500_buffer_by_year.RDS')
# Patches of forest loss > 1 ha. Fires V1, by year, intersected by forest-loss patches >1ha + 2.5 km buffer
loss1ha_firesv1_2500_byyear <- readRDS('out/forest_loss_1ha_firesv1_2500_buffer_by_year.RDS')
# Cores
UseCores <- detectCores() -1

# Creating "patches of forest loss < 1 ha", a value layer used in selected analyses
# * Parallel
# yearlist <- paste0('year', 1:7)
# yearlist <- paste0('year', 8:14)
yearlist <- paste0('year', 15:18)
cl <- makeCluster(UseCores)
registerDoParallel(cl)
clusterExport(cl, list('clumpssmaller','ly'))
system.time(
  losssmaller1ha_byyear <- parSapply(cl, yearlist, function(x) {
    library(tidyverse)
    library(raster)
    library(sf)
    y <- as.numeric(gsub('year', '', x))
    l <- ly == y
    smaller1ha <- clumpssmaller(l, threshold = 10000)
    return(smaller1ha)
  }, simplify = F, USE.NAMES = T)
)
system('echo "Job finished" | mail -s "Job finished" zoneminderjr@gmail.com')
#   user  system elapsed 
# 22.530  18.640  98.646
# stopCluster(cl)
# saveRDS(losssmaller1ha_byyear, 'out/forest_loss_clumps_smaller_than_1ha_by_year_years_1_to_7.RDS')
# rm(losssmaller1ha_byyear)
# gc()
#   user  system elapsed 
# 22.246  18.729  99.417
# stopCluster(cl)
# saveRDS(losssmaller1ha_byyear, 'out/forest_loss_clumps_smaller_than_1ha_by_year_years_8_to_14.RDS')
# rm(losssmaller1ha_byyear)
#   user  system elapsed 
# 12.652  11.122  61.441 
# stopCluster(cl)
# saveRDS(losssmaller1ha_byyear, 'out/forest_loss_clumps_smaller_than_1ha_by_year_years_15_to_18.RDS')
# rm(losssmaller1ha_byyear)
losssmaller1ha_byyear <- c(
  readRDS('out/forest_loss_clumps_smaller_than_1ha_by_year_years_1_to_7.RDS'),
  readRDS('out/forest_loss_clumps_smaller_than_1ha_by_year_years_8_to_14.RDS'),
  readRDS('out/forest_loss_clumps_smaller_than_1ha_by_year_years_15_to_18.RDS')
)
# saveRDS(losssmaller1ha_byyear, 'out/forest_loss_clumps_smaller_than_1ha_by_year.RDS')

# ZONAL STATISTICS COMPUTATIONS
lhex <- split(1:nrow(hexsf), sort(1:nrow(hexsf) %% UseCores+1))

# Area of patches of forest loss > 1 Ha
system.time(
  foo <- sapply(
    grep('loss1ha', names(loss1ha_firesm6_2500_byyear), value = T),
    function(y) {
      assign('l', loss1ha_firesm6_2500_byyear[[y]], envir = .GlobalEnv)
      names(l) <- y
      cl <- makeCluster(UseCores)
      registerDoParallel(cl)
      clusterExport(cl, list('ezonalobj', 'l', 'hexsf'))
      foochild <- parSapply(cl, lhex, function(x) {
        ezonalobj(
          objraster = l,
          nombre = y,
          objgeometrias = hexsf[x,],
          export = F,
          cuali = T)},
        simplify = F)
      stopCluster(cl)
      barchild <- hexsf %>%
        select(ENLACE) %>%
        inner_join(bind_rows(lapply(foochild, st_drop_geometry))) %>%
        rename_at(
          vars(matches('loss1ha')),
          funs(paste0(., '_PCT'))) %>%
        mutate_at(vars(matches('loss1ha.*')), funs("AREASQM" = .*AREASQM/100)) %>%
        rename_at(vars(matches('loss1ha')), funs(gsub('_\\d+','', .))) %>%
        rename_all(funs(gsub('PCT_AREA', 'AREA', .)))
      return(barchild)
    }, simplify = F, USE.NAMES = T
  )
)
system('echo "Job finished" | mail -s "Job finished" zoneminderjr@gmail.com')
#    user   system  elapsed 
# 375.045  172.500 5250.877 
hexloss1ha <- hexelev %>% inner_join(Reduce(
  function(x, y, ...) merge(x, y, ...), 
  lapply(foo, st_drop_geometry)
) %>% select(-AREASQM, -xutm, -yutm))
hexloss1ha <- hexloss1ha %>% setNames(gsub('out/forest_lossha_firesm6_buffer.*RDS\\.', '', names(.)))
# saveRDS(hexloss1ha, 'out/zonal_statistics_step_by_step/hexloss1ha.RDS')
rm(foo)

# Fires M6
hexfiresm6 <- hexloss1ha %>% inner_join(Reduce(
  function(x, y, ...) merge(x, y, ...),
  sapply(
    grep('firesselection', names(loss1ha_firesm6_2500_byyear), value = T),
    function(x) {
      bind_cols(
        hexsf,
        aggregate(
          loss1ha_firesm6_2500_byyear[[x]] %>%
            select(geometry) %>%
            mutate(!!paste0('NFIRESM6_', gsub('\\.firesselection', '', x)):=1),
          hexsf, length) %>% st_drop_geometry()) %>% select(ENLACE, contains('NFIRESM6')) %>% st_drop_geometry()
    }, simplify = F, USE.NAMES = T)))
hexfiresm6 <- hexfiresm6 %>% setNames(gsub('out/forest_loss_1ha_firesm6_2500_.*RDS\\.', '', names(.)))
# saveRDS(hexfiresm6, 'out/zonal_statistics_step_by_step/hexfiresm6.RDS')
rm(loss1ha_firesm6_2500_byyear)
gc()

#Fires V1
hexfiresv1 <- hexfiresm6 %>% inner_join(Reduce(
  function(x, y, ...) merge(x, y, ...),
  sapply(
    grep('firesselection', names(loss1ha_firesv1_2500_byyear), value = T),
    function(x) {
      bind_cols(
        hexsf,
        aggregate(
          loss1ha_firesv1_2500_byyear[[x]] %>%
            select(geometry) %>%
            mutate(!!paste0('NFIRESV1_', gsub('\\.firesselection', '', x)):=1),
          hexsf, length) %>% st_drop_geometry()) %>% select(ENLACE, contains('NFIRESV1')) %>% st_drop_geometry()
    }, simplify = F, USE.NAMES = T)))
# saveRDS(hexfiresv1, 'out/zonal_statistics_step_by_step/hexfiresv1.RDS')
# rm(loss1ha_firesv1_2500_byyear)
# gc()

#Count clumps of forest loss smaller than 1 ha
# hexfiresv1 <- readRDS('out/zonal_statistics_step_by_step/hexfiresv1.RDS')
# losssmaller1ha_byyear <- readRDS('out/forest_loss_clumps_smaller_than_1ha_by_year.RDS')
system.time(
  foo <- sapply(
    names(losssmaller1ha_byyear),
    function(y) {
      assign('l', losssmaller1ha_byyear[[y]], envir = .GlobalEnv)
      names(l) <- y
      cl <- makeCluster(UseCores)
      registerDoParallel(cl)
      clusterExport(cl, list('ezonalclumps', 'l', 'hexsf'))
      foochild <- parSapply(cl, lhex, function(x) {
        ezonalclumps(
          objraster = l,
          nombre = paste0('NCLUMPSSMALLER1HA_', y),
          objgeometrias = hexsf[x,],
          export = F)},
        simplify = F)
      stopCluster(cl)
      barchild <- hexsf %>%
        select(ENLACE) %>%
        inner_join(bind_rows(lapply(foochild, st_drop_geometry)))
      return(barchild)
    }, simplify = F, USE.NAMES = T
  )
)
system('echo "Job finished" | mail -s "Job finished" zoneminderjr@gmail.com')
#    user   system  elapsed 
# 370.381  185.246 5708.141 
foo2 <- map(foo, function(x) x %>% mutate_at(vars(matches('NCLUMPSSMALLER1HA_')), funs(unlist)))
hexlosssmaller1ha <- hexfiresv1 %>% inner_join(Reduce(
  function(x, y, ...) merge(x, y, ...), 
  lapply(foo2, st_drop_geometry)
) %>% select(-AREASQM, -xutm, -yutm))
# saveRDS(hexlosssmaller1ha, 'out/zonal_statistics_step_by_step/hexlosssmaller1ha.RDS')
rm(foo)
rm(losssmaller1ha_byyear)
gc()
# saveRDS(hexlosssmaller1ha, 'out/hex_zonal_statistics.RDS')
