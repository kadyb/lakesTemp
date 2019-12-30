# read data
fnames = list.files("data/reflectance", full.names = TRUE, pattern = ".+[457]+.+\\.csv")
csv = lapply(fnames, read.csv)
result = do.call(rbind, csv)

# extract sensor names
result$system.index = as.character(result$system.index)
result$sensor = as.factor(substr(result$system.index, 1, 4))
levels(result$sensor) = c("L7", "L4", "L5")

# extract dates
result$date = substr(result$system.index, 13, 20)
result$date = as.Date(result$date, format = "%Y%m%d")

# remove 'system.index' col
result = result[, -1]

# clean outliers using blue band
result = result[result$B1 < 700 & result$B1 > 0, ]

# specify the aerosol content
result = result[!is.na(result$sr_atmos_opacity), ]
result$sr_atmos_opacity = result$sr_atmos_opacity * 0.0010 # scale factor
result$areosols[result$sr_atmos_opacity < 0.1] = "low"
result$areosols[result$sr_atmos_opacity > 0.3] = "high"
result$areosols[is.na(result$areosols)] = "medium"
result$areosols = as.factor(result$areosols)
result = result[, -9]

# convert to Kelvin
result$B6 = result$B6 / 10

# save
write.csv2(result, "data/Landsat457processed.csv")
