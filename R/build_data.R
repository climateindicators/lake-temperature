# Build tidy long-format data for the Lake Temperature indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# Generated as a stub by the build-indicator skill. Each figure below has a
# `todo_reshape()` call standing where its reshape belongs. Replace that line,
# then delete the todo_reshape() helper once no call to it remains.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Lake Temperature",
  slug                    = "lake-temperature",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-lake-temperature/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/sites/default/files/2021-03/documents/lake-temperature_td.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: Change in Temperature for Selected North American Lakes, 1985-2009 ----

f1_path <- file.path(raw_dir, "lake-temp_fig-1_data.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

assert_headers(
  f1_raw,
  id_cols          = c("Lake Name", "Latitude", "Longitude", "Significant?"),
  expected_headers = "Total change 1985-2009 (°F)",
  what             = "lake-temp_fig-1_data.csv"
)

# Already one row per lake, so no pivot: rename to tidy names and keep every
# value as character so the 10-digit source values survive byte for byte.
f1 <- f1_raw |>
  transmute(
    lake        = `Lake Name`,
    latitude    = Latitude,
    longitude   = Longitude,
    value       = `Total change 1985-2009 (°F)`,
    significant = `Significant?`
  )

write_csv_stable(f1, file.path(out_dir, "lake_temperature_fig1.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

# One entry per output column, in order, filled from the data frame itself so it
# cannot drift. `type` and `description` are deliberately blank: tests/test-data.R
# fails while either is empty, so every column has to be documented by hand.
describe <- function(df) {
  docs <- list(
    lake        = c("string", "Lake name."),
    latitude    = c("number", "Latitude of the lake in decimal degrees (north positive)."),
    longitude   = c("number", "Longitude of the lake in decimal degrees (west negative)."),
    value       = c("number", "Total change in average summer surface water temperature, 1985-2009, in degrees Fahrenheit."),
    significant = c("string", "Whether the change is statistically significant: Yes or No.")
  )
  lapply(names(df), function(nm) col(nm, docs[[nm]][1], docs[[nm]][2]))
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "lake_temperature_fig1.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "lake-temp_fig-1_data.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "windows-1252",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      rows            = nrow(f1),
      columns         = describe(f1)
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
