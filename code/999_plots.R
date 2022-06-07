library("tidyr")
library("terra")
library("ggplot2")

if (!dir.exists("plots")) dir.create("plots")

## variable importance
mdl = readRDS("results/rf_model.rds")

imp = data.frame(importance = mdl$variable.importance)
rownames(imp)[10] = "Month"
ggplot(imp, aes(x = reorder(rownames(imp), importance), y = importance)) +
  geom_col() +
  xlab("Feature") +
  ylab("Importance") +
  coord_flip()  +
  theme_bw() +
  theme(panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text = element_text(color = "black"),
        axis.line = element_line(colour = "black", size = 0.5),
        axis.title = element_text(face = "bold"))


ggsave("plots/importance.pdf", device = cairo_pdf, width = 4, height = 3,
       units = "in")

## point plot
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
  theme_bw() +
  theme(panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text = element_text(color = "black"),
        axis.line = element_line(colour = "black", size = 0.5),
        axis.title = element_text(face = "bold"),
        strip.background = element_rect(fill = NA, colour = NA))

ggsave("plots/comparison.pdf", device = cairo_pdf, width = 7, height = 4,
       units = "in")

## differences histogram
ggplot(test_long, aes(T - value)) +
  geom_histogram(bins = 20) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  xlab("Difference [K]") +
  ylab("Frequency") +
  facet_wrap(vars(name)) +
  theme_bw() +
  theme(panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text = element_text(color = "black"),
        axis.line = element_line(colour = "black", size = 0.5),
        axis.title = element_text(face = "bold"),
        strip.background = element_rect(fill = NA, colour = NA))

ggsave("plots/differences.pdf", device = cairo_pdf, width = 7, height = 4,
       units = "in")


## lakes with thermal profile
plot_thermal = function(rast, mat) {
  line = vect(mat, type = "lines", crs = crs(rast))
  oldpar = par()
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
  par(oldpar)

  # plot thermal profile
  plot(val$val ~ val$dist, type = "l", lwd = 4, xlab = NULL, cex.lab = 1.5,
       cex.axis = 1.3, ylab = "Temperature [°C]", xaxt = "n")
}

### Drawsko
drawsko = rast("images/predict/Drawsko_T.tif")
ll = rbind(
  c(581229, 5935728),
  c(577066, 5939950)
)
plot_thermal(drawsko, ll)

### Lebsko
lebsko = rast("images/predict/Lebsko_T.tif")
ll = rbind(
  c(656646, 6063543),
  c(649291, 6067007)
)
plot_thermal(lebsko, ll)
