# Original script used to compute zonal statistics for annual approach grid

# Functions, packages, data
source('R/load-packages.R')
source('R/load-functions.R')
# Cutline
source('R/load-cutline.R')
#ly (loaded here just for illustration purposes)
ly <- raster('out/lossyear_crop.tif')
names(ly) <- 'LOSSYEAR'

# Generate the hexagonal grid. Each hexagon has 40% of its surface land area within the country
hg <- st_make_grid(cline, cellsize = 15000, square = F, offset = st_bbox(cline)[c("xmin", "ymin")]+c(0,3000))
plot(cline %>% st_geometry())
plot(hg, add=T)
hg2 <- st_as_sf(hg)
hg2 <- hg2 %>% mutate(ENLACE=1:nrow(hg2), AREASQM1=st_area(x) %>% units::drop_units())
hg3 <- st_intersection(hg2, cline %>% st_union) %>%
  mutate(AREASQM2=st_area(x) %>% units::drop_units(), AREASQM_PCT=AREASQM2/AREASQM1*100)
hg4 <- hg2 %>%
  inner_join(hg3 %>% filter(AREASQM_PCT>=40) %>% st_drop_geometry() %>% select(ENLACE, AREASQM2, AREASQM_PCT)) %>% 
  mutate(xutm=st_coordinates(st_centroid(x))[,1], yutm=st_coordinates(st_centroid(x))[,2]) %>% 
  rename(AREASQM=AREASQM2) %>% ### TODO: IT'S NOT AREASQM1 IT'S AREASQM2
  filter(!(xutm>500000 & yutm<2020000))#, !(xutm>275000 & yutm<2007000)) 
hg4$ENLACE <- 1:nrow(hg4)
hg4$ENLACE
hexsf <- hg4
names(hexsf)[grepl('^x$', names(hexsf))] <- "geometry"
st_geometry(hexsf) <- "geometry"
hexsf
hexsf <- hexsf %>% rename(a0_square_meters = AREASQM1)
# saveRDS(hexsf, 'out/honeycomb_grid_sf.RDS')
# hexsf %>% st_write('out/honeycomb_grid_sf.gpkg')
# hexsf <- readRDS('out/honeycomb_grid_sf.RDS')
