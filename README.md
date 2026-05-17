
# 🍽️ Swiggy Data Analytics — SQL Project

> End-to-end SQL project: data cleaning → dimensional modelling → KPI analysis on Swiggy food delivery data

![SQL Server](https://img.shields.io/badge/SQL_Server-T--SQL-blue) ![Star Schema](https://img.shields.io/badge/Schema-Star%20Schema-green) ![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## 📌 Project Overview

This project performs a full analytics pipeline on Swiggy food delivery order data using **Microsoft SQL Server**. It covers data validation, deduplication, dimensional modelling (star schema), KPI computation, and deep-dive analysis across time, geography, cuisine, and pricing — ready to plug into any BI tool (Power BI, Tableau, etc.).

---

## 📊 Key KPIs at a Glance

| KPI | Value |
|-----|-------|
| 🛵 Total Orders | *(run query to populate)* |
| 💰 Total Revenue | *(INR Millions — run query)* |
| 🍛 Avg Dish Price | *(INR — run query)* |
| ⭐ Avg Restaurant Rating | *(out of 5.00 — run query)* |

> Run the KPI section of `SQLQuery1.sql` against your dataset to get actual figures.

---

## 🗂️ Star Schema Design

```
                    ┌─────────────┐
                    │  dim_date   │
                    └──────┬──────┘
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────┴──────┐  ┌──────┴──────┐  ┌─────┴───────────┐
   │ dim_location│  │fact_orders  │  │ dim_restaurant  │
   └─────────────┘  │  (central)  │  └─────────────────┘
                    └──────┬──────┘
              ┌────────────┴────────────┐
       ┌──────┴──────┐        ┌─────────┴─────┐
       │ dim_category│        │   dim_dish    │
       └─────────────┘        └───────────────┘
```

**fact_orders** measures: `Price_INR`, `Rating`, `Rating_Count`

---

## 🔍 Analysis Modules

### 📅 Time-Based Trends
- Monthly order volume
- Quarterly revenue (INR Millions)
- Year-over-year order growth
- Week-of-year patterns

### 📍 Location Intelligence
- Top 10 cities by order volume
- State-level revenue contribution (Top 10)

### 🍽️ Food Performance
- Top 10 restaurants by order count
- Best cuisines by volume + average rating
- Most ordered dishes

### 💸 Customer Behaviour
- Orders by price band: Below ₹100 / ₹100–199 / ₹200–299 / ₹300–499 / ₹500+
- Rating distribution (Below 1 → 5)
- Top-rated dishes & restaurants (minimum 100 ratings)

---

## 🧹 Data Quality Steps

✅ **NULL check** — across all 10 critical columns (State, City, Order_Date, Restaurant_Name, Location, Category, Dish_Name, Price_INR, Rating, Rating_Count)

✅ **Duplicate detection** — GROUP BY all columns + `HAVING COUNT(*) > 1`

✅ **Deduplication** — `ROW_NUMBER()` CTE → `DELETE WHERE rn > 1`

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| Microsoft SQL Server | Database engine |
| T-SQL | Query language |
| CTEs (Common Table Expressions) | Deduplication logic |
| Window Functions (`ROW_NUMBER`) | Duplicate ranking |
| Star Schema | Dimensional modelling |
| `DATEPART` / `DATENAME` | Date dimension derivation |
| `FORMAT()` | KPI number formatting |

---

## 🚀 How to Run

1. Restore / import raw data into `dbo.swiggy_data`
2. Run **validation queries** (NULL check + duplicate scan)
3. Execute **deduplication CTE** to clean the data
4. Create **dimension + fact tables** (DDL section)
5. Populate dims and fact via `INSERT...SELECT`
6. Run **KPI + analysis queries**

---

## 📁 File Structure

```
📦 swiggy-sql-analytics
 ┣ 📄 SQLQuery1.sql    ← Full pipeline: clean → model → analyse
 ┗ 📄 README.md
```

---

## 🙌 Connect

If you find this useful, drop a ⭐ on the repo and feel free to fork and extend with your own BI dashboards!
