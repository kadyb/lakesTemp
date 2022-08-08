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
