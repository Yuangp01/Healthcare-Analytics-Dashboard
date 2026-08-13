-- ============================================================================
-- 04_create_views.sql
-- Healthcare Analytics Numeric Database
-- Analytical Presentation Layer: 3 pre-built views for Power BI
-- ============================================================================

USE HealthcareAnalytics_Numeric;
GO

PRINT '============================================================================';
PRINT 'PHASE 4: ANALYTICAL VIEWS';
PRINT '============================================================================';
PRINT '';

-- ============================================================================
-- VIEW 1: vw_ClaimsSummary
-- Revenue cycle insights: Outstanding vs Fully Paid status
-- Business question: Where is our revenue leaking?
-- ============================================================================

PRINT 'Creating vw_ClaimsSummary...';

IF OBJECT_ID('dbo.vw_ClaimsSummary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_ClaimsSummary;

GO

CREATE VIEW dbo.vw_ClaimsSummary
AS
SELECT
    c.Id AS ClaimId,
    c.PATIENT_ID,
    p.GENDER,
    p.AGE,
    p.AGE_GROUP,
    c.SERVICEDATE,
    YEAR(c.SERVICEDATE) AS ServiceYear,
    MONTH(c.SERVICEDATE) AS ServiceMonth,
    DATEDIFF(DAY, c.SERVICEDATE, GETDATE()) AS DaysOutstanding,
    c.STATUS1,
    c.STATUS2,
    c.STATUSP,
    c.TOTAL_OUTSTANDING,
    CASE 
        WHEN c.TOTAL_OUTSTANDING > 0 THEN 'Outstanding'
        ELSE 'Fully Paid / Settled'
    END AS ClaimStatus,
    CASE
        WHEN DATEDIFF(DAY, c.SERVICEDATE, GETDATE()) <= 30 THEN '0-30 Days'
        WHEN DATEDIFF(DAY, c.SERVICEDATE, GETDATE()) <= 60 THEN '31-60 Days'
        WHEN DATEDIFF(DAY, c.SERVICEDATE, GETDATE()) <= 90 THEN '61-90 Days'
        ELSE '90+ Days'
    END AS AgingBucket,
    c.LoadedAt
FROM dbo.Claims c
LEFT JOIN dbo.Patients p ON c.PATIENT_ID = p.Id;

GO

PRINT '✓ vw_ClaimsSummary created';
PRINT '';

-- ============================================================================
-- VIEW 2: vw_PatientOverview
-- Patient demographics with active conditions and encounter counts
-- Business question: What's our patient population? Who are high-risk cohorts?
-- ============================================================================

PRINT 'Creating vw_PatientOverview...';

IF OBJECT_ID('dbo.vw_PatientOverview', 'V') IS NOT NULL
    DROP VIEW dbo.vw_PatientOverview;

GO

CREATE VIEW dbo.vw_PatientOverview
AS
SELECT
    p.Id AS PATIENT_ID,
    p.GENDER,
    p.RACE,
    p.ETHNICITY,
    p.AGE,
    p.AGE_GROUP,
    p.CITY,
    p.STATE,
    p.ZIP,
    DATEDIFF(YEAR, p.BIRTHDATE, GETDATE()) AS CurrentAge,
    p.IS_DECEASED,
    DATEDIFF(YEAR, p.BIRTHDATE, p.DEATHDATE) AS AgeAtDeath,
    COUNT(DISTINCT e.Id) AS TotalEncounters,
    COUNT(DISTINCT CASE WHEN e.START >= DATEADD(YEAR, -1, GETDATE()) THEN e.Id END) AS EncountersLastYear,
    COUNT(DISTINCT c.CLINICAL_CATEGORY) AS ActiveConditionCount,
    STRING_AGG(DISTINCT c.CLINICAL_CATEGORY, '; ') WITHIN GROUP (ORDER BY c.CLINICAL_CATEGORY) AS ConditionList,
    AVG(CAST(e.ENCOUNTER_DURATION_HOURS AS FLOAT)) AS AvgLengthOfStay,
    SUM(e.TOTAL_CLAIM_COST) AS TotalClaimCost,
    SUM(e.PATIENT_RESPONSIBILITY) AS TotalPatientResponsibility,
    p.HEALTHCARE_EXPENSES,
    p.HEALTHCARE_COVERAGE,
    p.INCOME,
    p.LoadedAt
FROM dbo.Patients p
LEFT JOIN dbo.Encounters e ON p.Id = e.PATIENT_ID
LEFT JOIN dbo.Conditions c ON p.Id = c.PATIENT_ID
GROUP BY
    p.Id, p.GENDER, p.RACE, p.ETHNICITY, p.AGE, p.AGE_GROUP, p.CITY, p.STATE, p.ZIP,
    p.BIRTHDATE, p.DEATHDATE, p.IS_DECEASED, 
    p.HEALTHCARE_EXPENSES, p.HEALTHCARE_COVERAGE, p.INCOME, p.LoadedAt;

GO

PRINT '✓ vw_PatientOverview created';
PRINT '';

-- ============================================================================
-- VIEW 3: vw_DepartmentalPerformance
-- Department-level operational KPIs by month
-- Business question: Which departments are efficient? Where are unpaid claims stacking up?
-- ============================================================================

PRINT 'Creating vw_DepartmentalPerformance...';

IF OBJECT_ID('dbo.vw_DepartmentalPerformance', 'V') IS NOT NULL
    DROP VIEW dbo.vw_DepartmentalPerformance;

GO

CREATE VIEW dbo.vw_DepartmentalPerformance
AS
SELECT
    e.DEPARTMENT_ID,
    YEAR(e.START) AS ServiceYear,
    MONTH(e.START) AS ServiceMonth,
    DATEFROMPARTS(YEAR(e.START), MONTH(e.START), 1) AS YearMonth,
    COUNT(DISTINCT e.Id) AS MonthlyEncounters,
    COUNT(DISTINCT e.PATIENT_ID) AS UniquePatients,
    COUNT(DISTINCT CASE WHEN e.ENCOUNTER_CATEGORY = 'Emergency' THEN e.Id END) AS EmergencyEncounters,
    COUNT(DISTINCT CASE WHEN e.ENCOUNTER_CATEGORY = 'Inpatient' THEN e.Id END) AS InpatientEncounters,
    COUNT(DISTINCT CASE WHEN e.ENCOUNTER_CATEGORY = 'Outpatient' THEN e.Id END) AS OutpatientEncounters,
    SUM(CAST(e.TOTAL_CLAIM_COST AS DECIMAL(15,2))) AS TotalClaims,
    ROUND(AVG(CAST(e.ENCOUNTER_DURATION_HOURS AS FLOAT)), 2) AS AvgLengthOfStay,
    ROUND(AVG(CAST(e.TOTAL_CLAIM_COST AS FLOAT)), 2) AS AvgCostPerEncounter,
    SUM(CAST(c.TOTAL_OUTSTANDING AS DECIMAL(15,2))) AS CumulativeUnpaid,
    COUNT(DISTINCT CASE WHEN c.HAS_OUTSTANDING_BALANCE = 1 THEN c.Id END) AS ClaimsWithUnpaidBalance,
    ROUND(
        CAST(COUNT(DISTINCT CASE WHEN c.HAS_OUTSTANDING_BALANCE = 1 THEN c.Id END) AS FLOAT) / 
        NULLIF(COUNT(DISTINCT c.Id), 0) * 100, 
        2
    ) AS UnpaidPercentage
FROM dbo.Encounters e
LEFT JOIN dbo.Claims c ON e.PATIENT_ID = c.PATIENT_ID
    AND YEAR(c.SERVICEDATE) = YEAR(e.START)
    AND MONTH(c.SERVICEDATE) = MONTH(e.START)
GROUP BY
    e.DEPARTMENT_ID, YEAR(e.START), MONTH(e.START);

GO

PRINT '✓ vw_DepartmentalPerformance created';
PRINT '';

-- ============================================================================
-- VIEW SUMMARY
-- ============================================================================

PRINT '============================================================================';
PRINT 'ANALYTICAL VIEWS COMPLETE';
PRINT '============================================================================';
PRINT '';
PRINT 'Three views created:';
PRINT '  ✓ dbo.vw_ClaimsSummary';
PRINT '    └─ Revenue cycle insights (Outstanding vs Paid status, aging analysis)';
PRINT '';
PRINT '  ✓ dbo.vw_PatientOverview';
PRINT '    └─ Patient demographics with conditions and encounter aggregations';
PRINT '';
PRINT '  ✓ dbo.vw_DepartmentalPerformance';
PRINT '    └─ Department-level KPIs (encounters, LOS, claims, unpaid balances)';
PRINT '';
PRINT 'Next step: Connect Power BI to these views to build executive dashboards';
PRINT '';
PRINT 'SQL Server warehouse is now complete!';
PRINT 'Database: HealthcareAnalytics_Numeric';
PRINT 'Tables: 5 (Patients, Encounters, Conditions, Procedures, Claims)';
PRINT 'Views: 3 (vw_ClaimsSummary, vw_PatientOverview, vw_DepartmentalPerformance)';
