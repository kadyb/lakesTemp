hydro_stations = read.csv2("data/hydro_stations.csv")
lakes_temp = read.csv2("data/lakes_temp.csv")
lakes_temp$date = as.Date(lakes_temp$date)
lakes_temp$T = lakes_temp$T + 273.15 # to Kelvin

SR = read.csv2("data/SR_processed.csv")
SR = SR[, c(1, 9, 10)]
SR$date = as.Date(SR$date)
colnames(SR)[1] = "ID"

SR = merge(lakes_temp, SR, by = c("ID", "date"))

set.seed(1)
test_lakes = sample(nrow(hydro_stations), 10)
test_lakes = hydro_stations[test_lakes, ]

test = SR[SR$ID %in% test_lakes$ID, ]
train = SR[!SR$ID %in% test_lakes$ID, ]

mdl1 = lm(T ~ ST_B10, data = train) # with intercept
mdl2 = lm(T ~ ST_B10 + 0, data = train) # without intercept
summary(mdl1)
summary(mdl2)
calib = mean(train$ST_B10 - train$T) # determine systematic bias

# predict and validate
test$mdl1 = predict(mdl1, test)
test$mdl2 = predict(mdl2, test)
test$mdl3 = test$ST_B10 - calib

rmse = function(actual, predicted) {
  sqrt(mean((actual - predicted)^2))
}

round(rmse(test$T, test$mdl1), 2) #> 2.59
round(rmse(test$T, test$mdl2), 2) #> 2.86
round(rmse(test$T, test$mdl3), 2) #> 2.88



##### plots #####
library("ggplot2")
library("cowplot")
source("code/utils/custom_theme.R")

# scatterplot (before calibration; trainset)
p1 = ggplot(train, aes(ST_B10, T)) +
  geom_point(alpha = 0.7, stroke = 0) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  annotate("text", x = 301, y = 305, label = "y = x") +
  xlim(c(275, 308)) +
  ylim(c(275, 308)) +
  xlab(NULL) +
  ylab("In-situ temperature [K]") +
  custom_theme()
p1

# histogram (before calibration; trainset)
p2 = ggplot(train, aes(ST_B10 - T)) +
  geom_histogram(binwidth = 1) +
  geom_vline(aes(xintercept = mean(ST_B10 - T)),
             color = "blue", linetype = "dashed", size = 1) +
  annotate("text", x = 0.5, y = 310, label = round(calib, 2), col = "blue") +
  scale_x_continuous(labels = scales::label_number(style_negative = "minus")) +
  xlab(NULL) +
  ylab("Frequency") +
  custom_theme()
p2

# scatterplot (after calibration; testset)
p3 = ggplot(test, aes(mdl1, T)) +
  geom_point(alpha = 0.7, stroke = 0) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  annotate("text", x = 301, y = 305, label = "y = x") +
  xlim(c(275, 308)) +
  ylim(c(275, 308)) +
  xlab("Landsat Surface Temperature [K]") +
  ylab("In-situ temperature [K]") +
  custom_theme()
p3

# histogram (after calibration; testset)
p4 = ggplot(test, aes(mdl1 - T)) +
  geom_histogram(binwidth = 1) +
  scale_x_continuous(labels = scales::label_number(style_negative = "minus")) +
  xlab("Temperature difference [K]") +
  ylab("Frequency") +
  custom_theme()
p4

plot_grid(p1, p2, p3, p4, ncol = 2)
ggsave("plots/calibration.pdf", device = cairo_pdf, width = 7, height = 4,
       units = "in")
