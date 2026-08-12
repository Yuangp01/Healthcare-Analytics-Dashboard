# 🏥 Healthcare Analytics Pipeline & Executive Dashboard

![Python](https://img.shields.io/badge/Python-3.14-3776AB?style=for-the-badge&logo=python&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-CC292B?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Desktop-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)

An end-to-end data engineering and analytics pipeline processing **900,000+ medical records** from raw CSV exports into an optimized **SQL Server database**, featuring **custom analytical views** and an interactive **Power BI executive dashboard**.

---

## ⚡ Executive Summary

* **Scalable Data Ingestion:** Built a Python ETL pipeline using `pandas` and `pyodbc` to clean, type-cast, and load 900,000+ records.
* **Performance Optimization:** Implemented **50,000-row chunked batch loading** to eliminate database memory bottlenecks and driver crashes.
* **SQL Analytics Layer:** Shifted multi-table joins and age-group logic away from Power BI directly onto SQL Server via **3 pre-aggregated Views**.

---

## 🏗️ Architecture

```mermaid
flowchart LR
    A["📁 Raw Synthea CSVs"] --> B["🐍 Python ETL<br/><i>(Cleaning & 50k Batch Loading)</i>"]
    B --> C["🛢️ SQL Server<br/><i>(900k+ Records)</i>"]
    C --> D["👁️ SQL Analytical Views<br/><i>(Pre-aggregated Logic)</i>"]
    D --> E["📊 Power BI<br/><i>(Executive Dashboard)</i>"]
