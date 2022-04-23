library("terra")
library("ranger")

mdl = readRDS("results/rf_model.rds")

########################
###### predict entire scene

band_names = paste0("B", c(1:7, 10:11))
ras = rast("images/West.tif")
names(ras) = band_names

# create auxiliary variables
ras$month = 4L
ndvi = function(red, nir) (nir - red) / (nir + red)
ras$NDVI = lapp(ras[[4:5]], fun = ndvi)
ndwi = function(green, nir) (green - nir) / (green + nir)
ras$NDWI = lapp(ras[[c(3, 5)]], fun = ndvi)

# prediction
ras = ifel(is.na(ras), 0, ras)
predict(ras, mdl, filename = "West_preprocess.tif",
        fun = function(model, ...) predict(model, ...)$predictions)

# post-process
rmask = ifel(ras[["B10"]] == 0, NA, ras[["B10"]])
pred = rast("West_preprocess.tif")
pred = pred - 273.15
pred = mask(pred, rmask)
writeRaster(pred, "West_postprocess.tif", gdal = "COMPRESS=DEFLATE")

########################
###### predict single lakes
lakes_geom = vect("data/vector/lakes.gpkg")

lakes = list.files("images", pattern = "\\.tif$")
lakes = lakes[!grepl("West.tif"), lakes] # remove
lakes_names = substr(lakes, 1, nchar(lakes) - 4)
# Drawsko, Elckie, Goplo, Lebsko respectively
dates = c("20180529", "20211025", "20210608", "20150818")
dates = as.Date(dates, format = "%Y%m%d")

band_names = paste0("B", c(1:7, 10:11))

for (i in seq_along(lakes)) {

  ras = rast(lakes[i])
  names(ras) = band_names

  # create auxiliary variables
  ras$month = as.integer(format(dates[i], "%m"))
  ndvi = function(red, nir) (nir - red) / (nir + red)
  ras$NDVI = lapp(ras[[4:5]], fun = ndvi)
  ndwi = function(green, nir) (green - nir) / (green + nir)
  ras$NDWI = lapp(ras[[c(3, 5)]], fun = ndvi)

  # prediction
  ras = ifel(is.na(ras), 0, ras)
  pred = predict(ras, mdl, fun = function(model, ...) predict(model, ...)$predictions)

  # compare vector and raster CRS
  if (!identical(crs(lakes_geom), crs(ras))) {
    lakes_geom = project(lakes_geom, ras)
  }

  # post-process
  rmask = ifel(ras[["B10"]] == 0, NA, ras[["B10"]])
  pred = pred - 273.15
  pred = mask(pred, rmask)
  pred = crop(pred, lakes_geom[lakes_geom$name == lakes_names[i]], mask = TRUE)
  save_path = paste0(lakes_names[i], "_", "T", ".tif")
  writeRaster(pred, save_path, gdal = "COMPRESS=DEFLATE")

}
