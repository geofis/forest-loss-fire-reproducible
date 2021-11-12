# Functions, packages, data
source('R/load-packages.R')
source('R/load-functions.R')

gadmdr <- st_read('data/gadm36_DOM_gpkg/gadm36_DOM.gpkg', layer = 'gadm36_DOM_0')
gadmh <- st_read('data/gadm36_HTI_gpkg/gadm36_HTI.gpkg', layer = 'gadm36_HTI_0')
gadmmask <- st_union(gadmdr, gadmh)
gadmmask <- st_transform(gadmmask, 32619)
gadmmask <- st_simplify(gadmmask, preserveTopology = T, 40)
# st_write(gadmmask, 'data/gadm_mask.gpkg')
gadmh <- st_transform(gadmh, 32619)
gadmh <- st_simplify(gadmh, preserveTopology = T, 40)
# st_write(gadmh, 'data/gadmh.gpkg')
# In QGIS, a rectangle in the ocean/sea area was created, from where a polygon
# was generated, which then was overlaid to Haiti. Finally, the clipper and v.clean tools
# were used to generate a proper sea/ocean shape. The result was saved in the file
# out/gadm_mask_inv.gpkg