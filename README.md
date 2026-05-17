# 🍔 Swiggy Sales & Performance Analytics
### *Turning 197,000+ Food Orders into Boardroom-Ready Business Intelligence*

---

> **"Data is the new delivery driver — and this project makes sure every byte arrives on time."**

[![SQL Server](https://img.shields.io/badge/SQL%20Server-T--SQL-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/en-us/sql-server)
[![Star Schema](https://img.shields.io/badge/Architecture-Star%20Schema-FFD700?style=for-the-badge)](#-dimensional-modelling--star-schema)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-28a745?style=for-the-badge)](#)
[![Queries](https://img.shields.io/badge/Analytical%20Queries-18%2B-blue?style=for-the-badge)](#-kpis--deep-dive-analyses)

---

## 🚀 What Is This Project?

This is a **full-stack SQL analytics pipeline** built on Swiggy's food order dataset — covering everything from raw data ingestion to production-grade KPIs and strategic business recommendations.

The project doesn't just run queries. It **thinks like a business analyst** — every SQL block comes paired with:
- 🔍 The **business problem** being solved
- 💡 The **real-world impact** of the insight
- ✅ The **actionable answer** leadership can act on

---

## 📊 The Numbers Behind This Project

| Metric | Value |
|---|---|
| 🧾 Total Orders Analysed | **197,401** |
| 💰 Total Platform Revenue | **₹53.00 Million** |
| 🏙️ Cities Covered | Multi-city across India |
| 🗂️ Dimension Tables Built | **5** |
| 📈 KPIs Delivered | **4 Core + 14 Deep Dives** |
| 🎯 Final Business Recommendations | **3 High-Impact Insights** |

---

## 🏗️ Project Architecture

```
Raw Data (dbo.swiggy_data)
        │
        ▼
┌──────────────────────────┐
│  🧹 DATA CLEANING LAYER  │
│  • NULL Detection        │
│  • Duplicate Removal     │
│  • CTE-based Deduplication│
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────────────────────┐
│     ⭐ STAR SCHEMA (Dimensional Model)   │
│                                          │
│  dim_date ──────┐                        │
│  dim_location ──┤                        │
│  dim_restaurant─┼──► fact_orders (core) │
│  dim_category ──┤                        │
│  dim_dish ──────┘                        │
└──────────┬───────────────────────────────┘
           │
           ▼
┌──────────────────────────┐
│  📈 ANALYTICS LAYER      │
│  KPIs + Deep Dives       │
│  + Business Insights     │
└──────────────────────────┘
```

---

## ✨ Key Features That Make This Stand Out

### 🧹 1. Enterprise-Grade Data Validation
Before a single insight is generated, the data goes through a rigorous cleaning pipeline:
- **NULL audit** across all 10 critical columns — zero tolerance for missing data
- **Duplicate detection** using GROUP BY + HAVING COUNT(*) > 1
- **Safe deduplication** using CTE + ROW_NUMBER() — keeps exactly one clean record, deletes nothing more

### ⭐ 2. Production Star Schema Design
Not just flat table queries — this project builds a **proper dimensional model**:
- `dim_date` — full temporal breakdown (Year, Quarter, Month, Week, Day)
- `dim_location` — State → City → Location hierarchy
- `dim_restaurant` — restaurant master table
- `dim_category` — cuisine type dimension
- `dim_dish` — dish-level granularity
- `fact_orders` — central fact table with all FKs + measures (Price, Rating, Rating Count)

> BI tools like **Power BI** and **Tableau** are designed to work best with star schemas — this project is dashboard-ready out of the box.

### 📈 3. KPIs That Actually Matter
Four headline KPIs that any Swiggy executive would need on day one:

| KPI | Description |
|---|---|
| 📦 Total Orders | Platform volume baseline |
| 💵 Total Revenue (₹ Million) | Gross merchandise value |
| 🍽️ Average Dish Price | Typical customer spend per order |
| ⭐ Average Rating | Overall platform satisfaction score |

### 🔬 4. Deep Dive Across 4 Analytical Dimensions

**📅 Time-Based Analysis**
- Monthly order trends (seasonality detection)
- Quarterly revenue tracking
- Year-over-year growth measurement
- Week-of-year demand patterns

**📍 Location Intelligence**
- Top 10 cities by order volume
- State-level revenue contribution

**🍜 Food Performance**
- Top 10 restaurants by order volume
- Top 10 cuisine categories
- Most ordered dishes
- Cuisine orders + ratings combined (the dual-lens view!)

**💬 Customer Behaviour**
- Price range distribution (Below ₹100 → Above ₹500)
- Rating distribution (1 to 5 stars)
- Top 10 dishes by average rating (min. 100 reviews for statistical significance)
- Top 10 restaurants by average rating (min. 100 reviews)

---

## 🏆 The 3 Business Insights That Could Move the Needle

### 📍 Insight 1 — Double Down on High-Volume, High-Rating Cuisines
Cuisines that rank in the **top 5 for both order volume AND average rating** are the most powerful growth lever on the platform. Aggressively expanding restaurant supply in these categories in new cities drives faster adoption and stronger retention from day one.

### 📍 Insight 2 — Protect the ₹500+ Customer
The premium segment generates the **highest revenue per transaction** despite representing a smaller order share. A dedicated loyalty programme for this segment protects platform revenue even during slow-growth periods.

### 📍 Insight 3 — High Orders + Low Rating = Silent Churn Risk
Any cuisine appearing in the top 10 by order volume but carrying a **below-average rating** is a hidden retention bomb. Customers ordering these cuisines are being disappointed — immediately reducing the chance of a reorder. Minimum rating thresholds for high-demand categories should be enforced.

---

## 🛠️ Tech Stack

| Tool | Role |
|---|---|
| **Microsoft SQL Server** | Database engine |
| **T-SQL** | Query language |
| **CTE (Common Table Expressions)** | Deduplication & complex logic |
| **IDENTITY / FOREIGN KEYS** | Referential integrity in star schema |
| **FORMAT() + CONVERT()** | Business-readable output formatting |
| **ROW_NUMBER() OVER PARTITION** | Safe duplicate removal |

---

## 📁 Repository Structure

```
📦 swiggy-analytics/
 ┣ 📄 swiggy_analytics.sql    ← Full pipeline: cleaning → schema → KPIs → insights
 ┗ 📄 README.md               ← You are here
```

---

## ▶️ How to Run This

```sql
-- Step 1: Load your raw data into dbo.swiggy_data

-- Step 2: Run the Data Validation section (checks NULLs + duplicates)

-- Step 3: Run the Star Schema section (creates all dim tables + fact_orders)

-- Step 4: Run the KPI section (4 headline metrics)

-- Step 5: Run Deep Dive sections in any order — all queries are self-contained
```

> **Prerequisite:** Microsoft SQL Server (any modern version). All queries use standard T-SQL — no external dependencies required.

---

## 💡 What I Learned Building This

- How to design a **star schema from scratch** on a real-world messy dataset
- Writing SQL that doesn't just answer *what* — but explains *why it matters*
- The importance of **statistical significance** in ratings analysis (minimum threshold = 100 reviews)
- How dimensional modelling makes the same data **10x more useful** for BI tools

---

## 🤝 Connect With Me

If this project resonated with you or you're working on something similar, let's connect!

⭐ **Star this repo** if it helped you think about SQL analytics differently.

---

*Built with curiosity, caffeine, and a passion for turning raw data into real decisions.* 🚀
