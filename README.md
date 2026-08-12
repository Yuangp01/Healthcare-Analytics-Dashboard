# 🏥 Healthcare Operations & Financial Analytics: Executive Dashboard
> **An End-to-End Analytics Pipeline & Dimensional Data Model**

![Python](https://img.shields.io/badge/Python-3.14-3776AB?style=for-the-badge&logo=python&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-CC292B?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Desktop-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Pandas](https://img.shields.io/badge/Pandas-ETL-150458?style=for-the-badge&logo=pandas&logoColor=white)

An enterprise-grade healthcare analytics solution designed to process raw transactional medical records into actionable executive insights. This project demonstrates a complete data engineering and business intelligence workflow: ingesting 900,000+ records via a Python ETL pipeline, modeling the data in a SQL Server relational database, engineering a high-performance SQL presentation layer, and delivering interactive reporting through Power BI.

---

## 🔬 Senior Data Analyst Perspective: Project Overview

From an analytical standpoint, raw healthcare claims and encounter data are inherently complex, nested, and prone to anomalies. The core objective of this project was not just to visualize data, but to establish a trusted, single source of truth for **healthcare operations and revenue cycle management**.

By decoupling the data transformation logic from the visualization layer, this architecture ensures high data integrity, scalable query performance, and strict dimensional modeling standards. 

### 🎯 North Star Metrics & Core KPIs
The dashboard is anchored around key performance indicators designed to give hospital administrators immediate visibility into operational bottlenecks and financial health:
* **Revenue Cycle North Star:** Total Outstanding Balance & Claim Settlement Rate (tracking the efficiency of the billing department).
* **Operational Capacity:** Patient Encounters per Department & Length of Stay (LOS) distributions.
* **Clinical Demographics:** Case mix by clinical category, active condition prevalence, and demographic utilization rates.

---

## 🏗️ Architecture & System Flow

```mermaid
flowchart LR
    A["📁 Raw Synthea Data<br/><b>(CSV Exports)</b>"] ==>|"Extract, Profile & Clean"| B["🐍 Python ETL Pipeline<br/><b>(Pandas + PyODBC)</b>"]
    B ==>|"Chunked Insert<br/>(50k rows/batch)"| C["🛢️ SQL Server Database<br/><b>(HealthcareAnalytics_Numeric)</b>"]
    C ==>|"Business Logic<br/>& Multi-table Joins"| D["👁️ SQL Presentation Layer<br/><b>(Analytical Views)</b>"]
    D ==>|"Direct Import<br/>via Power Query"| E["📊 Power BI Dashboard<br/><b>(Star Schema & DAX)</b>"]

    style A fill:#161b22,stroke:#58a6ff,stroke-width:2px,color:#ffffff
    style B fill:#161b22,stroke:#3fb950,stroke-width:2px,color:#ffffff
    style C fill:#161b22,stroke:#f85149,stroke-width:2px,color:#ffffff
    style D fill:#161b22,stroke:#d29922,stroke-width:2px,color:#ffffff
    style E fill:#161b22,stroke:#a371f7,stroke-width:2px,color:#ffffff
