# Original script used to compute zonal statistics for provinces

# Functions, packages, data
# Function, packages
source('R/load-packages.R')
source('R/load-functions.R')
# Cutline
source('R/load-cutline.R')
# Provinces
admpath <- 'data/administrative/administrative.gpkg'
prov <- st_read(admpath, 'PROVCenso2010', quiet = T)
prov <- prov %>% mutate(AREASQM = st_area(geom) %>% units::drop_units())
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
l <- split(1:nrow(prov), sort(1:nrow(prov) %% UseCores+1))

# Tree cover for pctc threshold
cl <- makeCluster(UseCores)
registerDoParallel(cl)
clusterExport(cl, list('ezonalobj', 'tcforzonal', 'prov'))
system.time(
  foo <- parSapply(cl, l, function(x) {
    ezonalobj(
      objraster = tcforzonal,
      nombre = paste0('TREECOVER2000'),
      objgeometrias = prov[x,],
      export = F,
      cuali = T)},
    simplify = F)
)
#  user  system elapsed 
# 0.401   0.481 292.015 
stopCluster(cl)
provtc <- prov %>%
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
clusterExport(cl, list('ezonalobj', 'ly', 'provtc'))
system.time(
  foo <- parSapply(cl, l, function(x) {
    ezonalobj(
      objraster = ly,
      nombre = paste0('LOSSYEAR'),
      objgeometrias = provtc[x,],
      export = F,
      cuali = T)},
    simplify = F)
)
#  user  system elapsed 
# 0.543   0.561 354.570 
stopCluster(cl)
provly <- provtc %>%
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
clusterExport(cl, list('ezonalobj', 'lt', 'provly'))
system.time(
  foo <- parSapply(cl, l, function(x) {
    ezonalobj(
      objraster = lt,
      nombre = paste0('LOSS0118'),
      objgeometrias = provly[x,],
      export = F,
      cuali = T)},
    simplify = F)
)
#  user  system elapsed 
# 2.806   2.360 313.963 
stopCluster(cl)
provlt <- provly %>%
  select(ENLACE) %>%
  inner_join(bind_rows(lapply(foo, st_drop_geometry))) %>% 
  rename_at(
    vars(matches('LOSS0118')),
    funs(paste0(., '_PCT'))) %>% 
  mutate_at(vars(matches('LOSS0118.*')), funs("AREASQM" = .*AREASQM/100)) %>% 
  rename_at(vars(matches('LOSS0118')), funs(gsub('_\\d+','', .)))
colnames(provlt) <- gsub('PCT_AREA', 'AREA', colnames(provlt))
rm(foo)

# Total loss 2012-2018
cl <- makeCluster(UseCores)
registerDoParallel(cl)
clusterExport(cl, list('ezonalobj', 'lt1218', 'provlt'))
system.time(
  foo <- parSapply(cl, l, function(x) {
    ezonalobj(
      objraster = lt1218,
      nombre = paste0('LOSS1218'),
      objgeometrias = provlt[x,],
      export = F,
      cuali = T)},
    simplify = F)
)
#  user  system elapsed 
# 1.732   1.993 308.219 
stopCluster(cl)
provlt1218 <- provlt %>%
  select(ENLACE) %>%
  inner_join(bind_rows(lapply(foo, st_drop_geometry))) %>% 
  rename_at(
    vars(matches('LOSS1218')),
    funs(paste0(., '_PCT'))) %>% 
  mutate_at(vars(matches('LOSS1218.*')), funs("AREASQM" = .*AREASQM/100)) %>% 
  rename_at(vars(matches('LOSS1218')), funs(gsub('_\\d+','', .)))
colnames(provlt1218) <- gsub('PCT_AREA', 'AREA', colnames(provlt1218))
rm(foo)

# Fires M6
provfirm6 <- bind_cols(
  provlt1218,
  aggregate(
    firesm6sel2 %>%
      select(geometry) %>%
      mutate(NFIRESM6=1),
    provlt1218, length) %>% st_drop_geometry())

# Fires V1
provfirv1 <- bind_cols(
  provfirm6,
  aggregate(
    firesv1sel2 %>%
      select(geometry) %>%
      mutate(NFIRESV1=1),
    provfirm6, length) %>% st_drop_geometry())

#saveRDS(provfirv1, 'out/prov_zonal_statistics.RDS')