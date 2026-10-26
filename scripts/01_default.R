# 01_default.R  (Question 4, part 1)
# Earnings against age with R's defaults, untouched. Saved as figures/default.svg.
if (!dir.exists("data") && dir.exists("../data")) setwd("..")  # run from repo root
source("scripts/00_setup.R")

p <- ggplot(earners, aes(age, earn_annual)) + geom_point()

ggsave("figures/default.svg", p, width = 8, height = 5.5)
cat("Saved figures/default.svg with", nrow(earners), "earners\n")
