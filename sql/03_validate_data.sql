-- ============================================================================
-- 03_validate_data.sql
-- Healthcare Analytics Numeric Database
-- Validation Suite: 5 automated QA checks
-- ============================================================================

USE HealthcareAnalytics_Numeric;
GO

PRINT '============================================================================';
PRINT 'PHASE 3: DATA VALIDATION SUITE';
PRINT '============================================================================';
PRINT '';

-- Create a temp table to hold validation results
CREATE TABLE #ValidationResults (
    CheckNumber INT,
    CheckName NVARCHAR(100),
    TableName NVARCHAR(100),
    Status NVARCHAR(20),
    Details NVARCHAR(500),
    CheckedAt DATETIME
);

-- ============================================================================
-- CHECK 1: Row Counts
-- Verify all tables are populated and not empty
-- ============================================================================

PRINT 'CHECK 1: Row Counts';
PRINT '─────────────────────────────────────────────';

DECLARE @PatientRows INT = (SELECT COUNT(*) FROM dbo.Patients);
DECLARE @EncounterRows INT = (SELECT COUNT(*) FROM dbo.Encounters);
DECLARE @ConditionRows INT = (SELECT COUNT(*) FROM dbo.Conditions);
DECLARE @ProcedureRows INT = (SELECT COUNT(*) FROM dbo.Procedures);
DECLARE @ClaimRows INT = (SELECT COUNT(*) FROM dbo.Claims);

PRINT 'Patients:   ' + CAST(@PatientRows AS VARCHAR) + ' rows ' + 
      CASE WHEN @PatientRows > 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (1, 'Row Counts', 'Patients', CASE WHEN @PatientRows > 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@PatientRows AS NVARCHAR(50)), GETDATE());

PRINT 'Encounters: ' + CAST(@EncounterRows AS VARCHAR) + ' rows ' + 
      CASE WHEN @EncounterRows > 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (1, 'Row Counts', 'Encounters', CASE WHEN @EncounterRows > 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@EncounterRows AS NVARCHAR(50)), GETDATE());

PRINT 'Conditions: ' + CAST(@ConditionRows AS VARCHAR) + ' rows ' + 
      CASE WHEN @ConditionRows > 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (1, 'Row Counts', 'Conditions', CASE WHEN @ConditionRows > 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@ConditionRows AS NVARCHAR(50)), GETDATE());

PRINT 'Procedures: ' + CAST(@ProcedureRows AS VARCHAR) + ' rows ' + 
      CASE WHEN @ProcedureRows > 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (1, 'Row Counts', 'Procedures', CASE WHEN @ProcedureRows > 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@ProcedureRows AS NVARCHAR(50)), GETDATE());

PRINT 'Claims:     ' + CAST(@ClaimRows AS VARCHAR) + ' rows ' + 
      CASE WHEN @ClaimRows > 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (1, 'Row Counts', 'Claims', CASE WHEN @ClaimRows > 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@ClaimRows AS NVARCHAR(50)), GETDATE());

PRINT '';

-- ============================================================================
-- CHECK 2: Primary Key Uniqueness
-- Ensure no duplicate IDs in key tables
-- ============================================================================

PRINT 'CHECK 2: Primary Key Uniqueness';
PRINT '─────────────────────────────────────────────';

DECLARE @PatientDuplicates INT = (SELECT COUNT(*) - COUNT(DISTINCT Id) FROM dbo.Patients);
DECLARE @EncounterDuplicates INT = (SELECT COUNT(*) - COUNT(DISTINCT Id) FROM dbo.Encounters);
DECLARE @ClaimDuplicates INT = (SELECT COUNT(*) - COUNT(DISTINCT Id) FROM dbo.Claims);

PRINT 'Patients (duplicate IDs):   ' + CAST(@PatientDuplicates AS VARCHAR) + ' ' + 
      CASE WHEN @PatientDuplicates = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (2, 'PK Uniqueness', 'Patients', CASE WHEN @PatientDuplicates = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@PatientDuplicates AS NVARCHAR(50)), GETDATE());

PRINT 'Encounters (duplicate IDs): ' + CAST(@EncounterDuplicates AS VARCHAR) + ' ' + 
      CASE WHEN @EncounterDuplicates = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (2, 'PK Uniqueness', 'Encounters', CASE WHEN @EncounterDuplicates = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@EncounterDuplicates AS NVARCHAR(50)), GETDATE());

PRINT 'Claims (duplicate IDs):     ' + CAST(@ClaimDuplicates AS VARCHAR) + ' ' + 
      CASE WHEN @ClaimDuplicates = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (2, 'PK Uniqueness', 'Claims', CASE WHEN @ClaimDuplicates = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@ClaimDuplicates AS NVARCHAR(50)), GETDATE());

PRINT '';

-- ============================================================================
-- CHECK 3: Foreign Key Integrity
-- Ensure no orphaned records
-- ============================================================================

PRINT 'CHECK 3: Foreign Key Integrity';
PRINT '─────────────────────────────────────────────';

DECLARE @EncounterOrphans INT = (
    SELECT COUNT(*) FROM dbo.Encounters e
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Patients p WHERE p.Id = e.PATIENT_ID)
);

DECLARE @ConditionOrphans INT = (
    SELECT COUNT(*) FROM dbo.Conditions c
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Patients p WHERE p.Id = c.PATIENT_ID)
);

DECLARE @ProcedureOrphans INT = (
    SELECT COUNT(*) FROM dbo.Procedures pr
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Patients p WHERE p.Id = pr.PATIENT_ID)
);

DECLARE @ClaimOrphans INT = (
    SELECT COUNT(*) FROM dbo.Claims cl
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Patients p WHERE p.Id = cl.PATIENT_ID)
);

PRINT 'Encounters → Patients (orphans): ' + CAST(@EncounterOrphans AS VARCHAR) + ' ' + 
      CASE WHEN @EncounterOrphans = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (3, 'FK Integrity', 'Encounters→Patients', CASE WHEN @EncounterOrphans = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@EncounterOrphans AS NVARCHAR(50)), GETDATE());

PRINT 'Conditions → Patients (orphans): ' + CAST(@ConditionOrphans AS VARCHAR) + ' ' + 
      CASE WHEN @ConditionOrphans = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (3, 'FK Integrity', 'Conditions→Patients', CASE WHEN @ConditionOrphans = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@ConditionOrphans AS NVARCHAR(50)), GETDATE());

PRINT 'Procedures → Patients (orphans): ' + CAST(@ProcedureOrphans AS VARCHAR) + ' ' + 
      CASE WHEN @ProcedureOrphans = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (3, 'FK Integrity', 'Procedures→Patients', CASE WHEN @ProcedureOrphans = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@ProcedureOrphans AS NVARCHAR(50)), GETDATE());

PRINT 'Claims → Patients (orphans):     ' + CAST(@ClaimOrphans AS VARCHAR) + ' ' + 
      CASE WHEN @ClaimOrphans = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (3, 'FK Integrity', 'Claims→Patients', CASE WHEN @ClaimOrphans = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@ClaimOrphans AS NVARCHAR(50)), GETDATE());

PRINT '';

-- ============================================================================
-- CHECK 4: Temporal Logic
-- Ensure discharge/stop dates never precede admission/start dates
-- ============================================================================

PRINT 'CHECK 4: Temporal Logic (STOP >= START)';
PRINT '─────────────────────────────────────────────';

DECLARE @EncounterTemporalIssues INT = (
    SELECT COUNT(*) FROM dbo.Encounters
    WHERE STOP < START
);

DECLARE @ConditionTemporalIssues INT = (
    SELECT COUNT(*) FROM dbo.Conditions
    WHERE STOP IS NOT NULL AND STOP < START
);

DECLARE @ProcedureTemporalIssues INT = (
    SELECT COUNT(*) FROM dbo.Procedures
    WHERE STOP IS NOT NULL AND STOP < START
);

PRINT 'Encounters (STOP < START):   ' + CAST(@EncounterTemporalIssues AS VARCHAR) + ' ' + 
      CASE WHEN @EncounterTemporalIssues = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (4, 'Temporal Logic', 'Encounters', CASE WHEN @EncounterTemporalIssues = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@EncounterTemporalIssues AS NVARCHAR(50)), GETDATE());

PRINT 'Conditions (STOP < START):   ' + CAST(@ConditionTemporalIssues AS VARCHAR) + ' ' + 
      CASE WHEN @ConditionTemporalIssues = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (4, 'Temporal Logic', 'Conditions', CASE WHEN @ConditionTemporalIssues = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@ConditionTemporalIssues AS NVARCHAR(50)), GETDATE());

PRINT 'Procedures (STOP < START):   ' + CAST(@ProcedureTemporalIssues AS VARCHAR) + ' ' + 
      CASE WHEN @ProcedureTemporalIssues = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (4, 'Temporal Logic', 'Procedures', CASE WHEN @ProcedureTemporalIssues = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@ProcedureTemporalIssues AS NVARCHAR(50)), GETDATE());

PRINT '';

-- ============================================================================
-- CHECK 5: Financial Boundaries
-- Ensure financial metrics contain zero negative values
-- ============================================================================

PRINT 'CHECK 5: Financial Boundaries (No negatives)';
PRINT '─────────────────────────────────────────────';

DECLARE @EncounterNegativeCosts INT = (
    SELECT COUNT(*) FROM dbo.Encounters
    WHERE TOTAL_CLAIM_COST < 0 OR PAYER_COVERAGE < 0
);

DECLARE @ProcedureNegativeCosts INT = (
    SELECT COUNT(*) FROM dbo.Procedures
    WHERE BASE_COST < 0
);

DECLARE @ClaimNegativeOutstanding INT = (
    SELECT COUNT(*) FROM dbo.Claims
    WHERE TOTAL_OUTSTANDING < 0
);

PRINT 'Encounters (negative costs):  ' + CAST(@EncounterNegativeCosts AS VARCHAR) + ' ' + 
      CASE WHEN @EncounterNegativeCosts = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (5, 'Financial Boundaries', 'Encounters', CASE WHEN @EncounterNegativeCosts = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@EncounterNegativeCosts AS NVARCHAR(50)), GETDATE());

PRINT 'Procedures (negative costs):  ' + CAST(@ProcedureNegativeCosts AS VARCHAR) + ' ' + 
      CASE WHEN @ProcedureNegativeCosts = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (5, 'Financial Boundaries', 'Procedures', CASE WHEN @ProcedureNegativeCosts = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@ProcedureNegativeCosts AS NVARCHAR(50)), GETDATE());

PRINT 'Claims (negative outstanding): ' + CAST(@ClaimNegativeOutstanding AS VARCHAR) + ' ' + 
      CASE WHEN @ClaimNegativeOutstanding = 0 THEN '✓' ELSE '✗ FAIL' END;
INSERT INTO #ValidationResults VALUES (5, 'Financial Boundaries', 'Claims', CASE WHEN @ClaimNegativeOutstanding = 0 THEN 'PASS' ELSE 'FAIL' END, CAST(@ClaimNegativeOutstanding AS NVARCHAR(50)), GETDATE());

PRINT '';

-- ============================================================================
-- FINAL VALIDATION SUMMARY
-- ============================================================================

PRINT '============================================================================';
PRINT 'VALIDATION SUMMARY';
PRINT '============================================================================';

DECLARE @PassCount INT = (SELECT COUNT(*) FROM #ValidationResults WHERE Status = 'PASS');
DECLARE @FailCount INT = (SELECT COUNT(*) FROM #ValidationResults WHERE Status = 'FAIL');
DECLARE @TotalChecks INT = @PassCount + @FailCount;

PRINT 'Total Checks:  ' + CAST(@TotalChecks AS VARCHAR);
PRINT 'Passed:        ' + CAST(@PassCount AS VARCHAR);
PRINT 'Failed:        ' + CAST(@FailCount AS VARCHAR);
PRINT '';

IF @FailCount = 0
    PRINT '✓ ALL CHECKS PASSED - Data integrity verified. Ready for analytics views.';
ELSE
    PRINT '✗ VALIDATION FAILED - ' + CAST(@FailCount AS VARCHAR) + ' check(s) failed. Review errors above.';

PRINT '';
PRINT 'Next step: Run 04_create_views.sql to build analytical layer';

-- Clean up temp table
DROP TABLE #ValidationResults;
