/*
===============================================================================
Database Validation & Integrity Suite
===============================================================================
Database : HealthcareAnalytics_Numeric
Purpose  : Executes automated quality assurance checks across core base 
           tables post-ETL ingestion. Validates row counts, key 
           integrity, date logic, and financial domain bounds.
Author   : Healthcare Operations Analytics Team
===============================================================================
*/

SET NOCOUNT ON;
USE HealthcareAnalytics_Numeric;
GO

PRINT '===============================================================================';
PRINT ' SECTION 1: ROW COUNT VALIDATION';
PRINT '===============================================================================';

SELECT 
    TableName, 
    RowCount_,
    CASE 
        WHEN RowCount_ > 0 THEN 'PASS' 
        ELSE 'FAIL - EMPTY TABLE' 
    END AS Status
FROM (
    SELECT 'Patients'   AS TableName, COUNT(*) AS RowCount_ FROM dbo.Patients
    UNION ALL 
    SELECT 'Encounters' AS TableName, COUNT(*) AS RowCount_ FROM dbo.Encounters
    UNION ALL 
    SELECT 'Conditions' AS TableName, COUNT(*) AS RowCount_ FROM dbo.Conditions
    UNION ALL 
    SELECT 'Procedures' AS TableName, COUNT(*) AS RowCount_ FROM dbo.Procedures
    UNION ALL 
    SELECT 'Claims'     AS TableName, COUNT(*) AS RowCount_ FROM dbo.Claims
) AS RowCounts;

GO

PRINT '===============================================================================';
PRINT ' SECTION 2: PRIMARY KEY INTEGRITY (DUPLICATE CHECKS)';
PRINT '===============================================================================';

SELECT 
    TableName, 
    TotalRows, 
    UniqueIds,
    CASE 
        WHEN TotalRows = UniqueIds THEN 'PASS' 
        ELSE 'FAIL - DUPLICATE KEYS' 
    END AS Status
FROM (
    SELECT 'Patients'   AS TableName, COUNT(*) AS TotalRows, COUNT(DISTINCT Id) AS UniqueIds FROM dbo.Patients
    UNION ALL 
    SELECT 'Encounters' AS TableName, COUNT(*) AS TotalRows, COUNT(DISTINCT Id) AS UniqueIds FROM dbo.Encounters
    UNION ALL 
    SELECT 'Claims'     AS TableName, COUNT(*) AS TotalRows, COUNT(DISTINCT Id) AS UniqueIds FROM dbo.Claims
) AS PkChecks;

GO

PRINT '===============================================================================';
PRINT ' SECTION 3: FOREIGN KEY REFERENTIAL INTEGRITY (ORPHAN CHECKS)';
PRINT '===============================================================================';

SELECT 
    CheckName, 
    OrphanCount,
    CASE 
        WHEN OrphanCount = 0 THEN 'PASS' 
        ELSE 'FAIL - ORPHANED ROWS DETECTED' 
    END AS Status
FROM (
    SELECT '[FK] Encounters -> Patients' AS CheckName, COUNT(*) AS OrphanCount
    FROM dbo.Encounters e 
    LEFT JOIN dbo.Patients p ON e.PATIENT = p.Id
    WHERE p.Id IS NULL

    UNION ALL

    SELECT '[FK] Conditions -> Patients', COUNT(*)
    FROM dbo.Conditions c 
    LEFT JOIN dbo.Patients p ON c.PATIENT = p.Id
    WHERE p.Id IS NULL

    UNION ALL

    SELECT '[FK] Conditions -> Encounters', COUNT(*)
    FROM dbo.Conditions c 
    LEFT JOIN dbo.Encounters e ON c.ENCOUNTER = e.Id
    WHERE e.Id IS NULL

    UNION ALL

    SELECT '[FK] Procedures -> Patients', COUNT(*)
    FROM dbo.Procedures pc 
    LEFT JOIN dbo.Patients p ON pc.PATIENT = p.Id
    WHERE p.Id IS NULL

    UNION ALL

    SELECT '[FK] Procedures -> Encounters', COUNT(*)
    FROM dbo.Procedures pc 
    LEFT JOIN dbo.Encounters e ON pc.ENCOUNTER = e.Id
    WHERE e.Id IS NULL

    UNION ALL

    SELECT '[FK] Claims -> Patients', COUNT(*)
    FROM dbo.Claims cl 
    LEFT JOIN dbo.Patients p ON cl.PATIENTID = p.Id
    WHERE p.Id IS NULL
) AS FkChecks;

GO

PRINT '===============================================================================';
PRINT ' SECTION 4: TEMPORAL & DATE LOGIC INTEGRITY';
PRINT '===============================================================================';

SELECT 
    CheckName, 
    InvalidCount,
    CASE 
        WHEN InvalidCount = 0 THEN 'PASS' 
        ELSE 'FAIL - STOP DATE PRECEDES START DATE' 
    END AS Status
FROM (
    SELECT '[Date] Encounters: STOP >= START' AS CheckName, COUNT(*) AS InvalidCount
    FROM dbo.Encounters 
    WHERE STOP < START

    UNION ALL

    SELECT '[Date] Procedures: STOP >= START', COUNT(*)
    FROM dbo.Procedures 
    WHERE STOP < START

    UNION ALL

    SELECT '[Date] Conditions: STOP >= START', COUNT(*)
    FROM dbo.Conditions 
    WHERE STOP IS NOT NULL AND STOP < START
) AS DateChecks;

GO

PRINT '===============================================================================';
PRINT ' SECTION 5: FINANCIAL & BOUNDARY INTEGRITY';
PRINT '===============================================================================';

SELECT 
    CheckName, 
    InvalidCount,
    CASE 
        WHEN InvalidCount = 0 THEN 'PASS' 
        ELSE 'FAIL - NEGATIVE VALUE DETECTED' 
    END AS Status
FROM (
    SELECT '[Financial] Encounters.TOTAL_CLAIM_COST >= 0' AS CheckName, COUNT(*) AS InvalidCount
    FROM dbo.Encounters WHERE TOTAL_CLAIM_COST < 0

    UNION ALL

    SELECT '[Financial] Encounters.PAYER_COVERAGE >= 0', COUNT(*)
    FROM dbo.Encounters WHERE PAYER_COVERAGE < 0

    UNION ALL

    SELECT '[Financial] Encounters.BASE_ENCOUNTER_COST >= 0', COUNT(*)
    FROM dbo.Encounters WHERE BASE_ENCOUNTER_COST < 0

    UNION ALL

    SELECT '[Financial] Procedures.BASE_COST >= 0', COUNT(*)
    FROM dbo.Procedures WHERE BASE_COST < 0

    UNION ALL

    SELECT '[Financial] Claims.TotalOutstanding >= 0', COUNT(*)
    FROM dbo.Claims WHERE TotalOutstanding < 0
) AS FinancialChecks;

GO

PRINT '===============================================================================';
PRINT ' SECTION 6: EXECUTIVE DATA QUALITY SUMMARY ROLLUP';
PRINT '===============================================================================';

SELECT 'Row Count' AS Category, TableName AS CheckName, Status
FROM (
    SELECT 'Patients' AS TableName, CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS Status FROM dbo.Patients
    UNION ALL SELECT 'Encounters', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM dbo.Encounters
    UNION ALL SELECT 'Conditions', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM dbo.Conditions
    UNION ALL SELECT 'Procedures', CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM dbo.Procedures
    UNION ALL SELECT 'Claims',     CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM dbo.Claims
) AS RowCountSummary

UNION ALL

SELECT 'Primary Key', TableName, CASE WHEN TotalRows = UniqueIds THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT 'Patients' AS TableName, COUNT(*) AS TotalRows, COUNT(DISTINCT Id) AS UniqueIds FROM dbo.Patients
    UNION ALL SELECT 'Encounters', COUNT(*), COUNT(DISTINCT Id) FROM dbo.Encounters
    UNION ALL SELECT 'Claims',     COUNT(*), COUNT(DISTINCT Id) FROM dbo.Claims
) AS PkSummary

UNION ALL

SELECT 'Foreign Key', CheckName, CASE WHEN OrphanCount = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT 'Encounters -> Patients' AS CheckName, COUNT(*) AS OrphanCount
    FROM dbo.Encounters e LEFT JOIN dbo.Patients p ON e.PATIENT = p.Id WHERE p.Id IS NULL
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
) AS FkSummary

UNION ALL

SELECT 'Date Logic', CheckName, CASE WHEN InvalidCount = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT 'Encounters STOP >= START' AS CheckName, COUNT(*) AS InvalidCount FROM dbo.Encounters WHERE STOP < START
    UNION ALL
    SELECT 'Procedures STOP >= START', COUNT(*) FROM dbo.Procedures WHERE STOP < START
    UNION ALL
    SELECT 'Conditions STOP >= START', COUNT(*) FROM dbo.Conditions WHERE STOP IS NOT NULL AND STOP < START
) AS DateSummary

UNION ALL

SELECT 'Financial Bounds', CheckName, CASE WHEN InvalidCount = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT 'Encounters.TOTAL_CLAIM_COST >= 0' AS CheckName, COUNT(*) AS InvalidCount FROM dbo.Encounters WHERE TOTAL_CLAIM_COST < 0
    UNION ALL SELECT 'Encounters.PAYER_COVERAGE >= 0', COUNT(*) FROM dbo.Encounters WHERE PAYER_COVERAGE < 0
    UNION ALL SELECT 'Encounters.BASE_ENCOUNTER_COST >= 0', COUNT(*) FROM dbo.Encounters WHERE BASE_ENCOUNTER_COST < 0
    UNION ALL SELECT 'Procedures.BASE_COST >= 0', COUNT(*) FROM dbo.Procedures WHERE BASE_COST < 0
    UNION ALL SELECT 'Claims.TotalOutstanding >= 0', COUNT(*) FROM dbo.Claims WHERE TotalOutstanding < 0
) AS FinancialSummary;

GO
