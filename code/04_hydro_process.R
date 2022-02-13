source("download_hydro.R")

# download hydro data
months = as.character(1:12)
months = ifelse(nchar(months) < 2, paste0("0", months), months)
hydro_data = download_hydro(months, 1981:2018) # Landsat 4-8

# clean data
colnames = c("Station_ID", "Hydrological_year", "Hydrological_month", "Day",
             "Temperature", "Calendar_month")
temp = hydro_data[, colnames] # select columns
temp = temp[!is.na(temp$Temperature), ] # remove NA
short_colnames = c("ID", "h_year", "h_month", "day", "T", "month")
colnames(temp) = short_colnames

# select statnios
stations = read.csv("data/hydro_stations.csv", encoding = "UTF-8")
temp = temp[temp$ID %in% stations$Kod.stacji, ]

# create dates
temp$h_month = temp$h_month + 10
temp$h_year = ifelse(temp$h_month > 12, temp$h_year + 1, temp$h_year)
temp$h_month = ifelse(temp$h_month > 12, temp$h_month - 12, temp$h_month)
temp$date = paste0(temp$h_year, "-", temp$h_month, "-", temp$day)
temp$date = as.Date(temp$date, format = "%Y-%m-%d")

# select warm months
temp = temp[temp$month >= 4 & temp$month <= 10, ]

# save data
write.csv2(temp[, c("ID", "T", "date")], "data/lakes_temp.csv", row.names = FALSE)
