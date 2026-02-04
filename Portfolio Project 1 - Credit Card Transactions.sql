use project_db;

select* From creditcard; 
-- SQL porfolio project.
-- download credit card transactions dataset from below link :
-- https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
-- import the dataset in sql server with table name : credit_card_transcations
-- change the column names to lower case before importing data to sql server.Also replace space within column names with underscore.
-- (alternatively you can use the dataset present in zip file)
-- while importing make sure to change the data types of columns. by defualt it shows everything as varchar.

-- write 4-6 queries to explore the dataset and put your findings 

-- solve below questions
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
SELECT
    city,
    SUM(amount) AS city_spend,
    ROUND(
        (SUM(amount) * 100.0) / (SELECT SUM(amount) FROM creditcard),
        2
    ) AS percentage_contribution
FROM creditcard
GROUP BY city
ORDER BY city_spend DESC
LIMIT 5;
-- 2- write a query to print highest spend month for each year and amount spent in that month for each card type
WITH monthly_spend AS (
    SELECT
        card_type,
        EXTRACT(YEAR FROM transaction_date) AS year,
        EXTRACT(MONTH FROM transaction_date) AS month,
        SUM(amount) AS total_spend
    FROM creditcard
    GROUP BY
        card_type,
        EXTRACT(YEAR FROM transaction_date),
        EXTRACT(MONTH FROM transaction_date)
),
ranked_spend AS (
    SELECT
        card_type,
        year,
        month,
        total_spend,
        RANK() OVER (
            PARTITION BY card_type, year
            ORDER BY total_spend DESC
        ) AS rnk
    FROM monthly_spend
)
SELECT
    card_type,
    year,
    month AS highest_spend_month,
    total_spend AS amount_spent
FROM ranked_spend
WHERE rnk = 1
ORDER BY card_type, year;
-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
    WITH cumulative_spend AS (
    SELECT
        *,
        SUM(amount) OVER (
            PARTITION BY card_type
            ORDER BY transaction_date, transaction_id
        ) AS running_total
    FROM creditcard
),
filtered AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY card_type
               ORDER BY running_total
           ) AS rn
    FROM cumulative_spend
    WHERE running_total >= 1000000
)
SELECT *
FROM filtered
WHERE rn = 1;

-- 4- write a query to find city which had lowest percentage spend for gold card type
WITH gold_city_spend AS (
    SELECT
        city,
        SUM(amount) AS city_spend
    FROM creditcard
    WHERE card_type = 'Gold'
    GROUP BY city
),
total_gold_spend AS (
    SELECT
        SUM(city_spend) AS total_spend
    FROM gold_city_spend
)
SELECT
    g.city,
    ROUND((g.city_spend * 100.0) / t.total_spend, 2) AS percentage_spend
FROM gold_city_spend g
CROSS JOIN total_gold_spend t
ORDER BY percentage_spend ASC
LIMIT 1;

-- 6- write a query to find percentage contribution of spends by females for each expense type
WITH exp_total AS (
    SELECT
        exp_type,
        SUM(amount) AS total_spend
    FROM creditcard
    GROUP BY exp_type
),
female_spend AS (
    SELECT
        exp_type,
        SUM(amount) AS female_spend
    FROM creditcard
    WHERE gender = 'F'
    GROUP BY exp_type
)
SELECT
    t.exp_type,
    ROUND(
        COALESCE(f.female_spend, 0) * 100.0 / t.total_spend,
        2
    ) AS female_percentage_contribution
FROM exp_total t
LEFT JOIN female_spend f
    ON t.exp_type = f.exp_type
ORDER BY t.exp_type;
-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
WITH monthly_spend AS (
    SELECT
        card_type,
        exp_type,
        YEAR(transaction_date) AS yr,
        MONTH(transaction_date) AS mn,
        SUM(amount) AS total_spend
    FROM creditcard
    GROUP BY
        card_type,
        exp_type,
        YEAR(transaction_date),
        MONTH(transaction_date)
),
mom_growth AS (
    SELECT
        card_type,
        exp_type,
        total_spend -
        LAG(total_spend) OVER (
            PARTITION BY card_type, exp_type
            ORDER BY yr, mn
        ) AS mom_growth,
        yr,
        mn
    FROM monthly_spend
)
SELECT
    card_type,
    exp_type,
    mom_growth
FROM mom_growth
WHERE yr = 2014
  AND mn = 1
ORDER BY mom_growth DESC
LIMIT 10;

-- 8- during weekends which city has highest total spend to total no of transcations ratio 
WITH weekend_transactions AS (
    SELECT
        city,
        amount
    FROM creditcard
    WHERE DAYOFWEEK(transaction_date) IN (1, 7)
)
SELECT
    city,
    SUM(amount) * 1.0 / COUNT(*) AS spend_to_transaction_ratio
FROM weekend_transactions
GROUP BY city
ORDER BY spend_to_transaction_ratio DESC
LIMIT 6;

-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city
WITH ranked_txn AS (
    SELECT
        city,
        transaction_date,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY transaction_date, transaction_id
        ) AS txn_rank
    FROM creditcard
),
first_and_500th AS (
    SELECT
        city,
        MIN(CASE WHEN txn_rank = 1 THEN transaction_date END) AS first_txn_date,
        MIN(CASE WHEN txn_rank = 500 THEN transaction_date END) AS txn_500_date
    FROM ranked_txn
    GROUP BY city
)
SELECT
    city,
    DATEDIFF(txn_500_date, first_txn_date) AS days_taken
FROM first_and_500th
WHERE txn_500_date IS NOT NULL
ORDER BY days_taken ASC
LIMIT 21;
-- once you are done with this create a github repo to put that link in your resume. Some example github links:
-- https://github.com/ptyadana/SQL-Data-Analysis-and-Visualization-Projects/tree/master/Advanced%20SQL%20for%20Application%20Development
-- https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/COVID%20Portfolio%20Project%20-%20Data%20Exploration.sql