# Project Structure

This document explains how the repository is organized and the purpose of every
major folder and file.

```
crypto-tweet-impact-analysis/
├── README.md                       # Project overview, setup, usage
├── PROJECT_STRUCTURE.md            # This file
├── LICENSE                         # MIT license
├── Makefile                        # Common tasks: deps, report, dashboard, clean
├── crypto-tweet-impact-analysis.Rproj   # RStudio project file
├── .gitignore                      # Excludes IDE state, build artifacts, raw data
│
├── analysis/
│   └── data_analysis.qmd           # ★ Main analysis: full DOGE + BTC event study
│
├── dashboard/
│   └── app.R                       # Standalone Shiny app: per-tweet BTC price reaction
│
├── data/
│   ├── README.md                   # Data dictionary + provenance
│   ├── processed/                  # Analysis-ready datasets (committed)
│   │   ├── sentiment_classified.csv          # Tweet-level sentiment + categories
│   │   ├── doge_daily_10years.csv            # DOGE/USD daily OHLCV
│   │   └── BTC_USD_data_2013_to_present.csv  # BTC/USD daily prices
│   └── raw/                        # Large source scrapes (git-ignored)
│       ├── all_musk_posts.csv
│       ├── musk_quote_tweets.csv
│       └── tweet_text_metadata.csv
│
├── reports/
│   ├── phase1_proposal.pdf         # Project proposal (compiled)
│   ├── phase2_report.pdf           # Phase-2 report (compiled)
│   └── figures/                    # Figures embedded in the reports
│       ├── dashboard.png
│       ├── sentiment_vs_returns.png
│       └── volatility_vs_volume.png
│
├── docs/
│   ├── phase1_proposal.tex         # LaTeX source for the proposal
│   └── phase2_report.tex           # LaTeX source for the phase-2 report
│
└── scripts/
    └── install_dependencies.R      # One-shot installer for all R dependencies
```

`★` marks the primary deliverable.

---

## Folder responsibilities

### `analysis/`
The single source of truth for the study. `data_analysis.qmd` is a Quarto
notebook (~2,300 lines) that runs the complete pipeline end-to-end:

- Data loading (auto-downloads price data from Yahoo Finance if absent)
- Cleaning, filtering, and feature engineering (multi-horizon returns)
- Event-study return computation against a random baseline
- Statistical testing: Welch t-tests, Mann-Whitney U, Cohen's d, one-sample
  t-tests, correlation/regression, **multiple-testing correction** (Bonferroni +
  FDR), and **power analysis**
- Separate DOGE and BTC hypothesis sections, results summary, and discussion

Rendering it produces a single self-contained HTML report
(`embed-resources: true`).

### `dashboard/`
`app.R` is a self-contained Shiny application extracted from the original
exploratory work. It lets you step through individual Bitcoin tweets and see the
30-day forward BTC price path plus realized 1-/7-/30-day returns. It loads data
directly from `data/` and degrades gracefully if the git-ignored raw text file
is missing.

### `data/`
Split into `processed/` (small, committed, analysis-ready) and `raw/` (large,
git-ignored source scrapes). See [`data/README.md`](data/README.md) for the full
data dictionary and provenance.

### `reports/`
Rendered deliverables meant to be read directly: the compiled PDF proposal and
phase-2 report, plus the figures they embed.

### `docs/`
LaTeX **sources** for the reports in `reports/`. Kept separate so the editable
sources don't clutter the read-only deliverables.

### `scripts/`
Helper scripts. `install_dependencies.R` installs every R package the analysis
and dashboard need.

---

## How paths work

The analysis notebook lives in `analysis/` and references data with paths
relative to its own location (e.g. `../data/processed/sentiment_classified.csv`),
which matches Quarto's default "render from the document's directory" behavior.
The dashboard resolves `data/` whether it is launched from the repo root
(`shiny::runApp("dashboard")`) or from inside `dashboard/`.
