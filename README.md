# 🏥 Healthcare Operations & Financial Analytics 

[![Power BI](https://img.shields.io/badge/Power%20BI-Analytics-F2C811?logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-Database-CC2927?logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/sql-server)
[![Power Query](https://img.shields.io/badge/Power%20Query-ETL-217346?logo=microsoft&logoColor=white)](https://learn.microsoft.com/power-query/)

> **An enterprise-grade analytics solution bridging the gap between raw clinical data and executive financial/operational decision-making.**

## 📖 Table of Contents
- [Executive Summary](#-executive-summary)
- [Enterprise Data Architecture](#-enterprise-data-architecture)
- [Data Pipeline & ETL](#️-phase-1-etl-pipeline--data-governance)
- [Database & SQL Presentation Layer](#-phase-2--3-relational-database--sql-presentation-layer)
- [Data Modeling & DAX](#-phase-4-business-intelligence--dimensional-modeling)
- [Dashboard Previews](#-dashboard-previews)
- [Repository Structure](#-repository-structure)
- [Getting Started (Setup)](#-getting-started)
- [Data Disclaimer](#-data-disclaimer)

---

## 📌 Executive Summary

This project demonstrates an end-to-end data architecture designed to track **North Star metrics** and core operational KPIs for healthcare administration. By utilizing Power Query for robust ETL, engineering a SQL presentation layer, and implementing strict dimensional modeling, this solution transforms over **900,000 highly nested medical records** into a high-performance, actionable Power BI executive dashboard. 

**Key Business Value Delivered:**
* **Revenue Cycle Tracking:** Visibility into unpaid balances, settlement rates, and departmental financial performance.
* **Operational Capacity Optimization:** Tracking length-of-stay (LOS) and departmental patient volumes to identify clinical bottlenecks.
* **Clinical Quality Monitoring:** Analyzing readmission and mortality rates across distinct demographic cohorts.

---

## 🏗️ Enterprise Data Architecture

```mermaid
flowchart LR
    %% Architecture Diagram
    A["📁 Raw Synthea CSVs<br/>(Synthetic Data)"] ==>|"Data Extraction & Cleaning"| B["⚡ Power Query<br/>(ETL Workflow)"]
    B ==>|"Load Base Tables"| C["🛢️ SQL Server Database<br/>(HealthcareAnalytics_Numeric)"]
    C ==>|"Business Logic & Aggregation"| D["👁️ SQL Analytical Views<br/>(Presentation Layer)"]
    D ==>|"Direct Import"| E["🌟 Power BI Semantic Model<br/>(Star Schema & DAX)"]
    
    style A fill:#161b22,stroke:#58a6ff,stroke-width:2px,color:#fff
    style B fill:#161b22,stroke:#217346,stroke-width:2px,color:#fff
    style C fill:#161b22,stroke:#cc2927,stroke-width:2px,color:#fff
    style D fill:#161b22,stroke:#d29922,stroke-width:2px,color:#fff
    style E fill:#161b22,stroke:#f2c811,stroke-width:2px,color:#fff
