CREATE TABLE sales(
      sale_id INT,
	  date DATE,
	  store_id INT,
	  product_id INT,
	  units INT
);	  

SELECT * FROM sales;

SELECT COUNT(*)
FROM sales;

SELECT * FROM sales LIMIT 10;

DROP TABLE products;

CREATE TABLE products(
           product_id INT,
		   product_name VARCHAR(100),
		   product_category VARCHAR(50),
		   product_cost NUMERIC(10,2),
		   product_price NUMERIC(10,2)
);		   

SELECT * FROM products;	

SELECT COUNT(*)
FROM products;

CREATE TABLE stores(
             store_id INT,
			 store_name VARCHAR(100),
			 store_city VARCHAR(100),
			 store_location VARCHAR(100),
			 store_open_date DATE
);			 

SELECT * FROM stores;

SELECT COUNT(*)
FROM stores;


CREATE TABLE inventory(
         store_id INT,
		 product_id INT,
		 stock_on_hand INT
);		 
SELECT * FROM inventory;
SELECT COUNT(*)
FROM inventory;

CREATE TABLE products_raw(
           product_id INT,
		   product_name VARCHAR(100),
		   product_category VARCHAR(50),
		   product_cost TEXT,
		   product_price TEXT
);		   

SELECT COUNT(*) AS total_transactions,SUM(units) AS units_sold
FROM sales s;

SELECT SUM(s.units*p.product_price) AS total_revenue
FROM sales s
INNER JOIN products p
ON s.product_id=p.product_id;

SELECT SUM((p.product_price-p.product_cost)*s.units) AS total_profit
FROM sales s
INNER JOIN products p
ON s.product_id=p.product_id;

SELECT p.product_id,p.product_name,SUM(s.units) AS total_units_sold,SUM(s.units*p.product_price) AS total_revenue
FROM products p
INNER JOIN sales s
ON p.product_id=s.product_id
GROUP BY p.product_id,p.product_name;

SELECT p.product_id,p.product_name,SUM(s.units*p.product_price) AS total_revenue
FROM sales s
INNER JOIN products p
ON s.product_id=p.product_id
GROUP BY p.product_id,p.product_name
ORDER BY total_revenue DESC LIMIT 10;

-- Q6. Top 10 Most Profitable Products

SELECT
    p.product_id,
    p.product_name,
    SUM(s.units) AS total_units_sold,
    SUM(s.units * p.product_price) AS total_revenue,
    SUM((p.product_price - p.product_cost) * s.units) AS total_profit
FROM products p
INNER JOIN sales s
    ON p.product_id = s.product_id
GROUP BY
    p.product_id,
    p.product_name
ORDER BY total_profit DESC
LIMIT 10;

-- Q7. Year-wise and Month-wise Revenue and Profit

SELECT
    EXTRACT(YEAR FROM s.sale_date) AS year,
    EXTRACT(MONTH FROM s.sale_date) AS month,
    SUM(s.units * p.product_price) AS total_revenue,
    SUM((p.product_price - p.product_cost) * s.units) AS total_profit
FROM sales s
INNER JOIN products p
    ON s.product_id = p.product_id
GROUP BY
    EXTRACT(YEAR FROM s.sale_date),
    EXTRACT(MONTH FROM s.sale_date)
ORDER BY
    year,
    month;

-- Q8. Store-wise Sales Performance

SELECT
    st.store_id,
    st.store_name,
    SUM(s.units) AS total_units_sold,
    SUM(s.units * p.product_price) AS total_revenue,
    SUM((p.product_price - p.product_cost) * s.units) AS total_profit
FROM sales s
INNER JOIN products p
    ON s.product_id = p.product_id
INNER JOIN stores st
    ON s.store_id = st.store_id
GROUP BY
    st.store_id,
    st.store_name
ORDER BY total_revenue DESC; 


-- Q9. Stores with Revenue Greater Than 100,000

SELECT
    st.store_id,
    st.store_name,
    SUM(s.units * p.product_price) AS total_revenue
FROM sales s
INNER JOIN products p
    ON s.product_id = p.product_id
INNER JOIN stores st
    ON s.store_id = st.store_id
GROUP BY
    st.store_id,
    st.store_name
HAVING SUM(s.units * p.product_price) > 100000
ORDER BY total_revenue DESC;


-- Q10. Products That Have Never Been Sold

SELECT
    p.product_id,
    p.product_name,
    p.product_price
FROM products p
LEFT JOIN sales s
    ON p.product_id = s.product_id
WHERE s.product_id IS NULL;

-- Q11. Sales Count and Total Units for Every Product

SELECT
    p.product_id,
    p.product_name,
    COUNT(s.product_id) AS sales_count,
    COALESCE(SUM(s.units), 0) AS total_units_sold
FROM products p
LEFT JOIN sales s
    ON p.product_id = s.product_id
GROUP BY
    p.product_id,
    p.product_name
ORDER BY sales_count DESC;

-- Q12. Average Revenue per Transaction

SELECT
    AVG(s.units * p.product_price) AS average_transaction_revenue
FROM sales s
INNER JOIN products p
    ON s.product_id = p.product_id;


-- Q13. Category-wise Revenue and Profit

SELECT
    p.product_category,
    SUM(s.units * p.product_price) AS total_revenue,
    SUM((p.product_price - p.product_cost) * s.units) AS total_profit
FROM products p
INNER JOIN sales s
    ON p.product_id = s.product_id
GROUP BY
    p.product_category
ORDER BY total_revenue DESC;

SELECT
    p.product_category,
    SUM(s.units * p.product_price) AS category_revenue,
    SUM(s.units * p.product_price) * 100.0 /
    (
        SELECT SUM(s2.units * p2.product_price)
        FROM sales s2
        JOIN products p2
            ON s2.product_id = p2.product_id
    ) AS revenue_percentage
FROM sales s
JOIN products p
    ON s.product_id = p.product_id
GROUP BY p.product_category;


WITH product_revenue AS (
    SELECT
        p.product_category,
        p.product_name,
        SUM(s.units * p.product_price) AS total_revenue
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY
        p.product_category,
        p.product_name
),
ranked_products AS (
    SELECT
        product_category,
        product_name,
        total_revenue,
        RANK() OVER (
            PARTITION BY product_category
            ORDER BY total_revenue DESC
        ) AS product_rank
    FROM product_revenue
)
SELECT
    product_category,
    product_name,
    total_revenue,
    product_rank
FROM ranked_products
WHERE product_rank <= 3
ORDER BY product_category, product_rank;


WITH store_revenue AS (
    SELECT
        s.store_id,
        SUM(s.units * p.product_price) AS store_revenue
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY s.store_id
)
SELECT
    store_id,
    store_revenue,
    (
        SELECT AVG(store_revenue)
        FROM store_revenue
    ) AS average_store_revenue
FROM store_revenue
WHERE store_revenue > (
    SELECT AVG(store_revenue)
    FROM store_revenue
)
ORDER BY store_revenue DESC;


WITH store_revenue AS (
    SELECT
        s.store_id,
        SUM(s.units * p.product_price) AS store_revenue
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY s.store_id
),
average_revenue AS (
    SELECT
        AVG(store_revenue) AS avg_revenue
    FROM store_revenue
)
SELECT
    sr.store_id,
    sr.store_revenue,
    ar.avg_revenue AS average_store_revenue
FROM store_revenue sr
CROSS JOIN average_revenue ar
WHERE sr.store_revenue > ar.avg_revenue
ORDER BY sr.store_revenue DESC;


WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', s.sale_date)::date AS sales_month,
        SUM(s.units * p.product_price) AS monthly_revenue
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY DATE_TRUNC('month', s.sale_date)::date
),
previous_month AS (
    SELECT
        sales_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    sales_month,
    monthly_revenue,
    previous_month_revenue,
    monthly_revenue - previous_month_revenue AS revenue_change
FROM previous_month
ORDER BY sales_month;

WITH monthly_revenue AS (
    SELECT
        s.product_id,
        DATE_TRUNC('month', s.sale_date)::date AS sales_month,
        SUM(s.units * p.product_price) AS monthly_revenue
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY
        s.product_id,
        DATE_TRUNC('month', s.sale_date)::date
),
previous_month AS (
    SELECT
        product_id,
        sales_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            PARTITION BY product_id
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    product_id,
    sales_month,
    monthly_revenue,
    previous_month_revenue,
    monthly_revenue - previous_month_revenue AS revenue_change
FROM previous_month
ORDER BY product_id, sales_month;


WITH monthly_revenue AS (
    SELECT
        s.product_id,
        DATE_TRUNC('month', s.sale_date)::date AS sales_month,
        SUM(s.units * p.product_price) AS monthly_revenue
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY
        s.product_id,
        DATE_TRUNC('month', s.sale_date)::date
),

previous_month AS (
    SELECT
        product_id,
        sales_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            PARTITION BY product_id
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM monthly_revenue
),

revenue_change AS (
    SELECT
        product_id,
        sales_month,
        monthly_revenue,
        previous_month_revenue,
        monthly_revenue - previous_month_revenue AS revenue_change
    FROM previous_month
)
SELECT
    product_id,
    sales_month,
    monthly_revenue,
    previous_month_revenue,
    revenue_change,
    ROUND(
        (revenue_change / NULLIF(previous_month_revenue, 0)) * 100,
        2
    ) AS growth_percentage
FROM revenue_change
ORDER BY product_id, sales_month;


WITH monthly_store_revenue AS (
    SELECT
        s.store_id,
        DATE_TRUNC('month', s.sale_date)::date AS sales_month,
        SUM(s.units * p.product_price) AS monthly_revenue
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY
        s.store_id,
        DATE_TRUNC('month', s.sale_date)::date
),
store_average AS (
    SELECT
        store_id,
        sales_month,
        monthly_revenue,
        AVG(monthly_revenue) OVER (
            PARTITION BY sales_month
        ) AS average_store_revenue
    FROM monthly_store_revenue
)
SELECT
    store_id,
    sales_month,
    monthly_revenue,
    average_store_revenue,
    monthly_revenue - average_store_revenue AS revenue_difference
FROM store_average
ORDER BY sales_month, revenue_difference DESC;

WITH monthly_revenue AS(
                     SELECT st.store_id,DATE_TRUNC('month',s.date)::date AS sales_month,
					 SUM(s.units*p.product_price) AS monthly_revenue
					 FROM sales s
					 INNER JOIN products p
					 ON s.product_id=p.product_id
					 GROUP BY st.store_id,DATE_TRUNC('month',s.date)::date
),
ranked_months AS(
                  SELECT store_id,sales_month,monthly_revenue,RANK() OVER(
                             
SELECT store_id,SUM(units) AS total_units,
                SUM(
                    CASE
					WHEN units>10 THEN units
					ELSE 0
					END
				) AS units_above_10
FROM sales
GROUP BY store_id
ORDER BY store_id;


SELECT p.product_id,p.product_name
FROM products p
WHERE NOT EXISTS(
         SELECT 1
		 FROM sales s
		 JOIN stores st
		 ON s.store_id=st.store_id
		 WHERE s.product_id=p.product_id
		 AND st.store_city='Ludhiana'
		);		 

SELECT st.store_id,st.store_name
FROM stores st
WHERE NOT EXISTS(
              SELECT 1
			  FROM inventory i
			  WHERE i.store_id=st.store_id
);		

SELECT p.product_category,SUM(s.units) AS total_units_sold
FROM sales s
JOIN products p
ON s.product_id=p.product_id
GROUP BY p.product_category
HAVING SUM(s.units)<1000
ORDER BY total_units_sold ASC;


WITH filtered_sales AS(
              SELECT s.product_id,s.units,p.product_category,p.product_price,p.product_cost
			  FROM sales s
			  INNER JOIN products p
			  ON s.product_id=p.product_id
			  WHERE s.units>=3
),
category_profit AS(
             SELECT category,SUM(units*(product_price-product_cost))AS total_profit,
			 SUM(units) AS total_units_sold
			 FROM filtered_sales
			 GROUP BY category
),
average_profit AS(
             SELECT AVG(total_profit) AS average_category_profit
			 FROM category_profit
)			 
SELECT cp.category,cp.total_profit,cp.total_units_sold
FROM category_profit cp
CROSS JOIN average_profit cp
WHERE cp.total_profit>ap.average_category_profit
ORDER BY cp.total_profit DESC;

WITH filtered_sales AS(
             SELECT s.store_id,s.units,p.product_price
			 FROM sales s
			 INNER JOIN products p
			 ON s.product_id=p.product_id
			 WHERE s.units>=5
),
store_revenue AS(
            SELECT store_id,SUM(units*product_price) AS total_revenue,
			SUM(units) AS total_units_sold
			FROM filtered_sales
			GROUP BY store_id
),
average_revenue AS(
          SELECT AVG(total_revenue) AS average_revenue
		  FROM store_revenue
)
SELECT s.store_name,sr.total_revenue,sr.total_units_sold
FROM store_revenue sr
CROSS JOIN average_revenue ar
WHERE sr.store_revenue>ar.average_revenue
ORDER BY sr.total_revenue DESC;


WITH product_sales AS (
    SELECT
        store_id,
        product_id,
        SUM(units) AS total_units_sold
    FROM sales
    GROUP BY store_id, product_id
)
SELECT
    st.store_name,
    p.product_name,
    i.stock_on_hand,
    COALESCE(ps.total_units_sold, 0) AS total_units_sold
FROM inventory i
JOIN stores st
    ON i.store_id = st.store_id
JOIN products p
    ON i.product_id = p.product_id
LEFT JOIN product_sales ps
    ON i.store_id = ps.store_id
    AND i.product_id = ps.product_id
WHERE i.stock_on_hand > 0
  AND ps.total_units_sold IS NULL
ORDER BY st.store_name, p.product_name;


WITH product_summary AS(
                 SELECT p.product_id,p.product_name,p.product_category,SUM(s.units) AS total_units_sold,
				 SUM(s.units*p.product_price) AS total_revenue,
				 SUM(s.units*(p.product_price-p.product_cost)) AS total_profit,
				 ROUND(
                  SUM(s.units*(p.product_price-p.product_cost))*100.0
				  /NULLIF (SUM(s.units*p.product_price),0),
				  2
				  ) AS profit_margin_percentage
				 FROM sales s
				 INNER JOIN products p
				 ON s.product_id=p.product_id
				 GROUP BY p.product_id,p.product_name,p.product_category
),
average_revenue AS(
                SELECT AVG(total_revenue) AS average_revenue
				FROM product_summary
)
SELECT ps.product_name,ps.product_category,ps.total_units_sold,ps.total_revenue,ps.total_profit,ps.profit_margin_percentage
FROM product_summary ps
CROSS JOIN average_revenue ar
WHERE ps.total_revenue>ar.average_revenue
AND ps.profit_margin_percentage<20
ORDER BY ps.total_revenue DESC;

 WITH store_revenue AS(
                        SELECT st.store_id,st.store_name,st.store_city,DATE_TRUNC('month',s.date)::date AS sales_month,
						SUM(s.units*p.product_price) AS total_revenue
						FROM sales s
						INNER JOIN products p
						ON s.product_id=p.product_id
						INNER JOIN stores st
						ON s.store_id=st.store_id
						GROUP BY st.store_id,st.store_name,st.store_city,DATE_TRUNC('month',s.date)::date
),
revenue_comparison AS(
                        SELECT store_id,store_name,store_city,sales_month,total_revenue,
						LAG(total_revenue,1) OVER(
                                     PARTITION BY store_id 
									 ORDER BY sales_month
									 ) AS previous_month_revenue,
							LAG(total_revenue,2) OVER(
                                     PARTITION BY store_id 
									 ORDER BY sales_month
									 ) AS revenue_2_months_ago,
								LAG(total_revenue,3) OVER(
                                     PARTITION BY store_id 
									 ORDER BY sales_month
									 ) AS revenue_3_months_ago 
									 FROM store_revenue
),
declining_stores AS(
                  SELECT * 
				  FROM revenue_comparison
				  WHERE total_revenue<previous_month_revenue
				  AND previous_month_revenue<revenue_2_months_ago
				  AND revenue_2_months_ago<revenue_3_months_ago
)
SELECT store_city,store_name,sales_month,total_revenue,previous_month_revenue
ORDER BY store_name,sales_month;

WITH product_sales AS(
                    SELECT s.store_id,s.product_id,SUM(s.units) AS total_units_sold
					FROM sales s
					GROUP BY s.store_id,s.product_id
)
SELECT st.store_name,p.product_name,ps.total_units_sold,i.stock_on_hand
FROM product_sales ps
INNER JOIN stores st
ON ps.store_id=st.store_id
INNER JOIN products p
ON ps.product_id=p.product_id
INNER JOIN inventory i
ON ps.store_id=i.store_id
AND ps.product_id=i.product_id
WHERE ps.total_units_sold>i.stock_on_hand
ORDER BY ps.total_units_sold DESC;

WITH store_revenue AS(
                     SELECT st.store_name,st.store_city,st.store_id,
					 SUM(
                               CASE 
							   WHEN EXTRACT (YEAR FROM s.date)=2025
							   THEN s.units*p.product_price
							   ELSE 0
							  END
							  ) AS revenue_2025,
							  SUM(
                                 CASE
								 WHEN EXTRACT(YEAR FROM s.date)=2026
								 THEN s.units*p.product_price
								 ELSE 0
								 END 
								 ) as revenue_2026
								 FROM sales s
								 INNER JOIN stores st
								 ON s.store_id=st.store_id
								 INNER JOIN products p
								 ON s.product_id=p.product_id
								 WHERE EXTRACT(YEAR FROM s.date)IN(2025,2026)
								 GROUP BY st.store_id,st.store_name,st.store_city
)
SELECT store_name,store_city,revenue_2025,revenue_2026,
ROUND(
(revenue_2026-revenue_2025)*100.0
/NULLIF(revenue_2025,0),
2
) AS revenue_growth_percentage
FROM store_revenue
WHERE revenue_2025>0
AND revenue_2026>0
ORDER BY revenue_growth_percentage;

SELECT p.product_name,p.product_category,i.stock_on_hand
FROM products p
INNER JOIN inventory i
ON p.product_id=i.product_id
WHERE NOT EXISTS(
        SELECT 1
		FROM sales s
		WHERE s.product_id=p.product_id
)
ORDER BY p.product_name;

WITH product_sales AS(
                      SELECT s.store_id,s.product_id,SUM(s.units) AS total_units_sold
					  FROM sales s
					  GROUP BY s.store_id,s.product_id
),
ranked_products AS(
                      SELECT ps.store_id,ps.product_id,ps.total_units_sold,RANK() OVER(
                                                    PARTITION BY ps.store_id
													ORDER BY ps.total_units_sold DESC
													) AS product_rank
													FROM product_sales 
)
SELECT st.store_name,st.store_city,p.product_name,rp.total_units_sold
FROM ranked_products rs
INNER JOIN stores st
ON rp.store_id=st.store_id
INNER JOIN products p
ON rp.product_id=st.product_id
WHERE rp.product_rank=1
ORDER BY st.store_name;



											
													





					  )
					 
 





)
					






)






)





)
								 
								 
								 





							  )





					 )






)






)

)
									 
									 




						)





)







 )




)




				 )
				 






)
  






)




)




