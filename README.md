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

## 🏗️ Data Architecture & Engineering Pipeline

The architecture is built to cleanly separate data extraction, storage, business logic, and presentation. By utilizing **Power Query** for heavy data cleaning and pushing multi-table joins downstream into SQL Server, the Power BI semantic model remains highly optimized and lightweight.

```mermaid
flowchart LR
    %% Styling
    classDef raw fill:#161b22,stroke:#58a6ff,stroke-width:2px,color:#fff
    classDef pq fill:#161b22,stroke:#217346,stroke-width:2px,color:#fff
    classDef sql fill:#161b22,stroke:#cc2927,stroke-width:2px,color:#fff
    classDef view fill:#161b22,stroke:#d29922,stroke-width:2px,color:#fff
    classDef pbi fill:#161b22,stroke:#f2c811,stroke-width:2px,color:#fff

    subgraph Ingestion ["📥 Extraction & Transformation"]
        A["📁 Raw Synthea Data<br/>(CSV Exports)"]:::raw ==>|"Extract & Clean"| B["⚡ Power Query<br/>(Data Transformation & Type Casting)"]:::pq
    end

    subgraph Database ["🛢️ SQL Server Relational Database (900k+ Records)"]
        B ==>|"Load Base Tables"| C["💾 HealthcareAnalytics_Numeric<br/>(Procedures, Claims, Conditions, Encounters, Patients)"]:::sql
        C ==>|"Financial Logic"| D1["👁️ vw_ClaimsSummary<br/>(Status Normalization)"]:::view
        C ==>|"LEFT JOINs & Age Buckets"| D2["👁️ vw_PatientOverview<br/>(Dimensional Flattening)"]:::view
        C ==>|"GROUP BY Rollups"| D3["👁️ vw_DepartmentalPerformance<br/>(Capacity Aggregation)"]:::view
    end

    subgraph BI ["📊 Business Intelligence Layer"]
        D1 & D2 & D3 ==>|"Import Mode"| E["🌟 Power BI Semantic Model<br/>(Star Schema)"]:::pbi
        E ==>|"DAX Measures"| F["📈 Executive Dashboard<br/>(North Star Metrics & KPIs)"]:::pbi
    end
    F --> G[DAX Measures]
    G --> H[Executive Dashboard]
