# =============================================================================
# install_dependencies.R
# -----------------------------------------------------------------------------
# Installs every R package required to render the analysis (analysis/data_analysis.qmd)
# and run the dashboard (dashboard/app.R). Run once from the repository root:
#
#     Rscript scripts/install_dependencies.R
# =============================================================================

required_packages <- c(
  # Core tidyverse + modeling
  "tidyverse",    # dplyr, ggplot2, readr, stringr, tibble, purrr, ...
  "lubridate",    # date handling
  "broom",        # tidy() / glance() model summaries
  "tseries",      # time-series utilities

  # Statistics
  "pwr",          # power analysis (pwr.t.test)

  # Market data
  "quantmod",     # Yahoo Finance price downloads (getSymbols)

  # Reporting / tables
  "knitr",
  "kableExtra",

  # Interactive dashboard
  "shiny"
)

installed <- rownames(installed.packages())
to_install <- setdiff(required_packages, installed)

if (length(to_install) == 0) {
  message("All required packages are already installed.")
} else {
  message("Installing: ", paste(to_install, collapse = ", "))
  install.packages(to_install, repos = "https://cloud.r-project.org")
}

invisible(lapply(required_packages, function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    warning("Package failed to install or load: ", pkg)
  }
}))

message("Dependency check complete.")
