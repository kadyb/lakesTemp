library("ranger")

hydro_stations = read.csv2("data/hydro_stations.csv")
lakes_temp = read.csv2("data/lakes_temp.csv")
lakes_temp$date = as.Date(lakes_temp$date)
lakes_temp$T = lakes_temp$T + 273.15 # to Kelvin

LST = read.csv("data/SMW_LST_L8_Lakes_newEmiss.csv", encoding = "UTF-8")
LST$date = substr(LST$system.time_start, 1, 10)
LST$date = as.Date(LST$date)
LST = merge(LST, hydro_stations[, c(1, 3)], by.x = "NAZ_JEZIOR", by.y = "lake")
LST = LST[, c(7, 6, 3)]
colnames(LST) = c("ID", "date", "T_lst")
# check duplicates
sum(duplicated(LST[, c(1, 2)]))
# remove duplicates
LST = LST[!duplicated(LST[, c(1, 2)]), ]

### TOA
TOA = read.csv2("data/TOA_processed.csv")
TOA$date = as.Date(TOA$date)
colnames(TOA)[1] = "ID"

### SR
SR = read.csv2("data/SR_processed.csv")
SR = SR[, c(1, 9, 10)]
SR$date = as.Date(SR$date)
colnames(SR)[1] = "ID"

##### machine learning #####
TOA$month = as.factor(as.numeric(format(TOA$date, "%m")))
TOA$NDVI = (TOA$B5 - TOA$B4)/(TOA$B5 + TOA$B4)
TOA$NDWI = (TOA$B3 - TOA$B5)/(TOA$B3 + TOA$B5) # McFeeters (1996)

# merge
TOA = merge(TOA, lakes_temp, by = c("ID", "date"))

# randomly select test lakes (n = 10)
set.seed(1)
test_lakes = sample(nrow(hydro_stations), 10)
test_lakes = hydro_stations[test_lakes, ]
cat(test_lakes$lake, sep = ", ")

test = TOA[TOA$ID %in% test_lakes$ID, ]
train = TOA[!TOA$ID %in% test_lakes$ID, ]

# multiple linear regression
mdl1 = lm(T ~ B10 + B11, data = train)
summary(mdl1)
pred1 = predict(mdl1, test)


# random forest
set.seed(1)
mdl2 = ranger(T ~ B1 + B2 + B3 + B4 + B5 + B6 + B7 + B10 + B11 +
                month + NDVI + NDWI, data = train,
              importance = "impurity")
pred2 = predict(mdl2, test)

## save model
if (!dir.exists("results")) dir.create("results")
saveRDS(mdl2, "results/rf_model.rds")

### comparison
mbe = function(actual, predicted) {
  mean(predicted - actual)
}
rmse = function(actual, predicted) {
  sqrt(mean((actual - predicted)^2))
}
test$T_lm = pred1
test$T_rf = pred2$predictions
test = merge(test, LST, by = c("ID", "date"))
test = merge(test, SR, by = c("ID", "date"))

### validation on test dataset ###
# table 1
round(mbe(test$T, test$T_lm), 2) #> -0.01
round(mbe(test$T, test$T_rf), 2) #> -0.06
round(mbe(test$T, test$T_lst), 2) #> 2.04
round(mbe(test$T, test$ST_B10), 2) #> 2.55
round(mbe(test$T, test$B10), 2) #> -0.73

round(rmse(test$T, test$T_lm), 2) #> 2.29
round(rmse(test$T, test$T_rf), 2) #> 1.83
round(rmse(test$T, test$T_lst), 2) #> 3.35
round(rmse(test$T, test$ST_B10), 2) #> 3.68
round(rmse(test$T, test$B10), 2) #> 2.70

round(cor(test$T, test$T_lm), 2) #> 0.91
round(cor(test$T, test$T_rf), 2) #> 0.94
round(cor(test$T, test$T_lst), 2) #> 0.88
round(cor(test$T, test$ST_B10), 2) #> 0.90
round(cor(test$T, test$B10), 2) #> 0.88

round(sd(test$T_lm), 2) #> 4.98
round(sd(test$T_rf), 2) #> 4.92
round(sd(test$T_lst), 2) #> 5.52
round(sd(test$ST_B10), 2) #> 5.94
round(sd(test$B10), 2) #> 4.83

### statistics from train dataset ###
round(mbe(train$T, mdl1$fitted.values), 2) #> 0
round(mbe(train$T, mdl2$predictions), 2) #> 0.01

round(rmse(train$T, mdl1$fitted.values), 2) #> 2.28
round(rmse(train$T, mdl2$predictions), 2) #> 1.66

round(cor(train$T, mdl1$fitted.values), 2) #> 0.91
round(cor(train$T, mdl2$predictions), 2) #> 0.95

round(sd(mdl1$fitted.values), 2) #> 4.92
round(sd(mdl2$predictions), 2) #> 5

# correlation and rmse for all (test and train) lakes
# supplementary table 2
TOA$T_lm = predict(mdl1, TOA)
TOA$T_rf = predict(mdl2, TOA)$predictions
n = length(unique(TOA$ID))
tbl = data.frame(ID = unique(TOA$ID), mbe_lm = double(n), mbe_rf = double(n),
                 rmse_lm = double(n), rmse_rf = double(n), cor_lm = double(n),
                 cor_rf = double(n), sd_lm = double(n), sd_rf = double(n))
for (i in seq_along(tbl$ID)) {
  sel = which(TOA$ID == tbl$ID[i])
  tbl$mbe_lm[i] = mbe(TOA$T[sel], TOA$T_lm[sel])
  tbl$mbe_rf[i] = mbe(TOA$T[sel], TOA$T_rf[sel])
  tbl$rmse_lm[i] = rmse(TOA$T[sel], TOA$T_lm[sel])
  tbl$rmse_rf[i] = rmse(TOA$T[sel], TOA$T_rf[sel])
  tbl$cor_lm[i] = cor(TOA$T[sel], TOA$T_lm[sel])
  tbl$cor_rf[i] = cor(TOA$T[sel], TOA$T_rf[sel])
  tbl$sd_lm[i] = sd(TOA$T_lm[sel])
  tbl$sd_rf[i] = sd(TOA$T_rf[sel])
}
tbl[, 2:9] = round(tbl[, 2:9], 2)
tbl = merge(tbl, hydro_stations[, c(1, 3)], by = "ID")
tbl$test = ifelse(tbl$ID %in% test_lakes$ID, "x", "")
tbl = tbl[, c(10:11, 2:9)]
colnames(tbl) = c("Lake", "Test set", "MBE LM [K]", "MBE RF [K]",
                  "RMSE LM [K]", "RMSE RF [K]", "COR LM", "COR RF",
                  "SD LM [K]", "SD RF [K]")
write.csv2(tbl, "results/lakes_stats.csv", row.names = FALSE)

# correlation and rmse for months (on testset)
n = length(levels(test$month))
tbl = data.frame(month = levels(test$month), rmse_lm = double(n), rmse_rf = double(n),
                 rmse_lst = double(n), rmse_lst_l2 = double(n), cor_lm = double(n),
                 cor_rf = double(n), cor_lst = double(n), cor_lst_l2 = double(n))
for (i in seq_along(tbl$month)) {
  sel = which(test$month == levels(test$month)[i])
  tbl$rmse_lm[i] = rmse(test$T[sel], test$T_lm[sel])
  tbl$rmse_rf[i] = rmse(test$T[sel], test$T_rf[sel])
  tbl$rmse_lst[i] = rmse(test$T[sel], test$T_lst[sel])
  tbl$rmse_lst_l2[i] = rmse(test$T[sel], test$ST_B10[sel])
  tbl$cor_lm[i] = cor(test$T[sel], test$T_lm[sel])
  tbl$cor_rf[i] = cor(test$T[sel], test$T_rf[sel])
  tbl$cor_lst[i] = cor(test$T[sel], test$T_lst[sel])
  tbl$cor_lst_l2[i] = cor(test$T[sel], test$ST_B10[sel])
}
tbl[, 2:9] = round(tbl[, 2:9], 2)
tbl$month = c("April", "May", "June", "July", "August", "September", "October")
colnames(tbl) = c("Month", "RMSE LM [K]", "RMSE RF [K]", "RMSE LST [K]",
                  "RMSE LST_L2 [K]", "COR LM", "COR RF", "COR LST", "COR LST_L2")
write.csv2(tbl, "results/month_stats.csv", row.names = FALSE)

## save results from testset
test = merge(test, hydro_stations[, c(1, 3)], by = "ID")
test_save = test[, c(20, 2, 15:19)]
write.csv2(test_save, "results/predictions_testset.csv", row.names = FALSE)
