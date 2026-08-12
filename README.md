# Healthcare Operations Data Analytics Platform  
**Enterprise-Grade Data Architecture • Dimensional Modeling • Power BI Healthcare Intelligence**

![Power BI](https://img.shields.io/badge/Power%20BI-Data%20Modeling-F2C811?logo=powerbi&logoColor=black)
![SQL Server](https://img.shields.io/badge/SQL%20Server-Analytics%20DB-CC2927?logo=microsoftsqlserver&logoColor=white)
![Power Query](https://img.shields.io/badge/Power%20Query-ETL%20Pipelines-217346?logo=microsoftexcel&logoColor=white)

---

## 🚀 Executive Summary  
This project demonstrates an **end‑to‑end healthcare analytics architecture** built to showcase enterprise engineering capabilities: scalable ETL, dimensional modeling, SQL analytical views, and Power BI semantic modeling aligned to **North Star operational metrics**.

All data originates from **Synthea**, MITRE’s open‑source synthetic patient generator.  
> **Disclaimer:** *100% of the data used in this project is synthetic and contains **zero** real PHI.*

---

## 🏗️ System Architecture  
A clean, modern flow of the full data lifecycle — from raw CSVs to BI-ready star schema.

```mermaid
flowchart LR
    A[Raw Synthea CSVs] --> B[Power Query<br/>Extraction & Cleaning]
    B --> C[SQL Server<br/>Base Tables]
    C --> D[SQL Analytical Views]
    D --> E[Power BI<br/>Semantic Model (Star Schema)]
