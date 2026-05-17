select * from dbo.swiggy_data
 
--data validation and cleaning
-- Check for NULL values in critical columns
select 
	sum(case when State is null then 1 else 0 end) as Null_State,
	sum(case when City is null then 1 else 0 end) as Null_City,
	sum(case when Order_Date is null then 1 else 0 end) as Null_Order_Date,
	sum(case when Restaurant_Name is null then 1 else 0 end) as Null_Restaurant_Name,
	sum(case when Location is null then 1 else 0 end) as Null_Location,
	sum(case when Category is null then 1 else 0 end) as Null_Category,
	sum(case when Dish_Name is null then 1 else 0 end) as Null_Dish_Name,
	sum(case when Price_INR is null then 1 else 0 end) as Null_Price_INR,
	sum(case when Rating is null then 1 else 0 end) as Null_Rating,
	sum(case when Rating_Count is null then 1 else 0 end) as Null_Rating_Count
from dbo.swiggy_data

--blank or empty string values in critical columns
select
	   state,city,order_date,restaurant_name,
	   location,category,dish_name,price_inr,
	   rating,rating_count, count(*) as count
from dbo.swiggy_data
group by state,city,order_date,restaurant_name,
	   location,category,dish_name,price_inr,
	   rating,rating_count
having count(*) > 1

--delete duplicate records
with cte as (
	select *,
		   row_number() over (partition by state,city,order_date,restaurant_name,
	   location,category,dish_name,price_inr,
	   rating,rating_count order by (select null)) as rn
	from dbo.swiggy_data
)
delete from cte where rn > 1


--creating schema for dimensional modeling
--dimensional modeling
--data table
--dimensions: date, location, restaurant, category, dish

create table dbo.dim_date (
	Date_id int identity(1,1) primary key,
	Full_Date date,
	Year int,
	Month int,
	month_name varchar(20),
	Quarter  int,
	Day int,
	WEEK int
)

--create location dimension
create table dbo.dim_location (
	Location_id int identity(1,1) primary key,
	State nvarchar(100),
	City nvarchar(100),
	location nvarchar(255)
)

--create restaurant dimension
create table dbo.dim_restaurant (
	Restaurant_id int identity(1,1) primary key,
	Restaurant_Name varchar(255)
)

--create category dimension
create table dbo.dim_category (
	Category_id int identity(1,1) primary key,
	Category varchar(255)
)

--create dish dimension
create table dbo.dim_dish (
	Dish_id int identity(1,1) primary key,
	Dish_Name varchar(255)
)

--create fact table
create table dbo.fact_orders (
	Order_id int identity(1,1) primary key,
	Date_id int,
	Location_id int,
	Restaurant_id int,
	Category_id int,
	Dish_id int,
	Price_INR decimal(10,2),
	Rating decimal(4,2),
	Rating_Count int,
	foreign key (Date_id) references dbo.dim_date(Date_id),
	foreign key (Location_id) references dbo.dim_location(Location_id),
	foreign key (Restaurant_id) references dbo.dim_restaurant(Restaurant_id),
	foreign key (Category_id) references dbo.dim_category(Category_id),
	foreign key (Dish_id) references dbo.dim_dish(Dish_id)
)

--insert data into dimension tables
--insert into dim_date
insert into dbo.dim_date (Full_Date, Year, Month, month_name, Quarter, Day, WEEK)
select distinct 
       Order_Date,
	   year(Order_Date) as Year,
	   month(Order_Date) as Month,
	   datename(month, Order_Date) as month_name,
	   datepart(quarter, Order_Date) as Quarter,
	   day(Order_Date) as Day,
	   datepart(week, Order_Date) as WEEK
from dbo.swiggy_data

--insert into dim_location
insert into dbo.dim_location (State, City, location)
select distinct State, City, Location
from dbo.swiggy_data

--insert into dim_restaurant
insert into dbo.dim_restaurant (Restaurant_Name)
select distinct Restaurant_Name
from dbo.swiggy_data

--insert into dim_category
insert into dbo.dim_category (Category)
select distinct Category
from dbo.swiggy_data

--insert into dim_dish
insert into dbo.dim_dish (Dish_Name)
select distinct Dish_Name
from dbo.swiggy_data

--insert data into fact table
insert into dbo.fact_orders (Date_id, Location_id, Restaurant_id, Category_id, Dish_id, Price_INR, Rating, Rating_Count)
select 
	d.Date_id,
	l.Location_id,
	r.Restaurant_id,
	c.Category_id,
	dh.Dish_id,
	s.Price_INR,
	s.Rating,
	s.Rating_Count
from dbo.swiggy_data s
join dbo.dim_date d on s.Order_Date = d.Full_Date
join dbo.dim_location l on s.State = l.State and s.City = l.City and s.Location = l.location
join dbo.dim_restaurant r on s.Restaurant_Name = r.Restaurant_Name
join dbo.dim_category c on s.Category = c.Category
join dbo.dim_dish dh on s.Dish_Name = dh.Dish_Name

--kpi development
--total orders
select count(*) as Total_Orders
from dbo.fact_orders

--total revenue (INR Million)
select format(sum(convert(float, Price_INR))/1000000, 'N2') + ' INR Million' as Total_Revenue_Million
from dbo.fact_orders

--avg dish price
select format(avg(convert(float, Price_INR)), 'N2') + ' INR' as Avg_Dish_Price
from dbo.fact_orders

--avg restaurant rating
select format(avg(convert(float, Rating)), 'N2') as Avg_Restaurant_Rating
from dbo.fact_orders

--deep dive analysis
--date based analysis
--monthly order trend
select d.Year, d.Month, d.month_name, count(*) as Total_Orders
from dbo.fact_orders f
join dbo.dim_date d on f.Date_id = d.Date_id
group by d.Year, d.Month, d.month_name

--quarterly revenue trend
select d.Year, d.Quarter, format(sum(convert(float, Price_INR))/1000000, 'N2') + ' INR Million' as Revenue_Million
from dbo.fact_orders f
join dbo.dim_date d on f.Date_id = d.Date_id
group by d.Year, d.Quarter

--year wise growth in orders
select d.Year, count(*) as Total_Orders
from dbo.fact_orders f
join dbo.dim_date d on f.Date_id = d.Date_id
group by d.Year

--day of week analysis
select d.WEEK, count(*) as Total_Orders
from dbo.fact_orders f
join dbo.dim_date d on f.Date_id = d.Date_id
group by d.WEEK

--location based analysis
--top 10 cities by order volume
select top 10 l.City, count(*) as Total_Orders
from dbo.fact_orders f
join dbo.dim_location l on f.Location_id = l.Location_id
group by l.City
order by Total_Orders desc

--revenue contribution by state
select top 10 l.State, format(sum(convert(float, Price_INR))/1000000, 'N2') + ' INR Million' as Revenue_Million
from dbo.fact_orders f
join dbo.dim_location l on f.Location_id = l.Location_id
group by l.State
order by Revenue_Million desc

--food performance analysis
--top 10 restaurants by order volume
select top 10 r.Restaurant_Name, count(*) as Total_Orders
from dbo.fact_orders f
join dbo.dim_restaurant r on f.Restaurant_id = r.Restaurant_id
group by r.Restaurant_Name
order by Total_Orders desc

--top categories(cuisine) by order volume
select top 10 c.Category, count(*) as Total_Orders	
from dbo.fact_orders f
join dbo.dim_category c on f.Category_id = c.Category_id
group by c.Category
order by Total_Orders desc

--most ordered dishes
select top 10 dh.Dish_Name, count(*) as Total_Orders
from dbo.fact_orders f
join dbo.dim_dish dh on f.Dish_id = dh.Dish_id
group by dh.Dish_Name
order by Total_Orders desc

--cuisine performance analysis= orders+ AVG rating
select top 10 c.Category, count(*) as Total_Orders, format(avg(convert(float, Rating)), 'N2') as Avg_Rating
from dbo.fact_orders f
join dbo.dim_category c on f.Category_id = c.Category_id
group by c.Category
order by Total_Orders desc, Avg_Rating desc

--Customer behavior analysis
--total order by price range
select 
	case 
		when convert(float, Price_INR) < 100 then 'Below 100 INR'
		when convert(float, Price_INR) between 100 and 199 then '100-199 INR'
		when convert(float, Price_INR) between 200 and 299 then '200-299 INR'
		when convert(float, Price_INR) between 300 and 499 then '300-499 INR'		
		else 'Above 500 INR'
	end as Price_Range,
	count(*) as Total_Orders
from dbo.fact_orders
group by 
	case 
		when convert(float, Price_INR) < 100 then 'Below 100 INR'
		when convert(float, Price_INR) between 100 and 199 then '100-199 INR'
		when convert(float, Price_INR) between 200 and 299 then '200-299 INR'
		when convert(float, Price_INR) between 300 and 499 then '300-499 INR'		
		else 'Above 500 INR'
	end
order by Total_Orders desc

--Ratings Analysis
--Distribution of dish ratings from 1–5.
select 
	case 
		when convert(float, Rating) < 1 then 'Below 1'
		when convert(float, Rating) between 1 and 1.99 then '1-1.99'
		when convert(float, Rating) between 2 and 2.99 then '2-2.99'
		when convert(float, Rating) between 3 and 3.99 then '3-3.99'		
		when convert(float, Rating) between 4 and 4.99 then '4-4.99'		
		else '5'
	end as Rating_Range,
	count(*) as Total_Orders
from dbo.fact_orders
group by 
	case 
		when convert(float, Rating) < 1 then 'Below 1'
		when convert(float, Rating) between 1 and 1.99 then '1-1.99'
		when convert(float, Rating) between 2 and 2.99 then '2-2.99'
		when convert(float, Rating) between 3 and 3.99 then '3-3.99'		
		when convert(float, Rating) between 4 and 4.99 then '4-4.99'		
		else '5'
	end
order by Total_Orders desc


--top 10 dishes by avg rating (with minimum 100 ratings)
select top 10 dh.Dish_Name, format(avg(convert(float, Rating)), 'N2') as Avg_Rating, count(*) as Rating_Count
from dbo.fact_orders f
join dbo.dim_dish dh on f.Dish_id = dh.Dish_id
group by dh.Dish_Name
having count(*) >= 100
order by Rating_Count desc

--top 10 restaurants by avg rating (with minimum 100 ratings)
select top 10 r.Restaurant_Name, format(avg(convert(float, Rating)), 'N2') as Avg_Rating, count(*) as Rating_Count
from dbo.fact_orders f
join dbo.dim_restaurant r on f.Restaurant_id = r.Restaurant_id
group by r.Restaurant_Name
having count(*) >= 100
order by Rating_Count desc
