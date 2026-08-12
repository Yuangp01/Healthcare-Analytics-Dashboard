# 🏥 Healthcare Analytics & Claims Executive Dashboard
> **An End-to-End Healthcare Data Engineering & Business Intelligence Pipeline**

![Python](https://img.shields.io/badge/Python-3.14-3776AB?style=for-the-badge&logo=python&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-CC292B?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Desktop-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Pandas](https://img.shields.io/badge/Pandas-ETL-150458?style=for-the-badge&logo=pandas&logoColor=white)

An end-to-end healthcare analytics solution designed to ingest raw transactional healthcare data, process and clean it via a **Python batching pipeline**, store it in a relational **SQL Server** database, model it using **custom SQL Analytical Views**, and deliver executive insights in **Power BI**.

---

## 📸 Executive Dashboard Preview




*(💡 **Tip:** Replace the placeholder links above with actual image URLs once committed to your repo!)*


<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 180" width="100%" height="100%">
  <defs>
    <style>
      .bg { fill: #0d1117; }
      .card { fill: #161b22; stroke: #30363d; stroke-width: 1.5; rx: 8; }
      .title { fill: #58a6ff; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-size: 14px; font-weight: 600; }
      .desc { fill: #8b949e; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-size: 12px; }
      .arrow { stroke: #58a6ff; stroke-width: 2; marker-end: url(#arrowhead); }
    </style>
    <marker id="arrowhead" markerWidth="8" markerHeight="8" refX="6" refY="4" orient="auto">
      <polygon points="0 0, 8 4, 0 8" fill="#58a6ff" />
    </marker>
  </defs>

  <!-- Background -->
  <rect width="1000" height="180" class="bg" rx="10"/>

  <!-- Step 1: Raw Data -->
  <g transform="translate(20, 30)">
    <rect width="200" height="120" class="card"/>
    <text x="100" y="45" text-anchor="middle" class="title">Raw Synthea Data</text>
    <text x="100" y="75" text-anchor="middle" class="desc">CSV Datasets</text>
    <text x="100" y="95" text-anchor="middle" class="desc">(Synthetic Health Data)</text>
  </g>

  <!-- Arrow 1 -->
  <line x1="230" y1="90" x2="260" y2="90" class="arrow"/>

  <!-- Step 2: Python ETL -->
  <g transform="translate(270, 30)">
    <rect width="210" height="120" class="card"/>
    <text x="105" y="45" text-anchor="middle" class="title">Python ETL Pipeline</text>
    <text x="105" y="75" text-anchor="middle" class="desc">Pandas Data Cleaning</text>
    <text x="105" y="95" text-anchor="middle" class="desc">&amp; Chunked PyODBC Batching</text>
  </g>

  <!-- Arrow 2 -->
  <line x1="490" y1="90" x2="520" y2="90" class="arrow"/>

  <!-- Step 3: SQL Server -->
  <g transform="translate(530, 30)">
    <rect width="210" height="120" class="card"/>
    <text x="105" y="45" text-anchor="middle" class="title">SQL Server Database</text>
    <text x="105" y="70" text-anchor="middle" class="desc">HealthcareAnalytics_Numeric</text>
    <text x="105" y="95" text-anchor="middle" class="desc">3 Analytical SQL Views</text>
  </g>

  <!-- Arrow 3 -->
  <line x1="750" y1="90" x2="780" y2="90" class="arrow"/>

  <!-- Step 4: Power BI -->
  <g transform="translate(790, 30)">
    <rect width="190" height="120" class="card"/>
    <text x="95" y="45" text-anchor="middle" class="title">Power BI Desktop</text>
    <text x="95" y="75" text-anchor="middle" class="desc">Star Schema &amp; DAX</text>
    <text x="95" y="95" text-anchor="middle" class="desc">Interactive Dashboard</text>
  </g>
</svg>


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
