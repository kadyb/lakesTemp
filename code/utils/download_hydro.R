download_hydro = function(months, years) {

   # `months` must consist of 2 characters
   # note these are hydrological months, not calendar
   months = ifelse(nchar(months) < 2, paste0("0", months), months)

   # example URL:
   # https://danepubliczne.imgw.pl/data/dane_pomiarowo_obserwacyjne/dane_hydrologiczne/dobowe/2018/codz_2018_01.zip
   createURL = function(month, year) {
      paste0("https://danepubliczne.imgw.pl/data/dane_pomiarowo_obserwacyjne/dane_hydrologiczne/dobowe/",
             year, "/codz_", year, "_", month, ".zip")
   }

   result = data.frame()
   for (year in years) {
      for (month in months) {
         url = createURL(month, year)
         tmp = tempfile()
         download.file(url, tmp, quiet = TRUE)
         data_unzip = unz(tmp, paste0("codz_", year, "_", month, ".csv"))
         data = read.csv(data_unzip, header = FALSE, stringsAsFactors = FALSE)

         # the most recent data doesn't have 'Flow' column
         if (ncol(data) == 9) {
            flow_NA = rep_len(NA, nrow(data))
            data = cbind(data, flow_NA)
            data = data[, c(1:7, 10, 8:9)]
            colnames(data) = paste0("V", seq_len(ncol(data)))
         }

         unlink(tmp)
         result = rbind(result, data)
      }
   }

   # clean results
   hydro_names = c("Station_ID", "Station_name", "River_lake_name", "Hydrological_year",
                   "Hydrological_month", "Day", "Water_level", "Flow", "Temperature",
                   "Calendar_month")
   colnames(result) = hydro_names
   result$Temperature[result$Temperature == 99.9] = NA
   result$Water_level[result$Water_level == 9999] = NA
   result$Flow[result$Flow == 99999.999] = NA

   # convert hydrological year and month to calendar
   result[[5]] = result[[5]] - 2
   result[[4]] = ifelse(result[[5]] < 1, result[[4]] - 1, result[[4]])
   result[[5]] = ifelse(result[[5]] < 1, result[[5]] + 12, result[[5]])
   result$Date = paste0(result[[4]], "-", result[[5]], "-", result[[6]])
   result$Date = as.Date(result$Date, format = "%Y-%m-%d")
   # drop columns
   result = result[, -c(4, 5, 6, 10)]

   return(result)

}

# Example:
# hydro_data = download_hydro(1:12, 2000:2003)
