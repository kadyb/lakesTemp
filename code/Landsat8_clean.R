# read data
fnames = list.files("data/reflectance", full.names = TRUE, pattern = ".+[8]+.+\\.csv")
result = read.csv(fnames)

# extract dates
result$date = substr(result$system.index, 13, 20)
result$date = as.Date(result$date, format = "%Y%m%d")

# remove 'system.index' col
result = result[, -1]

# clean outliers using ultra-blue band
result = result[result$B1 < 350 & result$B1 > 0, ]

# specify the aerosol content
aerosol = data.frame(
   low = c(66, 68, 96, 100),
   medium = c(130, 132, 160, 164),
   high = c(194, 196, 224, 228)
)

result$areosols = ifelse(result$sr_aerosol %in% aerosol$low, "low", NA)
result$areosols = ifelse(result$sr_aerosol %in% aerosol$medium, "medium", result$areosols)
result$areosols = ifelse(result$sr_aerosol %in% aerosol$high, "high", result$areosols)
result$areosols = as.factor(result$areosols)
result = result[, -11]

# convert to Kelvin
result$B10 = result$B10 / 10
result$B11 = result$B11 / 10

# save
write.csv2(result, "data/Landsat8processed.csv")
