library("tidyr")
library("terra")
library("cowplot")
library("ggplot2")

if (!dir.exists("plots")) dir.create("plots")

## define custom theme
custom_theme = function() {
  theme_bw() +
  theme(panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text = element_text(color = "black"),
        axis.line = element_line(colour = "black", size = 0.5),
        axis.title = element_text(face = "bold"),
        strip.background = element_rect(fill = NA, colour = NA))
}


## variable importance ---------------------------------------------------------
mdl = readRDS("results/rf_model.rds")

imp = data.frame(importance = mdl$variable.importance)
rownames(imp)[10] = "Month"
ggplot(imp, aes(x = reorder(rownames(imp), importance), y = importance)) +
  geom_col() +
  xlab("Feature") +
  ylab("Importance") +
  coord_flip()  +
  custom_theme()

ggsave("plots/importance.pdf", device = cairo_pdf, width = 4, height = 3,
       units = "in")

## point plot ------------------------------------------------------------------
test = read.csv2("results/predictions_testset.csv")

test$date = as.Date(test$date)
test$month = format(test$date, "%m")
cols = c("T_lm", "T_rf", "T_lst", "ST_B10")
test_long = pivot_longer(test, all_of(cols))
test_long$name = factor(test_long$name, levels = cols,
                        labels = c("LM", "RF", "LST", "LST-L2"))
mth = c("APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT")
test_long$month = factor(test_long$month, labels = mth)

ggplot(test_long, aes(value, T, color = month)) +
  geom_point(alpha = 0.7, stroke = 0) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  annotate("text", x = 278, y = 275, label = "y = x") +
  xlab("Predicted temperature [K]") +
  ylab("In-situ temperature [K]") +
  scale_color_brewer(name = "Month", palette = "Dark2") +
  facet_wrap(vars(name)) +
  custom_theme()

ggsave("plots/comparison.pdf", device = cairo_pdf, width = 7, height = 4,
       units = "in")

## differences histogram -------------------------------------------------------
ggplot(test_long, aes(value - T)) +
  geom_histogram(bins = 20) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  xlab("Difference [K]") +
  ylab("Frequency") +
  facet_wrap(vars(name)) +
  custom_theme()

ggsave("plots/differences.pdf", device = cairo_pdf, width = 7, height = 4,
       units = "in")

## lakes with thermal profile --------------------------------------------------
thermal_profile = function(rast, mat) {
  line = vect(mat, type = "lines", crs = crs(rast))
  color = rev(RColorBrewer::brewer.pal(11, "RdYlBu"))

  # plot raster with legend
  plot(rast, axes = FALSE, col = color)
  sbar(type = "bar", below = "m", divs = 3, cex = 0.9)
  plot(line, col = "black", lwd = 2, add = TRUE)

  # create and smooth thermal profile
  val = terra::extract(rast, line)
  val = loess(val$lyr1 ~ seq_along(val$lyr1), span = 0.1)
  val = val$fitted
  dist = perim(line) / length(val)
  val = data.frame(val, dist = cumsum(rep(dist, length(val))))
  return(val)
}

### Drawsko lake
drawsko = rast("images/predict/Drawsko_T.tif")
ll = rbind(
  c(581229, 5935728),
  c(577066, 5939950)
)
drawsko_df = thermal_profile(drawsko, ll)

ggplot(drawsko_df, aes(dist, val)) +
  geom_line() +
  annotate("text", x = -0.6, y = 20.9, label = "A", fontface = 2) +
  annotate("text", x = 6000, y = 20.9, label = "B", fontface = 2) +
  scale_y_continuous(breaks = seq(19, 21, by = 0.25)) +
  xlab("Distance [km]") +
  ylab("Temperature [°C]") +
  custom_theme()

### Lebsko lake
lebsko = rast("images/predict/Lebsko_T.tif")
ll = rbind(
  c(656646, 6063543),
  c(649291, 6067007)
)
lebsko_df = thermal_profile(lebsko, ll)
ggplot(lebsko_df, aes(dist, val)) +
  geom_line() +
  annotate("text", x = -0.6, y = 18.9, label = "A", fontface = 2) +
  annotate("text", x = 8100, y = 18.9, label = "B", fontface = 2) +
  scale_y_continuous(breaks = seq(17, 19, by = 0.25)) +
  xlab("Distance [km]") +
  ylab("Temperature [°C]") +
  custom_theme()

## scenes availability ---------------------------------------------------------
lakes_temp = read.csv2("data/lakes_temp.csv")
lakes_temp$date = as.Date(lakes_temp$date)

hydro_stations = read.csv2("data/hydro_stations.csv")
lakes_temp = merge(lakes_temp, hydro_stations[, c(1, 3)], by = "ID")
lakes_temp$lake = as.factor(lakes_temp$lake)

TOA = read.csv2("data/TOA_processed.csv")
TOA$date = as.Date(TOA$date)
colnames(TOA)[1] = "ID"
TOA$month = as.factor(as.numeric(format(TOA$date, "%m")))
TOA$year = as.factor(format(TOA$date, "%Y"))

TOA = merge(TOA, lakes_temp, by = c("ID", "date"), all.x = TRUE)

n_lakes = length(unique(TOA$lake))
n_years = length(unique(TOA$year))

# availability by month
month_agg = data.frame(table(TOA$month) / n_lakes / n_years)
colnames(month_agg)[1] = "Month"
month_agg$Month = month.name[4:10]

# availability by year
year_agg = data.frame(table(TOA$year) / n_lakes)
colnames(year_agg)[1] = "Year"

# availability by lake
lakes_agg = data.frame(table(TOA$lake))
colnames(lakes_agg)[1] = "Lake"
lakes_agg$Lake = substring(lakes_agg$Lake, 6)

# availability by temperature
temp_agg = table(cut(TOA$T, seq(0, 28, by = 2)))
temp_agg = data.frame(temp_agg / n_years)
colnames(temp_agg)[1] = "Interval"

## plots
p1 = ggplot(month_agg, aes(Month, Freq)) +
  geom_col() +
  scale_x_discrete(limits = month_agg$Month) +
  ylab(NULL) +
  custom_theme()

p2 = ggplot(year_agg, aes(Year, Freq)) +
  geom_col() +
  ylab("Average number of scenes") +
  custom_theme()

p3 = ggplot(lakes_agg, aes(reorder(Lake, Freq), Freq)) +
  geom_col() +
  xlab("Lake") +
  ylab("Total number of scenes") +
  coord_flip() +
  custom_theme()

p4 = ggplot(temp_agg, aes(Interval, Freq)) +
  geom_col() +
  ylab(NULL) +
  xlab("Water temperature interval [°C]") +
  custom_theme()


right_side = plot_grid(p1, p2, p4, labels = c("b", "c", "d"), label_size = 14,
                       ncol = 1)
plot_grid(p3, right_side, labels = c("a", ""), label_size = 14, ncol = 2)
ggsave("plots/availability.pdf", device = cairo_pdf, width = 14, height = 10,
       units = "in")
