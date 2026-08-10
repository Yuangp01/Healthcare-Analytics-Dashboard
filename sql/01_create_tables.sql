/*
===========================================================
Healthcare Analytics Dashboard
SQL Server Data Model
===========================================================

Purpose:
Create the relational database structure for the cleaned
healthcare datasets prepared with Python.

Source:
Synthetic healthcare data cleaned and validated with Python.

Tables:
1. PATIENTS
2. ORGANIZATIONS
3. PROVIDERS
4. PAYERS
5. ENCOUNTERS
6. CONDITIONS
7. PROCEDURES
8. CLAIMS
9. CLAIMS_TRANSACTIONS

===========================================================
*/

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
    FIPS VARCHAR(10) NULL,               -- identifier, not a numeric quantity
    ZIP VARCHAR(10) NOT NULL,            -- preserves leading zeros (e.g. Northeast zips)
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


-- =========================================================
-- 2. ORGANIZATIONS
-- =========================================================

CREATE TABLE dbo.Organizations
(
    Id VARCHAR(100) NOT NULL,
    NAME VARCHAR(255) NOT NULL,
    ADDRESS VARCHAR(255) NOT NULL,
    CITY VARCHAR(100) NOT NULL,
    STATE VARCHAR(50) NOT NULL,
    ZIP VARCHAR(10) NOT NULL,
    LAT DECIMAL(10,6) NOT NULL,
    LON DECIMAL(10,6) NOT NULL,
    PHONE VARCHAR(50) NOT NULL,
    REVENUE DECIMAL(18,2) NOT NULL,
    UTILIZATION INT NOT NULL,

    CONSTRAINT PK_Organizations
        PRIMARY KEY (Id)
);


-- =========================================================
-- 3. PROVIDERS
-- =========================================================

CREATE TABLE dbo.Providers
(
    Id VARCHAR(100) NOT NULL,
    ORGANIZATION VARCHAR(100) NOT NULL,
    NAME VARCHAR(255) NOT NULL,
    GENDER VARCHAR(20) NOT NULL,
    SPECIALITY VARCHAR(150) NOT NULL,
    ADDRESS VARCHAR(255) NOT NULL,
    CITY VARCHAR(100) NOT NULL,
    STATE VARCHAR(50) NOT NULL,
    ZIP VARCHAR(10) NOT NULL,
    LAT DECIMAL(10,6) NOT NULL,
    LON DECIMAL(10,6) NOT NULL,
    ENCOUNTERS INT NOT NULL,
    PROCEDURES INT NOT NULL,

    CONSTRAINT PK_Providers
        PRIMARY KEY (Id),

    CONSTRAINT FK_Providers_Organizations
        FOREIGN KEY (ORGANIZATION)
        REFERENCES dbo.Organizations(Id)
);


-- =========================================================
-- 4. PAYERS
-- =========================================================

CREATE TABLE dbo.Payers
(
    Id VARCHAR(100) NOT NULL,
    NAME VARCHAR(255) NOT NULL,
    OWNERSHIP VARCHAR(100) NOT NULL,
    ADDRESS VARCHAR(255) NULL,
    CITY VARCHAR(100) NULL,
    STATE_HEADQUARTERED VARCHAR(50) NULL,
    ZIP VARCHAR(20) NULL,
    PHONE VARCHAR(50) NULL,
    AMOUNT_COVERED DECIMAL(18,2) NOT NULL,
    AMOUNT_UNCOVERED DECIMAL(18,2) NOT NULL,
    REVENUE DECIMAL(18,2) NOT NULL,
    COVERED_ENCOUNTERS INT NOT NULL,
    UNCOVERED_ENCOUNTERS INT NOT NULL,
    COVERED_MEDICATIONS INT NOT NULL,
    UNCOVERED_MEDICATIONS INT NOT NULL,
    COVERED_PROCEDURES INT NOT NULL,
    UNCOVERED_PROCEDURES INT NOT NULL,
    COVERED_IMMUNIZATIONS INT NOT NULL,
    UNCOVERED_IMMUNIZATIONS INT NOT NULL,
    UNIQUE_CUSTOMERS INT NOT NULL,
    QOLS_AVG DECIMAL(10,4) NOT NULL,
    MEMBER_MONTHS INT NOT NULL,

    CONSTRAINT PK_Payers
        PRIMARY KEY (Id)
);


-- =========================================================
-- 5. ENCOUNTERS
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
    REASONCODE INT NULL,                 -- reference code, not a currency/decimal value
    REASONDESCRIPTION VARCHAR(500) NULL,
    EncounterDurationHours DECIMAL(10,4) NOT NULL,

    CONSTRAINT PK_Encounters
        PRIMARY KEY (Id),

    CONSTRAINT FK_Encounters_Patients
        FOREIGN KEY (PATIENT)
        REFERENCES dbo.Patients(Id),

    CONSTRAINT FK_Encounters_Organizations
        FOREIGN KEY (ORGANIZATION)
        REFERENCES dbo.Organizations(Id),

    CONSTRAINT FK_Encounters_Providers
        FOREIGN KEY (PROVIDER)
        REFERENCES dbo.Providers(Id),

    CONSTRAINT FK_Encounters_Payers
        FOREIGN KEY (PAYER)
        REFERENCES dbo.Payers(Id)
);


-- =========================================================
-- 6. CONDITIONS
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


-- =========================================================
-- 7. PROCEDURES
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
    REASONCODE INT NULL,                 -- reference code, not a currency/decimal value
    REASONDESCRIPTION VARCHAR(500) NULL,
    ProcedureDurationHours DECIMAL(10,4) NOT NULL,

    CONSTRAINT FK_Procedures_Patients
        FOREIGN KEY (PATIENT)
        REFERENCES dbo.Patients(Id),

    CONSTRAINT FK_Procedures_Encounters
        FOREIGN KEY (ENCOUNTER)
        REFERENCES dbo.Encounters(Id)
);


-- =========================================================
-- 8. CLAIMS
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
    DIAGNOSIS2 INT NULL,                 -- reference code, not a currency/decimal value
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
        REFERENCES dbo.Patients(Id),

    CONSTRAINT FK_Claims_Providers
        FOREIGN KEY (PROVIDERID)
        REFERENCES dbo.Providers(Id)
);


-- =========================================================
-- 9. CLAIMS TRANSACTIONS
-- =========================================================

CREATE TABLE dbo.Claims_Transactions
(
    ID VARCHAR(100) NOT NULL,
    CLAIMID VARCHAR(100) NOT NULL,
    CHARGEID INT NOT NULL,
    PATIENTID VARCHAR(100) NOT NULL,
    TYPE VARCHAR(100) NOT NULL,
    AMOUNT DECIMAL(18,2) NOT NULL,
    METHOD VARCHAR(100) NULL,
    FROMDATE DATE NOT NULL,
    TODATE DATE NOT NULL,
    PLACEOFSERVICE VARCHAR(100) NOT NULL,
    PROCEDURECODE INT NOT NULL,
    MODIFIER1 VARCHAR(50) NULL,          -- reference code, not a currency/decimal value
    MODIFIER2 VARCHAR(50) NULL,
    DIAGNOSISREF1 INT NOT NULL,
    DIAGNOSISREF2 INT NULL,
    DIAGNOSISREF3 INT NULL,
    DIAGNOSISREF4 INT NULL,
    UNITS INT NOT NULL,
    DEPARTMENTID INT NOT NULL,
    NOTES VARCHAR(1000) NOT NULL,
    UNITAMOUNT DECIMAL(18,2) NOT NULL,
    TRANSFEROUTID VARCHAR(100) NULL,     -- identifier, not a currency/decimal value
    TRANSFERTYPE VARCHAR(100) NULL,
    PAYMENTS DECIMAL(18,2) NOT NULL,
    ADJUSTMENTS DECIMAL(18,2) NOT NULL,
    TRANSFERS DECIMAL(18,2) NOT NULL,
    OUTSTANDING DECIMAL(18,2) NOT NULL,
    APPOINTMENTID VARCHAR(100) NOT NULL,
    LINENOTE VARCHAR(1000) NULL,
    PATIENTINSURANCEID VARCHAR(100) NULL,
    FEESCHEDULEID INT NOT NULL,
    PROVIDERID VARCHAR(100) NOT NULL,
    SUPERVISINGPROVIDERID VARCHAR(100) NOT NULL,
    TransactionCategory VARCHAR(100) NOT NULL,
    FinancialFlow VARCHAR(100) NOT NULL,
    ChargeAmount DECIMAL(18,2) NOT NULL,
    PaymentAmount DECIMAL(18,2) NOT NULL,
    TransferAmount DECIMAL(18,2) NOT NULL,
    OutstandingAmount DECIMAL(18,2) NOT NULL,
    TransferInAmount DECIMAL(18,2) NOT NULL,
    TransferOutAmount DECIMAL(18,2) NOT NULL,
    NetTransferAmount DECIMAL(18,2) NOT NULL,

    CONSTRAINT PK_Claims_Transactions
        PRIMARY KEY (ID),

    CONSTRAINT FK_Claims_Transactions_Claims
        FOREIGN KEY (CLAIMID)
        REFERENCES dbo.Claims(Id),

    CONSTRAINT FK_Claims_Transactions_Patients
        FOREIGN KEY (PATIENTID)
        REFERENCES dbo.Patients(Id),

    CONSTRAINT FK_Claims_Transactions_Providers
        FOREIGN KEY (PROVIDERID)
        REFERENCES dbo.Providers(Id)
);
