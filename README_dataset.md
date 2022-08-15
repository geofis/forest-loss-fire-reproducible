# Dataset for the manuscript entitled "Fire and forest loss in the Dominican Republic during the 21st Century"

José Ramón Martínez Batlle, Universidad Autónoma de Santo Domingo (UASD) jmartinez19\@uasd.edu.do

This dataset may be used to run the reproducible R code saved of the associated [GitHub repo](https://github.com/geofis/forest-loss-fire-reproducible), which ultimately supports the results and conclusions of the manuscript "Martínez Batlle, J. R. (2021). Fire and forest loss in the Dominican Republic during the 21st Century. *bioRxiv*. https://doi.org/10.1101/2021.06.15.448604".

Two main directories make up the data set:

1. The `data/` directory contains GIS layers, downloaded and used as-is in the data analysis workflow:

  * The "Global Forest Change 2000–2018" TIF files (`*.tif`), downloaded from [this site](https://earthenginepartners.appspot.com/science-2013-global-forest/download_v1.6.html). These files were the original source of the processing workflow, and comprise the following data:

    - Tree cover for year 2000 (files named as `Hansen_GFC-2018-v1.6_treecover2000*`). According to the authors, this layer is "defined as canopy closure for all vegetation taller than 5m in height. Encoded as a percentage per output grid cell, in the range 0–100".
    - Year of gross forest cover loss event (files named as `Hansen_GFC-2018-v1.6_lossyear*`). The authors define these layers as "forest loss during the period 2000–2018, defined as a stand-replacement disturbance, or a change from a forest to non-forest state. Encoded as either 0 (no loss) or else a value in the range 1–17, representing loss detected primarily in the year 2001–2018, respectively".
    - Data mask (files named as `Hansen_GFC-2018-v1.6_datamask*`). This layer contains only three values, "representing areas of no data (0), mapped land surface (1), and permanent water bodies (2)".

  * The units of the administrative division of the Dominican Republic (according to [ONE](https://www.one.gob.do/informaciones-cartograficas/shapefiles)) stored in the subdirectory named `administrative/`. This file was used only to compute zonal statistics of forest loss and fire down to the level of municipalities.

  * The protected areas of the Dominican Republic (according to UNEP-WCMC and IUCN (2021), Protected Planet: The World Database on Protected Areas (WDPA) and World Database on Other Effective Area-based Conservation Measures (WD-OECM) [Online], October 2021, Cambridge, UK: UNEP-WCMC and IUCN. Available at: www.protectedplanet.net) stored in the subdirectory named `protected_areas/`. This file was used to compute zonal statistics of forest loss and fire for each protected area of the Country aimed to inform environmental policy strategies.

2. The `out/` directory contains processed files (generated from the original files) for a proper use in the analysis workflow. Some of them are just intermediate results (retained only to reduce the code execution time); the main files are the following:

  * The file named `cutline.geojson` represent the cutline for masking both raster and vector GIS layers to the extent of the study area.
  
  * Fire vector layers, files named as `fire_archive_*_manually_removed*.geojson`; these files contain the comprehensive FIRMS dataset where spontaneous landfills and chimneys hotspots where manually removed. In addition, the files named `fire_archive_*_sel2.geojson` contain the final selection of hotspots used in the study, from which the low quality records were programatically excluded.

  * Files with `*.tif` extension contain the Global Forest Change raster layers, clipped and masked to the extent of the study area.
  
  * Files with extension `*.RDS` are intermediate and final results of the zonal statistics computations for fires and forest loss. The files `grd_*.RDS`, `hex_zonal_statistics.RDS` and `honeycomb_grid_sf.RDS` are the hexagonal grids used for zonal statistics computations of fire and forest loss.
