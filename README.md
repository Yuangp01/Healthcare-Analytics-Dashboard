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



# 🏗️ Data Architecture



```mermaid

flowchart LR



    A[Raw Synthea CSVs] 

        --> B[Power Query<br/>Extraction & Cleaning]



    B --> C[(SQL Server<br/>HealthcareAnalytics_Numeric)]



    C --> D1[dbo.vw_ClaimsSummary]

    C --> D2[dbo.vw_PatientOverview]

    C --> D3[dbo.vw_DepartmentalPerformance]



    D1 --> E[Power BI<br/>Semantic Model]



    D2 --> E

    D3 --> E



    E --> F[Star Schema] (THIS IS WHAT CHATGPT SENT ME, I WANT MORE INFO TO BE ADDED) ALSO CHANGE THIS SECTION, A WANT THE BUTTONS ON THE PICTURE I WILL SEND YOU A BIT SMALLER: 

