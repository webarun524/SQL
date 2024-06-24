SELECT * FROM credit_card_transcations;

-- 1-write a query to print top 5 cities with highest spends 
	-- and their percentage contribution of total credit card spends 
WITH cte1 as(
	SELECT city, SUM(amount) as total_spend
	FROM credit
	GROUP BY city
), cte2 as(
	SELECT SUM(amount) as total_amount 
	FROM credit
)
SELECT cte1.*, ROUND(total_spend*1.0/total_amount*100, 2) as percentage_contribution 
FROM cte1
INNER JOIN cte2
ON 1=1
ORDER BY total_spend DESC
LIMIT 5;

-- 2- write a query to print highest spend month for each year and amount spent 
	-- in that month for each card type
WITH cte1 as(
	SELECT card_type, YEAR(transaction_date) yt,
	MONTH(transaction_date) mt, SUM(amount) as total_spend
	FROM credit
	GROUP BY card_type, YEAR(transaction_date), MONTH(transaction_date)
), cte2 as(
	SELECT *, DENSE_RANK() OVER(PARTITION BY card_type ORDER BY total_spend DESC) as rn
	FROM cte1
)
SELECT *
FROM cte2
WHERE rn =1;

-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of  1,000,000 total spends(We should have 4 rows in the o/p one for each card type)

WITH cte1 as(
	SELECT *, SUM(amount) OVER(PARTITION BY card_type ORDER BY transaction_date, transaction_id) as total_spend
	FROM credit
), cte2 as(
	SELECT *, DENSE_RANK() OVER(PARTITION BY card_type ORDER BY total_spend) as rn  
	FROM cte1 WHERE total_spend >= 1000000
)
SELECT *
FROM cte2
WHERE rn=1;

-- 4- write a query to find city which had lowest percentage spend for gold card type
WITH cte as(
	SELECT city, card_type, SUM(amount) as amount,
    SUM(CASE WHEN card_type='Gold' THEN amount END) as gold_amount
	FROM credit
	GROUP BY city, card_type
)
SELECT city, SUM(gold_amount)*1.0/SUM(amount) as gold_ratio
FROM cte
GROUP BY city
HAVING COUNT(gold_amount) > 0 AND SUM(gold_amount)>0
ORDER BY gold_ratio;

-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

WITH cte1 as (
	SELECT city, exp_type, SUM(amount) as total_amount 
    FROM credit
	GROUP BY city, exp_type
), cte2 as (
	SELECT *,
    DENSE_RANK() OVER(PARTITION BY city ORDER BY total_amount DESC) rn_desc,
    DENSE_RANK() OVER(PARTITION BY city ORDER BY total_amount ASC) rn_asc
	FROM cte1
)
SELECT city, 
MAX(CASE WHEN rn_asc=1 THEN exp_type END) as lowest_exp_type, 
MIN(CASE WHEN rn_desc=1 THEN exp_type END) as highest_exp_type
FROM cte2
GROUP BY city;

-- 6- write a query to find percentage contribution of spends by females for each expense type
SELECT exp_type,
SUM(CASE WHEN gender='F' THEN amount ELSE 0 END)*1.0/SUM(amount) as percentage_female_contribution
FROM credit
GROUP BY exp_type
ORDER BY percentage_female_contribution DESC;

-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
WITH cte1 as(
	SELECT card_type, exp_type, YEAR(transaction_date) yt, 
    MONTH(transaction_date) mt, SUM(amount) as total_spend
	FROM credit
	GROUP BY card_type, exp_type, YEAR(transaction_date), MONTH(transaction_date)
), cte2 as(
	SELECT *, 
    LAG(total_spend,1) OVER(PARTITION BY card_type, exp_type ORDER BY yt,mt) as prev_mont_spend
	FROM cte1
)
SELECT *, (total_spend-prev_mont_spend) as mom_growth
FROM cte2
WHERE prev_mont_spend IS NOT NULL AND yt=2014 AND mt=1
ORDER BY mom_growth DESC
LIMIT 1;

-- 8- during weekends which city has highest total spend to total no of transcations ratio 
SELECT city , SUM(amount)*1.0/COUNT(1) as ratio
FROM credit
WHERE DAYNAME(transaction_date) in ('Saturday','Sunday')
GROUP BY city
ORDER BY ratio DESC
LIMIT 1;

-- 9- which city took least number of days to reach its
	-- 500th transaction after the first transaction in that city;

WITH cte as(
	SELECT *,
    ROW_NUMBER() OVER(PARTITION BY city ORDER BY transaction_date, transaction_id) as rn
	FROM credit
)
SELECT city, TIMESTAMPDIFF(DAY, MIN(transaction_date), MAX(transaction_date)) as datediff1
FROM cte
WHERE rn=1 or rn=500
GROUP BY city
HAVING COUNT(1)=2
ORDER BY datediff1
LIMIT 1; 