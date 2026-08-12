# 🏥 Healthcare Analytics & Claims Executive Dashboard
> **End-to-End Healthcare Data Engineering & Business Intelligence Pipeline**

![Python](https://img.shields.io/badge/Python-3.14-3776AB?style=for-the-badge&logo=python&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-CC292B?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Desktop-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Pandas](https://img.shields.io/badge/Pandas-ETL-150458?style=for-the-badge&logo=pandas&logoColor=white)

An enterprise-grade healthcare analytics solution processing raw transactional medical data through a **Python batching ETL pipeline**, storing it in **SQL Server**, transforming it via **custom SQL Views**, and rendering interactive insights in **Power BI**.

---

## ⚡ Key Project Highlights (For Recruiters)
* **913K+ Total Records Ingested:** Built a robust Python ETL pipeline using `pandas` and `pyodbc` to clean, type-cast, and batch-load 900,000+ rows into SQL Server.
* **Batch Loading Optimization:** Solved driver memory limits by executing chunked insertion batches of **50,000 rows/batch**.
* **High-Performance SQL Layer:** Engineered **3 dedicated SQL Views** to handle multi-table joins (`LEFT JOIN`), age bucketing (`DATEDIFF`), and financial aggregations inside SQL Server rather than overloading Power BI.

---

## 📸 Executive Dashboard Preview

| **Executive Overview** | **Patient Demographics** |
| :---: | :---: |
| ![Executive Overview](https://via.placeholder.com/600x350.png?text=Add+Executive+Overview+Screenshot) | ![Patient Demographics](https://via.placeholder.com/600x350.png?text=Add+Demographics+Screenshot) |

---

## 🏗️ Architecture & System Flow

```mermaid
flowchart LR
    A["📁 Raw Synthea Data<br/><b>(CSV Exports)</b>"] ==>|"Extract & Clean"| B["🐍 Python ETL Pipeline<br/><b>(Pandas + PyODBC Batching)</b>"]
    B ==>|"Chunked Insert<br/>(50k rows/batch)"| C["🛢️ SQL Server Database<br/><b>(HealthcareAnalytics_Numeric)</b>"]
    C ==>|"Business Logic<br/>& Joins"| D["👁️ SQL Analytical Views<br/><b>(vw_Claims, vw_Patient, vw_Dept)</b>"]
    D ==>|"Direct Import"| E["📊 Power BI Dashboard<br/><b>(Star Schema & DAX)</b>"]

    style A fill:#161b22,stroke:#58a6ff,stroke-width:2px,color:#ffffff
    style B fill:#161b22,stroke:#3fb950,stroke-width:2px,color:#ffffff
    style C fill:#161b22,stroke:#f85149,stroke-width:2px,color:#ffffff
    style D fill:#161b22,stroke:#d29922,stroke-width:2px,color:#ffffff
    style E fill:#161b22,stroke:#a371f7,stroke-width:2px,color:#ffffff
