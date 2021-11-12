# Original script used to create the long-term approach analysis grid

# Functions, packages, data
source('R/load-packages.R')
source('R/load-functions.R')
# Cutline
source('R/load-cutline.R')

# Generate the grid
A = 100000000; a = sqrt((2*A)/(4*sqrt(3))); cellsize = 2*a; print(cellsize, digits = 10)
# 10745.69932
grd1 <- st_make_grid(cline, cellsize = cellsize, square = F)
grd2 <- st_as_sf(grd1)
grd2 <- grd2 %>% mutate(ENLACE=1:nrow(grd2), AREASQM1=st_area(x) %>% units::drop_units())
grd3 <- st_intersection(grd2, cline %>% st_union) %>%
  mutate(AREASQM2=st_area(x) %>% units::drop_units(), AREASQM_PCT=AREASQM2/AREASQM1*100)
plot(as_Spatial(cline))
plot(as_Spatial(grd3), add=T)
grd4 <- grd2 %>% select(ENLACE) %>% 
  inner_join(grd3 %>%
               filter(AREASQM_PCT>=45) %>%
               st_drop_geometry() %>%
               select(ENLACE, AREASQM2, AREASQM_PCT)) %>% 
  rename(AREASQM=AREASQM2)
plot(as_Spatial(cline))
plot(as_Spatial(grd4), add=T)
# rem <- click(as_Spatial(grd4), n=2, xy=T) #Saona Island, Enriquillo Lake
# saveRDS(rem, 'out/removed_lakes_islands_cells_from_grd.RDS')
sparseindex <- !st_intersects(grd4, st_as_sf(rem[[1]]))
logicalindex <- apply(sparseindex, 1, all)
grd <- grd4[logicalindex,]
grd
grd$ENLACE <- 1:nrow(grd)
grd
names(grd)[grep('^x$', names(grd))] <- 'geometry'
st_geometry(grd) <- 'geometry'
grd
cline %>% as_Spatial %>% plot
grd %>% as_Spatial %>% plot(add=T)
# saveRDS(grd, 'out/grd_plain_only_area_known_in_R_as_grd.RDS')
