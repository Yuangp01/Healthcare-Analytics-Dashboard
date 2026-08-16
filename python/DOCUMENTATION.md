# 🐍 Python — Healthcare Data Cleaning Pipeline

[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![pandas](https://img.shields.io/badge/pandas-Data%20Cleaning-150458?logo=pandas&logoColor=white)](https://pandas.pydata.org/)
[![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-F37626?logo=jupyter&logoColor=white)](https://jupyter.org/)

> **The ingestion layer of the [Healthcare Operations Analytics](../) project — turns nine raw Synthea tables into validated, analysis-ready CSVs consumed by the SQL Server warehouse and Power BI model.**

This notebook is step 1 of a 3-stage pipeline: **Python (this repo) → SQL Server → Power BI.** It exists because a dashboard is only as trustworthy as the data feeding it — every table here is typed, validated, and asserted-clean before it's allowed downstream.

---


## Overview

`01_data_cleaning.ipynb` cleans nine raw Synthea tables — patients, providers,
organizations, payers, encounters, conditions, procedures, claims, and claims
transactions — through a consistent **load → profile → clean → validate → export**
process, then applies a single consistent reporting window across every fact
table.

## What It Does

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

## 🧠 Design Decisions

*The choices here — not just the code — are what this notebook is meant to demonstrate.*

- **Full scope cleaned before windowing.** Every fact table is validated at full historical scope first, then a single `ANALYSIS_START`/`ANALYSIS_END` window is applied last and identically across all five. This keeps the "clean" and "in-scope" concerns separate, so the reporting window can change with a one-line edit instead of re-deriving logic per table.
- **Keyword-and-override lookup for clinical categories**, rather than a giant manual `if/else` per condition. New raw condition strings fall into a category by keyword match by default, with an explicit override list for exceptions — new Synthea condition text doesn't silently fall through uncategorized.
- **Assertions before export, not after.** Each table fails loudly (primary key uniqueness, date logic, non-negative financials) before it's ever written to `data/processed/`, so a broken table can't reach the SQL warehouse.
- **Both full and windowed CSVs are exported** for fact tables, so downstream consumers (ad hoc analysis vs. the production dashboard) can choose full history or the reporting window without re-running the pipeline.

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

## 📂 Repository Structure
