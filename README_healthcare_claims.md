# 💊 Healthcare Claims & Cost Analysis

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue) ![Tableau](https://img.shields.io/badge/Tool-Tableau-orange) ![Power BI](https://img.shields.io/badge/Tool-Power%20BI-yellow) ![Status](https://img.shields.io/badge/Status-Complete-green)

## 📌 Overview

This project analyzes **142,000+ healthcare insurance claims** to uncover cost trends, denial patterns, and billing anomalies across providers, procedures, and regions. The goal is to surface cost optimization opportunities and support data-driven decision-making for healthcare payers and administrators.

---

## 🎯 Objectives

- Calculate claim denial rates by provider type and claim category
- Identify the top procedures by average cost and claim volume
- Detect billing anomalies including duplicate claims, upcoding, and unbundling
- Build an interactive dashboard tracking key financial and operational KPIs

---

## 📊 Key Findings

- **Overall claim denial rate: 14.2%** — up 1.8% vs. prior year
- **Private Clinics** had the highest denial rate at **24.6%**
- **Cardiac Surgery** was the most expensive procedure at **$94,200 avg cost**
- **$18.7M in potential savings** flagged through anomaly detection:
  - $6.2M — duplicate billing
  - $4.8M — unbundling violations
  - $3.9M — upcoded procedures
  - $2.1M — outlier cost per claim
  - $1.7M — high-frequency same-day claims
- **Telehealth** had the lowest denial rate at just **4.2%**
- Average claim processing time: **18.3 days**

---

## 🗂️ Project Structure

```
healthcare-claims-cost-analysis/
│
├── healthcare_claims_queries.sql       # Full SQL pipeline (cleaning → analysis → anomaly detection)
├── healthcare_claims_dashboard.html    # Interactive dashboard (open in browser)
└── README.md
```

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|---|---|
| PostgreSQL / SQL | Data cleaning, KPI queries, anomaly detection |
| Tableau / Power BI | Interactive dashboard and visualizations |
| HCUP / Kaggle Dataset | Primary data source |
| Python / Pandas | Supplementary data preprocessing |

---

## 🔍 SQL Pipeline Breakdown

| Step | Description |
|---|---|
| 1 | Table creation — `claims` and `providers` |
| 2 | Data cleaning — nulls, duplicates, outliers, status standardization |
| 3 | Overall KPIs — avg cost, denial rate, processing days |
| 4 | Top 10 procedures by average cost |
| 5 | Denial rate by provider type |
| 6 | Monthly claim volume and cost trend |
| 7 | Regional cost breakdown |
| 8 | Anomaly detection — duplicate billing, upcoding, unbundling |
| 9 | Year-over-year denial rate comparison by provider |
| 10 | Summary view to feed Tableau / Power BI |

---

## 📈 Dashboard Features

- **5 KPI cards** — avg claim cost, denial rate, processing days, top procedure cost, flagged savings
- **Combo chart** — monthly claim volume (bars) + avg cost trend (line)
- **Doughnut chart** — claim distribution by type
- **Horizontal bar chart** — top 8 procedures by avg cost
- **Denial rate table** — by provider type with risk labels (High / Medium / Low)
- **Anomaly breakdown** — itemized cost savings flagged
- **Interactive filters** — by claim type, region, and fiscal year

---

## 📁 Dataset

**Sources:**
- HCUP (Healthcare Cost and Utilization Project) — [hcup-us.ahrq.gov](https://www.hcup-us.ahrq.gov)
- Kaggle Healthcare Insurance Dataset — [kaggle.com](https://www.kaggle.com/search?q=healthcare+insurance+claims)

Both are free and publicly available.

---

## 🚀 How to Run

1. Download the dataset from HCUP or Kaggle
2. Load into PostgreSQL or any SQL-compatible database
3. Run `healthcare_claims_queries.sql` step by step
4. Connect the summary view (`vw_claims_summary`) to Tableau or Power BI
5. Open `healthcare_claims_dashboard.html` in any browser for the interactive demo

---

## 👤 Author

**Joshua Giddirappa**
MS in Computer Science — University of Alabama at Birmingham
[LinkedIn](https://linkedin.com/in/joshua-giddirappa) | [GitHub](https://github.com/joshuagiddirappa)
