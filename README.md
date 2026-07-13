# Exposure of Workers to AI

**World Bank Reproducible Research Repository package `RR_WLD_2025_276`**

This repository contains the Stata code used to construct and analyze a
cross-country measure of workers' exposure to artificial intelligence, built
by applying the **AI Occupational Exposure (AIOE)** index to harmonized
household/labor-force survey microdata from the World Bank's **Global Labor
Database (GLD)** and **I2D2**.

- 📦 Reproducibility package (data availability, documentation, terms of use): https://reproducibility.worldbank.org/catalog/255
- 📄 Working paper (PDF): https://documents1.worldbank.org/curated/en/099629202052521198/pdf/IDU137d75e6614ee0145c919c7f1dc4831e7fa02.pdf
- 🔗 Publication landing page: https://openknowledge.worldbank.org/entities/publication/4a11a37d-149a-44fb-a941-100065ff5eb8

For the full abstract, author list, and citation details, please refer to the
publication landing page and PDF linked above.

## What the code does

The do-files build a harmonized, occupation-level panel across countries and
attach an AI exposure score to each worker based on their occupation, then
use it to describe how exposure to AI varies with country income level,
gender, age, education, urban/rural location, industry, and electricity
access (used as a proxy for the infrastructure needed to make use of
AI-enabled technologies).

The AIOE index (Felten, Raj, and Seamans) is originally defined at the level
of the US Standard Occupational Classification (SOC). It is cross-walked to
the 4-digit ISCO-08 occupational classification used in GLD/I2D2, with
missing scores imputed hierarchically at the 3-, 2-, and 1-digit ISCO level
where a 4-digit match is unavailable.

## Repository structure

```
Code/
├── I2D2 to GLD.do            Harmonizes the US I2D2/CPS extract into GLD-style variables
├── Harmonize and append survey.do   Appends the harmonized GLD country surveys into one panel
├── ISCO SOC.do                Builds the ISCO-08 <-> US SOC crosswalk and merges/imputes AIOE scores
├── ISCO.do                    Placeholder (empty in this package)
├── Imputation.do               Imputes missing electricity-access indicators by country
├── Analysis_AIOE_last.do       Final descriptive statistics, regressions, figures, and tables
└── ado/                        User-written Stata packages pinned for reproducibility (see below)
```

### Suggested run order

1. `I2D2 to GLD.do`
2. `Harmonize and append survey.do`
3. `ISCO SOC.do`
4. `Imputation.do`
5. `Analysis_AIOE_last.do`

Each do-file reads from and writes to paths under a `$data` global (and, in
the analysis file, `$figure` and `$tables` globals for output). These globals
are not defined in the do-files themselves — set them (e.g., in a
`profile.do` or at the top of a master script) to point at your local copy of
the underlying microdata before running the pipeline.

## Data

The underlying microdata (GLD and I2D2 country survey extracts, the
ISCO-SOC/AIOE crosswalk workbook, and World Bank income-classification and
GNI-per-capita series) are **not redistributed in this repository** because
of third-party data-sharing restrictions. See the reproducibility package
page linked above for information on data availability and access.

## Software requirements

The code was written for **Stata**. All user-written packages used by the
do-files are bundled under [`Code/ado`](Code/ado) so that the exact package
versions used for the analysis are pinned, following the World Bank DIME
Analytics reproducibility conventions (`repkit`/`repado`/`reproot`). Bundled
packages include:

- `estout` (estout, esttab, eststo, estadd, estpost) — regression tables
- `wbopendata` — World Bank Open Data API access (e.g., GNI per capita, income classification)
- `grstyle` / `grc1leg` — graph styling and combined legends
- `filelist` — recursive directory search for appending survey files
- `iscogen` / `iscolbl` — ISCO occupation code recoding and labeling
- `entropyetc` / `entropyetc2` — entropy/diversity measures used in the occupation-detail robustness checks
- `repkit` (`repado`, `reprun`, `reproot`) and `lint` — DIME Analytics reproducibility and code-linting toolkit (the `lint` command also relies on the Python scripts under `Code/ado/py`, which require Python with `pandas`)

## Citation

Please cite the underlying working paper when using this code or referring to
its results. See the publication landing page above for the full citation.
