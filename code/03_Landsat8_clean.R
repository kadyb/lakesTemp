fnames = list.files("data/reflectance", full.names = TRUE, pattern = ".+[8]+.+\\.csv")

##### Landsat 8 SR #####
SR = read.csv(fnames[1])

# extract dates
SR$date = substr(SR$system.index, 13, 20)
SR$date = as.Date(SR$date, format = "%Y%m%d")

# remove 'system.index' column
SR = SR[, -1]

# scale values
scale = 2.75e-05
offset = -0.2
SR[, 2:8] = apply(SR[, 2:8], MARGIN = 2, FUN = function(x) x * scale + offset)
SR[, "ST_B10"] = SR[, "ST_B10"] * 0.00341802 + 149

# clean outliers
SR = SR[SR$SR_B1 < 0.14, ]
for (i in 2:8) {

  idx = SR[, i] > 0 # reflectance must be above 0
  SR = SR[idx, ]

}
SR = SR[SR$ST_B10 > 273.15, ]

# check duplicates
sum(duplicated(SR[, c(1, 10)]))
# remove duplicates
SR = SR[!duplicated(SR[, c(1, 10)]), ]

# save
write.csv2(SR, "data/SR_processed.csv", row.names = FALSE)


##### Landsat 8 TOA #####
TOA = read.csv(fnames[2])

TOA$date = substr(TOA$system.index, 13, 20)
TOA$date = as.Date(TOA$date, format = "%Y%m%d")

TOA = TOA[, -1]

TOA = TOA[TOA$B1 < 0.15, ]
for (i in 2:8) {

  idx = TOA[, i] > 0
  TOA = TOA[idx, ]

}
TOA = TOA[TOA$B10 > 273.15, ]


sum(duplicated(TOA[, c(1, 11)]))
TOA = TOA[!duplicated(TOA[, c(1, 11)]), ]

write.csv2(TOA, "data/TOA_processed.csv", row.names = FALSE)
