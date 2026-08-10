/*
===========================================================
Healthcare Analytics Dashboard
SQL Server Data Loading
===========================================================

Purpose:
Load cleaned healthcare datasets produced by the Python
data preparation pipeline into SQL Server.

Source:
data/processed/ (see ../python-data-cleaning)

The CSV files are intentionally excluded from GitHub. Update
@DataPath below to the local location of the processed CSV
files before executing this script -- every load statement
references it, so it only needs to change in one place.

Prerequisite:
scripts/01_create_tables.sql has been run.

Load order (matches foreign key dependencies):
1. Patients
2. Organizations
3. Providers
4. Payers
5. Encounters
6. Conditions
7. Procedures
8. Claims
9. Claims Transactions

===========================================================
*/

SET NOCOUNT ON;

-- =========================================================
-- LOAD PROCEDURE
-- Wraps each BULK INSERT in TRY/CATCH so one failed file
-- reports clearly instead of silently stopping the script.
-- =========================================================

CREATE OR ALTER PROCEDURE #LoadTable
    @TableName VARCHAR(100),
    @FileName VARCHAR(255),
    @DataPath VARCHAR(500)
AS
BEGIN
    DECLARE @FullPath VARCHAR(1000) = @DataPath + @FileName;
    DECLARE @Sql NVARCHAR(MAX) = N'
        BULK INSERT ' + @TableName + N'
        FROM ''' + @FullPath + N'''
        WITH
        (
            FORMAT = ''CSV'',
            FIRSTROW = 2,
            FIELDQUOTE = ''"'',
            CODEPAGE = ''65001'',
            TABLOCK
        );';

    BEGIN TRY
        EXEC sp_executesql @Sql;
        PRINT CONCAT('Loaded: ', @TableName, ' <- ', @FileName);
    END TRY
    BEGIN CATCH
        PRINT CONCAT('FAILED: ', @TableName, ' <- ', @FileName,
                      '  |  ', ERROR_MESSAGE());
        THROW;
    END CATCH
END;
GO

-- =========================================================
-- LOAD ALL TABLES
-- =========================================================

DECLARE @DataPath VARCHAR(500) = 'C:\Healthcare_Analytics\data\processed\';

EXEC #LoadTable 'dbo.Patients',             'patients_clean.csv',              @DataPath;
EXEC #LoadTable 'dbo.Organizations',        'organizations_clean.csv',         @DataPath;
EXEC #LoadTable 'dbo.Providers',            'providers_clean.csv',             @DataPath;
EXEC #LoadTable 'dbo.Payers',               'payers_clean.csv',                @DataPath;
EXEC #LoadTable 'dbo.Encounters',           'encounters_clean.csv',            @DataPath;
EXEC #LoadTable 'dbo.Conditions',           'conditions_clean.csv',            @DataPath;
EXEC #LoadTable 'dbo.Procedures',           'procedures_clean.csv',            @DataPath;
EXEC #LoadTable 'dbo.Claims',               'claims_clean.csv',                @DataPath;
EXEC #LoadTable 'dbo.Claims_Transactions',  'claims_transactions_clean.csv',   @DataPath;

DROP PROCEDURE #LoadTable;

-- =========================================================
-- LOAD SUMMARY
-- =========================================================

SELECT TableName, RowCount_ FROM (
    SELECT 'Patients'             AS TableName, COUNT(*) AS RowCount_, 1 AS SortOrder FROM dbo.Patients
    UNION ALL
    SELECT 'Organizations',        COUNT(*), 2 FROM dbo.Organizations
    UNION ALL
    SELECT 'Providers',            COUNT(*), 3 FROM dbo.Providers
    UNION ALL
    SELECT 'Payers',               COUNT(*), 4 FROM dbo.Payers
    UNION ALL
    SELECT 'Encounters',           COUNT(*), 5 FROM dbo.Encounters
    UNION ALL
    SELECT 'Conditions',           COUNT(*), 6 FROM dbo.Conditions
    UNION ALL
    SELECT 'Procedures',           COUNT(*), 7 FROM dbo.Procedures
    UNION ALL
    SELECT 'Claims',               COUNT(*), 8 FROM dbo.Claims
    UNION ALL
    SELECT 'Claims Transactions',  COUNT(*), 9 FROM dbo.Claims_Transactions
) AS LoadSummary
ORDER BY SortOrder;
