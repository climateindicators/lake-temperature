# Regression checks on the generated data for the Lake Temperature indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 1 dataset(s)", length(meta$datasets) == 1L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")
f1 <- rd("lake_temperature_fig1.csv")
v1 <- as.numeric(f1$value)
check("fig1: 34 rows", nrow(f1) == 34L)
check("fig1: first row is Lake Athabasca, 59.47, -109.39, 1.812403296, No",
      identical(unlist(f1[1, ], use.names = FALSE),
                c("Lake Athabasca", "59.47", "-109.39", "1.812403296", "No")))
check("fig1: last row is Lake Winnipegosis, 52.66, -99.86, 2.361744, No",
      identical(unlist(f1[nrow(f1), ], use.names = FALSE),
                c("Lake Winnipegosis", "52.66", "-99.86", "2.361744", "No")))
check("fig1: value min is -0.81", f1$value[which.min(v1)] == "-0.81")
check("fig1: value max is 4.46256", f1$value[which.max(v1)] == "4.46256")
check("fig1: latitude range 20.23 to 66.47",
      f1$latitude[which.min(as.numeric(f1$latitude))] == "20.23" &&
        f1$latitude[which.max(as.numeric(f1$latitude))] == "66.47")
check("fig1: longitude range -160.52 to -60.79",
      f1$longitude[which.min(as.numeric(f1$longitude))] == "-160.52" &&
        f1$longitude[which.max(as.numeric(f1$longitude))] == "-60.79")
check("fig1: 9 significant, 25 not",
      identical(as.integer(table(f1$significant)[c("Yes", "No")]), c(9L, 25L)))

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
