# Original script used to compute zonal statistics for protected areas

# Functions, packages, data
source('R/load-packages.R')
source('R/load-functions.R')
# Cutline
source('R/load-cutline.R')
# Protected areas
papath <- 'data/protected_areas/protected-areas.gpkg'
pa_for_filtering <- st_read(papath, 'Protected Areas', quiet = T) %>% st_transform(32619)
pa_for_filtering <- pa_for_filtering %>% mutate(ORIGINALAREASQM = st_area(geom) %>% units::drop_units())
pa_cline <- st_intersection(pa_for_filtering, cline)
pa_cline <- pa_cline %>% group_by(WDPAID) %>% summarise()
pa_cline <- pa_cline %>% mutate(AREAWITHINCLINE = st_area(geom) %>% units::drop_units())
pa_cline <- pa_for_filtering %>%
  inner_join(pa_cline %>% st_drop_geometry) %>% 
  mutate(PCTWITHINCLINE = AREAWITHINCLINE/ORIGINALAREASQM*100)
pa <- pa_cline %>%
  filter(PCTWITHINCLINE>30, ORIGINALAREASQM>3000000) #Excluding protected areas with less than 3 sq. km and less than 30% within cutline
pa <- pa %>% mutate(AREASQM = st_area(geom) %>% units::drop_units())
pa$ENLACE <- pa$WDPAID
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
l <- split(1:nrow(pa), sort(1:nrow(pa) %% UseCores+1))

# Tree cover for pctc threshold
cl <- makeCluster(UseCores)
registerDoParallel(cl)
clusterExport(cl, list('ezonalobj', 'tcforzonal', 'pa'))
system.time(
  foo <- parSapply(cl, l, function(x) {
    ezonalobj(
      objraster = tcforzonal,
      nombre = paste0('TREECOVER2000'),
      objgeometrias = pa[x,],
      export = F,
      cuali = T)},
    simplify = F)
)
#  user  system elapsed 
# 0.190   0.163 130.584 
stopCluster(cl)
patc <- pa %>%
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
clusterExport(cl, list('ezonalobj', 'ly', 'patc'))
system.time(
  foo <- parSapply(cl, l, function(x) {
    ezonalobj(
      objraster = ly,
      nombre = paste0('LOSSYEAR'),
      objgeometrias = patc[x,],
      export = F,
      cuali = T)},
    simplify = F)
)
#  user  system elapsed 
# 0.291   0.294 191.508 
stopCluster(cl)
paly <- patc %>%
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
clusterExport(cl, list('ezonalobj', 'lt', 'paly'))
system.time(
  foo <- parSapply(cl, l, function(x) {
    ezonalobj(
      objraster = lt,
      nombre = paste0('LOSS0118'),
      objgeometrias = paly[x,],
      export = F,
      cuali = T)},
    simplify = F)
)
#  user  system elapsed 
# 0.190   0.162 128.490 
stopCluster(cl)
palt <- paly %>%
  select(ENLACE) %>%
  inner_join(bind_rows(lapply(foo, st_drop_geometry))) %>% 
  rename_at(
    vars(matches('LOSS0118')),
    funs(paste0(., '_PCT'))) %>% 
  mutate_at(vars(matches('LOSS0118.*')), funs("AREASQM" = .*AREASQM/100)) %>% 
  rename_at(vars(matches('LOSS0118')), funs(gsub('_\\d+','', .)))
colnames(palt) <- gsub('PCT_AREA', 'AREA', colnames(palt))
rm(foo)

# Total loss 2012-2018
cl <- makeCluster(UseCores)
registerDoParallel(cl)
clusterExport(cl, list('ezonalobj', 'lt1218', 'palt'))
system.time(
  foo <- parSapply(cl, l, function(x) {
    ezonalobj(
      objraster = lt1218,
      nombre = paste0('LOSS1218'),
      objgeometrias = palt[x,],
      export = F,
      cuali = T)},
    simplify = F)
)
#  user  system elapsed 
# 0.182   0.175 131.128 
stopCluster(cl)
palt1218 <- palt %>%
  select(ENLACE) %>%
  inner_join(bind_rows(lapply(foo, st_drop_geometry))) %>% 
  rename_at(
    vars(matches('LOSS1218')),
    funs(paste0(., '_PCT'))) %>% 
  mutate_at(vars(matches('LOSS1218.*')), funs("AREASQM" = .*AREASQM/100)) %>% 
  rename_at(vars(matches('LOSS1218')), funs(gsub('_\\d+','', .)))
colnames(palt1218) <- gsub('PCT_AREA', 'AREA', colnames(palt1218))
rm(foo)

# Fires M6
pafirm6 <- bind_cols(
  palt1218,
  aggregate(
    firesm6sel2 %>%
      select(geometry) %>%
      mutate(NFIRESM6=1),
    palt1218, length) %>% st_drop_geometry())

# Fires V1
pafirv1 <- bind_cols(
  pafirm6,
  aggregate(
    firesv1sel2 %>%
      select(geometry) %>%
      mutate(NFIRESV1=1),
    pafirm6, length) %>% st_drop_geometry())

#saveRDS(pafirv1, 'out/pa_zonal_statistics.RDS')
