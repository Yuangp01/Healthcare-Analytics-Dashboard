"""
Healthcare Data Cleaning Pipeline
==================================
Cleans nine raw Synthea tables (4 dimension, 5 fact) and exports them as
analysis-ready CSVs for the SQL Server warehouse and Power BI model.

Each table follows the same process: load -> profile -> clean -> validate -> export.
Fact tables are additionally windowed to a single consistent reporting period
(ANALYSIS_START to ANALYSIS_END) in Section 9, so every fact table in the
downstream model describes the same time range.

Run top to bottom via `python 01_data_cleaning.py` or as a notebook.
"""

import pandas as pd
from pathlib import Path

# =============================================================================
# Config
# =============================================================================

PROJECT_ROOT = Path("..")
RAW_DATA = PROJECT_ROOT / "data" / "raw"
PROCESSED_DATA = PROJECT_ROOT / "data" / "processed"
PROCESSED_DATA.mkdir(parents=True, exist_ok=True)

# Consistent reporting window applied to every fact table in Section 9
ANALYSIS_START = pd.Timestamp("2020-01-01", tz="UTC")
ANALYSIS_END = pd.Timestamp("2022-12-31 23:59:59", tz="UTC")

# Reference point for calculating patient age
REFERENCE_DATE = pd.Timestamp("2022-12-31")

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

CATEGORY_KEYWORDS = {
    "Dental": ["gingiv", "dental", "tooth", "teeth", "caries", "molar", "torus"],
    "Cardiovascular": ["myocardial infarction", "heart failure", "heart disease", "ischemic heart",
                        "hypertension", "coronary", "atrial fibrillation", "aortic valve",
                        "mitral valve", "pulmonic valve", "tricuspid valve", "pulmonary embolism",
                        "deep venous thrombosis", "preinfarction"],
    "Respiratory": ["sinusitis", "bronchitis", "pharyngitis", "pneumonia", "asthma", "otitis",
                     "wheezing", "sleep apnea", "emphysema", "hypoxemia", "rhinitis", "sore throat",
                     "nasal congestion", "sputum"],
    "Metabolic / Endocrine": ["diabetes", "obesity", "body mass index", "hyperlipidemia",
                               "hypertriglyceridemia", "hyperglycemia", "metabolic syndrome"],
    "Musculoskeletal / Injury": ["fracture", "sprain", "injury", "laceration", "scoliosis",
                                  "burn", "concussion", "bullet wound", "meniscus", "patellar",
                                  "osteoporosis", "fibromyalgia"],
    "Genitourinary": ["kidney", "renal", "cystitis", "urinary", "bladder", "pyelonephritis",
                       "retention of urine"],
    "Neurological": ["neurolog", "seizure", "migraine", "epilepsy", "alzheimer", "cerebral palsy",
                      "cerebrovascular", "stroke", "dementia", "spasticity", "intellectual disability",
                      "spina bifida"],
    "Women's Health": ["pregnan", "miscarriage", "prenatal", "postnatal", "postpartum",
                        "pre-eclampsia", "blighted ovum", "tubal ligation", "sterilization"],
    "Infectious Disease": ["infection", "infective", "viral", "bacterial", "coronavirus",
                            "streptococcal", "sepsis", "immune deficiency", "hepatitis"],
    "Mental / Behavioral": ["stress", "anxiety", "depress", "alcoholism", "drug abuse",
                             "opioid abuse", "misuses drugs", "smokes tobacco", "dependent drug"],
    "Oncology": ["cancer", "carcinoma", "leukemia", "lymphoma", "melanoma", "neoplasm", "myeloma"],
    "Hematologic": ["anemia", "coagulation disorder", "neutropenia"],
    "Gastrointestinal": ["appendic", "vomiting", "nausea", "gastro", "diarrhea", "bowel",
                          "bleeding from anus", "polyp of colon"],
    "Dermatological": ["dermatitis", "eczema", "rash", "allergic reaction"],
    "Symptoms": ["fever", "cough", "headache", "fatigue", "chill", "dyspnea", "pain",
                 "dystonia", "excessive salivation", "loss of taste", "shock"],
    "Social / SDOH": ["unemployed", "employment", "education", "social isolation",
                       "limited social contact", "intimate partner abuse", "not in labor force",
                       "homeless", "transport problem", "housing unsatisfactory", "refugee",
                       "criminal record", "military service", "risk activity", "social migrant",
                       "violence in the environment", "lack of access to transportation"],
    "Care / Administrative": ["medication review"],
    "Care / End-of-Life": ["hospice"],
}


# =============================================================================
# Shared helpers
# =============================================================================

def profile(df: pd.DataFrame, name: str) -> None:
    """One-line data quality snapshot: shape, duplicates, missingness."""
    missing = df.isna().sum().sum()
    print(f"{name:<20} rows={len(df):>9,}  cols={df.shape[1]:>3}  "
          f"duplicate_rows={df.duplicated().sum():>6,}  missing_values={missing:>9,}")


def load_raw(filename: str) -> pd.DataFrame:
    """Load a raw Synthea CSV and print its profile."""
    df = pd.read_csv(RAW_DATA / filename)
    profile(df, filename.replace(".csv", "_raw"))
    return df


def export(df: pd.DataFrame, filename: str) -> None:
    """Profile a cleaned table, write it to data/processed/, and confirm."""
    profile(df, filename.replace(".csv", ""))
    df.to_csv(PROCESSED_DATA / filename, index=False)
    print(f"Saved {filename}")


def categorize_condition(name: str) -> str:
    """Map a raw condition description to a clinical category by keyword match."""
    lowered = name.lower()
    for category, keywords in CATEGORY_KEYWORDS.items():
        if any(kw in lowered for kw in keywords):
            return category
    return "Unclassified"


def apply_window(df: pd.DataFrame, date_col: str, name: str) -> pd.DataFrame:
    """Filter a fact table to the shared ANALYSIS_START/ANALYSIS_END reporting window."""
    windowed = df[(df[date_col] >= ANALYSIS_START) & (df[date_col] <= ANALYSIS_END)].copy()
    print(f"{name:<22} full={len(df):>9,}  windowed={len(windowed):>9,}")
    return windowed


# =============================================================================
# 1. Patients (dimension)
# =============================================================================

def clean_patients() -> pd.DataFrame:
    raw = load_raw("patients.csv")

    keep_cols = [
        "Id", "BIRTHDATE", "DEATHDATE", "MARITAL", "RACE", "ETHNICITY", "GENDER",
        "CITY", "STATE", "COUNTY", "FIPS", "ZIP", "LAT", "LON",
        "HEALTHCARE_EXPENSES", "HEALTHCARE_COVERAGE", "INCOME",
    ]
    df = raw[keep_cols].copy()

    df["BIRTHDATE"] = pd.to_datetime(df["BIRTHDATE"], errors="coerce")
    df["DEATHDATE"] = pd.to_datetime(df["DEATHDATE"], errors="coerce")
    df["MARITAL"] = df["MARITAL"].fillna("Unknown")
    df["IS_DECEASED"] = df["DEATHDATE"].notna()

    # Age as of a fixed reference date. Ages that come out negative belong to
    # patients born after the reference date (a real possibility with a rolling
    # generation date) -- set to null rather than silently keeping a negative age.
    age_years = (REFERENCE_DATE - df["BIRTHDATE"]).dt.days / 365.25
    df["AGE"] = age_years.astype(int)
    df.loc[df["AGE"] < 0, "AGE"] = pd.NA

    df["AGE_GROUP"] = pd.cut(
        df["AGE"],
        bins=[0, 17, 34, 49, 64, 79, 120],
        labels=["0-17", "18-34", "35-49", "50-64", "65-79", "80+"],
        include_lowest=True,
    )

    assert df["Id"].is_unique, "Duplicate patient IDs found"
    assert (df["AGE"].dropna() < 0).sum() == 0

    export(df, "patients_clean.csv")
    return df


# =============================================================================
# 2. Providers (dimension)
# =============================================================================

def clean_providers() -> pd.DataFrame:
    df = load_raw("providers.csv").copy()

    assert df["Id"].is_unique
    assert ((df["LAT"].between(-90, 90)) & (df["LON"].between(-180, 180))).all()

    export(df, "providers_clean.csv")
    return df


# =============================================================================
# 3. Organizations (dimension)
# =============================================================================

def clean_organizations() -> pd.DataFrame:
    df = load_raw("organizations.csv").copy()

    assert df["Id"].is_unique
    assert (df["REVENUE"] >= 0).all()
    assert (df["UTILIZATION"] >= 0).all()

    export(df, "organizations_clean.csv")
    return df


# =============================================================================
# 4. Payers (dimension)
# =============================================================================

def clean_payers() -> pd.DataFrame:
    df = load_raw("payers.csv").copy()

    assert df["Id"].is_unique
    assert (df["AMOUNT_COVERED"] >= 0).all()
    assert (df["AMOUNT_UNCOVERED"] >= 0).all()

    export(df, "payers_clean.csv")
    return df


# =============================================================================
# 5. Encounters (fact)
# =============================================================================
# Cleaned at full scope with the derived columns the dashboard actually needs
# (duration, standardized category, patient financial responsibility). The
# 2020-2022 analysis window is applied later, in Section 9, alongside every
# other fact table -- not here in isolation.

def clean_encounters() -> pd.DataFrame:
    df = load_raw("encounters.csv").copy()

    df["START"] = pd.to_datetime(df["START"], errors="coerce")
    df["STOP"] = pd.to_datetime(df["STOP"], errors="coerce")

    df["ENCOUNTER_DURATION_HOURS"] = (
        (df["STOP"] - df["START"]).dt.total_seconds() / 3600
    ).round(2)

    df["ENCOUNTER_YEAR"] = df["START"].dt.year
    df["ENCOUNTER_MONTH"] = df["START"].dt.month
    df["ENCOUNTER_MONTH_NAME"] = df["START"].dt.month_name()

    df["ENCOUNTER_CATEGORY"] = df["ENCOUNTERCLASS"].map(ENCOUNTER_CATEGORY_MAP)

    df["PATIENT_RESPONSIBILITY"] = (
        df["TOTAL_CLAIM_COST"] - df["PAYER_COVERAGE"]
    ).round(2)

    df["PAYER_COVERAGE_RATE"] = (
        df["PAYER_COVERAGE"] / df["TOTAL_CLAIM_COST"]
    ).round(4)

    assert df["Id"].is_unique
    assert (df["STOP"] >= df["START"]).all()
    assert df["ENCOUNTER_CATEGORY"].notna().all(), "Unmapped ENCOUNTERCLASS value found"
    assert (df["TOTAL_CLAIM_COST"] >= 0).all()
    assert (df["PAYER_COVERAGE"] >= 0).all()

    export(df, "encounters_clean.csv")
    return df


# =============================================================================
# 6. Conditions (fact)
# =============================================================================
# Clinical category assignment is a single keyword-plus-explicit-override map
# (CATEGORY_KEYWORDS, defined at the top of this file), built once rather than
# iteratively patched across many notebook cells.

def clean_conditions() -> pd.DataFrame:
    df = load_raw("conditions.csv").copy()

    df["START"] = pd.to_datetime(df["START"], errors="coerce")
    df["STOP"] = pd.to_datetime(df["STOP"], errors="coerce")

    # Strip the trailing SNOMED classifier, e.g. "Chronic sinusitis (disorder)" -> "Chronic sinusitis"
    df["CONDITION_NAME"] = df["DESCRIPTION"].str.replace(r"\s*$", "", regex=True).str.strip()
    df["CLINICAL_CATEGORY"] = df["CONDITION_NAME"].apply(categorize_condition)

    unclassified_share = (df["CLINICAL_CATEGORY"] == "Unclassified").mean()
    print(f"Unclassified share: {unclassified_share:.2%}")
    # Keep this comfortably low (a handful of rare condition names); revisit
    # CATEGORY_KEYWORDS above if this creeps up after regenerating the population.

    export(df, "conditions_clean.csv")
    return df


# =============================================================================
# 7. Procedures (fact)
# =============================================================================

def clean_procedures() -> pd.DataFrame:
    df = load_raw("procedures.csv").copy()

    df["START"] = pd.to_datetime(df["START"], errors="coerce")
    df["STOP"] = pd.to_datetime(df["STOP"], errors="coerce")

    df["PROCEDURE_DURATION_HOURS"] = (
        (df["STOP"] - df["START"]).dt.total_seconds() / 3600
    )

    # A handful of rows have STOP before START (data artifact) -- drop rather than
    # clip, since a negative duration can't be trusted to represent the true
    # procedure length.
    before = len(df)
    df = df[df["PROCEDURE_DURATION_HOURS"] >= 0].copy()
    print(f"Dropped {before - len(df)} row(s) with negative duration")

    assert (df["PROCEDURE_DURATION_HOURS"] >= 0).all()
    assert (df["BASE_COST"] >= 0).all()

    export(df, "procedures_clean.csv")
    return df


# =============================================================================
# 8. Claims & Claims Transactions (fact)
# =============================================================================

def clean_claims() -> pd.DataFrame:
    df = load_raw("claims.csv").copy()

    date_cols = ["CURRENTILLNESSDATE", "SERVICEDATE", "LASTBILLEDDATE1", "LASTBILLEDDATE2", "LASTBILLEDDATEP"]
    for col in date_cols:
        df[col] = pd.to_datetime(df[col], errors="coerce")

    status_cols = ["STATUS1", "STATUS2", "STATUSP"]
    for col in status_cols:
        df[col] = df[col].str.strip().str.upper()

    df["TOTAL_OUTSTANDING"] = (
        df["OUTSTANDING1"].fillna(0)
        + df["OUTSTANDING2"].fillna(0)
        + df["OUTSTANDINGP"].fillna(0)
    ).round(2)
    df["HAS_OUTSTANDING_BALANCE"] = df["TOTAL_OUTSTANDING"] > 0

    assert df["Id"].is_unique
    assert (df["TOTAL_OUTSTANDING"] >= 0).all()

    export(df, "claims_clean.csv")
    return df


def clean_claims_transactions() -> pd.DataFrame:
    df = load_raw("claims_transactions.csv").copy()

    df["FROMDATE"] = pd.to_datetime(df["FROMDATE"], errors="coerce")
    df["TODATE"] = pd.to_datetime(df["TODATE"], errors="coerce")
    df["TYPE"] = df["TYPE"].str.strip().str.upper()

    numeric_cols = ["AMOUNT", "PAYMENTS", "ADJUSTMENTS", "TRANSFERS", "OUTSTANDING"]
    for col in numeric_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0).round(2)

    assert df["ID"].is_unique
    assert (df["AMOUNT"] >= 0).all()

    export(df, "claims_transactions_clean.csv")
    return df


# =============================================================================
# 9. Consistent 2020-2022 analysis window
# =============================================================================
# The full _clean tables produced above are the source of truth. This section
# applies the same ANALYSIS_START/ANALYSIS_END window across every fact table,
# so encounters, conditions, procedures, and claims all describe the same
# reporting period in Power BI -- not four different windows.

def window_fact_tables(
    encounters_clean: pd.DataFrame,
    conditions_clean: pd.DataFrame,
    procedures_clean: pd.DataFrame,
    claims_clean: pd.DataFrame,
    claims_txn_clean: pd.DataFrame,
) -> dict[str, pd.DataFrame]:
    windowed = {
        "encounters_2020_2022": apply_window(encounters_clean, "START", "encounters"),
        "conditions_2020_2022": apply_window(conditions_clean, "START", "conditions"),
        "procedures_2020_2022": apply_window(procedures_clean, "START", "procedures"),
        "claims_2020_2022": apply_window(claims_clean, "SERVICEDATE", "claims"),
        "claims_transactions_2020_2022": apply_window(claims_txn_clean, "FROMDATE", "claims_transactions"),
    }
    for name, df in windowed.items():
        df.to_csv(PROCESSED_DATA / f"{name}.csv", index=False)
    print("Saved 5 windowed analysis tables to data/processed/")
    return windowed


# =============================================================================
# 10. Pipeline summary
# =============================================================================

def print_summary(tables: dict[str, pd.DataFrame]) -> None:
    summary = pd.DataFrame([
        {"table": name, "rows": len(df)} for name, df in tables.items()
    ])
    print("\n--- Pipeline Summary ---")
    print(summary)


# =============================================================================
# Main
# =============================================================================

def main() -> None:
    patients_clean = clean_patients()
    providers_clean = clean_providers()
    organizations_clean = clean_organizations()
    payers_clean = clean_payers()

    encounters_clean = clean_encounters()
    conditions_clean = clean_conditions()
    procedures_clean = clean_procedures()
    claims_clean = clean_claims()
    claims_txn_clean = clean_claims_transactions()

    windowed = window_fact_tables(
        encounters_clean, conditions_clean, procedures_clean,
        claims_clean, claims_txn_clean,
    )

    all_tables = {
        "patients_clean": patients_clean,
        "providers_clean": providers_clean,
        "organizations_clean": organizations_clean,
        "payers_clean": payers_clean,
        "encounters_clean": encounters_clean,
        **{"encounters_2020_2022": windowed["encounters_2020_2022"]},
        "conditions_clean": conditions_clean,
        **{"conditions_2020_2022": windowed["conditions_2020_2022"]},
        "procedures_clean": procedures_clean,
        **{"procedures_2020_2022": windowed["procedures_2020_2022"]},
        "claims_clean": claims_clean,
        **{"claims_2020_2022": windowed["claims_2020_2022"]},
        "claims_transactions_clean": claims_txn_clean,
        **{"claims_transactions_2020_2022": windowed["claims_transactions_2020_2022"]},
    }
    print_summary(all_tables)


if __name__ == "__main__":
    main()
