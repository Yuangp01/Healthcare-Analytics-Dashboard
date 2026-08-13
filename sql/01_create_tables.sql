-- ============================================================================
-- 01_create_tables.sql
-- Healthcare Analytics Numeric Database
-- DDL: Create 5 core base tables with strict PKs and FKs
-- ============================================================================

USE HealthcareAnalytics_Numeric;
GO

-- ============================================================================
-- 1. PATIENTS (Dimension Table)
-- Demographic information for all patients in the dataset
-- ============================================================================

IF OBJECT_ID('dbo.Patients', 'U') IS NOT NULL 
    DROP TABLE dbo.Patients;

CREATE TABLE dbo.Patients (
    Id                          VARCHAR(36)     PRIMARY KEY,
    BIRTHDATE                   DATE            NOT NULL,
    DEATHDATE                   DATE            NULL,
    MARITAL                     VARCHAR(50)     NULL,
    RACE                        VARCHAR(100)    NULL,
    ETHNICITY                   VARCHAR(100)    NULL,
    GENDER                      VARCHAR(10)     NOT NULL,
    CITY                        VARCHAR(100)    NULL,
    STATE                       VARCHAR(50)     NULL,
    COUNTY                      VARCHAR(100)    NULL,
    FIPS                        VARCHAR(10)     NULL,
    ZIP                         VARCHAR(10)     NULL,
    LAT                         FLOAT           NULL,
    LON                         FLOAT           NULL,
    HEALTHCARE_EXPENSES         DECIMAL(15,2)   DEFAULT 0,
    HEALTHCARE_COVERAGE         DECIMAL(15,2)   DEFAULT 0,
    INCOME                      DECIMAL(15,2)   DEFAULT 0,
    IS_DECEASED                 BIT             DEFAULT 0,
    AGE                         INT             NULL,
    AGE_GROUP                   VARCHAR(20)     NULL,
    LoadedAt                    DATETIME        DEFAULT GETDATE()
);

CREATE INDEX IX_Patients_Gender ON dbo.Patients(GENDER);
CREATE INDEX IX_Patients_Race ON dbo.Patients(RACE);
CREATE INDEX IX_Patients_AgeGroup ON dbo.Patients(AGE_GROUP);

GO

-- ============================================================================
-- 2. ENCOUNTERS (Fact Table)
-- Hospital visits, admissions, and clinical encounters
-- ============================================================================

IF OBJECT_ID('dbo.Encounters', 'U') IS NOT NULL 
    DROP TABLE dbo.Encounters;

CREATE TABLE dbo.Encounters (
    Id                          VARCHAR(36)     PRIMARY KEY,
    PATIENT_ID                  VARCHAR(36)     NOT NULL,
    START                       DATETIME        NOT NULL,
    STOP                        DATETIME        NOT NULL,
    ENCOUNTER_CLASS             VARCHAR(50)     NULL,
    ENCOUNTER_CATEGORY          VARCHAR(50)     NULL,
    ENCOUNTER_DURATION_HOURS    DECIMAL(10,2)   NULL,
    ENCOUNTER_YEAR              INT             NULL,
    ENCOUNTER_MONTH             INT             NULL,
    ENCOUNTER_MONTH_NAME        VARCHAR(20)     NULL,
    TOTAL_CLAIM_COST            DECIMAL(15,2)   DEFAULT 0,
    PAYER_COVERAGE              DECIMAL(15,2)   DEFAULT 0,
    PATIENT_RESPONSIBILITY      DECIMAL(15,2)   DEFAULT 0,
    PAYER_COVERAGE_RATE         DECIMAL(5,4)    DEFAULT 0,
    PROVIDER_ID                 VARCHAR(36)     NULL,
    ORGANIZATION_ID             VARCHAR(36)     NULL,
    DEPARTMENT_ID               VARCHAR(50)     NULL,
    LoadedAt                    DATETIME        DEFAULT GETDATE(),
    CONSTRAINT FK_Encounters_Patients FOREIGN KEY (PATIENT_ID) REFERENCES dbo.Patients(Id)
);

CREATE INDEX IX_Encounters_PatientId ON dbo.Encounters(PATIENT_ID);
CREATE INDEX IX_Encounters_StartDate ON dbo.Encounters(START);
CREATE INDEX IX_Encounters_Category ON dbo.Encounters(ENCOUNTER_CATEGORY);
CREATE INDEX IX_Encounters_Department ON dbo.Encounters(DEPARTMENT_ID);

GO

-- ============================================================================
-- 3. CONDITIONS (Fact Table)
-- Clinical diagnoses and conditions per patient
-- ============================================================================

IF OBJECT_ID('dbo.Conditions', 'U') IS NOT NULL 
    DROP TABLE dbo.Conditions;

CREATE TABLE dbo.Conditions (
    PATIENT_ID                  VARCHAR(36)     NOT NULL,
    ENCOUNTER_ID                VARCHAR(36)     NULL,
    DESCRIPTION                 VARCHAR(500)    NOT NULL,
    CONDITION_NAME              VARCHAR(500)    NULL,
    CLINICAL_CATEGORY           VARCHAR(100)    NULL,
    START                       DATETIME        NOT NULL,
    STOP                        DATETIME        NULL,
    LoadedAt                    DATETIME        DEFAULT GETDATE(),
    CONSTRAINT FK_Conditions_Patients FOREIGN KEY (PATIENT_ID) REFERENCES dbo.Patients(Id),
    CONSTRAINT FK_Conditions_Encounters FOREIGN KEY (ENCOUNTER_ID) REFERENCES dbo.Encounters(Id)
);

CREATE INDEX IX_Conditions_PatientId ON dbo.Conditions(PATIENT_ID);
CREATE INDEX IX_Conditions_EncounterId ON dbo.Conditions(ENCOUNTER_ID);
CREATE INDEX IX_Conditions_Category ON dbo.Conditions(CLINICAL_CATEGORY);
CREATE INDEX IX_Conditions_StartDate ON dbo.Conditions(START);

GO

-- ============================================================================
-- 4. PROCEDURES (Fact Table)
-- Clinical procedures and treatments per patient/encounter
-- ============================================================================

IF OBJECT_ID('dbo.Procedures', 'U') IS NOT NULL 
    DROP TABLE dbo.Procedures;

CREATE TABLE dbo.Procedures (
    PATIENT_ID                  VARCHAR(36)     NOT NULL,
    ENCOUNTER_ID                VARCHAR(36)     NULL,
    DESCRIPTION                 VARCHAR(500)    NOT NULL,
    BASE_COST                   DECIMAL(15,2)   DEFAULT 0,
    START                       DATETIME        NOT NULL,
    STOP                        DATETIME        NULL,
    PROCEDURE_DURATION_HOURS    DECIMAL(10,2)   NULL,
    LoadedAt                    DATETIME        DEFAULT GETDATE(),
    CONSTRAINT FK_Procedures_Patients FOREIGN KEY (PATIENT_ID) REFERENCES dbo.Patients(Id),
    CONSTRAINT FK_Procedures_Encounters FOREIGN KEY (ENCOUNTER_ID) REFERENCES dbo.Encounters(Id)
);

CREATE INDEX IX_Procedures_PatientId ON dbo.Procedures(PATIENT_ID);
CREATE INDEX IX_Procedures_EncounterId ON dbo.Procedures(ENCOUNTER_ID);
CREATE INDEX IX_Procedures_StartDate ON dbo.Procedures(START);

GO

-- ============================================================================
-- 5. CLAIMS (Fact Table)
-- Financial billing status and revenue cycle data
-- ============================================================================

IF OBJECT_ID('dbo.Claims', 'U') IS NOT NULL 
    DROP TABLE dbo.Claims;

CREATE TABLE dbo.Claims (
    Id                          VARCHAR(36)     PRIMARY KEY,
    PATIENT_ID                  VARCHAR(36)     NOT NULL,
    CURRENTILLNESSDATE          DATE            NULL,
    SERVICEDATE                 DATE            NOT NULL,
    LASTBILLEDDATE1             DATE            NULL,
    LASTBILLEDDATE2             DATE            NULL,
    LASTBILLEDDATEP             DATE            NULL,
    STATUS1                     VARCHAR(50)     NULL,
    STATUS2                     VARCHAR(50)     NULL,
    STATUSP                     VARCHAR(50)     NULL,
    OUTSTANDING1                DECIMAL(15,2)   DEFAULT 0,
    OUTSTANDING2                DECIMAL(15,2)   DEFAULT 0,
    OUTSTANDINGP                DECIMAL(15,2)   DEFAULT 0,
    TOTAL_OUTSTANDING           DECIMAL(15,2)   DEFAULT 0,
    HAS_OUTSTANDING_BALANCE     BIT             DEFAULT 0,
    STATUS                      VARCHAR(50)     NULL,
    LoadedAt                    DATETIME        DEFAULT GETDATE(),
    CONSTRAINT FK_Claims_Patients FOREIGN KEY (PATIENT_ID) REFERENCES dbo.Patients(Id)
);

CREATE INDEX IX_Claims_PatientId ON dbo.Claims(PATIENT_ID);
CREATE INDEX IX_Claims_ServiceDate ON dbo.Claims(SERVICEDATE);
CREATE INDEX IX_Claims_Status ON dbo.Claims(HAS_OUTSTANDING_BALANCE);
CREATE INDEX IX_Claims_Outstanding ON dbo.Claims(TOTAL_OUTSTANDING);

GO

-- ============================================================================
-- Summary
-- ============================================================================

PRINT '✓ All 5 base tables created successfully';
PRINT '  - dbo.Patients (Dimension)';
PRINT '  - dbo.Encounters (Fact)';
PRINT '  - dbo.Conditions (Fact)';
PRINT '  - dbo.Procedures (Fact)';
PRINT '  - dbo.Claims (Fact)';
PRINT '';
PRINT 'Referential Integrity:';
PRINT '  - Encounters → Patients (PATIENT_ID)';
PRINT '  - Conditions → Patients (PATIENT_ID) + Encounters (ENCOUNTER_ID)';
PRINT '  - Procedures → Patients (PATIENT_ID) + Encounters (ENCOUNTER_ID)';
PRINT '  - Claims → Patients (PATIENT_ID)';
PRINT '';
PRINT 'Ready for Phase 2: Data Ingestion (02_load_data.sql)';
