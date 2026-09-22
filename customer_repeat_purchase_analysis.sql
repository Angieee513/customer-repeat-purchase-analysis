/*
============================================================
Customer Repeat Purchase & Retention Analysis
============================================================

Objective:
Analyze 90-day repeat purchasing behavior using more than
1 million retail transaction records.

Workflow:
1. Audit raw transaction data
2. Clean transactions
3. Construct customer order histories
4. Identify first and second purchases
5. Measure 30/60/90-day repeat behavior
6. Analyze first-order behavioral segments
7. Build customer-level features for predictive modeling

Tools: DBeaver
-- =========================================================
-- 1. RAW DATA AUDIT
-- =========================================================

-- Inspect overall dataset size and key identifiers
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT invoice) AS total_orders,
    COUNT(DISTINCT NULLIF(TRIM(customer_id), '')) AS total_customers,
    COUNT(DISTINCT stock_code) AS total_products
FROM retail_transactions_raw;


-- Audit cancellation and negative-quantity records
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE
            WHEN invoice LIKE 'C%' THEN 1
            ELSE 0
        END) AS cancelled_rows,
    SUM(CASE
            WHEN quantity < 0 THEN 1
            ELSE 0
        END) AS negative_quantity_rows,
    SUM(CASE
            WHEN invoice LIKE 'C%' AND quantity < 0 THEN 1
            ELSE 0
        END) AS cancelled_and_negative_rows
FROM retail_transactions_raw;


-- Audit non-positive prices
SELECT
    SUM(CASE
            WHEN price = 0 THEN 1
            ELSE 0
        END) AS zero_price_rows,
    SUM(CASE
            WHEN price < 0 THEN 1
            ELSE 0
        END) AS negative_price_rows,
    MIN(price) AS min_price, MAX(price) AS max_price
FROM retail_transactions_raw;


-- Audit missing customer identifiers
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE
            WHEN TRIM(customer_id) = '' THEN 1
            ELSE 0
        END) AS blank_customer_rows,
    COUNT(DISTINCT NULLIF(TRIM(customer_id), '')) AS identifiable_customers
FROM retail_transactions_raw;


-- Validate transaction date coverage
SELECT
    MIN(STR_TO_DATE(invoice_date, '%m/%d/%y %H:%i')) AS first_transaction,
    MAX(STR_TO_DATE(invoice_date, '%m/%d/%y %H:%i')) AS last_transaction,
    SUM(CASE
            WHEN STR_TO_DATE(invoice_date,'%m/%d/%y %H:%i') IS NULL
            THEN 1
            ELSE 0
        END) AS invalid_date_rows
FROM retail_transactions_raw;

-- =========================================================
-- 2. TRANSACTION CLEANING
-- =========================================================

/*
Cleaning rules:
- Keep transactions with identifiable customers
- Remove non-positive quantities
- Remove zero or negative prices
- Exclude cancelled invoices
- Convert transaction timestamps to DATETIME
- Create line-level revenue
*/

CREATE TABLE retail_transactions_clean AS

SELECT
    invoice,
    stock_code,
    description,
    quantity,
    STR_TO_DATE(invoice_date,'%m/%d/%y %H:%i') AS invoice_date,
    price, TRIM(customer_id) AS customer_id, country, quantity * price AS line_revenue
FROM retail_transactions_raw
WHERE TRIM(customer_id) <> '' AND quantity > 0 AND price > 0 AND invoice NOT LIKE 'C%';


-- Validate cleaned dataset
SELECT
    COUNT(*) AS clean_transaction_rows,
    COUNT(DISTINCT invoice) AS clean_orders,
    COUNT(DISTINCT customer_id) AS clean_customers,
    COUNT(DISTINCT stock_code) AS clean_products,
    MIN(invoice_date) AS first_transaction,
    MAX(invoice_date) AS last_transaction
FROM retail_transactions_clean;

-- =========================================================
-- 3. ORDER-LEVEL CUSTOMER JOURNEY
-- =========================================================

/*
The cleaned dataset is transaction-line level.
To analyze repeat purchasing, transactions are first
aggregated to one row per customer × invoice.
ROW_NUMBER() is then used to reconstruct each customer's
purchase sequence.
*/

CREATE TABLE customer_orders AS

WITH order_summary AS (
    SELECT
        customer_id, invoice, MIN(invoice_date) AS order_date, SUM(line_revenue) AS order_revenue, SUM(quantity) AS total_items, COUNT(DISTINCT stock_code) AS unique_products
    FROM retail_transactions_clean
    GROUP BY customer_id, invoice)

SELECT
    customer_id,
    invoice,
    order_date,
    order_revenue,
    total_items,
    unique_products,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY order_date, invoice) AS order_number
FROM order_summary;


-- Validate customer purchase sequences
SELECT
    customer_id,
    invoice,
    order_date,
    order_revenue,
    total_items,
    unique_products,
    order_number
FROM customer_orders
ORDER BY customer_id, order_number
LIMIT 50;


-- =========================================================
-- 4. FIRST & SECOND PURCHASE + RETENTION
-- =========================================================

/*
Identify each customer's first and second purchases and
calculate the number of days between them.

Customers without a second purchase are retained so they
can still be evaluated as non-repeat customers when they
have sufficient observation time.
*/

CREATE TABLE customer_purchase_summary AS

SELECT
    customer_id,
    MAX(CASE
            WHEN order_number = 1
            THEN order_date
        END) AS first_purchase_date,
    MAX(CASE
            WHEN order_number = 2
            THEN order_date
        END) AS second_purchase_date,
    DATEDIFF(MAX(CASE
                  WHEN order_number = 2
                  THEN order_date
                END),
        MAX(CASE
                WHEN order_number = 1
                THEN order_date
            END)) AS days_to_second_purchase,
    MAX( CASE
            WHEN order_number = 1
            THEN order_revenue
        END) AS first_order_value,
    MAX(CASE
            WHEN order_number = 1
            THEN total_items
        END) AS first_order_items,
    MAX(CASE
            WHEN order_number = 1
            THEN unique_products
        END) AS first_order_products,
    COUNT(*) AS total_orders
FROM customer_orders
GROUP BY customer_id;


-- =========================================================
-- 4. FIRST & SECOND PURCHASE + RETENTION
-- =========================================================

/*
Identify each customer's first and second purchases and
calculate the number of days between them.

Customers without a second purchase are retained so they
can still be evaluated as non-repeat customers when they
have sufficient observation time.
*/

CREATE TABLE customer_purchase_summary AS

SELECT
    customer_id,
    MAX(CASE
            WHEN order_number = 1
            THEN order_date
        END) AS first_purchase_date,
    MAX(CASE
            WHEN order_number = 2
            THEN order_date
        END) AS second_purchase_date,
    DATEDIFF(MAX(CASE
                  WHEN order_number = 2
                  THEN order_date
                END),
        MAX(CASE
                WHEN order_number = 1
                THEN order_date
            END)) AS days_to_second_purchase,
    MAX(CASE
            WHEN order_number = 1
            THEN order_revenue
        END) AS first_order_value,
    MAX(CASE
            WHEN order_number = 1
            THEN total_items
        END) AS first_order_items,

    MAX(CASE
            WHEN order_number = 1
            THEN unique_products
        END) AS first_order_products,
    COUNT(*) AS total_orders
FROM customer_orders
GROUP BY customer_id;


-- =========================================================
-- 5. CUSTOMER-LEVEL MODELING DATASET
-- =========================================================

/*
Create the final customer-level feature table used for
90-day retention analysis and predictive modeling.

Only customers with a complete 90-day observation window
are included.
*/

CREATE TABLE customer_features_90d AS

WITH first_order_country AS (
    SELECT
        co.customer_id, MAX(rtc.country) AS first_order_country
    FROM customer_orders co
    JOIN retail_transactions_clean rtc ON co.customer_id = rtc.customer_id AND co.invoice = rtc.invoice
    WHERE co.order_number = 1
    GROUP BY co.customer_id)

SELECT
    cps.customer_id,
    cps.first_purchase_date,
    DATE_FORMAT(cps.first_purchase_date, '%Y-%m') AS acquisition_month,
    cps.first_order_value,
    cps.first_order_items,
    cps.first_order_products,
    foc.first_order_country,
    cps.second_purchase_date,
    cps.days_to_second_purchase,
    CASE
        WHEN cps.days_to_second_purchase BETWEEN 0 AND 90
        THEN 1
        ELSE 0
    END AS repeat_90d
FROM customer_purchase_summary cps
LEFT JOIN first_order_country foc ON cps.customer_id = foc.customer_id
WHERE cps.first_purchase_date <= DATE_SUB('2011-12-09',INTERVAL 90 DAY);


-- Validate final modeling dataset
SELECT
    COUNT(*) AS customers,
    SUM(repeat_90d) AS repeat_customers_90d,
    ROUND(100.0 * AVG(repeat_90d), 2) AS repeat_rate_90d
FROM customer_features_90d;


-- =========================================================
-- 6. FIRST-ORDER VALUE SEGMENTATION
-- =========================================================

/*
Segment customers into quartiles based on first-order
value and compare subsequent 90-day repeat behavior.
*/

WITH value_segments AS (
    SELECT
        customer_id, first_order_value, repeat_90d,
        NTILE(4) OVER (ORDER BY first_order_value) AS value_quartile
    FROM customer_features_90d)
SELECT
    value_quartile,
    COUNT(*) AS customers,
    ROUND(MIN(first_order_value), 2) AS min_first_order_value,
    ROUND(MAX(first_order_value),2) AS max_first_order_value,
    ROUND(AVG(first_order_value), 2) AS avg_first_order_value,
    SUM(repeat_90d) AS repeat_customers_90d,
    ROUND(100.0 * AVG(repeat_90d),2) AS repeat_rate_90d
FROM value_segments
GROUP BY value_quartile
ORDER BY value_quartile;


-- =========================================================
-- 7. FIRST-ORDER PRODUCT VARIETY SEGMENTATION
-- =========================================================

/*
Evaluate whether customers who explore a broader range
of products on their first order show different repeat
purchase behavior.
*/

WITH product_segments AS (
    SELECT
        customer_id, first_order_products, repeat_90d,
        NTILE(4) OVER (ORDER BY first_order_products) AS product_quartile
    FROM customer_features_90d)

SELECT
    product_quartile,
    COUNT(*) AS customers,
    MIN(first_order_products) AS min_products,
    MAX(first_order_products) AS max_products,
    ROUND(AVG(first_order_products), 2) AS avg_products,
    SUM(repeat_90d) AS repeat_customers_90d,
    ROUND(100.0 * AVG(repeat_90d),2) AS repeat_rate_90d
FROM product_segments
GROUP BY product_quartile
ORDER BY product_quartile;


-- =========================================================
-- 8. ACQUISITION COHORT ANALYSIS
-- =========================================================

/*
Compare 90-day repeat behavior across customer acquisition
cohorts.

This analysis evaluates whether retention differs depending
on when customers were first acquired.
*/

SELECT
    acquisition_month,
    COUNT(*) AS new_customers,
    SUM(repeat_90d) AS repeat_customers_90d,
    ROUND(100.0 * AVG(repeat_90d),2) AS repeat_rate_90d
FROM customer_features_90d
GROUP BY acquisition_month
ORDER BY acquisition_month;


-- =========================================================
-- ANALYSIS SUMMARY
-- =========================================================

/*
Key findings produced by this SQL pipeline:

1. 23.39% of eligible customers repeated within 30 days.
2. 38.33% repeated within 60 days.
3. 47.26% repeated within 90 days.
4. 90-day repeat rates increased from 36.64% in the lowest
   first-order-value quartile to 57.12% in the highest.
5. 90-day repeat rates increased from 41.86% in the lowest
   first-order-product-variety quartile to 54.62% in the
   highest.
6. Repeat behavior varied substantially across acquisition
   cohorts, motivating further cohort-based analysis and
   predictive modeling in Python.
The customer_features_90d table was exported for downstream
exploratory analysis and logistic regression modeling.
*/
