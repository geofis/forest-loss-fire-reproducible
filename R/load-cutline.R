cutlinepath <- 'out/cutline.geojson'
crsdestino <- 32619
cline <- st_transform(st_read(cutlinepath), crs = crsdestino)