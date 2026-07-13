# Exposure of Workers to AI

**Code for:** Gabriel Demombynes, Jörg Langbein, and Michael Weber
(2025). *The Exposure of Workers to Artificial Intelligence in Low- and
Middle-Income Countries.* World Bank Policy Research Working Paper No.
11057.

**World Bank Reproducible Research Repository package `RR_WLD_2025_276`**

This repository contains the Stata code used to construct and analyze a
cross-country measure of workers' exposure to artificial intelligence, built
by applying the **AI Occupational Exposure (AIOE)** index to harmonized
household/labor-force survey microdata from the World Bank's **Global Labor
Database (GLD)** and **I2D2**.

- 📦 Reproducibility package (data availability, documentation, terms of use): https://reproducibility.worldbank.org/catalog/255 (DOI: [10.60572/7QR1-AM34](https://doi.org/10.60572/7QR1-AM34))
- 📄 Working paper (PDF): https://documents1.worldbank.org/curated/en/099629202052521198/pdf/IDU137d75e6614ee0145c919c7f1dc4831e7fa02.pdf
- 🔗 Publication landing page: https://openknowledge.worldbank.org/entities/publication/4a11a37d-149a-44fb-a941-100065ff5eb8

See [Citation](#citation) below for how to cite the paper and this
reproducibility package.

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

## Data sources

The underlying microdata are **not redistributed in this repository**
because of third-party data-sharing restrictions (see the reproducibility
package page linked above for access information). The inputs consumed by
the code, as read directly from the do-files, are:

- **Global Labor Database (GLD)** — the World Bank's harmonized collection
  of national household and labor-force survey microdata. `Harmonize and
  append survey.do` scans `$data/GLD-Add/last_survey` for one `.dta` extract
  per country/survey-round, keeps a common set of variables (occupation,
  industry, employment status, wages, hours, urban/rural, education,
  electricity and internet access, and survey weights), and appends them
  into a single cross-country panel (`GLD_All_last.dta`).
- **I2D2 (International Income Distribution Database)** — used for the
  United States. `I2D2 to GLD.do` takes a CPS-based I2D2 extract
  (`USA_2018_I2D2_CPS.dta`) and renames/recodes its variables (e.g. `gender`
  → `male`, `urb` → `urban`, `edulevel1-3` → `educat7`/`educat5`/`educat4`,
  `industry`/`industry1` → `industrycat10`/`industrycat4`) to match GLD
  conventions, producing `USA_GLD.dta`.
- **AI Occupational Exposure (AIOE) index** (Felten, Raj, and Seamans) — a
  measure of occupational exposure to AI defined at the level of the US
  Standard Occupational Classification (SOC). `ISCO SOC.do` imports a
  SOC-to-ISCO-08 crosswalk workbook (`ISCO_SOC_Crosswalk.xls`, sheet "2010
  SOC to ISCO-08") and merges in the AIOE score by SOC code
  (`SOCAIOE.dta`), producing an AIOE score at the 4-digit ISCO-08 level.
  Where a 4-digit ISCO code has no direct SOC match, the score is imputed
  hierarchically from the group average at the 3-, then 2-, then 1-digit
  ISCO level. A parallel crosswalk to US Census occupation codes
  (`CensusAIOE.dta`) is also produced.
- **World Bank World Development Indicators**, accessed live via the
  `wbopendata` package — GNI per capita, Atlas method, current US$
  (indicator `NY.GNP.PCAP.CD`) and the World Bank country income
  classification (High/Upper-middle/Lower-middle/Low income), used in
  `Analysis_AIOE_last.do` to group and plot AI exposure by country income
  level and against GNI per capita.
- **Auxiliary country benchmark surveys for electricity-access imputation**
  — `Imputation.do` fills in missing household/workplace electricity-access
  indicators for a handful of low- and lower-middle-income countries by
  fitting a logit model (on urban/rural location, industry, education, and
  sometimes hours worked) using a neighboring or regional country as the
  training benchmark, then classifying the missing cases at a 0.5 predicted-
  probability cutoff. This step draws on extra benchmark extracts not
  covered by the main GLD pull: `SLE_2011.dta`, `PAK_2015.dta`,
  `ZMB_2015.dta`, and `ZWE_2017.dta` (under `$data/Imputation/`). For
  countries with independently known electrification rates of ~99-100%
  (e.g. Brazil, Chile, Mexico, Thailand, Türkiye, the United States),
  electricity access is instead assumed directly rather than imputed.

**Note on pipeline completeness:** the do-files in this package pick up
from `GLD_All_AI_last.dta` in `Imputation.do` — i.e. the step that merges
the harmonized GLD/I2D2 panel (`GLD_All_last.dta`/`USA_GLD.dta`) with the
occupation-level AIOE crosswalk (`SOCISAIOE.dta`) into that file is not
itself included as a separate do-file here.

### Geographic coverage

Countries referenced explicitly in the code (mainly in the electricity-
imputation step of `Imputation.do`, plus the United States and Türkiye in
`Analysis_AIOE_last.do`) include: Bangladesh, Bolivia, Brazil, Chile,
Colombia, Egypt, Ethiopia, Georgia, The Gambia, India, Indonesia, Mexico,
Mongolia, Nepal, Pakistan, the Philippines, Rwanda, Sierra Leone, South
Africa, Sri Lanka, Tanzania, Thailand, Tunisia, Türkiye, the United States,
Zambia, and Zimbabwe. The full analysis sample is whatever set of GLD
country surveys is present under `$data/GLD-Add/last_survey` at run time,
so actual country/year coverage may be broader than this list.

### Key variables in the analysis file

`Analysis_AIOE_last.do` operates on a person-level panel with, among
others: `AIOE_adjusted` / `AIOE_adjusted_norm` (the AIOE score, rescaled
0-100), `AIOE_bin` (quartile groups: low / moderate-low / moderate-high /
high exposure), `occup` (1-digit ISCO-08) and `occup_isco_08` (4-digit
ISCO-08), `industrycat10`, `countrycode`/`countryname`, `year`, `male`,
`age`, `urban`, `educat4`, `empstat`, `electricity`, and `weight` (survey
sampling weight). It cross-tabulates AI exposure by country income group,
gender, age group, education, urban/rural location, industry, and
electricity access, runs country/occupation/industry-controlled OLS
regressions of AIOE on worker characteristics by income group, and checks
the sensitivity of the results to occupation-code granularity (1- vs 2- vs
4-digit ISCO) using Shannon/Simpson diversity measures (`entropyetc`).

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

If you use this code or refer to its results, please cite the working paper.
If you build on the reproducibility package itself (e.g. reuse or adapt the
code), please also cite the package.

### Working paper

**Plain text**

> Demombynes, Gabriel, Jörg Langbein, and Michael Weber. 2025. "The
> Exposure of Workers to Artificial Intelligence in Low- and Middle-Income
> Countries." Policy Research Working Paper No. 11057. World Bank,
> Washington, DC.
> https://openknowledge.worldbank.org/entities/publication/4a11a37d-149a-44fb-a941-100065ff5eb8

**RIS**

```ris
TY  - RPRT
AU  - Demombynes, Gabriel
AU  - Langbein, Jörg
AU  - Weber, Michael
PY  - 2025
TI  - The Exposure of Workers to Artificial Intelligence in Low- and Middle-Income Countries
PB  - World Bank
CY  - Washington, DC
T3  - Policy Research Working Paper
IS  - 11057
UR  - https://openknowledge.worldbank.org/entities/publication/4a11a37d-149a-44fb-a941-100065ff5eb8
ER  -
```

**BibTeX**

```bibtex
@techreport{demombynes2025exposure,
  author      = {Demombynes, Gabriel and Langbein, J{\"o}rg and Weber, Michael},
  title       = {The Exposure of Workers to Artificial Intelligence in Low- and Middle-Income Countries},
  institution = {World Bank},
  type        = {Policy Research Working Paper},
  number      = {11057},
  address     = {Washington, DC},
  year        = {2025},
  url         = {https://openknowledge.worldbank.org/entities/publication/4a11a37d-149a-44fb-a941-100065ff5eb8}
}
```

### Reproducibility package

**Plain text**

> Langbein, J., Demombynes, G., & Weber, M. (2025). Reproducibility package
> for *The Exposure Of Workers To Artificial Intelligence In Low- And
> Middle-Income Countries*. World Bank.
> https://doi.org/10.60572/7QR1-AM34

**RIS**

```ris
TY  - DATA
AU  - Langbein, Jörg
AU  - Demombynes, Gabriel
AU  - Weber, Michael
PY  - 2025
TI  - Reproducibility package for The Exposure Of Workers To Artificial Intelligence In Low- And Middle-Income Countries
PB  - World Bank
DO  - 10.60572/7QR1-AM34
UR  - https://doi.org/10.60572/7QR1-AM34
ER  -
```

**BibTeX**

```bibtex
@misc{langbein2025exposure_repro,
  author = {Langbein, J{\"o}rg and Demombynes, Gabriel and Weber, Michael},
  title  = {Reproducibility package for "The Exposure Of Workers To Artificial Intelligence In Low- And Middle-Income Countries"},
  howpublished = {World Bank Reproducible Research Repository, package RR\_WLD\_2025\_276},
  year   = {2025},
  doi    = {10.60572/7QR1-AM34},
  url    = {https://doi.org/10.60572/7QR1-AM34}
}
```
