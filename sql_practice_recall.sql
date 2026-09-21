-- ============================================
-- SQL Practice — Recall & Job-Readiness Module
-- Stage R2: SQL
-- ============================================

-- ============================================
-- R2.A — Filtering, sorting, limiting
-- ============================================

SELECT CUSTOMER, SKU, `GROSS AMT`
FROM cleaned_sales_data
WHERE `GROSS AMT` > 1000
ORDER BY `GROSS AMT` DESC
LIMIT 5;

SELECT CUSTOMER, SKU, `GROSS AMT`
FROM cleaned_sales_data
WHERE `GROSS AMT` >= 500 AND `GROSS AMT` <= 1000 AND CUSTOMER LIKE 'M%';


-- ============================================
-- R2.B — Aggregation (GROUP BY, HAVING)
-- ============================================

SELECT CUSTOMER,
       COUNT(*) AS NO_OF_ORDERS,
       SUM(`GROSS AMT`) AS TOTAL_GROSS
FROM cleaned_sales_data
GROUP BY CUSTOMER
HAVING NO_OF_ORDERS > 50
ORDER BY TOTAL_GROSS DESC;


-- ============================================
-- R2.C — Joins
-- ============================================

-- Anti-join: customers who never placed an order
SELECT customer_name
FROM customer_table c
LEFT JOIN orders_table o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- INNER JOIN practice
SELECT f.flower_id, f.fruit_id, f.flower_name, r.fruit_name
FROM flowers f
INNER JOIN fruits r
ON f.fruit_id = r.fruit_id;

-- UNION ALL practice
SELECT f.fruit_id, f.flower_name
FROM flowers f
UNION ALL
SELECT r.fruit_id, r.fruit_name
FROM fruits r;


-- ============================================
-- R2.D — CTEs / Subqueries
-- ============================================

WITH CTE as (
SELECT `product Category`, SUM(`Total Amount`) AS Total
FROM retail_sales GROUP BY `product Category` ORDER BY Total DESC ) ,
CTE_1 AS (SELECT GENDER ,SUM(`Total Amount`) AS Gender_Wise_Total From retail_sales group by GENDER)
SELECT p.`product Category`,p.Total from CTE p
UNION ALL
SELECT  s.GENDER,s.Gender_Wise_Total from  CTE_1 s;


-- ============================================
-- R2.E — Window Functions
-- ============================================

-- RANK, no partition
SELECT Store_ID,Total_Revenue,
RANK() OVER (ORDER BY Total_Revenue) AS Revenue_Wise_Ranking
FROM store_sales_summary;

-- RANK, partitioned by Store_Type
SELECT Store_ID,Total_Revenue,Store_Type,
RANK() OVER (PARTITION BY Store_Type ORDER BY Total_Revenue DESC) AS Store_Wise_Ranking
FROM store_city_performance;

-- Running total
Select `Customer ID`,`Product Category`,
Sum(`Total Amount`) Over(Order By Date
Rows Between Unbounded preceding and Current Row) as Running_Total
From retail_sales_dataset;

-- LAG
Select `Customer ID`,Date,`Total Amount` as Current_Day_Sale,
Lag(`Total Amount`) Over( Order By Date) As Previous_Day_Sale
From retail_sales_dataset;

-- LEAD
Select `Customer ID`,Date,`Product Category` as Current_Day_Product,
Lead(`Product Category`) Over( Order By Date) As Next_Day_Sold_Product
From retail_sales_dataset;

-- Moving average using a custom frame
Select `Customer ID`,`Product Category`,
Avg(`Total Amount`) Over( Order By Date) As Current_Day_Avg,
Avg(`Total Amount`) Over (Order By Date Rows between 1 preceding and 1 following) As  Comparing_Day_Avg
from retail_sales_dataset;


-- ============================================
-- R2.F — CASE, NULLs, Dates, Text
-- ============================================

-- CASE WHEN — bucketing into tiers
Select `Customer ID`,`Product Category`,
Case When `Total Amount` >= 1500 Then "High Valued"
When `Total Amount` > 1000 Then "Proficient"
Else "Competent"
End As category
from retail_sales_dataset;

-- Verifying CASE WHEN logic with a count per category
Select category, Count(*) As How_Many from (Select `Customer ID`,`Product Category`,
Case When `Total Amount` >= 1500 Then "High Valued"
When `Total Amount` > 1000 Then "Proficient"
Else "Competent"
End As category
From retail_sales_dataset) r
Group by category;

-- Date formatting
Select flight_number,date_format(date,"%Y-%m") As Date
from flight_cancellations;

-- DATEDIFF
Select flight_number,date_format(date,"%Y-%m") As Date,
datediff('2026-02-27','2026-03-20') AS Difference
from flight_cancellations;

-- COALESCE
Select flight_number,date_format(date,"%Y-%m") As Date,
datediff('2026-02-27','2026-03-20') AS Difference,
Coalesce(flight_number,"Not Mentioned") As Null_Handelling
from flight_cancellations;


-- ============================================
-- R2.G — Eight Core Query Patterns
-- Business questions on flight_cancellations / airline_losses
-- ============================================

-- Q1: Which origin_country has the highest number of cancelled flights?
Select origin_country,Count(origin_country) As Cancelled_flight_no 
From flight_cancellations Group BY origin_country Order By Cancelled_flight_no Desc;

-- Q2: What percentage of all flights originated from each origin_region?
With CTE_1 as (
Select origin_region,Count(origin_region) As No_Of_Cancelled_Flights
From flight_cancellations Group By origin_region Order by No_Of_Cancelled_Flights desc)
Select origin_region,Round((No_Of_Cancelled_Flights*100)/(Select Count(*) From flight_cancellations),0) As Percentage_Of_Cancelled_Flights
From CTE_1 Group By origin_region ;

-- Q3: Are there any flight_numbers that appear more than once?
Select s.flight_number, s.No_flights from (Select flight_number,count(flight_number) As No_flights from flight_cancellations 
Group By flight_number) s Where s.No_flights>1 ;

-- Q4: What is the 2nd highest passengers_affected value, and which flight had it?
Select s.flight_number,s.airline,s.date,s.origin_region,s.passengers_affected,s.passengers_affected_ranking from (Select flight_number,airline,date,origin_region,passengers_affected,
Dense_Rank() Over (order By passengers_affected Desc) As passengers_affected_ranking
from flight_cancellations) s
where passengers_affected_ranking=2;

-- Q5: For each origin_country, show the flight with the most passengers_affected.
Select s.flight_number,s.origin_country,s.airline,s.date,s.origin_region,s.passengers_affected,s.passengers_affected_ranking from 
(Select flight_number,origin_country,airline,date,origin_region,passengers_affected,
Dense_Rank() Over (partition by origin_country order By passengers_affected Desc) As passengers_affected_ranking 
from flight_cancellations) s
where passengers_affected_ranking=1;

-- Q6: Group cancellations by month — total passengers_affected, plus change from previous month.
Select s.Month,s.Passangers_Affected,
Lag(Passangers_Affected) over(order by s.Month) As Previous_Month from
(Select date_format(date,"%Y-%m") as Month,
Sum(passengers_affected) as Passangers_Affected
from flight_cancellations
Group By Month) s;

-- Q7: Are there airlines in airline_losses that never appear in flight_cancellations?
Select s.airline,s.country,s.region,r.flight_number,r.date
from airline_losses s left join flight_cancellations r
On s.airline=r.airline
where r.airline IS NULL;

-- Q8: Which origin_countries have an average passengers_affected higher than the company-wide average?
With CTE_1 as ( Select origin_country,avg(passengers_affected) as Avg_Passenger_Affected
from flight_cancellations
group by origin_country),
CTE_2 as ( Select avg(passengers_affected) as overall_company_wide_verage
from flight_cancellations)
Select origin_country,Avg_Passenger_Affected from CTE_1 
Cross Join CTE_2 Where Avg_Passenger_Affected>overall_company_wide_verage
;
