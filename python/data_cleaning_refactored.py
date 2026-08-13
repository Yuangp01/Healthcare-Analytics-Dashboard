"""
Healthcare Data Cleaning & Windowing Pipeline
==============================================

WHAT THIS DOES:
Transforms raw Synthea synthetic medical records (9 CSV tables) into analysis-ready
datasets for a SQL Server warehouse and Power BI dashboards. Handles data cleaning,
type casting, validation, and temporal windowing with a single consistent reporting
period across all fact tables.

ARCHITECTURE:
  Input:  9 raw CSV files (4 dimension, 5 fact tables)
  ↓
  Processing: Profile → Type Cast → Derive → Validate → Window (facts only)
  ↓
  Output: Clean CSVs ready for SQL Server ingestion

KEY DESIGN DECISIONS:
  • Dimension tables (Patients, Providers, etc.) → full historical scope (no windowing)
  • Fact tables (Encounters, Conditions, Claims, etc.) → strict 2020-01-01 to 2022-12-31 window
    Rationale: Ensures downstream Power BI model describes a single, consistent time period
  
  • Fail-fast validation via assert statements at each stage
    Rationale: Surface data quality issues immediately, not downstream in BI
  
  • Keyword-based condition categorization (18 clinical buckets)
    Rationale: Replaces manual mapping; scalable if Synthea population changes

RUN:
  python data_cleaning_refactored.py
  or: jupyter notebook (top to bottom)
"""

import pandas as pd
from pathlib import Path
from typing import Tuple
import logging

# ============================================================================
# LOGGING & CONFIGURATION
# ============================================================================

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)-8s | %(message)s"
)
logger = logging.getLogger(__name__)

# Paths
PROJECT_ROOT = Path("..")
RAW_DATA = PROJECT_ROOT / "data" / "raw"
PROCESSED_DATA = PROJECT_ROOT / "data" / "processed"
PROCESSED_DATA.mkdir(parents=True, exist_ok=True)

# Temporal Configuration
# All fact tables are windowed to this period; ensures Power BI model
# describes a single, consistent reporting window.
ANALYSIS_START = pd.Timestamp("2020-01-01", tz="UTC")
ANALYSIS_END = pd.Timestamp("2022-12-31 23:59:59", tz="UTC")

# Reference point for calculating patient age dynamically
REFERENCE_DATE = pd.Timestamp("2022-12-31")


# ============================================================================
# DIMENSION TABLES & MAPPING CONFIGURATION
# ============================================================================

ENCOUNTER_CATEGORY_MAP = {
    "ambulatory": "Outpatient",
    "outpatient": "Outpatient",
    "wellness": "Preventive",
    "urgentcare": "Urgent Care",
    "emergency": "Emergency",
    "inpatient": "Inpatient",
    "home": "Home Care",
    "snf": "Skilled Nursing",
    "virtual": "Telehealth",
    "hospice": "Hospice",
}

CLINICAL_CATEGORY_KEYWORDS = {
    "Dental": ["gingiv", "dental", "tooth", "teeth", "caries", "molar", "torus"],
    "Cardiovascular": ["myocardial infarction", "heart failure", "heart disease", 
                       "ischemic heart", "hypertension", "coronary", "atrial fibrillation",
                       "aortic valve", "mitral valve", "pulmonary embolism", "deep venous thrombosis"],
    "Respiratory": ["sinusitis", "bronchitis", "pharyngitis", "pneumonia", "asthma", 
                    "otitis", "wheezing", "sleep apnea", "emphysema"],
    "Metabolic / Endocrine": ["diabetes", "obesity", "body mass index", "hyperlipidemia",
                              "hypertriglyceridemia", "hyperglycemia", "metabolic syndrome"],
    "Musculoskeletal / Injury": ["fracture", "sprain", "injury", "laceration", "scoliosis",
                                 "burn", "concussion", "meniscus", "osteoporosis", "fibromyalgia"],
    "Genitourinary": ["kidney", "renal", "cystitis", "urinary", "bladder", "pyelonephritis"],
    "Neurological": ["neurolog", "seizure", "migraine", "epilepsy", "alzheimer",
                     "stroke", "dementia", "spina bifida"],
    "Women's Health": ["pregnan", "miscarriage", "prenatal", "postnatal", "postpartum",
                       "pre-eclampsia", "tubal ligation"],
    "Infectious Disease": ["infection", "infective", "viral", "bacterial", "coronavirus",
                           "streptococcal", "sepsis", "hepatitis"],
    "Mental / Behavioral": ["stress", "anxiety", "depress", "alcoholism", "drug abuse",
                            "opioid abuse", "smokes tobacco"],
    "Oncology": ["cancer", "carcinoma", "leukemia", "lymphoma", "melanoma", "neoplasm"],
    "Hematologic": ["anemia", "coagulation disorder", "neutropenia"],
    "Gastrointestinal": ["appendic", "vomiting", "nausea", "gastro", "diarrhea", 
                         "bowel", "polyp of colon"],
    "Dermatological": ["dermatitis", "eczema", "rash", "allergic reaction"],
    "Symptoms": ["fever", "cough", "headache", "fatigue", "chill", "dyspnea", "pain"],
    "Social / SDOH": ["unemployed", "employment", "education", "social isolation",
                      "homeless", "transport problem", "housing unsatisfactory"],
    "Care / Administrative": ["medication review"],
    "Care / End-of-Life": ["hospice"],
}


# ============================================================================
# DATA PROFILING & I/O HELPERS
# ============================================================================

def profile_dataframe(df: pd.DataFrame, name: str) -> None:
    """
    Print a one-line data quality snapshot.
    Helps quickly assess row counts, columns, and data quality issues.
    """
    missing_count = df.isna().sum().sum()
    duplicate_count = df.duplicated().sum()
    logger.info(
        f"[{name:30}] rows={len(df):>9,}  cols={df.shape[1]:>2}  "
        f"duplicates={duplicate_count:>6,}  missing={missing_count:>9,}"
    )


def load_raw_csv(filename: str) -> pd.DataFrame:
    """
    Load a raw Synthea CSV and log its profile.
    Intended as the entry point for all dimension/fact table processing.
    """
    df = pd.read_csv(RAW_DATA / filename)
    profile_dataframe(df, filename.replace(".csv", ""))
    return df


def export_clean_csv(df: pd.DataFrame, filename: str) -> None:
    """
    Export a cleaned table to data/processed/ after profiling.
    Confirms export via logging.
    """
    profile_dataframe(df, filename.replace(".csv", ""))
    df.to_csv(PROCESSED_DATA / filename, index=False)
    logger.info(f"✓ Exported: {filename}")


def categorize_condition(condition_name: str) -> str:
    """
    Classify a raw clinical condition into one of 18 semantic buckets
    via case-insensitive keyword matching (CLINICAL_CATEGORY_KEYWORDS).
    
    Rationale: Replaces manual hardcoding; scales if Synthea population regenerates.
    Returns 'Unclassified' only for rare/unmapped conditions.
    """
    lowered = condition_name.lower()
    for category, keywords in CLINICAL_CATEGORY_KEYWORDS.items():
        if any(kw in lowered for kw in keywords):
            return category
    return "Unclassified"


def apply_temporal_window(df: pd.DataFrame, date_column: str, table_name: str) -> pd.DataFrame:
    """
    Filter a fact table to the shared ANALYSIS_START/ANALYSIS_END window.
    
    Critical for ensuring all fact tables in Power BI describe the same
    reporting period. Prevents misalignment across Encounters, Conditions,
    Procedures, and Claims.
    """
    before_count = len(df)
    windowed = df[(df[date_column] >= ANALYSIS_START) & (df[date_column] <= ANALYSIS_END)].copy()
    after_count = len(windowed)
    pct_retained = (after_count / before_count * 100) if before_count > 0 else 0
    logger.info(f"[Windowing {table_name:20}] {before_count:>9,} → {after_count:>9,} ({pct_retained:.1f}% retained)")
    return windowed


# ============================================================================
# DIMENSION TABLE CLEANING
# ============================================================================

def clean_patients() -> pd.DataFrame:
    """
    Process patient demographics table.
    
    Derived fields:
      • AGE: Years since birth (as of REFERENCE_DATE = 2022-12-31)
      • AGE_GROUP: Bucketed into 6 bins for segmentation (0-17, 18-34, ..., 80+)
      • IS_DECEASED: Boolean flag for mortality tracking
    
    Validations:
      • Primary key uniqueness (no duplicate patient IDs)
      • Age >= 0 (catches patients born after reference date)
    """
    raw = load_raw_csv("patients.csv")
    df = raw[[
        "Id", "BIRTHDATE", "DEATHDATE", "MARITAL", "RACE", "ETHNICITY", "GENDER",
        "CITY", "STATE", "COUNTY", "FIPS", "ZIP", "LAT", "LON",
        "HEALTHCARE_EXPENSES", "HEALTHCARE_COVERAGE", "INCOME",
    ]].copy()

    # Convert dates
    df["BIRTHDATE"] = pd.to_datetime(df["BIRTHDATE"], errors="coerce")
    df["DEATHDATE"] = pd.to_datetime(df["DEATHDATE"], errors="coerce")
    
    # Derive age and demographic flags
    df["MARITAL"] = df["MARITAL"].fillna("Unknown")
    df["IS_DECEASED"] = df["DEATHDATE"].notna()
    
    age_days = (REFERENCE_DATE - df["BIRTHDATE"]).dt.days
    age_years = (age_days / 365.25).astype(int)
    df["AGE"] = age_years.where(age_years >= 0, pd.NA)
    
    df["AGE_GROUP"] = pd.cut(
        df["AGE"],
        bins=[0, 17, 34, 49, 64, 79, 120],
        labels=["0-17", "18-34", "35-49", "50-64", "65-79", "80+"],
        include_lowest=True,
    )

    # Validations
    assert df["Id"].is_unique, "ERROR: Duplicate patient IDs found"
    assert (df["AGE"].dropna() >= 0).all(), "ERROR: Negative ages detected"
    logger.info(f"   Patients with AGE_GROUP assigned: {df['AGE_GROUP'].notna().sum():,}")

    export_clean_csv(df, "patients_clean.csv")
    return df


def clean_providers() -> pd.DataFrame:
    """
    Process provider directory table (minimal transformation).
    
    Validations:
      • Primary key uniqueness
      • Geographic coordinates within valid ranges
    """
    df = load_raw_csv("providers.csv").copy()
    
    assert df["Id"].is_unique, "ERROR: Duplicate provider IDs"
    assert ((df["LAT"].between(-90, 90)) & (df["LON"].between(-180, 180))).all(), \
        "ERROR: Invalid geographic coordinates"
    logger.info(f"   Providers in dataset: {len(df):,}")

    export_clean_csv(df, "providers_clean.csv")
    return df


def clean_organizations() -> pd.DataFrame:
    """
    Process healthcare organization reference table.
    
    Validations:
      • Primary key uniqueness
      • Revenue and utilization metrics are non-negative
    """
    df = load_raw_csv("organizations.csv").copy()
    
    assert df["Id"].is_unique, "ERROR: Duplicate organization IDs"
    assert (df["REVENUE"] >= 0).all(), "ERROR: Negative revenue values"
    assert (df["UTILIZATION"] >= 0).all(), "ERROR: Negative utilization values"
    logger.info(f"   Organizations: {len(df):,}")

    export_clean_csv(df, "organizations_clean.csv")
    return df


def clean_payers() -> pd.DataFrame:
    """
    Process insurance payer reference table.
    
    Validations:
      • Primary key uniqueness
      • Coverage amounts are non-negative
    """
    df = load_raw_csv("payers.csv").copy()
    
    assert df["Id"].is_unique, "ERROR: Duplicate payer IDs"
    assert (df["AMOUNT_COVERED"] >= 0).all(), "ERROR: Negative covered amounts"
    assert (df["AMOUNT_UNCOVERED"] >= 0).all(), "ERROR: Negative uncovered amounts"
    logger.info(f"   Payers: {len(df):,}")

    export_clean_csv(df, "payers_clean.csv")
    return df


# ============================================================================
# FACT TABLE CLEANING
# ============================================================================

def clean_encounters() -> pd.DataFrame:
    """
    Process hospital encounter (visit) fact table.
    
    Derived fields:
      • ENCOUNTER_DURATION_HOURS: Calculated from START/STOP timestamps
      • ENCOUNTER_CATEGORY: Standardized from raw ENCOUNTERCLASS via mapping
      • ENCOUNTER_YEAR/MONTH: Temporal buckets for aggregation
      • PATIENT_RESPONSIBILITY: Out-of-pocket cost (TOTAL_CLAIM - PAYER_COVERAGE)
      • PAYER_COVERAGE_RATE: % of cost covered by insurance
    
    Validations:
      • Primary key uniqueness
      • STOP >= START (no negative durations)
      • All encounters mapped to valid ENCOUNTER_CATEGORY
      • Non-negative financial amounts
    
    Note: Full historical scope here; temporal windowing applied in Section 9.
    """
    df = load_raw_csv("encounters.csv").copy()

    # Parse timestamps
    df["START"] = pd.to_datetime(df["START"], errors="coerce")
    df["STOP"] = pd.to_datetime(df["STOP"], errors="coerce")

    # Derive temporal and duration fields
    df["ENCOUNTER_DURATION_HOURS"] = (
        (df["STOP"] - df["START"]).dt.total_seconds() / 3600
    ).round(2)
    df["ENCOUNTER_YEAR"] = df["START"].dt.year
    df["ENCOUNTER_MONTH"] = df["START"].dt.month
    df["ENCOUNTER_MONTH_NAME"] = df["START"].dt.month_name()

    # Categorize encounter type
    df["ENCOUNTER_CATEGORY"] = df["ENCOUNTERCLASS"].map(ENCOUNTER_CATEGORY_MAP)

    # Financial responsibility calculation
    df["PATIENT_RESPONSIBILITY"] = (
        df["TOTAL_CLAIM_COST"] - df["PAYER_COVERAGE"]
    ).round(2)
    df["PAYER_COVERAGE_RATE"] = (
        df["PAYER_COVERAGE"] / df["TOTAL_CLAIM_COST"]
    ).round(4)

    # Validations
    assert df["Id"].is_unique, "ERROR: Duplicate encounter IDs"
    assert (df["STOP"] >= df["START"]).all(), "ERROR: STOP before START detected"
    assert df["ENCOUNTER_CATEGORY"].notna().all(), "ERROR: Unmapped ENCOUNTERCLASS value"
    assert (df["TOTAL_CLAIM_COST"] >= 0).all(), "ERROR: Negative claim costs"
    assert (df["PAYER_COVERAGE"] >= 0).all(), "ERROR: Negative payer coverage"
    
    logger.info(f"   Encounter categories: {df['ENCOUNTER_CATEGORY'].nunique()}")
    logger.info(f"   Avg payer coverage rate: {df['PAYER_COVERAGE_RATE'].mean():.1%}")

    export_clean_csv(df, "encounters_clean.csv")
    return df


def clean_conditions() -> pd.DataFrame:
    """
    Process clinical conditions (diagnoses) fact table.
    
    Derived fields:
      • CLINICAL_CATEGORY: Mapped from raw condition description via keyword matching
        (18 semantic buckets: Cardiovascular, Respiratory, Oncology, etc.)
    
    Validations:
      • Unclassified rate should remain < 5% (indicators potential new categories needed)
    
    Note: Full historical scope here; temporal windowing applied in Section 9.
    """
    df = load_raw_csv("conditions.csv").copy()

    # Parse dates
    df["START"] = pd.to_datetime(df["START"], errors="coerce")
    df["STOP"] = pd.to_datetime(df["STOP"], errors="coerce")

    # Condition categorization
    df["CONDITION_NAME"] = df["DESCRIPTION"].str.strip()
    df["CLINICAL_CATEGORY"] = df["CONDITION_NAME"].apply(categorize_condition)

    unclassified_pct = (df["CLINICAL_CATEGORY"] == "Unclassified").mean()
    logger.info(f"   Unclassified rate: {unclassified_pct:.2%}")
    if unclassified_pct > 0.05:
        logger.warning(
            f"   ⚠ Unclassified rate is high. Consider adding keywords to CLINICAL_CATEGORY_KEYWORDS."
        )

    export_clean_csv(df, "conditions_clean.csv")
    return df


def clean_procedures() -> pd.DataFrame:
    """
    Process clinical procedures (treatments) fact table.
    
    Derived fields:
      • PROCEDURE_DURATION_HOURS: Calculated from START/STOP
    
    Data quality handling:
      • Rows with STOP before START are dropped (data artifact; duration unrecoverable)
    
    Validations:
      • Non-negative procedure durations
      • Non-negative base costs
    
    Note: Full historical scope here; temporal windowing applied in Section 9.
    """
    df = load_raw_csv("procedures.csv").copy()

    # Parse dates
    df["START"] = pd.to_datetime(df["START"], errors="coerce")
    df["STOP"] = pd.to_datetime(df["STOP"], errors="coerce")

    # Duration calculation
    df["PROCEDURE_DURATION_HOURS"] = (
        (df["STOP"] - df["START"]).dt.total_seconds() / 3600
    ).round(2)

    # Drop unrecoverable records (negative durations = data artifact)
    before = len(df)
    df = df[df["PROCEDURE_DURATION_HOURS"] >= 0].copy()
    dropped = before - len(df)
    if dropped > 0:
        logger.warning(f"   ⚠ Dropped {dropped} row(s) with negative duration (data artifact)")

    # Validations
    assert (df["PROCEDURE_DURATION_HOURS"] >= 0).all(), "ERROR: Negative durations remain"
    assert (df["BASE_COST"] >= 0).all(), "ERROR: Negative base costs"

    export_clean_csv(df, "procedures_clean.csv")
    return df


def clean_claims() -> pd.DataFrame:
    """
    Process claims/billing fact table (revenue cycle).
    
    Derived fields:
      • TOTAL_OUTSTANDING: Sum of outstanding balances across 3 claim types
      • HAS_OUTSTANDING_BALANCE: Boolean for outstanding status
    
    Transformations:
      • Standardize status codes to uppercase (STATUS1, STATUS2, STATUSP)
      • Parse all date columns
      • Consolidate outstanding amounts (handles multi-payer claims)
    
    Validations:
      • Primary key uniqueness
      • Non-negative outstanding balances
    
    Note: Full historical scope here; temporal windowing applied in Section 9.
    """
    df = load_raw_csv("claims.csv").copy()

    # Parse dates
    date_cols = ["CURRENTILLNESSDATE", "SERVICEDATE", "LASTBILLEDDATE1", 
                 "LASTBILLEDDATE2", "LASTBILLEDDATEP"]
    for col in date_cols:
        df[col] = pd.to_datetime(df[col], errors="coerce")

    # Standardize status codes
    status_cols = ["STATUS1", "STATUS2", "STATUSP"]
    for col in status_cols:
        df[col] = df[col].str.strip().str.upper()

    # Aggregate outstanding balances
    df["TOTAL_OUTSTANDING"] = (
        df["OUTSTANDING1"].fillna(0)
        + df["OUTSTANDING2"].fillna(0)
        + df["OUTSTANDINGP"].fillna(0)
    ).round(2)
    df["HAS_OUTSTANDING_BALANCE"] = df["TOTAL_OUTSTANDING"] > 0

    # Validations
    assert df["Id"].is_unique, "ERROR: Duplicate claim IDs"
    assert (df["TOTAL_OUTSTANDING"] >= 0).all(), "ERROR: Negative outstanding balances"
    
    outstanding_pct = df["HAS_OUTSTANDING_BALANCE"].mean()
    logger.info(f"   Claims with outstanding balance: {outstanding_pct:.1%}")

    export_clean_csv(df, "claims_clean.csv")
    return df


def clean_claims_transactions() -> pd.DataFrame:
    """
    Process claims transactions (payment/adjustment ledger).
    
    Transformations:
      • Parse date range (FROMDATE, TODATE)
      • Standardize transaction type (TYPE)
      • Coerce numeric amounts; treat missing as 0 (payment ledger convention)
    
    Validations:
      • Primary key uniqueness
      • Non-negative amounts
    
    Note: Full historical scope here; temporal windowing applied in Section 9.
    """
    df = load_raw_csv("claims_transactions.csv").copy()

    # Parse dates
    df["FROMDATE"] = pd.to_datetime(df["FROMDATE"], errors="coerce")
    df["TODATE"] = pd.to_datetime(df["TODATE"], errors="coerce")
    
    # Standardize type
    df["TYPE"] = df["TYPE"].str.strip().str.upper()

    # Coerce numeric amounts
    numeric_cols = ["AMOUNT", "PAYMENTS", "ADJUSTMENTS", "TRANSFERS", "OUTSTANDING"]
    for col in numeric_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0).round(2)

    # Validations
    assert df["ID"].is_unique, "ERROR: Duplicate transaction IDs"
    assert (df["AMOUNT"] >= 0).all(), "ERROR: Negative amounts"

    export_clean_csv(df, "claims_transactions_clean.csv")
    return df


# ============================================================================
# TEMPORAL WINDOWING (CRITICAL FOR POWER BI CONSISTENCY)
# ============================================================================

def window_all_fact_tables(
    encounters_clean: pd.DataFrame,
    conditions_clean: pd.DataFrame,
    procedures_clean: pd.DataFrame,
    claims_clean: pd.DataFrame,
    claims_txn_clean: pd.DataFrame,
) -> dict[str, pd.DataFrame]:
    """
    Apply the same 2020-2022 analysis window to all fact tables.
    
    CRITICAL RATIONALE:
    Power BI dashboards require all facts to describe the same time period.
    Without this centralized windowing, Encounters might span 2018-2024 while
    Claims spans 2019-2023, leading to misaligned KPIs and incorrect drill-downs.
    
    Returns: Dictionary of windowed tables ready for SQL Server ingestion.
    """
    logger.info("\n" + "="*70)
    logger.info("APPLYING TEMPORAL WINDOW: 2020-01-01 to 2022-12-31")
    logger.info("="*70)
    
    windowed = {
        "encounters_2020_2022": apply_temporal_window(encounters_clean, "START", "encounters"),
        "conditions_2020_2022": apply_temporal_window(conditions_clean, "START", "conditions"),
        "procedures_2020_2022": apply_temporal_window(procedures_clean, "START", "procedures"),
        "claims_2020_2022": apply_temporal_window(claims_clean, "SERVICEDATE", "claims"),
        "claims_transactions_2020_2022": apply_temporal_window(claims_txn_clean, "FROMDATE", "claims_transactions"),
    }
    
    # Export windowed tables
    for name, df in windowed.items():
        output_file = PROCESSED_DATA / f"{name}.csv"
        df.to_csv(output_file, index=False)
    
    logger.info("✓ All windowed tables exported to data/processed/")
    return windowed


# ============================================================================
# PIPELINE EXECUTION & REPORTING
# ============================================================================

def main() -> None:
    """
    Execute the complete data pipeline: load, clean, validate, window, export.
    """
    logger.info("\n" + "="*70)
    logger.info("HEALTHCARE DATA CLEANING PIPELINE")
    logger.info("="*70 + "\n")

    # Clean dimension tables (full historical scope)
    logger.info("[DIMENSION TABLES]")
    patients_clean = clean_patients()
    providers_clean = clean_providers()
    organizations_clean = clean_organizations()
    payers_clean = clean_payers()

    # Clean fact tables (full scope; windowing applied below)
    logger.info("\n[FACT TABLES - FULL SCOPE]")
    encounters_clean = clean_encounters()
    conditions_clean = clean_conditions()
    procedures_clean = clean_procedures()
    claims_clean = clean_claims()
    claims_txn_clean = clean_claims_transactions()

    # Apply consistent 2020-2022 window to all facts
    windowed = window_all_fact_tables(
        encounters_clean, conditions_clean, procedures_clean,
        claims_clean, claims_txn_clean,
    )

    # Summary report
    logger.info("\n" + "="*70)
    logger.info("PIPELINE COMPLETE - SUMMARY")
    logger.info("="*70)
    
    summary_tables = {
        "patients_clean": patients_clean,
        "providers_clean": providers_clean,
        "organizations_clean": organizations_clean,
        "payers_clean": payers_clean,
        "encounters_2020_2022": windowed["encounters_2020_2022"],
        "conditions_2020_2022": windowed["conditions_2020_2022"],
        "procedures_2020_2022": windowed["procedures_2020_2022"],
        "claims_2020_2022": windowed["claims_2020_2022"],
        "claims_transactions_2020_2022": windowed["claims_transactions_2020_2022"],
    }
    
    summary_df = pd.DataFrame([
        {"table": name, "rows": f"{len(df):,}"} 
        for name, df in summary_tables.items()
    ])
    
    logger.info("\nOutput Summary:\n" + summary_df.to_string(index=False))
    logger.info("\n✓ All cleaned data exported to: " + str(PROCESSED_DATA))


if __name__ == "__main__":
    main()
