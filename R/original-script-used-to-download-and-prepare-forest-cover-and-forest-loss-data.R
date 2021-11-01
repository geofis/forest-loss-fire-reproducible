# Original script used to download and prepare forest cover and forest loss data

# Define URLs
baseurl <- paste0(
  'https://storage.googleapis.com/earthenginepartners-hansen/',
  'GFC-2018-v1.6/Hansen_GFC-2018-v1.6')
type <- c('treecover2000', 'gain', 'lossyear', 'datamask')
lat <- '20N'
lon <- c('070W', '080W')
all <- expand.grid(baseurl, type, lat, lon, stringsAsFactors = F)
urls <- paste0(apply(all, 1, paste, collapse = '_'), '.tif')
urls
downdir <- 'data/'

# Download images
sapply(urls, function(x) {
  destdownfile <- paste0(downdir, sub(".*/", "", x))
  download.file(x, destfile = destdownfile)
})
# The files downloaded with the previous code chunk comprise the raw versions of the Hansen et al. (2013) database.

# Mosaicking
destdownfile <- paste0(downdir, sub(".*/", "", urls))
map(
  type,
  function(x){
    mosaic_rasters(
      gdalfile = grep(x, destdownfile, value = T),
      dst_dataset = paste0('out/', x, '.tif'),
      co = 'COMPRESS=LZW'
    )})

# Crop and mask treecover, loss, gain
# Note: although no further use of the `gain` layer was performed, it was masked along with `treecover` and `loss` layers to enable future analyses on forest gain.
sapply(type, function(x) {
  gdalwarp(
    srcfile = paste0('out/', x, '.tif'),
    dstfile = paste0('out/', x, '_crop.tif'),
    cutline = cutlinepath,
    crop_to_cutline = T,
    co = 'COMPRESS=LZW',
    t_srs = 'EPSG:32619',
    dstnodata = '255',
    overwrite = T
  )})