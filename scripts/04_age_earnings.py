# 04_age_earnings.py  (Question 5)
# Recompute the Question 3 band table in Python and redraw the figure.
# Saved as figures/age_earnings_python.svg.
# Run from the repository root:  python scripts/04_age_earnings.py
import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")                       # draw to file, no window needed
import matplotlib.pyplot as plt
from matplotlib.ticker import FixedLocator, FuncFormatter, NullLocator

# If run from inside scripts/, step up to the repo root
if not os.path.isdir("data") and os.path.isdir("../data"):
    os.chdir("..")

# ---- Variant (same rule as 00_setup.R) ---------------------------------------
REG_NO = "FA24-BEDS-037"                     # <- your registration number
VARIANT = int(REG_NO[-2:]) % 8
PROV_CODE = [2, 2, 3, 3, 1, 1, 4, 4][VARIANT]
AREA_CODE = 1 if VARIANT % 2 == 0 else 2
PROV_NAME = {1: "Khyber Pakhtunkhwa", 2: "Punjab", 3: "Sindh", 4: "Balochistan"}[PROV_CODE]
AREA_NAME = {1: "rural", 2: "urban"}[AREA_CODE]
PLACE = f"{AREA_NAME} {PROV_NAME}"

# ---- Data: attach weight, province and area from the household file ---------
person = pd.read_csv("data/pslm_person_subset.csv", usecols=["hhid", "idc", "age", "earn_annual"])
hh = pd.read_csv("data/pslm_hh_subset.csv", usecols=["hhid", "hhweight", "prov_code", "urban_rural"])
d = person.merge(hh, on="hhid", how="left")

earners = d[(d.prov_code == PROV_CODE) & (d.urban_rural == AREA_CODE)
            & d.age.between(15, 64) & (d.earn_annual > 0)].copy()

# ---- Band table --------------------------------------------------------------
earners["band_lo"] = 15 + 5 * ((earners.age - 15) // 5)
earners["band"] = earners.band_lo.astype(int).astype(str) + "-" + (earners.band_lo + 4).astype(int).astype(str)
earners["mid"] = earners.band_lo + 2
earners["wx"] = earners.hhweight * earners.earn_annual

band = (earners.groupby(["band_lo", "band", "mid"])
        .agg(n=("age", "size"), sum_wx=("wx", "sum"), sum_w=("hhweight", "sum"))
        .reset_index())
band["mean_w"] = band.sum_wx / band.sum_w      # weighted mean = sum(w*x) / sum(w)
band["thin"] = band.n < 30
top = band.loc[band.mean_w.idxmax()]

def rupees(v):
    return f"Rs {round(v):,}"

# ---- Figure (matched to the R version) ----------------------------------------
pts = earners[(earners.earn_annual >= 1e4) & (earners.earn_annual <= 1e7)]
rng = np.random.default_rng(346)
jitter = rng.uniform(-0.4, 0.4, size=len(pts))  # at most 0.4 years left or right

red = "#B5442C"
fig, ax = plt.subplots(figsize=(8, 5.5))         # same size as ggsave(width=8, height=5.5)
ax.scatter(pts.age + jitter, pts.earn_annual, s=7, color="#4d4d4d", alpha=0.3, linewidths=0)
ax.plot(band.mid, band.mean_w, color=red, linewidth=1.8, zorder=3)
for _, r in band.iterrows():
    ax.scatter(r.mid, r.mean_w, s=80, zorder=4, edgecolors=red, linewidths=1.6,
               facecolors="white" if r.thin else red)
ax.annotate(f"Highest: ages {top.band}\nmean {rupees(top.mean_w)}",
            xy=(top.mid, top.mean_w * 1.15), xytext=(top.mid, top.mean_w * 2.6),
            ha="center", va="center", color=red, fontsize=9,
            arrowprops=dict(arrowstyle="->", color=red))

ax.set_yscale("log")
ax.set_ylim(1e4, 1e7)
ax.yaxis.set_major_locator(FixedLocator([1e4, 1e5, 1e6, 1e7]))
ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: rupees(v)))  # not 10^4
ax.yaxis.set_minor_locator(NullLocator())
ax.set_xlim(14.5, 64.5)
ax.set_xticks(list(range(15, 61, 5)) + [64])
ax.grid(True, color="#e6e6e6", linewidth=0.8)
for side in ["top", "right", "left", "bottom"]:
    ax.spines[side].set_visible(False)
ax.tick_params(length=0, colors="#4d4d4d")
ax.set_xlabel("Age (years)")
ax.set_ylabel("Annual earnings (log scale)")
fig.suptitle(f"In {PLACE}, average earnings rise with age and peak at {top.band}\n"
             f"({rupees(top.mean_w)} a year)", x=0.02, ha="left", fontweight="bold", fontsize=12)
fig.text(0.02, 0.01,
         "Source: Pakistan Bureau of Statistics, PSLM 2019-20 person file. Redrawn in Python (matplotlib).\n"
         f"Sample: {len(earners):,} earners in {PLACE}, aged 15-64 with annual earnings above zero. "
         "Grey dots: one earner each, jittered up to 0.4 years.\n"
         "Red markers: weighted mean earnings of each five-year age band (weighted by hhweight). "
         "Hollow markers: bands with fewer than 30 earners.",
         fontsize=7.5, color="#595959", ha="left", va="bottom")
fig.subplots_adjust(left=0.13, right=0.97, top=0.88, bottom=0.21)
fig.savefig("figures/age_earnings_python.svg")

# ---- Report ------------------------------------------------------------------
print(f"\nQuestion 5 (Python) - {PLACE} (variant {VARIANT})")
print(band.assign(weighted_mean=band.mean_w.round().astype(int))[["band", "n", "weighted_mean", "thin"]]
      .to_string(index=False))
print("\nBand 25-29 weighted mean (Python):", rupees(band.loc[band.band == "25-29", "mean_w"].iloc[0]))
