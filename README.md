# 🏥 Healthcare Operations Data Analytics

[![Power BI](https://img.shields.io/badge/Power%20BI-Analytics-F2C811?logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-Database-CC2927?logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/sql-server)
[![Power Query](https://img.shields.io/badge/Power%20Query-ETL-217346?logo=microsoft&logoColor=white)](https://learn.microsoft.com/power-query/)

> **Enterprise-style healthcare analytics solution designed to transform synthetic clinical and financial data into actionable operational intelligence.**

---

## 📌 Executive Summary

This project demonstrates an end-to-end **Healthcare Operations Analytics** workflow designed around the business questions healthcare leaders need to answer:

- Are patient admissions increasing or declining?
- What is the current readmission rate?
- How is mortality trending?
- Which departments generate the highest claim volume?
- Where are unpaid balances accumulating?
- How does utilization vary across patient demographics?
- What operational factors are associated with longer stays?

The solution bridges the gap between **raw clinical data and executive decision-making** by combining a SQL Server presentation layer with a Power BI semantic model and KPI framework.

### 🎯 Primary Objective

Build a scalable analytics solution that defines and tracks **North Star metrics and core operational KPIs** across:

**Patient Utilization → Clinical Operations → Revenue Cycle → Financial Performance**

---
```mermaid
flowchart TB
    %% Custom Styling for Large, Readable Text
    classDef raw fill:#161b22,stroke:#58a6ff,stroke-width:3px,color:#fff,font-size:16px,font-weight:bold
    classDef pq fill:#161b22,stroke:#217346,stroke-width:3px,color:#fff,font-size:16px,font-weight:bold
    classDef sql fill:#161b22,stroke:#cc2927,stroke-width:3px,color:#fff,font-size:16px,font-weight:bold
    classDef view fill:#161b22,stroke:#d29922,stroke-width:3px,color:#fff,font-size:16px,font-weight:bold
    classDef pbi fill:#161b22,stroke:#f2c811,stroke-width:3px,color:#fff,font-size:16px,font-weight:bold
    classDef dash fill:#161b22,stroke:#a371f7,stroke-width:3px,color:#fff,font-size:18px,font-weight:bold

    %% Nodes and Flow
    A["📁 Raw Synthea CSVs"]:::raw ==>|"Extract & Clean"| B["⚡ Power Query"]:::pq
    
    B ==>|"Load Base Tables"| C[("🛢️ SQL Server Database<br/>(HealthcareAnalytics_Numeric)")]:::sql
    
    C ==>|"Financial Logic"| D1["👁️ dbo.vw_ClaimsSummary"]:::view
    C ==>|"Dimensional Flattening"| D2["👁️ dbo.vw_PatientOverview"]:::view
    C ==>|"Capacity Rollups"| D3["👁️ dbo.vw_DepartmentalPerformance"]:::view
    
    D1 ==>|"Import Mode"| E["🌟 Power BI Semantic Model<br/>(Star Schema & DAX Measures)"]:::pbi
    D2 ==> E
    D3 ==> E
    
    E ==> F["📈 Executive Dashboard"]:::dash

    %% Link Styling
    linkStyle default stroke:#8b949e,stroke-width:3px,color:#c9d1d9,font-size:14px,font-weight:bold;
