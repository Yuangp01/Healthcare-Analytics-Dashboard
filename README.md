# 🏥 Healthcare Operations Data Analytics

[![Python](https://img.shields.io/badge/Python-Scripting-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-Database-CC2927?logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/sql-server)
[![Power Query](https://img.shields.io/badge/Power%20Query-ETL-217346?logo=microsoft&logoColor=white)](https://learn.microsoft.com/power-query/)
[![Power BI](https://img.shields.io/badge/Power%20BI-Analytics-F2C811?logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)
[![DAX](https://img.shields.io/badge/DAX-Data%20Modeling-blue)](https://learn.microsoft.com/dax/)

> **Transforming 900,000+ synthetic patient records into an executive dashboard that tracks clinical capacity and revenue cycle KPIs — built on a SQL Server presentation layer and a Power BI semantic model.**

**[▶ Live Dashboard](#)** &nbsp;&nbsp; **[📊 Sample Screenshots](#dashboard-preview)**

---

## 📌 Business Problem

Healthcare leaders sit on enormous volumes of clinical and financial data, but rarely have a single, governed source of truth to answer basic operational questions in real time. This project simulates the analytics function of a hospital system, built around the questions executives actually ask:

- Are patient admissions increasing or declining?
- What is the current readmission rate?
- How is mortality trending?
- Which departments generate the highest claim volume?
- Where are unpaid balances accumulating?
- How does utilization vary across patient demographics?
- What operational factors are associated with longer length of stay?

The solution bridges raw clinical data and executive decision-making by combining a **SQL Server presentation layer** with a **Power BI semantic model and KPI framework** — mirroring how analytics teams operate in real healthcare organizations.

---

## 🎯 Project Objective

Build a scalable analytics solution that defines and tracks **North Star metrics and core operational KPIs** across the full value chain:

**Patient Utilization → Clinical Operations → Revenue Cycle → Financial Performance**

---

## 🏗 Architecture

```mermaid
flowchart TB
    classDef raw fill:#161b22,stroke:#58a6ff,stroke-width:3px,color:#fff,font-size:16px,font-weight:bold
    classDef pq fill:#161b22,stroke:#217346,stroke-width:3px,color:#fff,font-size:16px,font-weight:bold
    classDef sql fill:#161b22,stroke:#cc2927,stroke-width:3px,color:#fff,font-size:16px,font-weight:bold
    classDef view fill:#161b22,stroke:#d29922,stroke-width:3px,color:#fff,font-size:16px,font-weight:bold
    classDef pbi fill:#161b22,stroke:#f2c811,stroke-width:3px,color:#fff,font-size:16px,font-weight:bold
    classDef dash fill:#161b22,stroke:#a371f7,stroke-width:3px,color:#fff,font-size:18px,font-weight:bold

    A["📁 Raw Synthea CSVs"]:::raw ==>|"Extract & Clean"| B["Power Query"]:::pq
    B ==>|"Load Base Tables"| C[("SQL Server Database<br/>(HealthcareAnalytics_Numeric)")]:::sql
    C ==>|"Financial Logic"| D1["dbo.vw_ClaimsSummary"]:::view
    C ==>|"Dimensional Flattening"| D2["dbo.vw_PatientOverview"]:::view
    C ==>|"Capacity Rollups"| D3["dbo.vw_DepartmentalPerformance"]:::view
    D1 ==>|"Import Mode"| E["Power BI Semantic Model<br/>(Star Schema & DAX Measures)"]:::pbi
    D2 ==> E
    D3 ==> E
    E ==> F["📈 Executive Dashboard"]:::dash

    linkStyle default stroke:#8b949e,stroke-width:3px,color:#c9d1d9,font-size:14px,font-weight:bold;
```

## 🗃 Data Source

This project uses **[Synthea](https://synthea.mitre.org/)**, an open-source synthetic patient generator developed by MITRE. All 900,000+ records are **artificially generated** — there is no real patient data (PHI) involved, which makes the dataset safe to publish and analyze publicly while still modeling realistic clinical and claims patterns (admissions, encounters, conditions, procedures, claims).

---

## 🧪 Methodology

1. **Extraction** — Raw Synthea CSVs (patients, encounters, conditions, procedures, claims) ingested via Power Query.
2. **Cleaning & Standardization** — Data typing, null handling, and date normalization performed in Python.
3. **Loading** — Cleaned tables loaded into SQL Server (`HealthcareAnalytics_Numeric`).
4. **Business Logic Layer** — T-SQL views built to encapsulate reusable logic: claims financials, patient-level rollups, and departmental capacity metrics.
5. **Modeling** — Star schema built in Power BI with fact/dimension separation; DAX measures written for KPIs.

---

## 📊 Key KPIs Tracked

| Category | Metrics |
|---|---|
| Patient Utilization | Admissions volume, admissions trend, demographic mix |
| Clinical Operations | Readmission rate, mortality rate, average length of stay |
| Revenue Cycle | Claim volume by department, unpaid balance / AR aging |
| Financial Performance | Revenue by payer, revenue by department |

---

## 💡 Key Findings

- **[Finding 1]** — e.g., "Readmission rates were X% higher in [department], driven primarily by [factor]."
- **[Finding 2]** — e.g., "Unpaid balances were concentrated in [payer/department], representing $X in outstanding AR."
- **[Finding 3]** — e.g., "Average length of stay increased X% among [demographic], correlating with [operational factor]."
- **[Recommendation]** — What would you tell a hospital COO to do based on this?

---

## 🖼 Dashboard Preview

```
![Executive Overview](assets/screenshots/executive-overview.png)
![Revenue Cycle View](assets/screenshots/revenue-cycle.png)
```

```

```

