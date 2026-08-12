# 🏥 Healthcare Analytics & Claims Executive Dashboard
> **An End-to-End Healthcare Data Engineering & Business Intelligence Pipeline**

![Python](https://img.shields.io/badge/Python-3.14-3776AB?style=for-the-badge&logo=python&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-CC292B?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Desktop-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Pandas](https://img.shields.io/badge/Pandas-ETL-150458?style=for-the-badge&logo=pandas&logoColor=white)

An end-to-end healthcare analytics solution designed to ingest raw transactional healthcare data, process and clean it via a **Python batching pipeline**, store it in a relational **SQL Server** database, model it using **custom SQL Analytical Views**, and deliver executive insights in **Power BI**.

---

## 📸 Executive Dashboard Preview

| **Page 1: Executive Overview** | **Page 2: Patient Demographics** |
| :---: | :---: |
| ![Executive Overview Dashboard](https://via.placeholder.com/600x350.png?text=Add+Executive+Overview+Screenshot+Here) | ![Patient Demographics Dashboard](https://via.placeholder.com/600x350.png?text=Add+Patient+Demographics+Screenshot+Here) |

| **Page 3: Clinical & Operations** | **Data Model Architecture** |
| :---: | :---: |
| ![Clinical Operations Dashboard](https://via.placeholder.com/600x350.png?text=Add+Clinical+Operations+Screenshot+Here) | ![Power BI Star Schema](https://via.placeholder.com/600x350.png?text=Add+Power+BI+Model+Screenshot+Here) |

*(💡 **Tip:** Replace the placeholder links above with actual image URLs once committed to your repo!)*


┌─────────────────┐       ┌───────────────────────────┐       ┌───────────────────────────────┐       ┌───────────────────────────┐
│   Raw Synthea   │  ──►  │    Python ETL Pipeline    │  ──►  │    SQL Server Database        │  ──►  │     Power BI Desktop      │
│   (CSV Datasets)│       │  (Pandas + Chunked Batch) │       │ (HealthcareAnalytics_Numeric) │       │ (DAX & Interactive Report)│
└─────────────────┘       └───────────────────────────┘       └───────────────────────────────┘       └───────────────────────────┘

### 1. Data Ingestion & Batch Pipeline (`python/`)
* **Source:** Synthea™ open-source synthetic medical dataset (free of HIPAA/PII constraints).
* **Processing:** Handles complex type conversion, string truncation checks, and null values for large tables using `pandas` and `pyodbc`.
* **Performance Optimization:** Uses **chunked batching (50,000 rows/batch)** to safely load sub-million row tables directly into SQL Server without driver buffer overflows or memory bottlenecks.

### 2. SQL Server Relational Database (`sql/`)
Database: **`HealthcareAnalytics_Numeric`**

| Table Name | Record Count | Description |
| :--- | :---: | :--- |
| **`dbo.Procedures`** | `460,244` | Clinical procedures and interventions executed during visits |
| **`dbo.Claims`** | `310,474` | Financial billing records, primary/secondary claim statuses, and balances |
| **`dbo.Conditions`** | `102,851` | Patient medical diagnoses and active clinical conditions |
| **`dbo.Encounters`** | `37,289` | Patient hospital visits, stay durations, and encounters |
| **`dbo.Patients`** | `2,868` | Demographic profiles, location details, and birth dates |

---

## 🗄️ SQL Presentation Layer (Analytical Views)

Rather than connecting Power BI directly to high-volume transactional tables, **3 SQL Analytical Views** were constructed directly inside SQL Server. This reduces memory overhead in Power BI and centralizes business logic within the database.

```sql
-- View Architecture Overview
├── dbo.vw_ClaimsSummary             --> Formats billing statuses & calculates outstanding vs settled balances
├── dbo.vw_PatientOverview           --> Joins Patients + Encounters + Conditions into 1 row per patient with age groups
└── dbo.vw_DepartmentalPerformance  --> Aggregates monthly claim counts, unique patient counts, & outstanding balances


---

## 🏗️ Architecture & Data Pipeline Flow
