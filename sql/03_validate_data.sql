/*
===========================================================
Healthcare Analytics Dashboard
SQL Server Data Validation
===========================================================

Purpose:
Validate row counts, primary keys, foreign keys, date logic,
and financial values after loading the cleaned datasets.

Prerequisite:
scripts/02_load_data.sql has been run.

Sections:
1. Row Count Validation
2. Primary Key Integrity
3. Foreign Key Integrity
4. Date Logic Integrity
5. Financial Integrity
6. Descriptive Data Quality Summary
7. Validation Summary (single pass/fail overview)

Each check in Sections 2-5 returns a Status of PASS or FAIL,
so a reviewer can scan results without manually interpreting
raw counts. Section 7 rolls every check into one result set
for a single-glance overview.

===========================================================
*/

SET NOCOUNT ON;


-- =========================================================
-- 1. ROW COUNT VALIDATION
-- =========================================================

SELECT TableName, RowCount_,
       CASE WHEN RowCount_ > 0 THEN 'PASS' ELSE 'FAIL - EMPTY TABLE' END AS Status
FROM (
    SELECT 'Patients'             AS TableName, COUNT(*) AS RowCount_ FROM dbo.Patients
    UNION ALL SELECT 'Organizations',       COUNT(*) FROM dbo.Organizations
    UNION ALL SELECT 'Providers',           COUNT(*) FROM dbo.Providers
    UNION ALL SELECT 'Payers',              COUNT(*) FROM dbo.Payers
    UNION ALL SELECT 'Encounters',          COUNT(*) FROM dbo.Encounters
    UNION ALL SELECT 'Conditions',          COUNT(*) FROM dbo.Conditions
    UNION ALL SELECT 'Procedures',          COUNT(*) FROM dbo.Procedures
    UNION ALL SELECT 'Claims',              COUNT(*) FROM dbo.Claims
    UNION ALL SELECT 'Claims Transactions', COUNT(*) FROM dbo.Claims_Transactions
) AS RowCounts;


-- =========================================================
-- 2. PRIMARY KEY INTEGRITY
-- Only tables with a declared PK (Id) are checked here.
-- Conditions and Procedures have no single-column PK in the
-- current schema, so they're validated for orphaned rows in
-- Section 3 instead.
-- =========================================================

SELECT TableName, TotalRows, UniqueIds,
       CASE WHEN TotalRows = UniqueIds THEN 'PASS' ELSE 'FAIL - DUPLICATE KEYS' END AS Status
FROM (
    SELECT 'Patients'             AS TableName, COUNT(*) AS TotalRows, COUNT(DISTINCT Id) AS UniqueIds FROM dbo.Patients
    UNION ALL SELECT 'Organizations',       COUNT(*), COUNT(DISTINCT Id) FROM dbo.Organizations
    UNION ALL SELECT 'Providers',           COUNT(*), COUNT(DISTINCT Id) FROM dbo.Providers
    UNION ALL SELECT 'Payers',              COUNT(*), COUNT(DISTINCT Id) FROM dbo.Payers
    UNION ALL SELECT 'Encounters',          COUNT(*), COUNT(DISTINCT Id) FROM dbo.Encounters
    UNION ALL SELECT 'Claims',              COUNT(*), COUNT(DISTINCT Id) FROM dbo.Claims
    UNION ALL SELECT 'Claims Transactions', COUNT(*), COUNT(DISTINCT ID) FROM dbo.Claims_Transactions
) AS PkChecks;


-- =========================================================
-- 3. FOREIGN KEY INTEGRITY
-- Every FK declared in 01_create_tables.sql is checked here
-- for orphaned references (rows pointing to a parent Id that
-- doesn't exist).
-- =========================================================

SELECT CheckName, OrphanCount,
       CASE WHEN OrphanCount = 0 THEN 'PASS' ELSE 'FAIL - ORPHANED ROWS' END AS Status
FROM (
    SELECT 'Providers.Organization -> Organizations' AS CheckName, COUNT(*) AS OrphanCount
    FROM dbo.Providers pr LEFT JOIN dbo.Organizations o ON pr.ORGANIZATION = o.Id
    WHERE o.Id IS NULL

    UNION ALL
    SELECT 'Encounters.Patient -> Patients', COUNT(*)
    FROM dbo.Encounters e LEFT JOIN dbo.Patients p ON e.PATIENT = p.Id
    WHERE p.Id IS NULL

    UNION ALL
    SELECT 'Encounters.Organization -> Organizations', COUNT(*)
    FROM dbo.Encounters e LEFT JOIN dbo.Organizations o ON e.ORGANIZATION = o.Id
    WHERE o.Id IS NULL

    UNION ALL
    SELECT 'Encounters.Provider -> Providers', COUNT(*)
    FROM dbo.Encounters e LEFT JOIN dbo.Providers pr ON e.PROVIDER = pr.Id
    WHERE pr.Id IS NULL

    UNION ALL
    SELECT 'Encounters.Payer -> Payers', COUNT(*)
    FROM dbo.Encounters e LEFT JOIN dbo.Payers pa ON e.PAYER = pa.Id
    WHERE pa.Id IS NULL

    UNION ALL
    SELECT 'Conditions.Patient -> Patients', COUNT(*)
    FROM dbo.Conditions c LEFT JOIN dbo.Patients p ON c.PATIENT = p.Id
    WHERE p.Id IS NULL

    UNION ALL
    SELECT 'Conditions.Encounter -> Encounters', COUNT(*)
    FROM dbo.Conditions c LEFT JOIN dbo.Encounters e ON c.ENCOUNTER = e.Id
    WHERE e.Id IS NULL

    UNION ALL
    SELECT 'Procedures.Patient -> Patients', COUNT(*)
    FROM dbo.Procedures pc LEFT JOIN dbo.Patients p ON pc.PATIENT = p.Id
    WHERE p.Id IS NULL

    UNION ALL
    SELECT 'Procedures.Encounter -> Encounters', COUNT(*)
    FROM dbo.Procedures pc LEFT JOIN dbo.Encounters e ON pc.ENCOUNTER = e.Id
    WHERE e.Id IS NULL

    UNION ALL
    SELECT 'Claims.PatientId -> Patients', COUNT(*)
    FROM dbo.Claims cl LEFT JOIN dbo.Patients p ON cl.PATIENTID = p.Id
    WHERE p.Id IS NULL

    UNION ALL
    SELECT 'Claims.ProviderId -> Providers', COUNT(*)
    FROM dbo.Claims cl LEFT JOIN dbo.Providers pr ON cl.PROVIDERID = pr.Id
    WHERE pr.Id IS NULL

    UNION ALL
    SELECT 'ClaimsTransactions.ClaimId -> Claims', COUNT(*)
    FROM dbo.Claims_Transactions ct LEFT JOIN dbo.Claims cl ON ct.CLAIMID = cl.Id
    WHERE cl.Id IS NULL

    UNION ALL
    SELECT 'ClaimsTransactions.PatientId -> Patients', COUNT(*)
    FROM dbo.Claims_Transactions ct LEFT JOIN dbo.Patients p ON ct.PATIENTID = p.Id
    WHERE p.Id IS NULL

    UNION ALL
    SELECT 'ClaimsTransactions.ProviderId -> Providers', COUNT(*)
    FROM dbo.Claims_Transactions ct LEFT JOIN dbo.Providers pr ON ct.PROVIDERID = pr.Id
    WHERE pr.Id IS NULL
) AS FkChecks;


-- =========================================================
-- 4. DATE LOGIC INTEGRITY
-- Confirms every event's end timestamp is not before its
-- start timestamp.
-- =========================================================

SELECT CheckName, InvalidCount,
       CASE WHEN InvalidCount = 0 THEN 'PASS' ELSE 'FAIL - STOP BEFORE START' END AS Status
FROM (
    SELECT 'Encounters: STOP < START' AS CheckName, COUNT(*) AS InvalidCount
    FROM dbo.Encounters WHERE STOP < START

    UNION ALL
    SELECT 'Procedures: STOP < START', COUNT(*)
    FROM dbo.Procedures WHERE STOP < START

    UNION ALL
    SELECT 'Conditions: STOP < START (where STOP is recorded)', COUNT(*)
    FROM dbo.Conditions WHERE STOP IS NOT NULL AND STOP < START
) AS DateChecks;


-- =========================================================
-- 5. FINANCIAL INTEGRITY
-- No cost, coverage, or outstanding-balance field should
-- ever be negative.
-- =========================================================

SELECT CheckName, InvalidCount,
       CASE WHEN InvalidCount = 0 THEN 'PASS' ELSE 'FAIL - NEGATIVE VALUE' END AS Status
FROM (
    SELECT 'Encounters.TOTAL_CLAIM_COST < 0' AS CheckName, COUNT(*) AS InvalidCount
    FROM dbo.Encounters WHERE TOTAL_CLAIM_COST < 0

    UNION ALL
    SELECT 'Encounters.PAYER_COVERAGE < 0', COUNT(*)
    FROM dbo.Encounters WHERE PAYER_COVERAGE < 0

    UNION ALL
    SELECT 'Encounters.BASE_ENCOUNTER_COST < 0', COUNT(*)
    FROM dbo.Encounters WHERE BASE_ENCOUNTER_COST < 0

    UNION ALL
    SELECT 'Encounters.EncounterDurationHours < 0', COUNT(*)
    FROM dbo.Encounters WHERE EncounterDurationHours < 0

    UNION ALL
    SELECT 'Procedures.BASE_COST < 0', COUNT(*)
    FROM dbo.Procedures WHERE BASE_COST < 0

    UNION ALL
    SELECT 'Procedures.ProcedureDurationHours < 0', COUNT(*)
    FROM dbo.Procedures WHERE ProcedureDurationHours < 0

    UNION ALL
    SELECT 'Claims.TotalOutstanding < 0', COUNT(*)
    FROM dbo.Claims WHERE TotalOutstanding < 0

    UNION ALL
    SELECT 'ClaimsTransactions.OutstandingAmount < 0', COUNT(*)
    FROM dbo.Claims_Transactions WHERE OutstandingAmount < 0
) AS FinancialChecks;


-- =========================================================
-- 6. DESCRIPTIVE DATA QUALITY SUMMARY
-- Informational only -- not pass/fail, gives a quick sense
-- of the loaded population.
-- =========================================================

SELECT
    COUNT(*) AS TotalPatients,
    SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END) AS DeceasedPatients,
    AVG(CAST(INCOME AS DECIMAL(18,2))) AS AverageIncome
FROM dbo.Patients;

SELECT
    ENCOUNTERCLASS,
    COUNT(*) AS EncounterCount
FROM dbo.Encounters
GROUP BY ENCOUNTERCLASS
ORDER BY EncounterCount DESC;

SELECT
    COUNT(*) AS TotalEncounters,
    SUM(TOTAL_CLAIM_COST) AS TotalClaimCost,
    SUM(PAYER_COVERAGE) AS TotalPayerCoverage,
    AVG(BASE_ENCOUNTER_COST) AS AverageEncounterCost
FROM dbo.Encounters;

SELECT
    COUNT(*) AS TotalClaims,
    SUM(TotalOutstanding) AS TotalOutstanding,
    SUM(CASE WHEN HasOutstandingBalance = 1 THEN 1 ELSE 0 END) AS ClaimsWithOutstandingBalance
FROM dbo.Claims;


-- =========================================================
-- 7. VALIDATION SUMMARY
-- Every check from Sections 1-5, in one result set, so the
-- overall pass/fail state can be read at a glance.
-- =========================================================

SELECT 'Row Count'    AS Category, TableName AS CheckName, Status
FROM (
    SELECT 'Patients' AS TableName, CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS Status FROM dbo.Patients
    UNION ALL SELECT 'Organizations', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM dbo.Organizations
    UNION ALL SELECT 'Providers', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM dbo.Providers
    UNION ALL SELECT 'Payers', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM dbo.Payers
    UNION ALL SELECT 'Encounters', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM dbo.Encounters
    UNION ALL SELECT 'Conditions', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM dbo.Conditions
    UNION ALL SELECT 'Procedures', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM dbo.Procedures
    UNION ALL SELECT 'Claims', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM dbo.Claims
    UNION ALL SELECT 'Claims Transactions', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM dbo.Claims_Transactions
) RowCountSummary

UNION ALL

SELECT 'Primary Key', TableName,
       CASE WHEN TotalRows = UniqueIds THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT 'Patients' AS TableName, COUNT(*) AS TotalRows, COUNT(DISTINCT Id) AS UniqueIds FROM dbo.Patients
    UNION ALL SELECT 'Organizations', COUNT(*), COUNT(DISTINCT Id) FROM dbo.Organizations
    UNION ALL SELECT 'Providers', COUNT(*), COUNT(DISTINCT Id) FROM dbo.Providers
    UNION ALL SELECT 'Payers', COUNT(*), COUNT(DISTINCT Id) FROM dbo.Payers
    UNION ALL SELECT 'Encounters', COUNT(*), COUNT(DISTINCT Id) FROM dbo.Encounters
    UNION ALL SELECT 'Claims', COUNT(*), COUNT(DISTINCT Id) FROM dbo.Claims
    UNION ALL SELECT 'Claims Transactions', COUNT(*), COUNT(DISTINCT ID) FROM dbo.Claims_Transactions
) PkSummary

UNION ALL

SELECT 'Foreign Key', CheckName, CASE WHEN OrphanCount = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT 'Providers -> Organizations' AS CheckName, COUNT(*) AS OrphanCount
    FROM dbo.Providers pr LEFT JOIN dbo.Organizations o ON pr.ORGANIZATION = o.Id WHERE o.Id IS NULL
    UNION ALL
    SELECT 'Encounters -> Patients', COUNT(*)
    FROM dbo.Encounters e LEFT JOIN dbo.Patients p ON e.PATIENT = p.Id WHERE p.Id IS NULL
    UNION ALL
    SELECT 'Encounters -> Organizations', COUNT(*)
    FROM dbo.Encounters e LEFT JOIN dbo.Organizations o ON e.ORGANIZATION = o.Id WHERE o.Id IS NULL
    UNION ALL
    SELECT 'Encounters -> Providers', COUNT(*)
    FROM dbo.Encounters e LEFT JOIN dbo.Providers pr ON e.PROVIDER = pr.Id WHERE pr.Id IS NULL
    UNION ALL
    SELECT 'Encounters -> Payers', COUNT(*)
    FROM dbo.Encounters e LEFT JOIN dbo.Payers pa ON e.PAYER = pa.Id WHERE pa.Id IS NULL
    UNION ALL
    SELECT 'Conditions -> Patients', COUNT(*)
    FROM dbo.Conditions c LEFT JOIN dbo.Patients p ON c.PATIENT = p.Id WHERE p.Id IS NULL
    UNION ALL
    SELECT 'Conditions -> Encounters', COUNT(*)
    FROM dbo.Conditions c LEFT JOIN dbo.Encounters e ON c.ENCOUNTER = e.Id WHERE e.Id IS NULL
    UNION ALL
    SELECT 'Procedures -> Patients', COUNT(*)
    FROM dbo.Procedures pc LEFT JOIN dbo.Patients p ON pc.PATIENT = p.Id WHERE p.Id IS NULL
    UNION ALL
    SELECT 'Procedures -> Encounters', COUNT(*)
    FROM dbo.Procedures pc LEFT JOIN dbo.Encounters e ON pc.ENCOUNTER = e.Id WHERE e.Id IS NULL
    UNION ALL
    SELECT 'Claims -> Patients', COUNT(*)
    FROM dbo.Claims cl LEFT JOIN dbo.Patients p ON cl.PATIENTID = p.Id WHERE p.Id IS NULL
    UNION ALL
    SELECT 'Claims -> Providers', COUNT(*)
    FROM dbo.Claims cl LEFT JOIN dbo.Providers pr ON cl.PROVIDERID = pr.Id WHERE pr.Id IS NULL
    UNION ALL
    SELECT 'ClaimsTransactions -> Claims', COUNT(*)
    FROM dbo.Claims_Transactions ct LEFT JOIN dbo.Claims cl ON ct.CLAIMID = cl.Id WHERE cl.Id IS NULL
    UNION ALL
    SELECT 'ClaimsTransactions -> Patients', COUNT(*)
    FROM dbo.Claims_Transactions ct LEFT JOIN dbo.Patients p ON ct.PATIENTID = p.Id WHERE p.Id IS NULL
    UNION ALL
    SELECT 'ClaimsTransactions -> Providers', COUNT(*)
    FROM dbo.Claims_Transactions ct LEFT JOIN dbo.Providers pr ON ct.PROVIDERID = pr.Id WHERE pr.Id IS NULL
) FkSummary

UNION ALL

SELECT 'Date Logic', CheckName, CASE WHEN InvalidCount = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT 'Encounters STOP >= START' AS CheckName, COUNT(*) AS InvalidCount FROM dbo.Encounters WHERE STOP < START
    UNION ALL
    SELECT 'Procedures STOP >= START', COUNT(*) FROM dbo.Procedures WHERE STOP < START
    UNION ALL
    SELECT 'Conditions STOP >= START', COUNT(*) FROM dbo.Conditions WHERE STOP IS NOT NULL AND STOP < START
) DateSummary

UNION ALL

SELECT 'Financial', CheckName, CASE WHEN InvalidCount = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT 'Encounters.TOTAL_CLAIM_COST >= 0' AS CheckName, COUNT(*) AS InvalidCount FROM dbo.Encounters WHERE TOTAL_CLAIM_COST < 0
    UNION ALL SELECT 'Encounters.PAYER_COVERAGE >= 0', COUNT(*) FROM dbo.Encounters WHERE PAYER_COVERAGE < 0
    UNION ALL SELECT 'Encounters.BASE_ENCOUNTER_COST >= 0', COUNT(*) FROM dbo.Encounters WHERE BASE_ENCOUNTER_COST < 0
    UNION ALL SELECT 'Procedures.BASE_COST >= 0', COUNT(*) FROM dbo.Procedures WHERE BASE_COST < 0
    UNION ALL SELECT 'Claims.TotalOutstanding >= 0', COUNT(*) FROM dbo.Claims WHERE TotalOutstanding < 0
    UNION ALL SELECT 'ClaimsTransactions.OutstandingAmount >= 0', COUNT(*) FROM dbo.Claims_Transactions WHERE OutstandingAmount < 0
) FinancialSummary;
