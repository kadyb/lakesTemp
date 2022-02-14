source("code/utils/download_hydro.R")

# download hydro data
hydro_data = download_hydro(1:12, 2013:2020) # Landsat 8 time range

# clean data
colnames = c("Station_ID", "Date", "Temperature")
temp = hydro_data[, colnames] # select columns
temp = temp[!is.na(temp$Temperature), ] # remove NA
short_colnames = c("ID", "date", "T")
colnames(temp) = short_colnames

# select stations
stations = read.csv2("data/hydro_stations.csv")
temp = temp[temp$ID %in% stations$ID, ]

# select warm months
temp$month = as.numeric(format(temp$date, "%m"))
temp = temp[temp$month >= 4 & temp$month <= 10, ]

# save data
write.csv2(temp[, c("ID", "T", "date")], "data/lakes_temp.csv", row.names = FALSE)
