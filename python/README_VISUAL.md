# Healthcare Admissions — Data Cleaning Pipeline

Cleans and validates a synthetic healthcare dataset (generated with [Synthea](https://github.com/synthetichealth/synthea)) for use in a Power BI star-schema admissions dashboard.

---

## Pipeline Steps Per Table

**load** → **profile** → **clean** → **validate** → **export**

---

## Design Decisions

**Dimension tables** (`patients`, `providers`, `organizations`, `payers`) are cleaned and exported at **full scope** — no date filtering. These describe entities, not events, so trimming them by date would silently drop valid dimension members that fact tables still reference.

**Fact tables** (`encounters`, `conditions`, `procedures`, `claims`, `claims_transactions`) are cleaned at full scope first, then a **single, consistent** analysis window (`ANALYSIS_START` – `ANALYSIS_END`) is applied identically across all of them in the final section — so every fact table reflects the same reporting period.

**Why this matters:** Power BI dashboards require temporal alignment. Without a consistent window, Encounters might span 2018–2024 while Claims span 2019–2023, leading to misaligned KPIs.

---

## What Gets Transformed

### Patients (Dimension)

- **AGE** — Years since birth, calculated against a fixed reference date (2022-12-31)
  - Negative ages set to null (patients born after reference date)
- **AGE_GROUP** — Bucketed into 6 segments
  - 0–17, 18–34, 35–49, 50–64, 65–79, 80+
- **IS_DECEASED** — Boolean flag derived from DEATHDATE

### Encounters (Fact)

- **ENCOUNTER_DURATION_HOURS** — Calculated from START/STOP timestamps
- **ENCOUNTER_CATEGORY** — Standardized from raw ENCOUNTERCLASS
  - Maps to: Outpatient, Emergency, Inpatient, Telehealth, Home Care, Skilled Nursing, Urgent Care, Preventive, Hospice
- **ENCOUNTER_YEAR / ENCOUNTER_MONTH** — Temporal bucketing for aggregation
- **PATIENT_RESPONSIBILITY** — Out-of-pocket cost (TOTAL_CLAIM_COST − PAYER_COVERAGE)
- **PAYER_COVERAGE_RATE** — Insurance coverage as a decimal (0.0–1.0)

### Conditions (Fact)

- **CLINICAL_CATEGORY** — Semantic bucket assigned via keyword matching
  - 18 categories: Cardiovascular, Respiratory, Oncology, Neurological, Women's Health, Metabolic/Endocrine, etc.
  - Keyword-based (e.g., "myocardial infarction", "heart failure" → Cardiovascular)
  - Rationale: Replaces manual hardcoding; scales if Synthea population regenerates
- Unclassified rates monitored; high rates trigger warnings

### Procedures (Fact)

- **PROCEDURE_DURATION_HOURS** — Calculated from START/STOP
- Data quality: rows with STOP < START are dropped (unrecoverable)

### Claims (Fact)

- **TOTAL_OUTSTANDING** — Sum of outstanding balances across 3 claim types (OUTSTANDING1, OUTSTANDING2, OUTSTANDINGP)
- **HAS_OUTSTANDING_BALANCE** — Boolean flag for revenue cycle analysis
- Status codes normalized to uppercase

---

## Validation Checkpoints

All tables enforce **fail-fast assertions** at processing:

✓ **Primary Key Uniqueness** — No duplicate IDs  
✓ **Temporal Bounds** — STOP ≥ START; dates parse correctly  
✓ **Financial Sanity** — Non-negative amounts (revenue, coverage, claims)  
✓ **Type Safety** — Correct data types across all columns  
✓ **Mapping Completeness** — All encounter classes and conditions mapped  

Assertions stop execution immediately with descriptive error messages, preventing silent corruption downstream.

---

## Output Structure

```
data/processed/
├── patients_clean.csv
├── providers_clean.csv
├── organizations_clean.csv
├── payers_clean.csv
├── encounters_clean.csv
├── encounters_2020_2022.csv                 ← windowed
├── conditions_clean.csv
├── conditions_2020_2022.csv                 ← windowed
├── procedures_clean.csv
├── procedures_2020_2022.csv                 ← windowed
├── claims_clean.csv
├── claims_2020_2022.csv                     ← windowed
├── claims_transactions_clean.csv
└── claims_transactions_2020_2022.csv        ← windowed
```

**Full-scope** tables (`_clean.csv`) preserve all historical data.  
**Windowed** tables (`_2020_2022.csv`) are the analysis-ready datasets for SQL Server and Power BI.

---

## How to Run

```bash
python data_cleaning_refactored.py
```

Expected output:
- Profiling metrics (row counts, missing values, duplicates) for each table
- Data quality insights (unclassified condition rates, outstanding balance %)
- Temporal windowing summary (before/after row counts, retention %)
- Final pipeline summary table

---

## Error Handling

The pipeline uses fail-fast assertions. If validation fails, you'll see:

| Error Message | Likely Cause |
|---|---|
| `ERROR: Duplicate patient IDs found` | Raw data has duplicate patients |
| `ERROR: Negative ages detected` | Patients born after reference date |
| `ERROR: STOP before START detected` | Temporal anomaly in Synthea export |
| `ERROR: Unmapped ENCOUNTERCLASS value` | New encounter type in Synthea output |
| `ERROR: Negative outstanding balances` | Revenue cycle data corruption |

---

## Production Readiness

✓ **Reproducible** — Fixed reference date and analysis window  
✓ **Maintainable** — Clear docstrings, descriptive variable names  
✓ **Observable** — Professional logging with data quality metrics  
✓ **Validated** — Fail-fast assertions catch issues early  
✓ **Scalable** — Keyword-based categorization adapts to new populations  

---

## Code Quality

- **Type hints** on all functions for clarity
- **Comprehensive docstrings** explaining design rationale
- **Professional logging** instead of print statements
- **Descriptive error messages** that aid debugging
- **DRY principle** — Shared helpers reduce duplication
- **No magic numbers** — All mappings and dates defined at module top

---

## Next Steps

1. **SQL Server Ingestion** — Load windowed tables into `HealthcareAnalytics_Numeric`
2. **Analytical Views** — Create SQL views for denormalized dimensions and aggregated facts
3. **Power BI Model** — Import views, build star schema, write DAX measures
4. **Executive Dashboard** — Clinical capacity, patient demographics, revenue cycle KPIs
