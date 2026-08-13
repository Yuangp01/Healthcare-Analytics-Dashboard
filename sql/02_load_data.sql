-- ============================================================================
-- 02_load_data.sql
-- Healthcare Analytics Numeric Database
-- Data Ingestion: BULK INSERT cleaned CSVs into 5 base tables
-- ============================================================================

USE HealthcareAnalytics_Numeric;
GO

-- ============================================================================
-- Configuration
-- Update this path to match your environment
-- ============================================================================

DECLARE @DataPath NVARCHAR(500) = 'C:\Data\Healthcare\processed\';
DECLARE @LoadStartTime DATETIME = GETDATE();

PRINT '============================================================================';
PRINT 'PHASE 2: DATA INGESTION';
PRINT '============================================================================';
PRINT 'Data Path: ' + @DataPath;
PRINT 'Load Start Time: ' + CONVERT(VARCHAR, @LoadStartTime, 121);
PRINT '';

-- ============================================================================
-- 1. LOAD PATIENTS
-- ============================================================================

PRINT 'Loading patients_clean.csv...';

BULK INSERT dbo.Patients
FROM @DataPath + 'patients_clean.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    TABLOCK,
    ERRORFILE = @DataPath + 'errors_patients.txt'
);

DECLARE @PatientCount INT = (SELECT COUNT(*) FROM dbo.Patients);
PRINT '✓ Loaded ' + CAST(@PatientCount AS VARCHAR) + ' patients';
PRINT '';

-- ============================================================================
-- 2. LOAD ENCOUNTERS
-- ============================================================================

PRINT 'Loading encounters_2020_2022.csv...';

BULK INSERT dbo.Encounters
FROM @DataPath + 'encounters_2020_2022.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    TABLOCK,
    ERRORFILE = @DataPath + 'errors_encounters.txt'
);

DECLARE @EncounterCount INT = (SELECT COUNT(*) FROM dbo.Encounters);
PRINT '✓ Loaded ' + CAST(@EncounterCount AS VARCHAR) + ' encounters';
PRINT '';

-- ============================================================================
-- 3. LOAD CONDITIONS
-- ============================================================================

PRINT 'Loading conditions_2020_2022.csv...';

BULK INSERT dbo.Conditions
FROM @DataPath + 'conditions_2020_2022.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    TABLOCK,
    ERRORFILE = @DataPath + 'errors_conditions.txt'
);

DECLARE @ConditionCount INT = (SELECT COUNT(*) FROM dbo.Conditions);
PRINT '✓ Loaded ' + CAST(@ConditionCount AS VARCHAR) + ' conditions';
PRINT '';

-- ============================================================================
-- 4. LOAD PROCEDURES
-- ============================================================================

PRINT 'Loading procedures_2020_2022.csv...';

BULK INSERT dbo.Procedures
FROM @DataPath + 'procedures_2020_2022.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    TABLOCK,
    ERRORFILE = @DataPath + 'errors_procedures.txt'
);

DECLARE @ProcedureCount INT = (SELECT COUNT(*) FROM dbo.Procedures);
PRINT '✓ Loaded ' + CAST(@ProcedureCount AS VARCHAR) + ' procedures';
PRINT '';

-- ============================================================================
-- 5. LOAD CLAIMS
-- ============================================================================

PRINT 'Loading claims_2020_2022.csv...';

BULK INSERT dbo.Claims
FROM @DataPath + 'claims_2020_2022.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    TABLOCK,
    ERRORFILE = @DataPath + 'errors_claims.txt'
);

DECLARE @ClaimCount INT = (SELECT COUNT(*) FROM dbo.Claims);
PRINT '✓ Loaded ' + CAST(@ClaimCount AS VARCHAR) + ' claims';
PRINT '';

-- ============================================================================
-- Summary
-- ============================================================================

DECLARE @LoadEndTime DATETIME = GETDATE();
DECLARE @ElapsedSeconds INT = DATEDIFF(SECOND, @LoadStartTime, @LoadEndTime);

PRINT '============================================================================';
PRINT 'LOAD COMPLETE';
PRINT '============================================================================';
PRINT 'Patients:    ' + CAST(@PatientCount AS VARCHAR) + ' rows';
PRINT 'Encounters:  ' + CAST(@EncounterCount AS VARCHAR) + ' rows';
PRINT 'Conditions:  ' + CAST(@ConditionCount AS VARCHAR) + ' rows';
PRINT 'Procedures:  ' + CAST(@ProcedureCount AS VARCHAR) + ' rows';
PRINT 'Claims:      ' + CAST(@ClaimCount AS VARCHAR) + ' rows';
PRINT '';
PRINT 'Total rows loaded: ' + CAST(@PatientCount + @EncounterCount + @ConditionCount + @ProcedureCount + @ClaimCount AS VARCHAR);
PRINT 'Elapsed time: ' + CAST(@ElapsedSeconds AS VARCHAR) + ' seconds';
PRINT '';
PRINT 'Next step: Run 03_validate_data.sql to verify data integrity';
