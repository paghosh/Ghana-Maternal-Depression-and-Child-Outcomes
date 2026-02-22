# Maternal Depression, Parental Investment, and Child Cognitive Development in Ghana

**Pallab Ghosh**
Department of Economics, University of Oklahoma

Draft: February 2026

---

## Overview

This repository contains the Stata code, estimation results, and summary reports for a study examining the relationship between maternal depression and child cognitive development in Ghana. Using three waves of the Ghana Socioeconomic Panel Survey (GSPS, 2009--2018), we estimate the effect of maternal depression---measured by the Kessler Psychological Distress Scale (K10)---on a composite cognitive index constructed from Raven's progressive matrices, digit span, math, and English tests.

**Main finding:** Maternal depression has **no statistically significant direct effect** on child cognitive outcomes. In the preferred EA fixed effects specification (N = 11,958), a one standard deviation increase in K10 depression is associated with a 0.002 SD change in child cognition (p = 0.834). This precisely estimated null holds across alternative depression measures, individual cognitive tests, child fixed effects, and an extensive battery of robustness checks. The one exception is a significant *positive* effect among children aged 10--14 (0.030 SD, p = 0.047), possibly reflecting compensatory parental behavior. Depression does significantly reduce reading/homework time by 29%, but this does not translate into cognitive deficits.

The repository also includes a **prenatal depression analysis** that identifies mothers who were depressed during pregnancy using pregnancy status at K10 measurement and retrospective birth timing. Prenatal depression also shows no effect on child cognition (coefficient = -0.002, p = 0.973).

## Data

**Ghana Socioeconomic Panel Survey (GSPS)**, Yale Economic Growth Center

| Wave | Year | Period |
|------|------|--------|
| Wave 1 | 2009 | Nov 2009 -- Apr 2010 |
| Wave 2 | 2012 | Mar 2014 -- Aug 2015 |
| Wave 3 | 2018 | 2018 |

**Sample sizes:**
- Full analysis sample: 13,746 mother--child pair-wave observations
- Preferred EA FE specification: 11,958 observations (334 EAs)
- Prenatal depression sample: 724 observations (150 EAs)

**Note:** The raw GSPS data files are excluded from the repository via `.gitignore`. The data can be obtained from the [Yale Economic Growth Center](https://egc.yale.edu/) and should be placed in the `data/` directory.

## Key Variables

| Variable | Description |
|----------|-------------|
| **K10 Depression (std.)** | Kessler Psychological Distress Scale, 10 items, standardized to mean 0, SD 1 |
| **Depressed (binary)** | K10 >= 20 (standard cutoff) or K10 >= 30 (severe, used in prenatal analysis) |
| **Cognitive Index** | Standardized average of Raven's, digit span forward/backward, math, English |
| **Controls** | Child age, child gender, mother's age, household size, log per capita consumption |
| **Fixed effects** | Enumeration area (EA) FE, wave FE; also child FE and household FE in robustness |

## Repository Structure

```
.
├── README.md
├── .gitignore
├── programs/stata/
│   ├── Draft1_Feb2026/                # Concurrent depression analysis
│   │   ├── master.do                  # Pipeline runner (defines paths, runs all do files)
│   │   ├── install_packages.do        # Installs required Stata packages
│   │   ├── 00_data_cleaning.do        # Merges GSPS waves, constructs all variables
│   │   ├── 01_summary_stats.do        # Summary statistics (Tables 1-5)
│   │   ├── 02_main_estimation.do      # Main results: OLS, EA FE, child FE (Tables 6-12)
│   │   ├── 02b_revised_estimation.do  # Revised full-sample EA FE specifications
│   │   ├── 03_mechanisms.do           # Channel analysis: time, financial, nutrition, health (Tables 13-18)
│   │   ├── 04_robustness.do           # Robustness checks (Tables A1-A9)
│   │   └── *.log                      # Stata log files
│   └── Draft1_Feb2026_MH_Pregnancy/   # Prenatal depression analysis
│       ├── 03_prenatal_depression.do   # Prenatal identification & estimation (Tables P1-P2)
│       └── 03_prenatal_depression.log
├── rersults/
│   ├── Draft1_Feb2026/                # 27 tables in LaTeX (.tex), text (.txt), and CSV formats
│   │   ├── All_Tables.pdf             # Compiled PDF of all tables
│   │   ├── All_Tables.tex             # LaTeX master document
│   │   ├── SummaryStatistics.xlsx     # Summary statistics spreadsheet
│   │   ├── Table1_SummaryStats.*
│   │   ├── Table2_BalanceByDepression.*
│   │   ├── ...
│   │   └── TableA9_RobClustering.*
│   └── Draft1_Feb2026_MH_Pregnancy/   # Prenatal analysis tables and summary
│       ├── All_Tables.pdf
│       ├── All_Tables.tex
│       ├── Results_Summary.pdf        # Full narrative summary of prenatal analysis
│       ├── Results_Summary.tex
│       ├── TableP1_PrenatalDepression.*
│       └── TableP2_PrenatalSensitivity.*
├── Draft/Draft1_Feb2026/
│   ├── Results_Summary.pdf            # Full narrative summary of main analysis
│   ├── Results_Summary.tex
│   └── Results_Summary_Prenatal_Depression.pdf
├── data/                              # Raw GSPS data (excluded from git via .gitignore)
└── references/                        # Key literature
    ├── baranov-et-al-2020-maternal-depression-womens-empowerment-...pdf
    ├── JHR_2016_Anna_Aizer.pdf
    ├── JHR_2020.pdf
    ├── NBER 2016.pdf
    └── persson-rossin-slater-2018-family-ruptures-stress-...pdf
```

**Note:** The `data/` directory containing raw GSPS data files and `*.dta` intermediate data files are excluded from the repository via `.gitignore`.

## Results Tables

### Main Analysis

| Table | Description |
|-------|-------------|
| **Summary Statistics** | |
| Table 1 | Summary Statistics: Full Analysis Sample |
| Table 2 | Balance by Maternal Depression Status |
| Table 3 | Summary Statistics by Wave |
| Table 4 | Depression Severity Distribution by Wave |
| Table 5 | Correlation Matrix |
| **Main Results** | |
| Table 6 | Main Results: Depression and Cognitive Index (OLS, EA FE, Child FE) |
| Table 6b | Additional Specifications (Raven's, binary, severity, lagged, persistent) |
| Table 6c | Heterogeneity by Child Age Group (Full Sample) |
| Table 7 | Results by Individual Test (Raven's, DSF, DSB, Math, English) |
| Table 8 | Binary Depression (K10 >= 20) |
| Table 9 | Depression Severity Categories (Mild, Moderate, Severe) |
| Table 10 | Anthropometry (Height-for-age, Weight-for-age) |
| Table 11 | Heterogeneity by Child Age |
| Table 12 | Heterogeneity by Child Gender |
| **Mechanism Channels** | |
| Table 13 | Channel 1: Parental Time Investment |
| Table 14 | Channel 2: Financial Investment (Food Expenditure) |
| Table 15 | Channel 3: Child Nutritional Status |
| Table 16 | Channel 4: Stimulation Quality |
| Table 17 | Mediation Analysis |
| Table 18 | Child Health Channel |
| **Robustness** | |
| Table A1 | Alternative Depression Measures |
| Table A2 | Alternative Fixed Effects Specifications |
| Table A3 | Subsample Analyses (Urban/Rural, Poor/Non-Poor) |
| Table A4 | Value-Added Model |
| Table A5 | Placebo and Falsification Tests |
| Table A6 | Non-Linear Effects |
| Table A7 | IPW Attrition Correction |
| Table A8 | Alternative Cognitive Outcomes |
| Table A9 | Alternative Standard Error Clustering |

### Prenatal Depression Analysis

| Table | Description |
|-------|-------------|
| Table P1 | Effect of Prenatal Depression on Child Cognition (OLS, EA FE, Binary, +Concurrent) |
| Table P2 | Sensitivity: Alternative Timing Windows, Raven's, Strategy A Only |

## Software Requirements

- **Stata SE** (version 14 or later)
- Required packages (installed automatically by `install_packages.do`):
  - `estout` (esttab for table output)
  - `reghdfe` (high-dimensional fixed effects)
  - `ftools` (fast Stata tools, required by reghdfe)

## How to Run

1. Obtain the GSPS data and place it in the `data/` directory
2. Edit the file paths in `programs/stata/Draft1_Feb2026/master.do` to match your local setup
3. Run `master.do` to execute the full pipeline:
   ```
   cd programs/stata/Draft1_Feb2026
   stata-se -b -e master.do
   ```
4. For the prenatal analysis, run separately:
   ```
   cd programs/stata/Draft1_Feb2026_MH_Pregnancy
   stata-se -b -e 03_prenatal_depression.do
   ```

## Summary of Key Findings

| Specification | Coefficient | SE | p-value | N |
|---|---|---|---|---|
| **Main: EA FE (preferred)** | **0.002** | **(0.010)** | **0.834** | **11,958** |
| Main: Child FE | 0.014 | (0.019) | 0.462 | 6,583 |
| Main: Ages 10--14 | 0.030** | (0.015) | 0.047 | 5,135 |
| Channel: Reading/HW time | -0.278** | (0.110) | 0.012 | 1,081 |
| Prenatal: EA FE | -0.002 | (0.052) | 0.973 | 724 |

\*\* p < 0.05

## Key References

The `references/` folder contains key papers from the literature on maternal mental health and child development:

- **Baranov et al. (2020)** -- "Maternal Depression, Women's Empowerment, and Parental Investment: Evidence from a Randomized Controlled Trial." *American Economic Review*. Randomized evidence from Pakistan on how treating maternal depression affects parental investment and child outcomes.
- **Aizer (2016)** -- *Journal of Human Resources*. Examines the causal effect of maternal stress during pregnancy on child outcomes.
- **Persson & Rossin-Slater (2018)** -- "Family Ruptures, Stress, and the Mental Health of the Next Generation." *American Economic Review*. Studies how prenatal maternal stress from family ruptures affects children's mental health.

## Citation

```
Ghosh, P. (2026). Maternal Depression, Parental Investment, and Child Cognitive
Development in Ghana. Working Paper, University of Oklahoma.
```

## License

This project is for academic research purposes.
