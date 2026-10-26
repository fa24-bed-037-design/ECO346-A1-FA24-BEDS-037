# 03_age_earnings.R  (Question 3, and the redesign for Question 4)
# Every earner as a faint jittered point, plus the weighted mean of each
# five-year age band. Saved as figures/age_earnings.svg.
if (!dir.exists("data") && dir.exists("../data")) setwd("..")  # run from repo root
source("scripts/00_setup.R")

POINT_ALPHA <- 0.3    # transparency of the individual points (see README)

# ---- Age bands: 15-19, 20-24, ..., 60-64, plotted at midpoints 17, 22, ..., 62
earners <- earners %>%
  mutate(band_lo = 15 + 5 * floor((age - 15) / 5),
         band    = paste0(band_lo, "-", band_lo + 4),
         mid     = band_lo + 2)

band_table <- earners %>%
  group_by(band_lo, band, mid) %>%
  summarise(n       = n(),                          # unweighted count
            mean_w  = wmean(earn_annual, hhweight), # weighted mean
            .groups = "drop") %>%
  mutate(thin = n < 30)                             # fewer than 30 = thin

top <- band_table[which.max(band_table$mean_w), ]

# Points outside the Rs 10,000-10,000,000 axis cannot be drawn; the band means
# above still use every earner.
pts      <- earners %>% filter(earn_annual >= 1e4, earn_annual <= 1e7)
n_offaxis <- nrow(earners) - nrow(pts)

# ---- Figure ------------------------------------------------------------------
p <- ggplot() +
  geom_point(data = pts, aes(age, earn_annual),
             position = position_jitter(width = 0.4, height = 0, seed = 346),
             alpha = POINT_ALPHA, size = 1.3, colour = "grey30", stroke = 0) +
  geom_line(data = band_table, aes(mid, mean_w), colour = "#B5442C", linewidth = 0.9) +
  geom_point(data = band_table, aes(mid, mean_w, fill = thin),
             shape = 21, size = 3.4, stroke = 1.2, colour = "#B5442C") +
  scale_fill_manual(values = c(`FALSE` = "#B5442C", `TRUE` = "white"), guide = "none") +
  annotate("label", x = top$mid, y = top$mean_w * 2.6,
           label = paste0("Highest: ages ", top$band, "\nmean ", rupees(top$mean_w)),
           size = 3.3, colour = "#B5442C", fill = "white", label.size = 0) +
  annotate("segment", x = top$mid, xend = top$mid,
           y = top$mean_w * 2.0, yend = top$mean_w * 1.15,
           colour = "#B5442C", arrow = arrow(length = unit(0.15, "cm"))) +
  scale_y_log10(limits = c(1e4, 1e7), breaks = 10^(4:7), labels = rupees(10^(4:7))) +
  scale_x_continuous(limits = c(14.5, 64.5), breaks = c(seq(15, 60, 5), 64)) +
  labs(
    title = paste0("In ", PLACE, ", average earnings rise with age and peak at ",
                   top$band, "\n(", rupees(top$mean_w), " a year)"),
    x = "Age (years)",
    y = "Annual earnings (log scale)",
    caption = wrap(c(
      SOURCE_TXT,
      paste0("Sample: ", comma(nrow(earners)), " earners in ", PLACE,
             ", persons aged 15-64 with annual earnings above zero. Grey dots: one earner each, ",
             "jittered up to 0.4 years left or right",
             if (n_offaxis > 0) paste0(" (", n_offaxis, " outside the axis range not drawn)"), "."),
      paste0("Red markers: weighted mean earnings of each five-year age band at its midpoint, ",
             "weighted by household weight (hhweight). ",
             "Hollow markers: thin bands with fewer than 30 earners (unweighted).")))
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 12),
        plot.title.position = "plot",
        plot.caption = element_text(hjust = 0, colour = "grey35", size = 8),
        plot.caption.position = "plot",
        panel.grid.minor = element_blank())

ggsave("figures/age_earnings.svg", p, width = 8, height = 5.5)

# ---- Report ------------------------------------------------------------------
cat("\nQuestion 3 -", PLACE, "(variant", VARIANT, ")\n")
print(as.data.frame(band_table %>%
  transmute(band, earners = n, weighted_mean = round(mean_w), thin)), row.names = FALSE)
cat("\nBand 25-29 weighted mean:", rupees(band_table$mean_w[band_table$band == "25-29"]), "\n")
cat("Band 45-49 weighted mean:", rupees(band_table$mean_w[band_table$band == "45-49"]), "\n")
cat("Band with highest weighted mean:", top$band, "\n")
