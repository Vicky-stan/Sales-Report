---- Analyze Sales Performance over time
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


----- Cumulative sales analysis
--- Calculate the total sales per month and the running total sales over time
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



-----Performance Analysis
-------- Analyze the yearly performance of products by comparing each product's sales to both its 
---average sales performance and the previous year sales
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





---- Analyze the yearly performance of products by comparing each product's profit to both its 
---average profit performance and the previous year profit
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



---- Which categories and Subcategories contribute the most to overall sales
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


---Which state contribute the most to the overallsales 
WITH State_Sales AS 
(
		SELECT 
		l.State,
		SUM(Sales) AS Total_sales
		FROM dbo.Order_table o 
		LEFT JOIN dbo.location l
		ON l.Postal_Code = o.Postal_Code
		GROUP BY l.State
)
		SELECT 
		State,
		Total_sales,
		SUM(Total_sales) OVER () overallsales,
		CONCAT(ROUND((CAST(Total_sales AS FLOAT)/ SUM(Total_sales) OVER ()) * 100, 2), '%')  State_percentage
		FROM State_Sales
		ORDER BY Total_sales DESC  


----- Group customers into three segments based on their spending behaviour

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


------Build Customer report by customer metrics and behaviours
WITH Base_query AS (

SELECT
		O.Order_ID,
		O.Order_Date,
		O.Product_ID,
		O.Sales,
		O.Quantity,
		C.Customer_ID,
		C.Customer_Name
		FROM dbo.Order_table O 
		LEFT JOIN dbo.Customer C 
		ON C.Customer_ID = O.Customer_ID
  )

  ,Customer_aggregation  AS
            (
				SELECT 
				Customer_ID,
				Customer_Name,
				COUNT(DISTINCT Order_ID) AS total_orders,
				SUM(Sales) AS Total_spending,
				SUM(Quantity) AS total_quantity,
				COUNT(DISTINCT Product_ID) AS total_products,
				MAX(Order_Date) AS Last_order_date,
				DATEDIFF(MONTH, MIN(Order_Date), MAX(Order_Date)) AS Lifespan
		  FROM Base_query
		  GROUP BY  Customer_ID,
		  Customer_Name
	  )
	  SELECT 
			Customer_ID,
			Customer_Name,
			Lifespan,
			CASE WHEN Lifespan >= 30 AND Total_spending > 500000 THEN 'VIP'
				    WHEN Lifespan >= 30 AND Total_spending <= 500000 THEN 'Regular'
				    ELSE 'New'
				    END AS Customer_segments,
			total_orders,
			Last_order_date,
			DATEDIFF(MONTH, Last_order_date, GETDATE()) AS Recency,
			Total_spending,
			total_quantity,
			total_products,
			Lifespan,
			---Average order value
			CASE WHEN total_orders = 0 THEN 0
			     ELSE total_spending/ total_orders
				 END AS Avg_order_value,
			--- Average monthly spend
			CASE WHEN Lifespan = 0 THEN Total_spending
			     ELSE Total_spending/Lifespan
			END AS Avg_monthly_spend
			FROM Customer_aggregation
	

          