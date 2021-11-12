# Original script used to create the hotspot/fire layers M6 and V1 for the long-term analytical approach

# Functions, packages, data
source('R/load-packages.R')
source('R/load-functions.R')

# Fires M6
# Manually removed chimneys and landfills
firesm6manrem <- st_read('out/fire_archive_M6_93308_DR_manually_removed_chimneys_landfills.geojson')
firesm6sel <- firesm6manrem %>%
  filter(ACQ_DATE>='2001-01-01' & ACQ_DATE<='2018-12-31', CONFIDENCE >= 30)
# firesm6sel %>% st_write('out/fire_archive_M6_93308_DR_manually_removed_chimneys_landfills_dates_conf_30_aka_firesm6sel.geojson')
# firesm6sel <- st_read('out/fire_archive_M6_93308_DR_manually_removed_chimneys_landfills_dates_conf_30_aka_firesm6sel.geojson')
#Next, let's keep thermal anomalies occuring only inside tcforzonalmask, that is, within forest.
#More: https://gis.stackexchange.com/questions/252900/extracting-spatial-points-that-match-raster-value-using-r
firesm6sel2index <- which(raster::extract(tcforzonal == 1, firesm6sel) == 1)
firesm6sel2 <- firesm6sel[firesm6sel2index,]
firesm6sel2
# firesm6sel2 %>% st_write('out/fire_archive_M6_93308_DR_firesm6sel2.geojson')
# firesm6sel2 <- st_read('out/fire_archive_M6_93308_DR_firesm6sel2.geojson')
plot(firesm6sel2['SATELLITE'], main = "Thermal anomalies within forest")
# ** Note: the suffix "sel2" stands for "selection 2", which for this study means "fires or thermal anomalies recorded within areas which in 2000 had forest, assuming by forest areas with treecover equal or greater than pctc (25% in the last run)"

# Fires V1
# Manually removed chimneys and landfills
firesv1manrem <- st_read('out/fire_archive_V1_93309_DR_manually_removed_chimneys_landfills.geojson')
firesv1sel <- firesv1manrem %>%
  filter(ACQ_DATE>='2012-01-01' & ACQ_DATE<='2018-12-31', CONFIDENCE %in% c('n','h'))
# firesv1sel %>% st_write('out/fire_archive_V1_93309_DR_manually_removed_chimneys_landfills_dates_conf_n_h_aka_firesv1sel.geojson')
# firesv1sel <- st_read('out/fire_archive_V1_93309_DR_manually_removed_chimneys_landfills_dates_conf_n_h_aka_firesv1sel.geojson')
#Keep thermal anomalies occuring only inside tcforzonalmask, that is, wihtin forest.
#More: https://gis.stackexchange.com/questions/252900/extracting-spatial-points-that-match-raster-value-using-r
firesv1sel2index <- which(raster::extract(tcforzonal == 1, firesv1sel) == 1)
firesv1sel2 <- firesv1sel[firesv1sel2index,]
firesv1sel2
# firesv1sel2 %>% st_write('out/fire_archive_V1_93309_DR_firesv1sel2.geojson')
# firesv1sel2 <- st_read('out/fire_archive_V1_93309_DR_firesv1sel2.geojson')
plot(firesv1sel2['SATELLITE'], main = "Thermal anomalies within forest")
# ** Note: the suffix "sel2" stands for "selection 2", which for this study means "fires or thermal anomalies recorded within areas which in 2000 had forest, assuming by forest areas with treecover equal or greater than pctc (25% in the last run)"