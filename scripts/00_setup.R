# 00_setup.R
# Shared setup. Every R script below starts with source("scripts/00_setup.R").
# It loads packages, works out the variant, builds the earners sample,
# and defines the weighted statistics used everywhere.

# If the script is run from inside scripts/ (e.g. in RStudio), step up to the repo root
if (!dir.exists("data") && dir.exists("../data")) setwd("..")

suppressPackageStartupMessages({
  library(dplyr)    # filter, join, group_by, summarise
  library(ggplot2)  # figures
  library(scales)   # comma() for rupee labels
})
# svglite must also be installed: ggsave() uses it to write .svg files

# ---- Variant -----------------------------------------------------------------
REG_NO  <- "FA24-BEDS-037"                       # <- your registration number
VARIANT <- as.integer(substr(REG_NO, nchar(REG_NO) - 1, nchar(REG_NO))) %% 8

# Variant table from the assignment: 0 Punjab rural, 1 Punjab urban, 2 Sindh rural,
# 3 Sindh urban, 4 KP rural, 5 KP urban, 6 Balochistan rural, 7 Balochistan urban.
# prov_code: 1 = KP, 2 = Punjab, 3 = Sindh, 4 = Balochistan; urban_rural: 1 rural, 2 urban
PROV_CODE  <- c(2, 2, 3, 3, 1, 1, 4, 4)[VARIANT + 1]
AREA_CODE  <- ifelse(VARIANT %% 2 == 0, 1, 2)
PROV_NAME  <- c("Khyber Pakhtunkhwa", "Punjab", "Sindh", "Balochistan")[PROV_CODE]
AREA_NAME  <- c("rural", "urban")[AREA_CODE]
PLACE      <- paste(AREA_NAME, PROV_NAME)        # e.g. "urban Punjab"

# ---- Data --------------------------------------------------------------------
# The person file has no weight, province or area, so attach them from the
# household file by hhid.
person <- read.csv("data/pslm_person_subset.csv")[, c("hhid", "idc", "age", "earn_annual")]
hh     <- read.csv("data/pslm_hh_subset.csv")[, c("hhid", "hhweight", "prov_code", "urban_rural")]

earners <- person %>%
  left_join(hh, by = "hhid") %>%
  filter(prov_code == PROV_CODE,
         urban_rural == AREA_CODE,
         age >= 15, age <= 64,
         !is.na(earn_annual), earn_annual > 0)

# ---- Weighted statistics -----------------------------------------------------
# Weighted mean: sum(w * x) / sum(w)
wmean <- function(x, w) sum(w * x) / sum(w)

# Weighted p-th quantile, exactly as the assignment defines it:
# sort by x, compute the cumulative share of weight, and take the smallest x
# at which that share reaches or exceeds p.
wquantile <- function(x, w, p) {
  o     <- order(x)
  x     <- x[o]
  share <- cumsum(w[o]) / sum(w)
  x[which(share >= p)[1]]
}

# Label rupees with thousands separators, e.g. 100000 -> "Rs 100,000"
rupees <- function(v) paste0("Rs ", comma(round(v), accuracy = 1))

# Same caption source line for every figure
SOURCE_TXT <- "Source: Pakistan Bureau of Statistics, PSLM 2019-20 person file."

# Wrap long caption text so it fits the figure width (one paragraph per element)
wrap <- function(parts, width = 135) {
  paste(sapply(parts, function(t) paste(strwrap(t, width), collapse = "\n")), collapse = "\n")
}
