/*
===============================================================================
Healthcare Analytics Dashboard - Relational Database Schema
Database : HealthcareAnalytics_Numeric
===============================================================================

Purpose:
Creates the core relational base table structure for the healthcare 
datasets extracted and cleaned via Power Query.

Base Tables:
1. dbo.Patients   (Demographic dimension)
2. dbo.Encounters (Hospital visits & stay fact table)
3. dbo.Conditions (Diagnoses & active conditions dimension)
4. dbo.Procedures (Clinical procedures & treatments fact table)
5. dbo.Claims     (Financial billing & revenue cycle fact table)

===============================================================================
*/

USE HealthcareAnalytics_Numeric;
GO

-- Drop tables in reverse dependency order if re-initializing
IF OBJECT_ID('dbo.Claims', 'U') IS NOT NULL DROP TABLE dbo.Claims;
IF OBJECT_ID('dbo.Procedures', 'U') IS NOT NULL DROP TABLE dbo.Procedures;
IF OBJECT_ID('dbo.Conditions', 'U') IS NOT NULL DROP TABLE dbo.Conditions;
IF OBJECT_ID('dbo.Encounters', 'U') IS NOT NULL DROP TABLE dbo.Encounters;
IF OBJECT_ID('dbo.Patients', 'U') IS NOT NULL DROP TABLE dbo.Patients;
GO

-- =========================================================
-- 1. PATIENTS
-- =========================================================

CREATE TABLE dbo.Patients
(
    Id VARCHAR(100) NOT NULL,
    BIRTHDATE DATE NOT NULL,
    DEATHDATE DATE NULL,
    MARITAL VARCHAR(50) NULL,
    RACE VARCHAR(100) NOT NULL,
    ETHNICITY VARCHAR(100) NOT NULL,
    GENDER VARCHAR(20) NOT NULL,
    CITY VARCHAR(100) NOT NULL,
    STATE VARCHAR(50) NOT NULL,
    COUNTY VARCHAR(100) NOT NULL,
    FIPS VARCHAR(10) NULL,               -- Identifier, preserves formatting
    ZIP VARCHAR(10) NOT NULL,            -- Preserves leading zeros
    LON DECIMAL(10,6) NOT NULL,
    HEALTHCARE_EXPENSES DECIMAL(18,2) NOT NULL,
    HEALTHCARE_COVERAGE DECIMAL(18,2) NOT NULL,
    INCOME INT NOT NULL,
    AGE_2022 DECIMAL(5,2) NULL,
    IS_DECEASED BIT NOT NULL,
    BIRTH_YEAR INT NOT NULL,

    CONSTRAINT PK_Patients
        PRIMARY KEY (Id)
);
GO

-- =========================================================
-- 2. ENCOUNTERS
-- =========================================================

CREATE TABLE dbo.Encounters
(
    Id VARCHAR(100) NOT NULL,
    START DATETIME2 NOT NULL,
    STOP DATETIME2 NOT NULL,
    PATIENT VARCHAR(100) NOT NULL,
    ORGANIZATION VARCHAR(100) NOT NULL,
    PROVIDER VARCHAR(100) NOT NULL,
    PAYER VARCHAR(100) NOT NULL,
    ENCOUNTERCLASS VARCHAR(50) NOT NULL,
    CODE INT NOT NULL,
    DESCRIPTION VARCHAR(500) NOT NULL,
    BASE_ENCOUNTER_COST DECIMAL(18,2) NOT NULL,
    TOTAL_CLAIM_COST DECIMAL(18,2) NOT NULL,
    PAYER_COVERAGE DECIMAL(18,2) NOT NULL,
    REASONCODE INT NULL,                  -- Reference code
    REASONDESCRIPTION VARCHAR(500) NULL,
    EncounterDurationHours DECIMAL(10,4) NOT NULL,

    CONSTRAINT PK_Encounters
        PRIMARY KEY (Id),

    CONSTRAINT FK_Encounters_Patients
        FOREIGN KEY (PATIENT)
        REFERENCES dbo.Patients(Id)
);
GO

-- =========================================================
-- 3. CONDITIONS
-- =========================================================

CREATE TABLE dbo.Conditions
(
    START DATETIME2 NOT NULL,
    STOP DATETIME2 NULL,
    PATIENT VARCHAR(100) NOT NULL,
    ENCOUNTER VARCHAR(100) NOT NULL,
    SYSTEM VARCHAR(100) NOT NULL,
    CODE INT NOT NULL,
    DESCRIPTION VARCHAR(500) NOT NULL,
    ConditionCategory VARCHAR(150) NULL,
    ConditionName VARCHAR(255) NOT NULL,
    ClinicalCategory VARCHAR(150) NOT NULL,

    CONSTRAINT FK_Conditions_Patients
        FOREIGN KEY (PATIENT)
        REFERENCES dbo.Patients(Id),

    CONSTRAINT FK_Conditions_Encounters
        FOREIGN KEY (ENCOUNTER)
        REFERENCES dbo.Encounters(Id)
);
GO

-- =========================================================
-- 4. PROCEDURES
-- =========================================================

CREATE TABLE dbo.Procedures
(
    START DATETIME2 NOT NULL,
    STOP DATETIME2 NOT NULL,
    PATIENT VARCHAR(100) NOT NULL,
    ENCOUNTER VARCHAR(100) NOT NULL,
    SYSTEM VARCHAR(100) NOT NULL,
    CODE INT NOT NULL,
    DESCRIPTION VARCHAR(500) NOT NULL,
    BASE_COST DECIMAL(18,2) NOT NULL,
    REASONCODE INT NULL,                  -- Reference code
    REASONDESCRIPTION VARCHAR(500) NULL,
    ProcedureDurationHours DECIMAL(10,4) NOT NULL,

    CONSTRAINT FK_Procedures_Patients
        FOREIGN KEY (PATIENT)
        REFERENCES dbo.Patients(Id),

    CONSTRAINT FK_Procedures_Encounters
        FOREIGN KEY (ENCOUNTER)
        REFERENCES dbo.Encounters(Id)
);
GO

-- =========================================================
-- 5. CLAIMS
-- =========================================================

CREATE TABLE dbo.Claims
(
    Id VARCHAR(100) NOT NULL,
    PATIENTID VARCHAR(100) NOT NULL,
    PROVIDERID VARCHAR(100) NOT NULL,
    PRIMARYPATIENTINSURANCEID VARCHAR(100) NULL,
    SECONDARYPATIENTINSURANCEID VARCHAR(100) NULL,
    DEPARTMENTID INT NOT NULL,
    PATIENTDEPARTMENTID INT NOT NULL,
    DIAGNOSIS1 INT NOT NULL,
    DIAGNOSIS2 INT NULL,
    DIAGNOSIS3 INT NULL,
    DIAGNOSIS4 INT NULL,
    DIAGNOSIS5 INT NULL,
    DIAGNOSIS6 INT NULL,
    DIAGNOSIS7 INT NULL,
    DIAGNOSIS8 INT NULL,
    REFERRINGPROVIDERID VARCHAR(100) NULL,
    APPOINTMENTID VARCHAR(100) NOT NULL,
    CURRENTILLNESSDATE DATE NOT NULL,
    SERVICEDATE DATE NOT NULL,
    SUPERVISINGPROVIDERID VARCHAR(100) NOT NULL,
    STATUS1 VARCHAR(50) NOT NULL,
    STATUS2 VARCHAR(50) NULL,
    STATUSP VARCHAR(50) NOT NULL,
    OUTSTANDING1 DECIMAL(18,2) NOT NULL,
    OUTSTANDING2 DECIMAL(18,2) NULL,
    OUTSTANDINGP DECIMAL(18,2) NOT NULL,
    LASTBILLEDDATE1 DATE NOT NULL,
    LASTBILLEDDATE2 DATE NULL,
    LASTBILLEDDATEP DATE NOT NULL,
    HEALTHCARECLAIMTYPEID1 INT NOT NULL,
    HEALTHCARECLAIMTYPEID2 INT NOT NULL,
    TotalOutstanding DECIMAL(18,2) NOT NULL,
    HasOutstandingBalance BIT NOT NULL,
    ServiceYear INT NOT NULL,
    ServiceMonth INT NOT NULL,
    ServiceMonthName VARCHAR(20) NOT NULL,

    CONSTRAINT PK_Claims
        PRIMARY KEY (Id),

    CONSTRAINT FK_Claims_Patients
        FOREIGN KEY (PATIENTID)
        REFERENCES dbo.Patients(Id)
);
GO
