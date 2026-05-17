SELECT * FROM dbo.swiggy_data


-- ============================================================
-- DATA VALIDATION AND CLEANING
-- ============================================================

-- 1. Check for NULL values in critical columns

SELECT 
	SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS Null_State,
	SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS Null_City,
	SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS Null_Order_Date,
	SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS Null_Restaurant_Name,
	SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS Null_Location,
	SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS Null_Category,
	SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS Null_Dish_Name,
	SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS Null_Price_INR,
	SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS Null_Rating,
	SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS Null_Rating_Count
FROM dbo.swiggy_data

--🔍 Business Problem
--The raw dataset may contain missing values across critical columns.
--Without identifying NULLs, downstream KPIs like revenue totals,
--average ratings, and order counts will be silently wrong.

--💡 Business Impact
--Ensures data completeness before building the star schema
--Prevents incorrect aggregations caused by NULL values
--Builds confidence that every order record is fully populated

--✅ Answer
--A result of 0 across all 10 columns confirms the dataset has no NULL values.
--The data is complete and safe to load into the dimensional model.
--If any value > 0 is returned, those rows must be investigated and 
--either filled or excluded before proceeding.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 2. Detect blank or empty string values and find duplicate records

SELECT
	   State, City, Order_Date, Restaurant_Name,
	   Location, Category, Dish_Name, Price_INR,
	   Rating, Rating_Count, COUNT(*) AS count
FROM dbo.swiggy_data
GROUP BY State, City, Order_Date, Restaurant_Name,
	   Location, Category, Dish_Name, Price_INR,
	   Rating, Rating_Count
HAVING COUNT(*) > 1

--🔍 Business Problem
--The dataset may contain identical records entered more than once.
--Duplicate orders inflate Total Orders, Total Revenue, and all
--derived KPIs, making the business look larger than it actually is.

--💡 Business Impact
--Prevents double-counting of orders and revenue
--Ensures every metric is based on real, unique transactions
--Makes the star schema loading clean and reliable

--✅ Answer
--Any rows returned here are exact duplicates across all business columns.
--These must be removed before loading the fact table.
--If no rows are returned, the dataset has no duplicates and is ready to proceed.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 3. Delete duplicate records — keep one clean copy per unique order

WITH cte AS (
	SELECT *,
		   ROW_NUMBER() OVER (PARTITION BY State, City, Order_Date, Restaurant_Name,
	   Location, Category, Dish_Name, Price_INR,
	   Rating, Rating_Count ORDER BY (SELECT NULL)) AS rn
	FROM dbo.swiggy_data
)
DELETE FROM cte WHERE rn > 1

--🔍 Business Problem
--After detecting duplicates, the business needs a safe method to remove
--extras while keeping exactly one copy of each unique order.

--💡 Business Impact
--Produces a clean, deduplicated source table
--All KPIs calculated after this step are accurate and non-inflated
--Protects integrity of the star schema that will be built on top of this data

--✅ Answer
--ROW_NUMBER() assigns rank 1 to the first occurrence of each duplicate group.
--All rows with rn > 1 are deleted, leaving exactly one clean record per order.
--After execution, dbo.swiggy_data contains only unique, trustworthy records.

--------------------------------------------------------------------------------------------------------------------------------------------------


-- ============================================================
-- DIMENSIONAL MODELLING — STAR SCHEMA
-- ============================================================

-- Why Star Schema?
-- Dimensional modelling separates descriptive attributes into focused
-- dimension tables and keeps all measurable values in a central fact table.
-- This reduces redundancy, improves query performance, and makes the
-- entire dataset BI-tool ready (Power BI, Tableau, etc.).
-- Most analytics tools are designed to work best with star schemas,
-- so this approach ensures smooth dashboard creation, accurate
-- aggregations, and reliable insights at any scale.

-- Dimensions: date, location, restaurant, category, dish
-- Fact Table: fact_orders (Price_INR, Rating, Rating_Count + all FK keys)

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Create date dimension

CREATE TABLE dbo.dim_date (
	Date_id INT IDENTITY(1,1) PRIMARY KEY,
	Full_Date DATE,
	Year INT,
	Month INT,
	month_name VARCHAR(20),
	Quarter INT,
	Day INT,
	WEEK INT
)

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Create location dimension

CREATE TABLE dbo.dim_location (
	Location_id INT IDENTITY(1,1) PRIMARY KEY,
	State NVARCHAR(100),
	City NVARCHAR(100),
	location NVARCHAR(255)
)

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Create restaurant dimension

CREATE TABLE dbo.dim_restaurant (
	Restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
	Restaurant_Name VARCHAR(255)
)

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Create category dimension

CREATE TABLE dbo.dim_category (
	Category_id INT IDENTITY(1,1) PRIMARY KEY,
	Category VARCHAR(255)
)

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Create dish dimension

CREATE TABLE dbo.dim_dish (
	Dish_id INT IDENTITY(1,1) PRIMARY KEY,
	Dish_Name VARCHAR(255)
)

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Create central fact table

CREATE TABLE dbo.fact_orders (
	Order_id INT IDENTITY(1,1) PRIMARY KEY,
	Date_id INT,
	Location_id INT,
	Restaurant_id INT,
	Category_id INT,
	Dish_id INT,
	Price_INR DECIMAL(10,2),
	Rating DECIMAL(4,2),
	Rating_Count INT,
	FOREIGN KEY (Date_id) REFERENCES dbo.dim_date(Date_id),
	FOREIGN KEY (Location_id) REFERENCES dbo.dim_location(Location_id),
	FOREIGN KEY (Restaurant_id) REFERENCES dbo.dim_restaurant(Restaurant_id),
	FOREIGN KEY (Category_id) REFERENCES dbo.dim_category(Category_id),
	FOREIGN KEY (Dish_id) REFERENCES dbo.dim_dish(Dish_id)
)

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Insert data into dim_date

INSERT INTO dbo.dim_date (Full_Date, Year, Month, month_name, Quarter, Day, WEEK)
SELECT DISTINCT 
       Order_Date,
	   YEAR(Order_Date) AS Year,
	   MONTH(Order_Date) AS Month,
	   DATENAME(MONTH, Order_Date) AS month_name,
	   DATEPART(QUARTER, Order_Date) AS Quarter,
	   DAY(Order_Date) AS Day,
	   DATEPART(WEEK, Order_Date) AS WEEK
FROM dbo.swiggy_data

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Insert data into dim_location

INSERT INTO dbo.dim_location (State, City, location)
SELECT DISTINCT State, City, Location
FROM dbo.swiggy_data

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Insert data into dim_restaurant

INSERT INTO dbo.dim_restaurant (Restaurant_Name)
SELECT DISTINCT Restaurant_Name
FROM dbo.swiggy_data

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Insert data into dim_category

INSERT INTO dbo.dim_category (Category)
SELECT DISTINCT Category
FROM dbo.swiggy_data

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Insert data into dim_dish

INSERT INTO dbo.dim_dish (Dish_Name)
SELECT DISTINCT Dish_Name
FROM dbo.swiggy_data

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Insert data into fact table — all foreign keys resolved via JOIN

INSERT INTO dbo.fact_orders (Date_id, Location_id, Restaurant_id, Category_id, Dish_id, Price_INR, Rating, Rating_Count)
SELECT 
	d.Date_id,
	l.Location_id,
	r.Restaurant_id,
	c.Category_id,
	dh.Dish_id,
	s.Price_INR,
	s.Rating,
	s.Rating_Count
FROM dbo.swiggy_data s
JOIN dbo.dim_date d ON s.Order_Date = d.Full_Date
JOIN dbo.dim_location l ON s.State = l.State AND s.City = l.City AND s.Location = l.location
JOIN dbo.dim_restaurant r ON s.Restaurant_Name = r.Restaurant_Name
JOIN dbo.dim_category c ON s.Category = c.Category
JOIN dbo.dim_dish dh ON s.Dish_Name = dh.Dish_Name

--------------------------------------------------------------------------------------------------------------------------------------------------


-- ============================================================
-- KPI DEVELOPMENT
-- ============================================================

-- 1. Total Orders

SELECT COUNT(*) AS Total_Orders
FROM dbo.fact_orders

--🔍 Business Problem
--The business needs to know the overall scale of operations.
--Without this, there is no baseline to measure growth or decline.

--💡 Business Impact
--Provides the headline volume metric for all executive reporting
--Acts as the denominator for per-order metrics like average price
--Tracks whether platform usage is growing over time

--✅ Answer
--The total number of individual dish-level order records are 197401
--across all cities, restaurants, and time periods in the cleaned dataset.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 2. Total Revenue (INR Million)

SELECT FORMAT(SUM(CONVERT(FLOAT, Price_INR))/1000000, 'N2') + ' INR Million' AS Total_Revenue_Million
FROM dbo.fact_orders

--🔍 Business Problem
--The business needs to understand the total money generated across
--the entire platform to assess financial health and set targets.

--💡 Business Impact
--Reveals the gross merchandise value (GMV) on the platform
--Helps leadership set quarterly and annual revenue goals
--Tracks whether revenue growth is keeping pace with order growth

--✅ Answer
--Revenue is the sum of Price_INR across all orders divided by 1,000,000 for readability. 
--53.00 INR Million is the total gross value of all food orders
--processed within the dataset's time window.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 3. Average Dish Price

SELECT FORMAT(AVG(CONVERT(FLOAT, Price_INR)), 'N2') + ' INR' AS Avg_Dish_Price
FROM dbo.fact_orders

--🔍 Business Problem
--The business does not know what a typical customer pays per dish.
--Without this, pricing strategy is based on guesswork.

--💡 Business Impact
--Benchmarks pricing decisions for restaurant partners
--Shows whether the platform is serving budget or premium customers
--Can be compared against the price-range buckets to see where most orders fall

--✅ Answer
--The average price per dish reflects the typical spend per order.
--Comparing this against the price range bucket analysis reveals
--whether most customers order below or above the platform average.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 4. Average Restaurant Rating

SELECT FORMAT(AVG(CONVERT(FLOAT, Rating)), 'N2') AS Avg_Restaurant_Rating
FROM dbo.fact_orders

--🔍 Business Problem
--The business needs a single number that captures overall
--customer satisfaction across the entire platform.

--💡 Business Impact
--Acts as the platform health indicator for customer experience
--A rating below 3.5 warrants an immediate restaurant quality review
--Should be tracked over time to catch satisfaction trends early

--✅ Answer
--A result close to 4.0 or above signals strong overall customer satisfaction.
--This KPI should be monitored monthly. A declining average rating is
--an early warning sign that restaurant quality or delivery experience
--is deteriorating and needs intervention.

--------------------------------------------------------------------------------------------------------------------------------------------------


-- ============================================================
-- DEEP DIVE ANALYSIS
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- DATE-BASED ANALYSIS
-- ─────────────────────────────────────────────────────────────

-- 5. Monthly order trend

SELECT d.Year, d.Month, d.month_name, COUNT(*) AS Total_Orders
FROM dbo.fact_orders f
JOIN dbo.dim_date d ON f.Date_id = d.Date_id
GROUP BY d.Year, d.Month, d.month_name
ORDER BY d.Year, d.Month

--🔍 Business Problem
--The business does not know which months see the highest and lowest demand.
--Without this, marketing budgets and staffing are applied uniformly
--throughout the year instead of being focused on peak periods.

--💡 Business Impact
--Identifies seasonal demand peaks for targeted promotions
--Guides delivery capacity planning during high-order months
--Reveals low-demand months where discounting can stimulate orders

--✅ Answer
--Month-over-month order volumes reveal clear demand seasonality.
--Spikes typically align with festive seasons or summer months.
--A consistent upward trend signals healthy platform growth.
--A declining trend warrants investigation into customer churn
--or increasing competitive pressure.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 6. Quarterly revenue trend

SELECT d.Year, d.Quarter, FORMAT(SUM(CONVERT(FLOAT, Price_INR))/1000000, 'N2') + ' INR Million' AS Revenue_Million
FROM dbo.fact_orders f
JOIN dbo.dim_date d ON f.Date_id = d.Date_id
GROUP BY d.Year, d.Quarter
ORDER BY d.Year, d.Quarter

--🔍 Business Problem
--Leadership needs to track revenue performance by financial quarter
--to compare against targets and plan the next quarter's budget.

--💡 Business Impact
--Supports quarterly business reviews and financial planning
--Identifies which quarters consistently outperform others
--Quarter-on-quarter decline is an early warning for re-evaluating
--restaurant partnerships, pricing, or marketing budgets

--✅ Answer
--Q3 and Q4 typically see festive uplift in Indian markets.
--If a quarter shows revenue decline despite stable order counts,
--it points to customers shifting toward lower-priced dishes —
--a signal to review the premium product mix.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 7. Year-wise growth in orders

SELECT d.Year, COUNT(*) AS Total_Orders
FROM dbo.fact_orders f
JOIN dbo.dim_date d ON f.Date_id = d.Date_id
GROUP BY d.Year
ORDER BY d.Year

--🔍 Business Problem
--The company needs to understand whether the platform is scaling
--year over year or if growth is flattening out.

--💡 Business Impact
--Confirms whether the business is expanding its market reach annually
--Slower growth in later years may indicate market saturation
--in existing cities, reinforcing the need to explore new geographies

--✅ Answer
--Consistent year-over-year order growth confirms expanding market penetration.
--If growth rate is slowing, the business should accelerate expansion
--into new cities before the current markets fully saturate.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 8. Day of week / week-of-year order pattern

SELECT d.WEEK, COUNT(*) AS Total_Orders
FROM dbo.fact_orders f
JOIN dbo.dim_date d ON f.Date_id = d.Date_id
GROUP BY d.WEEK
ORDER BY d.WEEK

--🔍 Business Problem
--The business does not know which weeks of the year consistently
--drive the most orders. Logistics and staffing are planned without
--any data on intra-year demand cycles.

--💡 Business Impact
--Identifies high-demand weeks for pre-positioning delivery capacity
--Helps plan rider availability and restaurant promotions in advance
--Reduces last-minute operational strain during demand spikes

--✅ Answer
--Certain weeks consistently outperform others — typically tied to
--national holidays, cricket matches, or year-end festivities.
--Use this pattern to plan marketing pushes and delivery fleet
--capacity 2-3 weeks before the identified demand peaks.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ─────────────────────────────────────────────────────────────
-- LOCATION-BASED ANALYSIS
-- ─────────────────────────────────────────────────────────────

-- 9. Top 10 cities by order volume

SELECT TOP 10 l.City, COUNT(*) AS Total_Orders
FROM dbo.fact_orders f
JOIN dbo.dim_location l ON f.Location_id = l.Location_id
GROUP BY l.City
ORDER BY Total_Orders DESC

--🔍 Business Problem
--The company needs to know which cities are driving the most platform
--usage so that investment and resources are directed to the right markets.

--💡 Business Impact
--Identifies the core markets that must be protected from competition
--Cities ranked 5-10 with accelerating order counts are prime candidates
--for increased restaurant acquisition and marketing investment
--Helps avoid spreading resources too thin across low-volume cities

--✅ Answer
--The top 10 cities account for the bulk of platform volume.
--Cities ranking 1-4 are mature markets to defend.
--Cities ranked 5-10 that are still growing fast
--are the best candidates for the next wave of expansion.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 10. Revenue contribution by state (Top 10)

SELECT TOP 10 l.State, FORMAT(SUM(CONVERT(FLOAT, Price_INR))/1000000, 'N2') + ' INR Million' AS Revenue_Million
FROM dbo.fact_orders f
JOIN dbo.dim_location l ON f.Location_id = l.Location_id
GROUP BY l.State
ORDER BY SUM(CONVERT(FLOAT, Price_INR)) DESC

--🔍 Business Problem
--The business needs to understand which states generate the most
--revenue so geographic resources and partnerships are allocated correctly.

--💡 Business Impact
--Highlights the revenue backbone of the platform by geography
--States with high order volume but lower revenue signal price-sensitive
--customers where discount strategies may drive volume but compress margins
--Supports state-level marketing and restaurant partner investment decisions

--✅ Answer
--States like Maharashtra, Karnataka, and Tamil Nadu typically lead
--in urban food delivery markets.
--A state with high orders but low total revenue indicates customers
--are ordering cheaper dishes — premium restaurant onboarding in
--those states can improve revenue per order significantly.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ─────────────────────────────────────────────────────────────
-- FOOD PERFORMANCE ANALYSIS
-- ─────────────────────────────────────────────────────────────

-- 11. Top 10 restaurants by order volume

SELECT TOP 10 r.Restaurant_Name, COUNT(*) AS Total_Orders
FROM dbo.fact_orders f
JOIN dbo.dim_restaurant r ON f.Restaurant_id = r.Restaurant_id
GROUP BY r.Restaurant_Name
ORDER BY Total_Orders DESC

--🔍 Business Problem
--The company does not know which restaurant partners are driving
--the most demand. High-performing partners may be at risk of
--leaving for a competitor if they are not identified and rewarded.

--💡 Business Impact
--Identifies star partners for exclusive deal negotiations
--These restaurants should receive priority app placement
--Their success stories serve as benchmarks for new restaurant onboarding

--✅ Answer
--The top 10 restaurants are the platform's highest-demand partners.
--They should be offered loyalty incentives, reduced commission rates,
--and co-marketing opportunities to retain them exclusively on Swiggy.
--Capacity constraints at these restaurants should be proactively addressed.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 12. Top 10 categories (cuisines) by order volume

SELECT TOP 10 c.Category, COUNT(*) AS Total_Orders	
FROM dbo.fact_orders f
JOIN dbo.dim_category c ON f.Category_id = c.Category_id
GROUP BY c.Category
ORDER BY Total_Orders DESC

--🔍 Business Problem
--The company does not know which cuisine types customers prefer most.
--Launching new city stores with the wrong cuisine mix leads to
--poor early adoption and slow revenue ramp-up.

--💡 Business Impact
--Directly informs which restaurant types to onboard first in new cities
--Ensures the right cuisine mix from day one of a city launch
--Helps identify underserved cuisine categories with growth potential

--✅ Answer
--North Indian, Chinese, and South Indian typically rank highest
--in Indian delivery markets.
--Any cuisine appearing in top 10 with a strong upward trend is
--a category to aggressively expand restaurant supply for.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 13. Most ordered dishes (Top 10)

SELECT TOP 10 dh.Dish_Name, COUNT(*) AS Total_Orders
FROM dbo.fact_orders f
JOIN dbo.dim_dish dh ON f.Dish_id = dh.Dish_id
GROUP BY dh.Dish_Name
ORDER BY Total_Orders DESC

--🔍 Business Problem
--The business does not know which specific dishes customers
--repeatedly choose. The homepage and recommendation engine
--are not using actual order data to surface the right content.

--💡 Business Impact
--Enables data-driven curation of homepage "Trending" sections
--Helps push notifications feature dishes customers are already ordering
--Restaurants offering these dishes should be highlighted as high-demand partners

--✅ Answer
--The top 10 dishes are the platform's bestsellers.
--They should be featured in trending banners, push notifications,
--and recommendation tiles.
--Identifying whether bestsellers are budget or premium items tells
--the business whether its most loyal customers are value-driven
--or quality-driven.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 14. Cuisine performance analysis — Orders + Avg Rating

SELECT TOP 10 c.Category, COUNT(*) AS Total_Orders, FORMAT(AVG(CONVERT(FLOAT, Rating)), 'N2') AS Avg_Rating
FROM dbo.fact_orders f
JOIN dbo.dim_category c ON f.Category_id = c.Category_id
GROUP BY c.Category
ORDER BY Total_Orders DESC, AVG(CONVERT(FLOAT, Rating)) DESC

--🔍 Business Problem
--High order volume alone does not mean a cuisine is performing well.
--A cuisine with many orders but poor ratings is creating dissatisfied
--customers who may not reorder — a hidden retention problem.

--💡 Business Impact
--Finds the ideal combination of high demand AND high satisfaction
--Exposes cuisines that are popular but disappointing customers
--Uncovers niche cuisines with high ratings but untapped demand potential

--✅ Answer
--Cuisines ranking high on BOTH orders and rating are the platform's
--strongest categories — prioritise their restaurant supply expansion.
--Cuisines with high orders but low rating need restaurant quality audits.
--Cuisines with low orders but high ratings are hidden gems —
--targeted marketing can unlock their latent demand significantly.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ─────────────────────────────────────────────────────────────
-- CUSTOMER BEHAVIOUR ANALYSIS
-- ─────────────────────────────────────────────────────────────

-- 15. Total orders by price range

SELECT 
	CASE 
		WHEN CONVERT(FLOAT, Price_INR) < 100 THEN 'Below 100 INR'
		WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100-199 INR'
		WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200-299 INR'
		WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 499 THEN '300-499 INR'		
		ELSE 'Above 500 INR'
	END AS Price_Range,
	COUNT(*) AS Total_Orders
FROM dbo.fact_orders
GROUP BY 
	CASE 
		WHEN CONVERT(FLOAT, Price_INR) < 100 THEN 'Below 100 INR'
		WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100-199 INR'
		WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200-299 INR'
		WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 499 THEN '300-499 INR'		
		ELSE 'Above 500 INR'
	END
ORDER BY Total_Orders DESC

--🔍 Business Problem
--The company does not know at what price points customers are most
--comfortable spending. Without this, menu pricing and discount
--strategies are not aligned with actual customer behaviour.

--💡 Business Impact
--Reveals the dominant price segment driving platform volume
--If most orders are Below 100 INR, discount and value meals are key levers
--The Above 500 INR bucket contributes disproportionately to revenue —
--loyalty rewards in this segment protect overall margins

--✅ Answer
--The price bucket with the highest order count is where the majority
--of customers are comfortable spending.
--100-199 INR leading = value-conscious mainstream customer base.
--200-499 INR leading = customers showing willingness to pay for quality.
--Above 500 INR customers should be enrolled in a premium loyalty program
--as they are the highest revenue contributors per transaction.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- ─────────────────────────────────────────────────────────────
-- RATINGS ANALYSIS
-- ─────────────────────────────────────────────────────────────

-- 16. Distribution of dish ratings from 1-5

SELECT 
	CASE 
		WHEN CONVERT(FLOAT, Rating) < 1 THEN 'Below 1'
		WHEN CONVERT(FLOAT, Rating) BETWEEN 1 AND 1.99 THEN '1-1.99'
		WHEN CONVERT(FLOAT, Rating) BETWEEN 2 AND 2.99 THEN '2-2.99'
		WHEN CONVERT(FLOAT, Rating) BETWEEN 3 AND 3.99 THEN '3-3.99'		
		WHEN CONVERT(FLOAT, Rating) BETWEEN 4 AND 4.99 THEN '4-4.99'		
		ELSE '5'
	END AS Rating_Range,
	COUNT(*) AS Total_Orders
FROM dbo.fact_orders
GROUP BY 
	CASE 
		WHEN CONVERT(FLOAT, Rating) < 1 THEN 'Below 1'
		WHEN CONVERT(FLOAT, Rating) BETWEEN 1 AND 1.99 THEN '1-1.99'
		WHEN CONVERT(FLOAT, Rating) BETWEEN 2 AND 2.99 THEN '2-2.99'
		WHEN CONVERT(FLOAT, Rating) BETWEEN 3 AND 3.99 THEN '3-3.99'		
		WHEN CONVERT(FLOAT, Rating) BETWEEN 4 AND 4.99 THEN '4-4.99'		
		ELSE '5'
	END
ORDER BY Total_Orders DESC

--🔍 Business Problem
--The business needs to understand how customer satisfaction is
--distributed across the 1-5 rating scale. A single average rating
--hides whether most customers are happy or merely neutral.

--💡 Business Impact
--Shows the true shape of customer satisfaction across the platform
--Heavy concentration in 2-2.99 is a serious quality red flag
--Percentage of orders rated 4+ is the most important platform health metric

--✅ Answer
--A healthy platform sees the bulk of orders in the 4-4.99 and 3-3.99 bands.
--If less than 50% of orders receive a 4+ rating, immediate restaurant
--quality improvement programs should be launched.
--The 5-star bucket identifies restaurants worth spotlighting as
--the platform's absolute best.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 17. Top 10 dishes by avg rating (with minimum 100 ratings for statistical significance)

SELECT TOP 10 dh.Dish_Name, FORMAT(AVG(CONVERT(FLOAT, Rating)), 'N2') AS Avg_Rating, COUNT(*) AS Rating_Count
FROM dbo.fact_orders f
JOIN dbo.dim_dish dh ON f.Dish_id = dh.Dish_id
GROUP BY dh.Dish_Name
HAVING COUNT(*) >= 100
ORDER BY AVG(CONVERT(FLOAT, Rating)) DESC, COUNT(*) DESC

--🔍 Business Problem
--The company wants to know which dishes consistently delight customers,
--but a dish with only 5 ratings averaging 5.0 is not meaningful.
--The business needs statistically reliable quality data.

--💡 Business Impact
--Provides trustworthy, evidence-backed quality champions to promote
--Enables creation of a "Swiggy's Best" curated collection
--Identifies dishes suitable for homepage banners and marketing campaigns

--✅ Answer
--These dishes consistently delight customers across enough orders
--to be statistically meaningful (minimum 100 ratings).
--Restaurants serving multiple top-rated dishes are ideal candidates
--for exclusive partnership agreements and premium placement in the app.

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 18. Top 10 restaurants by avg rating (with minimum 100 ratings for statistical significance)

SELECT TOP 10 r.Restaurant_Name, FORMAT(AVG(CONVERT(FLOAT, Rating)), 'N2') AS Avg_Rating, COUNT(*) AS Rating_Count
FROM dbo.fact_orders f
JOIN dbo.dim_restaurant r ON f.Restaurant_id = r.Restaurant_id
GROUP BY r.Restaurant_Name
HAVING COUNT(*) >= 100
ORDER BY AVG(CONVERT(FLOAT, Rating)) DESC, COUNT(*) DESC

--🔍 Business Problem
--Which restaurant partners are genuinely delivering the best experience
--to customers? Without filtering for minimum ratings, a restaurant
--with 2 five-star reviews could appear as "top rated" — misleading.

--💡 Business Impact
--Identifies quality benchmark partners to celebrate and promote
--Their operational practices should guide new restaurant onboarding standards
--Rewarding top-rated restaurants with reduced commissions encourages
--them to stay exclusively on Swiggy

--✅ Answer
--These restaurants are the platform's quality champions.
--Featuring them prominently improves customer trust and overall
--platform perception.
--Their practices — preparation time, packaging, portion consistency —
--should be packaged as onboarding guidelines for all new restaurant partners.

--------------------------------------------------------------------------------------------------------------------------------------------------


-- ============================================================
-- FINAL RECOMMENDATIONS
-- ============================================================

--🏆 Top Insights for Business Action

--📍 Insight 1 — Prioritise high-volume, high-rating cuisine categories

--Cuisines that rank in the top 5 for both Total Orders and Avg Rating
--are the most powerful growth levers on the platform. Aggressively
--expanding restaurant supply in these categories across new cities
--will drive faster adoption and stronger early retention.


--📍 Insight 2 — Protect the Above 500 INR customer segment

--Although the smallest price bucket by order count, Above 500 INR
--customers generate the highest revenue per transaction.
--A dedicated premium loyalty program for this segment can significantly
--protect overall platform revenue even during periods of slower volume growth.


--📍 Insight 3 — Act on cuisine categories with high orders but low ratings

--Any cuisine appearing in the top 10 by order volume but with a
--below-average rating is a hidden churn risk. Customers ordering
--these cuisines are disappointed, reducing the chance of reorder.
--Restaurant quality audits and minimum rating thresholds for listing
--in high-demand cuisine categories should be implemented immediately.

-- ============================================================
-- END OF SWIGGY SALES ANALYSIS
-- ============================================================
