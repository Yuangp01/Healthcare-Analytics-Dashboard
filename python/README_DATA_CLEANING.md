# Healthcare Operations — Data Cleaning Pipeline

Transforms raw synthetic healthcare records (generated with [**Synthea**](https://github.com/synthetichealth/synthea)) into analysis-ready datasets for a SQL Server warehouse and Power BI executive dashboard. Enterprise-grade data validation and temporal consistency enforced across all fact tables.

---

## Pipeline Steps Per Table

**load** → **profile** → **clean** → **validate** → **export**

Each table follows this identical process: ingest raw CSV, assess data quality, apply transformations and type-casting, run fail-fast assertions, export to `data/processed/`.

---

## Design Decisions

**Dimension tables** (`patients`, `providers`, `organizations`, `payers`) are cleaned and exported at **full historical scope** — no date filtering. These describe entities, not events, so trimming by date would silently drop valid dimension members that downstream fact tables still reference.

**Fact tables** (`encounters`, `conditions`, `procedures`, `claims`, `claims_transactions`) are cleaned at full scope first, then a **single, consistent analysis window** (`ANALYSIS_START` – `ANALYSIS_END` = **2020-01-01 to 2022-12-31**) is applied identically across all of them in the final section. Rationale: Power BI dashboards require all facts to describe the same reporting period, preventing misaligned KPIs and incorrect drill-downs.

---

## Key Transformations

### **Patients** (Dimension)
- **AGE** — Years since birth, calculated against fixed reference date (2022-12-31); negative ages set to null
- **AGE_GROUP** — Bucketed into 6 segments (0–17, 18–34, 35–49, 50–64, 65–79, 80+)
- **IS_DECEASED** — Boolean flag derived from DEATHDATE

### **Encounters** (Fact)
- **ENCOUNTER_DURATION_HOURS** — Calculated from START/STOP; rounds to 2 decimals
- **ENCOUNTER_CATEGORY** — Standardized from raw ENCOUNTERCLASS via mapping (Outpatient, Emergency, Inpatient, etc.)
- **ENCOUNTER_YEAR/MONTH** — Temporal bucketing for aggregation
- **PATIENT_RESPONSIBILITY** — Out-of-pocket cost (TOTAL_CLAIM_COST − PAYER_COVERAGE)
- **PAYER_COVERAGE_RATE** — Insurance coverage % (0.0–1.0 scale)

### **Conditions** (Fact)
- **CLINICAL_CATEGORY** — Mapped from raw description via 18-bucket keyword classification
  - Cardiovascular, Respiratory, Metabolic/Endocrine, Musculoskeletal, Oncology, Neurological, etc.
  - Keyword-based matching ensures scalability if Synthea population regenerates
  - Unclassified rate monitored; high rates trigger warnings

### **Procedures** (Fact)
- **PROCEDURE_DURATION_HOURS** — Calculated from START/STOP
- Data quality: rows with STOP < START are dropped (unrecoverable artifact)

### **Claims** (Fact)
- **TOTAL_OUTSTANDING** — Sum of outstanding balances across 3 claim types
- **HAS_OUTSTANDING_BALANCE** — Boolean for revenue cycle analysis
- Status codes standardized to uppercase (STATUS1, STATUS2, STATUSP)

---

## Validation Strategy

All tables enforce **fail-fast assertions** at the point of processing:

✓ **Primary Key Uniqueness** — No duplicate IDs allowed  
✓ **Foreign Key Integrity** — Patients/Encounters referenced by facts must exist  
✓ **Temporal Bounds** — STOP ≥ START; dates parsed correctly  
✓ **Financial Sanity** — Non-negative amounts (revenue, coverage, claims)  
✓ **Type Safety** — Correct data types for all columns  
✓ **Completeness** — All expected columns present; critical fields are non-null after cleaning  

Assertions stop execution immediately with descriptive error messages, preventing silent data corruption downstream.

---

## Output Structure

```
data/processed/
├── patients_clean.csv
├── providers_clean.csv
├── organizations_clean.csv
├── payers_clean.csv
├── encounters_clean.csv
├── encounters_2020_2022.csv                    ← windowed
├── conditions_clean.csv
├── conditions_2020_2022.csv                    ← windowed
├── procedures_clean.csv
├── procedures_2020_2022.csv                    ← windowed
├── claims_clean.csv
├── claims_2020_2022.csv                        ← windowed
├── claims_transactions_clean.csv
└── claims_transactions_2020_2022.csv           ← windowed
```

**Full-scope** tables (`_clean.csv`) preserve historical data for reference and audit trails.

**Windowed** tables (`_2020_2022.csv`) are the analysis-ready datasets for SQL Server and Power BI.

---

## Usage

### **Run the pipeline**
```bash
python data_cleaning_refactored.py
```

### **Expected output**
- Console logging shows profiling metrics (row counts, missing values, duplicates)
- Data quality checks and unclassified condition rates logged
- Temporal windowing summary (before/after counts, retention %)
- Final pipeline summary table

### **Error handling**
If any assertion fails, the pipeline stops with a descriptive error message. Common issues:

- `ERROR: Duplicate patient IDs found` → Raw data has duplicate patients
- `ERROR: Negative ages detected` → Patients born after reference date (check BIRTHDATE data)
- `ERROR: STOP before START detected` → Temporal data anomaly in Synthea export
- `ERROR: Negative outstanding balances` → Revenue cycle data corruption

---

## Production Readiness

✓ **Reproducible** — Fixed reference date and analysis window ensure consistent output  
✓ **Maintainable** — Clear function docstrings and variable naming; easy onboarding  
✓ **Observable** — Professional logging with data quality metrics  
✓ **Validated** — Fail-fast assertions catch issues before downstream systems  
✓ **Scalable** — Keyword-based condition categorization adapts to new Synthea populations  

---

## Next Steps

1. **SQL Server Ingestion** — Load windowed tables into `HealthcareAnalytics_Numeric` database
2. **Analytical Views** — Create SQL views for flattened dimensions and aggregated facts
3. **Power BI Model** — Import views, build star schema, write DAX measures
4. **Executive Dashboard** — Clinical capacity, patient demographics, revenue cycle KPIs

---

## Code Quality

- **Type hints** on all functions
- **Comprehensive docstrings** explaining *why*, not just *what*
- **Logging instead of print** for production-grade observability
- **Descriptive error messages** that aid debugging
- **DRY principle** — Shared helpers (`profile_dataframe`, `export_clean_csv`, `apply_temporal_window`)
- **No magic numbers** — All temporal and categorical mappings defined at module top
