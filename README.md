# E-commerce Sales Analysis

## Table of Contents

- [Project Overview](#project-overview)
- [Data Source](#data-source)
- [Tools used](#tools-used)
- [Data Preparation](#data-preparation)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Data Analysis](#data-analysis)
- [Results /Findings](#results-findings)
- [Recommendations](#recommendation)
- [Limitations](#limitations)
- [References](#references)

### Project Overview
This data analysis project aims to provide insights into the sales performance of an e-commerce company, analyze  the performance trends. This project analysis will seek to identify trends, make data-driven recommendations, and gain an understanding of the company's performance over time.

### Data Source
This dataset used for this analysis was a 'sales data_csv file' containing the detailed information of the sales made by the company.

### Tools used
- Power Query - Data cleaning [Download here](https://microsoft.com)
- SQL - Analysis
- PowerBI - data visualization/report


### Data Preparation
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
The analysis results are summarized as follows:
### Overall Performance metrics

The business is experiencing impressive growth across all key areas:
Revenue hit $1.13 billion, reflecting a year-over-year (YoY) increase of 45.84% and a month-over-month (MoM) growth of 3.05%. This suggests strong and consistent market demand.
Total Profit surged to $1.80 billion, outpacing revenue growth with a YoY gain of 55.37%. This likely indicates improved cost management, better pricing strategies, or a shift toward high-margin products.
Total Orders and Transactions are also on the rise—over 5,000 orders and nearly 10,000 transactions showing that customer engagement is high and expanding.
With 37.87K units sold, the rise in total quantity (up 49.12% YoY) aligns well with the increase in orders and revenue, suggesting that growth isn’t just coming from price hikes but also higher volume.
### Sales Trend Insights

The line chart tracking sales trends from 2020 to 2023 shows a clear upward trajectory, with 2023 (blue line) standing out as the strongest performer by a large margin.
Notable spikes occur in September and October, which may indicate seasonal trends, successful campaigns, or major events driving demand.
Earlier years (2020–2022) were relatively flat in comparison, confirming a sharp turnaround or recent success in strategic execution.
Takeaway: 2023 has been a breakout year for sales. This momentum can be capitalized on with forward-looking planning and targeted promotions during seasonal peaks.
Sub-Category Performance Breakdown

### Diving into product-level insights, there's a diverse range of profitability across sub-categories:

### Top Performers:
Copiers boast extraordinary profitability, with a profit margin exceeding 700%. This suggests a premium pricing model or minimal cost relative to revenue.
Chairs show excellent performance as well, with over $45 million in profit and a healthy 122% profit margin.
Accessories and Binders are also contributing positively with consistent profit margins.

### Underperformers:
Bookcases are in the red, posting a shocking -1531% margin, which may be due to excess costs, returns, or pricing issues.
Tables and Machines are also dragging profitability down significantly, with multi-million-dollar losses and negative margins of -68.83% and -117.95% respectively.
Supplies, Storage, and Paper have modest sales but are also unprofitable, potentially due to high competition or low pricing.

### Top Products:
The Riverside product leads at $30M, followed by Canon and Atlantic brands, each at $24M.
These top products likely belong to the high-performing sub-categories mentioned above.

### Worst-Selling Sub-Categories & Products
Lowest Revenue Sub-Categories:
Supplies ($17M), Art ($9M), and Envelopes ($6M) are underperformers.

Labels and Fasteners also bring in minimal revenue, indicating either niche demand or declining interest.

### Worst-Selling Products:
Products like Sanford Pens and Dell Slim devices have shockingly low individual sales values (e.g., $152, $125).
These could be one-off SKUs, outdated inventory, or irrelevant items in the current market.
Bookcases, despite $202M in sales, are running a $26.3M loss, with a negative profit margin. The same goes for Tables and Machines profitable in appearance but actually delivering major losses.
Chairs, on the other hand, combine high sales with high profit ($45.8M in profit, margin of 122.18%), making them a strong performer across the board.

### Sales by Shipping Mode
Standard Class dominates shipping, contributing $664. 08M in sales.
Second Class and First Class follow far behind at $224.08M and $189.30M respectively.

### Geographical Insights

### Sales Performance by State
### Top States by Sales:
California leads massively with $44.36M in sales over 3x more than any other state.
Florida follows with $24.34M.
Illinois also stands out with $12.81M.

### Underperforming States:
Kansas, Iowa, and Arkansas each have less than $50K in sales barely visible on the heatmap.
This could reflect a lack of presence, poor distribution, or limited customer base in those areas.

### Profit Margin Performance
### Top Profit Margin States:
Arizona has an exceptional profit margin of 434.31% indicating extremely high efficiency or product pricing power.
Montana (85.84%), California (48.24%), and Michigan (16.81%) also show strong profitability with large sales bases, which is impressive.

### States with Alarming Profitability Issues:
Illinois has a profit margin of -778.60%, despite over $12.8M in sales. This is a critical red flag it’s possibly the biggest loss-making region.
Florida also shows -256.64% meaning the second-highest sales state is deeply unprofitable.
Colorado is down -90.12%, despite decent sales (~$3.9M).

### Sales Performance by City
### Top Cities by Sales:
Houston leads, even outperforming New York City highlighting Texas as a strong regional hub (consistent with the dark blue on the map).
Other strong performers include Dallas, Los Angeles, Philadelphia, and Fort Lauderdale all large metro areas.
### City-Level Insight:
Sales are concentrated in a few major metro areas, meaning urban targeting has been effective.
However, cities in Florida and Illinois (e.g., Fort Lauderdale, Chicago) may be contributing to state-level profit erosion.

### Recommendation
Based on the analysis, we recommend the following actions:
### Optimize Product Portfolio

### Promote Best-Selling Products & Categories:
- Products like Riverside, Canon printers, and Atlantic Metals drive strong revenue.
- Sub-categories like Bookcases, Chairs, Phones, Tables, and Binders perform well.
### Action:
- Double down on inventory and promotion for these items.
- Feature them in marketing campaigns and bundle offers.
- Discontinue or Rework Poor Performers:
- Products like Sanford Pencils, Dell Slim models, and Art Supplies are consistently underperforming.
- High losses in sub-categories like Supplies, Art, and Labels indicate poor demand or pricing issues.
### Action:
- Consider discontinuing or redesigning unprofitable SKUs.
- Reevaluate sourcing costs and renegotiate vendor contracts for underperformers.

### Improve Sales Channel Efficiency

### Shipping Optimization:
- Standard Class shipping is the most used mode (~$0.66bn in sales).
- Same Day is underused but could serve high-margin customers.
### Action:
- Improve cost-efficiency in Standard Class logistics to preserve margin.
- Offer premium shipping options for high-value orders at a slight fee to increase margin.

### Regional & Market Expansion Strategy
- Fix High-Sales, Low-Profit States (e.g., Illinois, Florida):
- These states generate high revenue but suffer from extremely negative profit margins.
### Action:
- Audit operations in these states—review fulfillment, discounts, returns, and overhead costs.
- Localize pricing or introduce minimum order thresholds to reduce fulfillment losses.
-  Expand in High-Margin, Low-Touch States (e.g., Arizona, Montana):

### High profit margins with relatively lower sales indicate strong unit economics.
### Action:
- Run targeted ads, pop-up stores, or online geo-targeted campaigns to boost sales in these states.
- Use Arizona as a blueprint for lean, profitable expansion.
  
### Intelligent Customer Targeting
- Focus on High-Converting Cities: Houston, NYC, Dallas, LA, and Philly are top-performing cities.
### Action:
- Launch regional promotions and email campaigns tied to local events.
- Offer loyalty programs or early access deals to top zip codes.

### Mitigate Low Engagement Areas:
- Cities in underperforming states need awareness-building efforts or may be deprioritized.
### Action:
- Use A/B testing to assess if digital ads or influencer campaigns can drive demand before fully investing in physical presence.

### Pricing and Promotion Strategy
Action:
- Avoid blanket discounts. Instead, apply data-driven dynamic pricing:
- Lower prices in low-performing, high-margin areas to boost volume.
- Keep premium pricing in states like Arizona where margins are excellent.
- Offer volume-based discounts only for high-margin products.

### Limitations
- There are probably still outliers in the dataset but it is not much to affect the results of the analysis.

### References
1. SQL for data analyst by Cathy Tanimura
2. [Stack Overflow](https://stack.com)
