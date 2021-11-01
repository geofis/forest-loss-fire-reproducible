selectbuffer <- function(src, points, dist) {
  require(raster)
  require(tidyverse)
  require(sf)
  bu <- rasterToPolygons(src, dissolve = T) %>% st_as_sf() %>% st_buffer(dist, endCapStyle = 'SQUARE')
  sel <- st_intersection(points, bu)
  return(sel)
}
