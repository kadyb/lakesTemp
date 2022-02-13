download_hydro = function(months, years) {
   # Note these are hydrological months, not calendar months
   if(!is.character(months) || nchar(months) != 2) stop("Invalid month format")
   
   # Example URL:
   # https://dane.imgw.pl/data/dane_pomiarowo_obserwacyjne/dane_hydrologiczne/dobowe/2018/codz_2018_01.zip
   createURL = function(month, year) {
      paste0("https://dane.imgw.pl/data/dane_pomiarowo_obserwacyjne/dane_hydrologiczne/dobowe/", 
             year, "/codz_", year, "_", month, ".zip")
   }
   
   result = NULL
   for(year in years) {
      for(month in months) {
         url = createURL(month, year)
         tmp = tempfile()
         download.file(url, tmp, quiet = TRUE)
         data_unzip = unz(tmp, paste0("codz_", year, "_", month, ".csv"))
         data = read.csv(data_unzip, header = FALSE, stringsAsFactors = FALSE)
         unlink(tmp)
         result = rbind(result, data)
      }
   }
   
   # Clean results
   hydro_names = c("Station_ID", "Station_name", "River_lake_name", "Hydrological_year",
                   "Hydrological_month", "Day", "Water_level", "Flow", "Temperature",
                   "Calendar_month")
   colnames(result) = hydro_names
   result$Temperature[result$Temperature == 99.9] = NA
   result$Water_level[result$Water_level == 9999] = NA
   result$Flow[result$Flow == 99999.999] = NA
   return(result)
}

# Example:
# months = as.character(1:12)
# months = ifelse(nchar(months) < 2, paste0("0", months), months)
# hydro_data = download_hydro(months, 2000:2003)

