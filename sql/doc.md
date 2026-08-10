# SQL Data Warehouse & Analytics

T-SQL scripts that load, validate, transform, and analyze cleaned healthcare
data (patients, encounters, conditions, procedures, claims) into a SQL Server
data warehouse, feeding a downstream Power BI executive dashboard.

## Overview

This repository takes the cleaned CSV output from the
[data cleaning pipeline](../healthcare-data-cleaning) and loads it into a
dimensional SQL Server warehouse, following a standard ETL flow: schema
creation → table creation → data load → validation → analysis.

## Workflow

| Step | Script | Description |
|---|---|---|
| 1. Initialize | `scripts/01_init_database.sql` | Creates the database and `bronze` / `silver` / `gold` schemas |
| 2. Create tables | `scripts/02_create_tables.sql` | Defines staging and warehouse table structures |
| 3. Load data | `scripts/03_load_data.sql` | Bulk loads cleaned CSVs via `BULK INSERT` |
| 4. Validate | `scripts/04_validate_data.sql` | Row counts, null checks, referential integrity, duplicate keys |
| 5. Transform | `scripts/05_transform_gold.sql` | Builds the star-schema fact/dimension tables |
| 6. Analyze | `scripts/06_analysis_queries.sql` | Ad hoc and dashboard-supporting analytical queries |

## Architecture

```
Raw CSV (data/processed/)
        ↓
   Bronze layer      — raw load, as-is from source
        ↓
   Silver layer       — cleaned, typed, deduplicated
        ↓
   Gold layer          — star schema (FactAdmissions + dimensions)
        ↓
   Power BI Dashboard
```

## Data Model

Star schema centered on `FactAdmissions`, surrounded by:

- `DimPatient`
- `DimProvider`
- `DimOrganization`
- `DimPayer`
- `DimDate` (role-playing: admission date, discharge date, death date)

See [`docs/data_model.png`](docs/data_model.png) for the full entity
relationship diagram.

## Repository Structure

```
sql-data-warehouse/
├── scripts/
│   ├── 01_init_database.sql
│   ├── 02_create_tables.sql
│   ├── 03_load_data.sql
│   ├── 04_validate_data.sql
│   ├── 05_transform_gold.sql
│   └── 06_analysis_queries.sql
├── docs/
│   └── data_model.png
└── README.md
```

## Prerequisites

- SQL Server 2019+ (or Azure SQL Database)
- SQL Server Management Studio (SSMS)
- Cleaned CSV files from the [data cleaning pipeline](../healthcare-data-cleaning), placed in a location accessible to `BULK INSERT`

## Setup

1. Clone this repository.
2. Update the file paths in `scripts/03_load_data.sql` to point to your local `data/processed/` directory.
3. Run the scripts in SSMS in order, `01` through `06`.
4. Confirm all checks in `04_validate_data.sql` pass before proceeding to the transform step.

## Validation Checks

`04_validate_data.sql` confirms, per table:

- Row counts match the source CSV
- Primary keys are unique with no nulls
- Foreign keys resolve to an existing dimension row
- Date fields contain no logically invalid values (e.g. discharge before admission)
- Financial fields contain no negative values

## Tech Stack

- SQL Server
- SQL Server Management Studio (SSMS)
- T-SQL

## Data Source

Built on synthetic healthcare data generated with
[Synthea](https://synthetichealth.github.io/synthea/). No real patient data
is used anywhere in this project.
