🚀 Swiggy Data Analysis Project (SQL + Data Warehousing)
📌 Project Overview

This project focuses on end-to-end data analysis of Swiggy order data using SQL.
It covers data cleaning, transformation, data modeling (star schema), and business insights generation.

The goal is to simulate a real-world data analyst workflow — from raw data to actionable insights.

🧠 Problem Statement

Food delivery platforms generate massive transactional data.
This project answers key business questions like:

📈 When do orders peak?
🌍 Which cities and states generate maximum revenue?
🍽️ Which restaurants and categories perform best?
💰 What are customer spending patterns?
⚙️ Tech Stack
🗄️ SQL Server (T-SQL)
📊 Data Warehousing (Star Schema)
📈 Analytical Queries
🧹 Data Cleaning Techniques
📂 Dataset
Source: Swiggy-like dataset
Contains:
Location data (State, City, Area)
Order details
Restaurant & dish info
Price, Ratings, Rating Count
🧹 Data Cleaning & Validation

✔ Checked NULL values across all columns
✔ Identified blank/empty records
✔ Detected duplicate records
✔ Removed duplicates using ROW_NUMBER()

🏗️ Data Modeling (Star Schema)

Designed a scalable data warehouse structure:

⭐ Fact Table
fact_orders
Order metrics (Price, Rating, Count)
🌐 Dimension Tables
dim_date → Time-based analysis
dim_location → Geography insights
dim_restaurant → Restaurant performance
dim_category → Food categories
dim_dish → Dish-level analysis
🔄 ETL Process
Extracted raw data from swiggy_data
Transformed into structured format
Loaded into fact & dimension tables
Maintained referential integrity using foreign keys
📊 Key KPIs
📦 Total Orders
💰 Total Revenue
🍽️ Average Dish Price
⭐ Average Rating
📈 Business Insights
📅 Time-Based Analysis
Monthly order trends 📊
Quarterly performance 📈
Year-wise growth 📉
Peak order days (weekday analysis)
🌍 Location Analysis
🏙️ Top cities by order volume
💸 Top cities by revenue
🌎 State-wise revenue contribution
🍽️ Food Performance
🏆 Top restaurants by revenue
🍔 Top categories by orders
💰 Customer Spending Behavior

Orders categorized into buckets:

Under ₹100
₹100–199
₹200–299
₹300–499
₹500+

➡ Helps understand pricing strategy & customer affordability

🔥 Advanced Insights
Combined restaurant + location analysis
Identified top revenue-generating restaurants with geographic context
Enabled multi-dimensional slicing (time + location + category)
💡 Key Learnings
Real-world data cleaning challenges
Importance of data modeling (Star Schema)
Writing efficient analytical SQL queries
Translating data into business decisions
🧠 Why This Project Stands Out (Top 1% 🚀)

✔ Not just queries — complete data pipeline
✔ Includes data warehousing concepts
✔ Covers business-focused analysis
✔ Clean, structured, and scalable design
✔ Mimics industry-level analytics workflow

📌 Future Improvements
📊 Power BI / Tableau Dashboard
⚡ Query optimization (indexes)
🤖 Predictive analytics (ML models)
📡 Real-time data pipeline integration
🙌 Final Note

This project demonstrates how raw data can be transformed into powerful business insights using SQL.

“Data is not useful until it tells a story — this project tells that story.”
