USE HealthcareAnalytics_Numeric;
GO

-------------------------------------------------------------------
-- 1. Claims Summary View
-------------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_ClaimsSummary AS
SELECT 
    ClaimID,
    PatientID,
    ProviderID,
    DepartmentID,
    ServiceDate,
    YEAR(ServiceDate) AS ServiceYear,
    MONTH(ServiceDate) AS ServiceMonth,
    TotalOutstanding,
    CASE 
        WHEN TotalOutstanding > 0 THEN 'Outstanding'
        ELSE 'Fully Paid / Settled'
    END AS BalanceCategory
FROM dbo.Claims;
GO

-------------------------------------------------------------------
-- 2. Patient Overview View
-------------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_PatientOverview AS
WITH EncounterTotals AS (
    SELECT PatientID, COUNT(EncounterID) AS TotalEncounters
    FROM dbo.Encounters
    GROUP BY PatientID
),
ConditionTotals AS (
    SELECT PatientID, COUNT(ConditionID) AS ActiveConditionsCount
    FROM dbo.Conditions
    GROUP BY PatientID
)
SELECT 
    p.PatientID,
    p.Gender,
    p.Race,
    p.City,
    p.State,
    DATEDIFF(YEAR, p.BirthDate, GETDATE()) AS CurrentAge,
    CASE 
        WHEN DATEDIFF(YEAR, p.BirthDate, GETDATE()) < 18 THEN 'Under 18'
        WHEN DATEDIFF(YEAR, p.BirthDate, GETDATE()) BETWEEN 18 AND 34 THEN '18-34'
        WHEN DATEDIFF(YEAR, p.BirthDate, GETDATE()) BETWEEN 35 AND 50 THEN '35-50'
        WHEN DATEDIFF(YEAR, p.BirthDate, GETDATE()) BETWEEN 51 AND 65 THEN '51-65'
        ELSE '65+'
    END AS AgeGroup,
    COALESCE(e.TotalEncounters, 0) AS TotalEncounters,
    COALESCE(c.ActiveConditionsCount, 0) AS ActiveConditionsCount
FROM dbo.Patients p
LEFT JOIN EncounterTotals e ON p.PatientID = e.PatientID
LEFT JOIN ConditionTotals c ON p.PatientID = c.PatientID;
GO

-------------------------------------------------------------------
-- 3. Departmental Performance View
-------------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_DepartmentalPerformance AS
SELECT 
    DepartmentID,
    YEAR(ServiceDate) AS ServiceYear,
    MONTH(ServiceDate) AS ServiceMonth,
    COUNT(ClaimID) AS TotalClaimsCount,
    COUNT(DISTINCT PatientID) AS UniquePatientsServed,
    SUM(TotalOutstanding) AS TotalOutstandingBalance
FROM dbo.Claims
GROUP BY 
    DepartmentID,
    YEAR(ServiceDate),
    MONTH(ServiceDate);
GO
