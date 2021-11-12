# Original script used to compute zonal statistics for long-term approach grid

# Functions, packages, data
source('R/load-packages.R')
source('R/load-functions.R')
# Cutline
source('R/load-cutline.R')
# Grid
grd <- readRDS('out/grd_plain_only_area_known_in_R_as_grd.RDS')
grd
# tcforzonal
tc <- raster('out/treecover2000_crop.tif')
names(tc) <- 'TREECOVER2000'
pctc <- 25
tcforzonal <- tc
tcforzonal[tcforzonal < pctc] <- NA
tcforzonal[tcforzonal >= pctc] <- 1
#ly lt
ly <- raster('out/lossyear_crop.tif')
names(ly) <- 'LOSSYEAR'
lt <- ly
lt[lt > 0] <- 1
lt[lt == 0] <- NA
lt1218 <- ly
lt1218[ly <= 11] <- NA
lt1218[ly > 11] <- 1
# firess m6 and v1
firesm6sel2 <- st_read('out/fire_archive_M6_93308_DR_firesm6sel2.geojson')
firesv1sel2 <- st_read('out/fire_archive_V1_93309_DR_firesv1sel2.geojson')
# Cores
UseCores <- detectCores() -1

# Split for parallel computing
lgrd <- split(1:nrow(grd), sort(1:nrow(grd) %% UseCores+1))

# Tree cover for pctc threshold
cl <- makeCluster(UseCores)
registerDoParallel(cl)
clusterExport(cl, list('ezonalobj', 'tcforzonal', 'grd'))
system.time(
  foo <- parSapply(cl, lgrd, function(x) {
    ezonalobj(
      objraster = tcforzonal,
      nombre = paste0('TREECOVER2000'),
      objgeometrias = grd[x,],
      export = F,
      cuali = T)},
    simplify = F)
)
#  user  system elapsed 
# 0.472   0.429 285.587 
stopCluster(cl)
grdtc <- grd %>%
  select(ENLACE) %>%
  inner_join(bind_rows(lapply(foo, st_drop_geometry))) %>% 
  rename_at(
    vars(TREECOVER2000_1,`TREECOVER2000_<NA>`),
    funs(str_replace_all(
      c('TREECOVER2000_1', 'TREECOVER2000_<NA>'),
      c('_1'=paste0('_>=', pctc, '%TC_PCT'), '_<NA>'=paste0('_<', pctc, '%TC_PCT'))))) %>% 
  mutate_at(vars(matches('TREECOVER2000.*')), funs("AREASQM" = .*AREASQM/100)) %>% 
  rename_all(funs(gsub('PCT_AREA', 'AREA', .)))
rm(foo)

# Loss year
cl <- makeCluster(UseCores)
registerDoParallel(cl)
clusterExport(cl, list('ezonalobj', 'ly', 'grdtc'))
system.time(
  foo <- parSapply(cl, lgrd, function(x) {
    ezonalobj(
      objraster = ly,
      nombre = paste0('LOSSYEAR'),
      objgeometrias = grdtc[x,],
      export = F,
      cuali = T)},
    simplify = F)
)
#  user  system elapsed 
# 1.096   1.163 665.252 
stopCluster(cl)
grdly <- grdtc %>%
  select(ENLACE) %>%
  inner_join(bind_rows(lapply(foo, st_drop_geometry))) %>% 
  rename_at(
    vars(matches('LOSSYEAR')),
    funs(paste0(., '_PCT'))) %>% 
  mutate_at(vars(matches('LOSSYEAR.*')), funs("AREASQM" = .*AREASQM/100)) %>% 
  rename_all(funs(gsub('PCT_AREA', 'AREA', .)))
rm(foo)

# Total loss 2001-2018
cl <- makeCluster(UseCores)
registerDoParallel(cl)
clusterExport(cl, list('ezonalobj', 'lt', 'grdly'))
system.time(
  foo <- parSapply(cl, lgrd, function(x) {
    ezonalobj(
      objraster = lt,
      nombre = paste0('LOSS0118'),
      objgeometrias = grdly[x,],
      export = F,
      cuali = T)},
    simplify = F)
)
#  user  system elapsed 
# 0.468   0.432 286.941 
stopCluster(cl)
grdlt <- grdly %>%
  select(ENLACE) %>%
  inner_join(bind_rows(lapply(foo, st_drop_geometry))) %>% 
  rename_at(
    vars(matches('LOSS0118')),
    funs(paste0(., '_PCT'))) %>% 
  mutate_at(vars(matches('LOSS0118.*')), funs("AREASQM" = .*AREASQM/100)) %>% 
  rename_at(vars(matches('LOSS0118')), funs(gsub('_\\d+','', .))) %>% 
  rename_all(funs(gsub('PCT_AREA', 'AREA', .)))
rm(foo)

# Total loss 2012-2018
cl <- makeCluster(UseCores)
registerDoParallel(cl)
clusterExport(cl, list('ezonalobj', 'lt1218', 'grdlt'))
system.time(
  foo <- parSapply(cl, lgrd, function(x) {
    ezonalobj(
      objraster = lt1218,
      nombre = paste0('LOSS1218'),
      objgeometrias = grdlt[x,],
      export = F,
      cuali = T)},
    simplify = F)
)
#  user  system elapsed 
# 0.417   0.499 291.198 
stopCluster(cl)
grdlt1218 <- grdlt %>%
  select(ENLACE) %>%
  inner_join(bind_rows(lapply(foo, st_drop_geometry))) %>% 
  rename_at(
    vars(matches('LOSS1218')),
    funs(paste0(., '_PCT'))) %>% 
  mutate_at(vars(matches('LOSS1218.*')), funs("AREASQM" = .*AREASQM/100)) %>% 
  rename_at(vars(matches('LOSS1218')), funs(gsub('_\\d+','', .))) %>% 
  rename_all(funs(gsub('PCT_AREA', 'AREA', .)))
rm(foo)

# Fires M6
grdfirm6 <- bind_cols(
  grdlt1218,
  aggregate(
    firesm6sel2 %>%
      dplyr::select(geometry) %>%
      mutate(NFIRESM6=1),
    grdlt1218, length) %>% st_drop_geometry())

# Fires V1
grdfirv1 <- bind_cols(
  grdfirm6,
  aggregate(
    firesv1sel2 %>%
      dplyr::select(geometry) %>%
      mutate(NFIRESV1=1),
    grdfirm6, length) %>% st_drop_geometry())

# Generate the final grdzonal object
grdzonal <- grdfirv1 %>%
  mutate(X_UTM=st_coordinates(st_centroid(geometry))[,1], Y_UTM=st_coordinates(st_centroid(geometry))[,2]) %>%
  mutate(X_KM=(X_UTM-min(X_UTM, na.rm=T))/1000, Y_KM=(Y_UTM-min(Y_UTM, na.rm=T))/1000) %>%
  mutate(X_KM_P2=X_KM^2, Y_KM_P2=Y_KM^2) %>% 
  mutate_at(vars(matches('NFIRES??')), funs("PSQKM" = ./(AREASQM/1000000))) %>% 
  mutate(NFIRESM6_PSQKM_PYR=NFIRESM6_PSQKM/18, NFIRESV1_PSQKM_PYR=NFIRESV1_PSQKM/7) %>% 
  mutate_at(vars(matches('PCT')), funs("PUA" = ./100)) %>% #Proportion per unit area
  rename_all(funs(gsub('PCT_PUA', 'PUA', .))) %>%
  mutate_at(vars(matches('0118.*')), funs("PYR" = ./18)) %>% #Per year
  mutate_at(vars(matches('1218.*')), funs("PYR" = ./7)) #Per year
# saveRDS(grdzonal, 'out/grd_zonal_statistics.RDS')
