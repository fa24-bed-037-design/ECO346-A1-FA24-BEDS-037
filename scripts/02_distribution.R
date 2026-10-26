# 02_distribution.R  (Question 2)
# Weighted histogram of annual earnings on a log10 scale, with the weighted
# median and 90th percentile marked. Saved as figures/distribution.svg.
if (!dir.exists("data") && dir.exists("../data")) setwd("..")  # run from repo root
source("scripts/00_setup.R")

x <- earners$earn_annual
w <- earners$hhweight

# ---- Numbers to report (computed on ALL earners) ----------------------------
n_earners  <- nrow(earners)
median_w   <- wquantile(x, w, 0.5)
median_u   <- wquantile(x, rep(1, n_earners), 0.5)  # every person weight 1
p10_w      <- wquantile(x, w, 0.1)
p90_w      <- wquantile(x, w, 0.9)
ratio_9010 <- p90_w / p10_w

# ---- Histogram bins: 0.1 wide in log10 units, from 4.0 to 7.0 ---------------
in_range   <- x >= 1e4 & x <= 1e7          # Rs 10,000 to Rs 10,000,000
n_excluded <- sum(!in_range)

breaks <- round(seq(4, 7, by = 0.1), 1)    # 31 edges -> 30 bins
hist_data <- earners[in_range, ] %>%
  mutate(lx  = log10(earn_annual),
         bin = findInterval(lx, breaks, rightmost.closed = TRUE)) %>%
  group_by(bin) %>%
  summarise(weight = sum(hhweight), .groups = "drop") %>%
  mutate(xmin    = breaks[bin],
         xmax    = breaks[bin + 1],
         # density per log10 unit: share of weight in the bin / bin width
         density = (weight / sum(weight)) / 0.1)

# ---- Figure ------------------------------------------------------------------
y_top <- max(hist_data$density)

p <- ggplot(hist_data) +
  geom_rect(aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = density),
            fill = "#4C7EA8", colour = "white", linewidth = 0.3) +
  geom_vline(xintercept = log10(median_w), linetype = "dashed", colour = "grey15") +
  geom_vline(xintercept = log10(p90_w),    linetype = "dashed", colour = "#B5442C") +
  annotate("text", x = log10(median_w), y = y_top * 1.06, hjust = 1.05,
           label = paste0("Median\n", rupees(median_w)), size = 3.4, colour = "grey15") +
  annotate("text", x = log10(p90_w), y = y_top * 1.06, hjust = -0.05,
           label = paste0("90th percentile\n", rupees(p90_w)), size = 3.4, colour = "#B5442C") +
  scale_x_continuous(limits = c(4, 7), breaks = 4:7, labels = rupees(10^(4:7)),
                     expand = expansion(mult = 0.03)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = paste0("Half of earners in ", PLACE, " make under ", rupees(median_w),
                   " a year;\nthe top tenth make over ", rupees(p90_w)),
    x = "Annual earnings (log scale)",
    y = "Density per log10 unit",
    caption = wrap(c(
      SOURCE_TXT,
      paste0("Sample: ", comma(n_earners), " earners in ", PLACE,
             ", persons aged 15-64 with annual earnings above zero."),
      paste0("All statistics weighted by household weight (hhweight). Excluded from the histogram: ",
             n_excluded, " earner(s) outside Rs 10,000-10,000,000 (still counted in the median and 90th percentile).")))
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 12),
        plot.title.position = "plot",
        plot.caption = element_text(hjust = 0, colour = "grey35", size = 8),
        plot.caption.position = "plot",
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        plot.margin = margin(10, 40, 10, 10))

ggsave("figures/distribution.svg", p, width = 8, height = 5.5)

# ---- Report ------------------------------------------------------------------
cat("\nQuestion 2 -", PLACE, "(variant", VARIANT, ")\n")
cat("Number of earners:            ", n_earners, "\n")
cat("Weighted median:              ", rupees(median_w), "\n")
cat("Unweighted median:            ", rupees(median_u), "\n")
cat("Weighted 10th percentile:     ", rupees(p10_w), "\n")
cat("Weighted 90th percentile:     ", rupees(p90_w), "\n")
cat("P90 / P10 ratio:              ", sprintf("%.2f", ratio_9010), "\n")
cat("Excluded from histogram:      ", n_excluded, "\n")
