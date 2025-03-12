# E-commerce Sales Analysis

### Project Overview
This data analysis project aims to provide insights into the sales performance of an e-commerce company, analyze  the performance trends. This project analysis will seek to identify trends, make data-driven recommendations, and gain an understanding of the company's performance over time.

### Data Source
This dataset used for this analysis was a 'sales data_csv file' containing the detailed information of the sales made by the company.

### Tools used
- Power Query - Data cleaning [Download here](https://microsoft.com)
- SQL - Analysis
- PowerBI - data visualization/report


### Data Cleaning/Preparation
In the initial data preparation phase, the following tasks were performed:
1. Data loading and inspection
2. Handling missing values
3. Data cleaning and formatting.

### Exploratory Data Analysis

EDA involved exploring the sales data to answer key questions such as:
1. Change Over time Analysis
    - Calculate the sales and profit performance over time.
2. Cumulative sales analysis
   - Calculate the total sales per month and the running total sales over time
3. Performance Analysis
   - Analyze the yearly performance of products by comparing each product's sales to both its average sales performance and the previous year sales
4. Part-to-whole Analysis
   - Which categories and Subcategories contribute the most to overall sales
5. Data Segmentation
   - Group customers into three segments based on their spending behaviour
### Data Analysis
Analysis was done using microsoft SSMS server
 - Calculate the sales and profit performance over time
```sql
SELECT 
		YEAR(Order_Date) AS Order_year,
		DATENAME(MONTH, Order_Date) AS Order_month,
		COUNT(DISTINCT Customer_ID) AS Total_customers,
		SUM(Sales) AS Total_sales,
		SUM(Quantity) AS Total_quantity,
		SUM(Profit) AS Total_profit
		FROM [dbo].[Order_table]
		GROUP BY YEAR(Order_Date), DATENAME(MONTH, Order_Date)
		ORDER BY YEAR(Order_Date), DATENAME(MONTH, Order_Date)
```
- Calculate the total sales per month and the running total sales over time
```
SELECT 
		  order_date,
		  total_sales,
		  SUM(total_sales) OVER (ORDER BY order_date) Running_total_sales
		  FROM 
			  (SELECT 
				DATETRUNC(MONTH, Order_Date) AS order_date,
			    SUM(Sales) AS total_sales
			    FROM dbo.Order_table
			    WHERE Order_Date IS NOT NULL
			    GROUP BY DATETRUNC(MONTH, Order_Date)
		        )t
ORDER BY DATETRUNC(MONTH, Order_Date)  
```
- Analyze the yearly performance of products by comparing each product's sales to both its average sales performance and the previous year sales
```
WITH Yearly_product_sales AS 
(SELECT 
	YEAR(o.Order_Date) AS order_year,
	p.Product_Name,
	SUM(o.Sales) AS Current_sales
	FROM dbo.Products p 
	LEFT JOIN dbo.Order_table o 
	ON p.Product_ID = o.Product_ID
	GROUP BY p.Product_Name, YEAR(o.Order_Date)
)
	SELECT order_year,
	Product_Name,
	Current_sales,
	AVG(Current_sales) OVER (PARTITION BY product_Name) AS Avg_sales,
	Current_sales - AVG(Current_sales) OVER (PARTITION BY product_Name) AS Diff_avg,
	   CASE WHEN Current_sales - AVG(Current_sales) OVER (PARTITION BY product_Name) >  0 THEN 'Above Avg'
	        WHEN Current_sales - AVG(Current_sales) OVER (PARTITION BY product_Name) <  0 THEN 'Below Avg'
			ELSE 'Avg'
			END AS Avg_change,
	LAG(Current_sales) OVER (PARTITION BY product_Name ORDER BY order_year) PrevYear,
	Current_sales - LAG(Current_sales) OVER (PARTITION BY product_Name ORDER BY order_year) AS DiffPY,
	    CASE WHEN Current_sales - LAG(Current_sales) OVER (PARTITION BY product_Name ORDER BY order_year) >  0 THEN 'Increase'
	        WHEN Current_sales - LAG(Current_sales) OVER (PARTITION BY product_Name ORDER BY order_year)<  0 THEN 'Decrease'
			ELSE 'No_change'
			END AS PY_change
	FROM Yearly_product_sales
	ORDER BY order_year,Product_Name
```
- Analyze the yearly performance of products by comparing each product's profit to both its average profit performance and the previous year profit
```
WITH Yearly_product_profit AS 
(SELECT 
	YEAR(o.Order_Date) AS order_year,
	p.Product_Name,
	SUM(o.Profit) AS Current_profit
	FROM dbo.Products p 
	LEFT JOIN dbo.Order_table o 
	ON p.Product_ID = o.Product_ID
	GROUP BY p.Product_Name, YEAR(o.Order_Date)
)
	SELECT order_year,
	Product_Name,
	Current_profit,
	AVG(Current_profit) OVER (PARTITION BY product_Name) AS Avg_profit,
	Current_profit - AVG(Current_profit) OVER (PARTITION BY product_Name) AS Diff_avg,
	   CASE WHEN Current_profit - AVG(Current_profit) OVER (PARTITION BY product_Name) >  0 THEN 'Above Avg'
	        WHEN Current_profit - AVG(Current_profit) OVER (PARTITION BY product_Name) <  0 THEN 'Below Avg'
			ELSE 'Avg'
			END AS Avg_change,
	LAG(Current_profit) OVER (PARTITION BY product_Name ORDER BY order_year) PrevYear,
	Current_profit - LAG(Current_profit) OVER (PARTITION BY product_Name ORDER BY order_year) AS DiffPY,
	    CASE WHEN Current_profit - LAG(Current_profit) OVER (PARTITION BY product_Name ORDER BY order_year) >  0 THEN 'Increase'
	        WHEN Current_profit - LAG(Current_profit) OVER (PARTITION BY product_Name ORDER BY order_year)<  0 THEN 'Decrease'
			ELSE 'No_change'
			END AS PY_change
	FROM Yearly_product_profit
	ORDER BY order_year,Product_Name
```
- Which categories and Subcategories contribute the most to overall sales
```
WITH Category_sales AS 
(
	SELECT P.Category, P.Sub_Category,
	SUM(O.Sales) AS total_sales
	FROM dbo.Order_table O 
	LEFT JOIN dbo.Products P 
	ON P.Product_ID = O.Product_ID
	GROUP BY P.Category, P.Sub_Category
	)
	SELECT 
	Category,
	Sub_Category,
	total_sales,
	SUM(total_sales) OVER () OverallSales,
	CONCAT(ROUND((CAST(total_sales AS FLOAT)/ SUM(total_sales) OVER ()) * 100, 2), '%') Percen_total
	FROM Category_sales
	ORDER BY total_sales DESC 
```

- Group customers into three segments based on their spending behaviour
```
WITH Customer_spending AS (
SELECT 
		C.Customer_ID,
		SUM(O.Sales) Total_spending,
		MIN(Order_Date) First_order,
		MAX(Order_Date) Last_order,
		DATEDIFF(MONTH, MIN(Order_Date), Max(Order_Date)) Lifespan
		FROM dbo.Customer C 
		LEFT JOIN dbo.Order_table O
		ON C.Customer_ID = O.Customer_ID
		GROUP BY C.Customer_ID
		)

		SELECT 
		Customer_segments,
		COUNT(Customer_ID) AS total_customers
      FROM (
		   SELECT 
				Customer_ID,
				CASE WHEN Lifespan >= 30 AND Total_spending > 500000 THEN 'VIP'
				WHEN Lifespan >= 30 AND Total_spending <= 500000 THEN 'Regular'
				ELSE 'New'
				END AS Customer_segments
				FROM Customer_spending
				) t
				GROUP BY Customer_segments
				ORDER BY total_customers DESC
```


### Results /Findings
