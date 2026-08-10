/*
===========================================================
Healthcare Analytics Dashboard
SQL Server Data Validation
===========================================================

Purpose:
Validate row counts, primary keys, foreign keys, NULL values,
and basic financial data after loading the cleaned datasets.

Prerequisite:
02_load_data.sql must be executed first.

===========================================================
*/

SET NOCOUNT ON;


-- =========================================================
-- 1. ROW COUNT VALIDATION
-- =========================================================

SELECT
    'Patients' AS TableName,
    COUNT(*) AS RowCount
FROM dbo.Patients

UNION ALL

SELECT
    'Organizations',
    COUNT(*)
FROM dbo.Organizations

UNION ALL

SELECT
    'Providers',
    COUNT(*)
FROM dbo.Providers

UNION ALL

SELECT
    'Payers',
    COUNT(*)
FROM dbo.Payers

UNION ALL

SELECT
    'Encounters',
    COUNT(*)
FROM dbo.Encounters

UNION ALL

SELECT
    'Conditions',
    COUNT(*)
FROM dbo.Conditions

UNION ALL

SELECT
    'Procedures',
    COUNT(*)
FROM dbo.Procedures

UNION ALL

SELECT
    'Claims',
    COUNT(*)
FROM dbo.Claims

UNION ALL

SELECT
    'Claims Transactions',
    COUNT(*)
FROM dbo.Claims_Transactions;


-- =========================================================
-- 2. PRIMARY KEY VALIDATION
-- =========================================================

SELECT
    'Patients' AS TableName,
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT Id) AS UniqueIds
FROM dbo.Patients

UNION ALL

SELECT
    'Organizations',
    COUNT(*),
    COUNT(DISTINCT Id)
FROM dbo.Organizations

UNION ALL

SELECT
    'Providers',
    COUNT(*),
    COUNT(DISTINCT Id)
FROM dbo.Providers

UNION ALL

SELECT
    'Payers',
    COUNT(*),
    COUNT(DISTINCT Id)
FROM dbo.Payers

UNION ALL

SELECT
    'Encounters',
    COUNT(*),
    COUNT(DISTINCT Id)
FROM dbo.Encounters

UNION ALL

SELECT
    'Claims',
    COUNT(*),
    COUNT(DISTINCT Id)
FROM dbo.Claims;


-- =========================================================
-- 3. FOREIGN KEY VALIDATION
-- =========================================================

SELECT
    COUNT(*) AS Invalid_Claim_Patients
FROM dbo.Claims c
LEFT JOIN dbo.Patients p
    ON c.PATIENTID = p.Id
WHERE p.Id IS NULL;


SELECT
    COUNT(*) AS Invalid_Claim_Providers
FROM dbo.Claims c
LEFT JOIN dbo.Providers p
    ON c.PROVIDERID = p.Id
WHERE p.Id IS NULL;


SELECT
    COUNT(*) AS Invalid_Encounter_Patients
FROM dbo.Encounters e
LEFT JOIN dbo.Patients p
    ON e.PATIENT = p.Id
WHERE p.Id IS NULL;


SELECT
    COUNT(*) AS Invalid_Encounter_Organizations
FROM dbo.Encounters e
LEFT JOIN dbo.Organizations o
    ON e.ORGANIZATION = o.Id
WHERE o.Id IS NULL;


SELECT
    COUNT(*) AS Invalid_Encounter_Providers
FROM dbo.Encounters e
LEFT JOIN dbo.Providers p
    ON e.PROVIDER = p.Id
WHERE p.Id IS NULL;


-- =========================================================
-- 4. FINANCIAL VALIDATION
-- =========================================================

SELECT
    'Claims' AS TableName,
    COUNT(*) AS NegativeOutstanding
FROM dbo.Claims
WHERE TotalOutstanding < 0

UNION ALL

SELECT
    'Claims Transactions',
    COUNT(*)
FROM dbo.Claims_Transactions
WHERE OutstandingAmount < 0;


-- =========================================================
-- 5. ENCOUNTER VALIDATION
-- =========================================================

SELECT
    COUNT(*) AS InvalidDurations
FROM dbo.Encounters
WHERE EncounterDurationHours < 0;


SELECT
    ENCOUNTERCLASS,
    COUNT(*) AS EncounterCount
FROM dbo.Encounters
GROUP BY ENCOUNTERCLASS
ORDER BY EncounterCount DESC;


-- =========================================================
-- 6. DATA QUALITY SUMMARY
-- =========================================================

SELECT
    COUNT(*) AS TotalPatients,
    SUM(CASE WHEN DEATHDATE IS NOT NULL THEN 1 ELSE 0 END)
        AS DeceasedPatients,
    AVG(CAST(INCOME AS DECIMAL(18,2)))
        AS AverageIncome
FROM dbo.Patients;


SELECT
    COUNT(*) AS TotalEncounters,
    SUM(TOTAL_CLAIM_COST) AS TotalClaimCost,
    SUM(PAYER_COVERAGE) AS TotalPayerCoverage,
    AVG(BASE_ENCOUNTER_COST) AS AverageEncounterCost
FROM dbo.Encounters;


SELECT
    COUNT(*) AS TotalClaims,
    SUM(TotalOutstanding) AS TotalOutstanding,
    SUM(CASE
        WHEN HasOutstandingBalance = 1 THEN 1
        ELSE 0
    END) AS ClaimsWithOutstandingBalance
FROM dbo.Claims;
