# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-lake-temperature/index.html>  \
  sha256 `c9698f5e4b4b072955b08bb93e32a288d0bad69ea542c4ebd5e3190fb6d7b9cb`

Technical documentation: <https://19january2025snapshot.epa.gov/sites/default/files/2021-03/documents/lake-temperature_td.pdf>

## Figure data

- `lake-temp_fig-1_data.csv`  \
  <https://19january2025snapshot.epa.gov/sites/default/files/2021-03/lake-temp_fig-1_data.csv>  \
  sha256 `7f4893dd6032371977052c72c188193471db98bfba3fa8fc93fe715abe296f87`  \
  encoding windows-1252, 34 data rows, columns: `Lake Name`, `Latitude`, `Longitude`, `Total change 1985-2009 (°F)`, `Significant?`  \
  title: Figure 1. Change in Temperature for Selected North American Lakes, 1985-2009  \
  data source: Sharma et al., 2015; web update: April 2021; units: °F
