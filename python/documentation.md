# (Python) Healthcare Data Cleaning Pipeline 

A Python/pandas pipeline that takes raw synthetic healthcare data and produces
analysis-ready, validated tables for downstream use in SQL Server and Power BI.

## Overview

`01_data_cleaning.ipynb` cleans nine raw Synthea tables — patients, providers,
organizations, payers, encounters, conditions, procedures, claims, and claims
transactions — through a consistent load → profile → clean → validate → export
process, then applies a single consistent reporting window across every fact
table.

## What it does

**Dimension tables** (`patients`, `providers`, `organizations`, `payers`) are
cleaned and exported at full scope:

- Type conversion (dates, numerics)
- Derived fields (e.g. patient age, age group, deceased flag)
- Missing-value handling with explicit, documented defaults
- Key uniqueness and range validation before export

**Fact tables** (`encounters`, `conditions`, `procedures`, `claims`,
`claims_transactions`) are cleaned at full scope, then windowed consistently:

- Encounter duration, standardized encounter category, and financial metrics
  (patient responsibility, payer coverage rate) derived from raw cost fields
- Clinical condition names mapped to a defined set of clinical categories
  (Cardiovascular, Respiratory, Metabolic/Endocrine, etc.) via a single
  keyword-and-override lookup
- A single `ANALYSIS_START` / `ANALYSIS_END` window applied identically
  across all five fact tables, so every table in the downstream model
  reflects the same reporting period
- Assertions on primary keys, date logic, and non-negative financial values
  before each table is exported

## Output

Running the notebook top to bottom produces, in `data/processed/`:

| File | Scope |
|---|---|
| `patients_clean.csv` | full |
| `providers_clean.csv` | full |
| `organizations_clean.csv` | full |
| `payers_clean.csv` | full |
| `encounters_clean.csv` | full |
| `encounters_2020_2022.csv` | windowed |
| `conditions_clean.csv` | full |
| `conditions_2020_2022.csv` | windowed |
| `procedures_clean.csv` | full |
| `procedures_2020_2022.csv` | windowed |
| `claims_clean.csv` | full |
| `claims_2020_2022.csv` | windowed |
| `claims_transactions_clean.csv` | full |
| `claims_transactions_2020_2022.csv` | windowed |

These files feed the [SQL Data Warehouse](../sql-warehouse) load scripts.

## Tech Stack

- Python
- pandas
- Jupyter Notebook

## Setup

1. Generate a Synthea population and export as CSV (see
   [Synthea's documentation](https://synthetichealth.github.io/synthea/)).
2. Place the raw CSVs in `data/raw/`.
3. Run `01_data_cleaning.ipynb` top to bottom.
4. Cleaned and windowed tables are written to `data/processed/`.

## Data Source

Built entirely on synthetic data generated with Synthea. No real patient
data is used anywhere in this project.
