USE magist;

-- How many orders are there in the dataset? The orders table contains a row for each order, so this should be easy to find out!

SELECT 
    COUNT(DISTINCT order_id) AS total_orders
FROM
    orders;
# Answer: total orders are 99441

SELECT 
    COUNT(order_id) AS total_orders
FROM
    order_items;
# Answer: 112650

SELECT 
    COUNT(DISTINCT order_id) AS t_order
FROM
    order_items;
# Answer: 98666
# ========================================================================================================================
-- Are orders actually delivered? Look at the columns in the orders table: one of them is called order_status. 
-- Most orders seem to be delivered, but some aren’t. Find out how many orders are delivered and how many are cancelled, 
-- unavailable, or in any other status by grouping and aggregating this column.
SELECT 
    order_status, COUNT(order_id) AS Order_status_count
FROM
    Orders
GROUP BY order_status;
# Answers: 
-- delivered 96478,
-- unavailable 609,
-- shipped	1107,
-- canceled 625,
-- invoiced 314,
-- processing 301,
-- approved 2,
-- created 5

SELECT 
    COUNT(*) AS delivered_orders
FROM
    orders
WHERE
    order_status = 'delivered';
# Answer:delivered_orders 96478

-- How many orders were delivered and how many undelivered: 
SELECT 
    CASE
        WHEN order_status = 'delivered' THEN 'delivered'
        ELSE 'undelivered'
    END AS delivery_status,
    COUNT(*) AS status_count
FROM
    orders
WHERE
    order_status IS NOT NULL
GROUP BY delivery_status;
# answer: delivered-96478
		-- undelivered-2963
# ========================================================================================================================
-- Is Magist having user growth? A platform losing users left and right isn’t going to be very useful 
-- to us. It would be a good idea to check for the number of orders grouped by year and month.
--  Tip: you can use the functions YEAR() and MONTH() to separate the year and the month of the order_purchase_timestamp.
SELECT 
    YEAR(order_purchase_timestamp) AS year_,
    MONTH(order_purchase_timestamp) AS month_,
    COUNT(customer_id) AS nr_customers
FROM
    orders
GROUP BY year_ , month_
ORDER BY year_ , month_;

-- other way 
SELECT 
    year_ord, month_ord, month_name, nr_customers
FROM
    (SELECT 
        YEAR(order_purchase_timestamp) AS year_ord,
            MONTH(order_purchase_timestamp) AS month_ord,
            DATE_FORMAT(order_purchase_timestamp, '%M') AS month_name,
            COUNT(customer_id) AS nr_customers
    FROM
        orders
    GROUP BY year_ord , month_ord , month_name) AS subquery
ORDER BY year_ord , month_ord;

# ==========================================================================================================================
-- How many products are there on the products table? (Make sure that there are no duplicate products.)
SELECT 
    COUNT(DISTINCT product_id) total_products
FROM
    products;
-- Answer: 32951 products

# ==========================================================================================================================
-- Which are the categories with the most products? Since this is an external database and has been partially 
-- anonymized, we do not have the names of the products. But we do know which categories products belong to. 
-- This is the closest we can get to knowing what sellers are offering in the Magist marketplace. By counting the 
-- rows in the products table and grouping them by categories, we will know how many products are offered in each category. 
-- This is not the same as how many products are actually sold by category. To acquire this insight we will have to combine 
-- multiple tables together: we’ll do this in the next lesson.

SELECT 
    product_category_name,
    COUNT(DISTINCT product_id) AS nr_products
FROM
    products
GROUP BY product_category_name
ORDER BY nr_products DESC
LIMIT 10;

SELECT 
    product_category_name_english pt,
    COUNT(DISTINCT product_id) AS nr_products
FROM
    products p
        LEFT JOIN
    product_category_name_translation pt ON p.product_category_name = pt.product_category_name
GROUP BY product_category_name_english
ORDER BY nr_products DESC
LIMIT 10;
# Answer:
# pt, nr_products
-- 'bed_bath_table' 3029,
-- 'sports_leisure' 2867,
-- 'furniture_decor' 2657,
-- 'health_beauty' 2444,
-- 'housewares' 2335,
-- 'auto' 1900,
-- 'computers_accessories' 1639,
-- 'toys' 1411,
-- 'watches_gifts' 1329,
-- 'telephony' 1134.
# =====================================================================================================================
-- How many of those products were present in actual transactions? The products table is a “reference” of 
-- all the available products. Have all these products been involved in orders? Check out the order_items table to find out!
SELECT 
    COUNT(DISTINCT product_id) AS nr_products
FROM
    order_items;
SELECT 
    COUNT(DISTINCT product_id)
FROM
    products;
# answer:32951

-- orther option 
SELECT 
    COUNT(DISTINCT oi.product_id), COUNT(DISTINCT p.product_id)
FROM
    order_items oi
        JOIN
    products p USING (product_id);
    
    
# How many of those products were present in actual transactions?    
SELECT 
    product_category_name_translation.product_category_name_english,
    COUNT(DISTINCT order_id) AS order_quantity,
    (COUNT(DISTINCT order_id) / (SELECT 
            COUNT(*)
        FROM
            order_items) * 100) AS percentage
FROM
    products
        RIGHT JOIN
    order_items ON products.product_id = order_items.product_id
        JOIN
    product_category_name_translation ON products.product_category_name = product_category_name_translation.product_category_name
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
GROUP BY product_category_name_translation.product_category_name_english
ORDER BY COUNT(order_id) DESC;   

# ========================================================================================================================  
-- what’s the price for the most expensive and cheapest products? Sometimes, having a broad range of prices is informative. 
-- Looking for the maximum and minimum values is also a good way to detect extreme outliers.
SELECT 
    MAX(price) AS max_price, MIN(price) AS min_price
FROM
    order_items;
# Answer:  max_price 6735, min_price 0.85

SELECT DISTINCT
    product_id, price AS max_min
FROM
    order_items
WHERE
    price = (SELECT 
            MAX(price)
        FROM
            order_items)
        OR price = (SELECT 
            MIN(price)
        FROM
            order_items);

-- other option 
SELECT 
    MAX(price) AS max_and_min
FROM
    order_items 
UNION SELECT 
    MIN(price)
FROM
    order_items;
(SELECT 
    product_id, price
FROM
    order_items
ORDER BY price ASC
LIMIT 1) UNION (SELECT 
    product_id, price
FROM
    order_items
ORDER BY price DESC
LIMIT 1);

-- other option
SELECT DISTINCT
    pcnt.product_category_name_english, oi.price AS min_max
FROM
    order_items oi
        JOIN
    products p ON p.product_id = oi.product_id
        JOIN
    product_category_name_translation pcnt ON p.product_category_name = pcnt.product_category_name
WHERE
    price = (SELECT 
            MIN(price) AS min_
        FROM
            order_items oi)
        OR price = (SELECT 
            MAX(price) AS max_
        FROM
            order_items oi);
# =========================================================================================================================
-- What are the highest and lowest payment values? Some orders contain multiple products. 
-- What’s the highest someone has paid for an order? Look at the order_payments table and try to find it out.
SELECT 
    MAX(payment_value) AS highest_payment,
    MIN(payment_value) AS lowest_payment
FROM
    order_payments;

SELECT 
    MAX(payment_value) AS highest_payment,
    MIN(payment_value) AS lowest_payment
FROM
    order_payments
WHERE
    payment_value > 0;
    
#================================ Business questions ======================================================================#
-- In relation to the products:
-- What categories of tech products does Magist have?
-- How many products of these tech categories have been sold (within the time window of the database snapshot)? What percentage does that represent from the overall number of products sold?
-- What’s the average price of the products being sold?
-- Are expensive tech products popular? *

SELECT DISTINCT
    product_category_name_english
FROM
    product_category_name_translation;

-- Count of product categories 
SELECT 
    COUNT(DISTINCT product_category_name_english) AS nr_prod_category
FROM
    product_category_name_translation;
# answer: 74

-- =========================================================================================================================
-- What categories of products does Magist have?
SELECT DISTINCT
    product_category_name_english AS nr_prod_category,
    p.product_category_name
FROM
    products p
        LEFT JOIN
    product_category_name_translation pt ON p.product_category_name = pt.product_category_name;

-- I have selected this tech categories 
# Audio
-- Products: Apple-compatible headphones, earphones, Bluetooth speakers, AirPods accessories.
-- Relevance: High demand among Apple users who prioritize quality audio experiences.

# Computers
-- Products: MacBook stands, cooling pads, docking stations, external monitors compatible with macOS.
-- Relevance: Essential for Apple users looking to enhance their productivity setups.

# Electronics
-- Products: Smart home devices compatible with HomeKit, smartwatches, and other gadgets.
-- Relevance: Increasing adoption of smart home technology and wearables among Apple users.

#  Computers Accessories
-- Products: Keyboards, mice, cables, adapters, protective cases, screen protectors for MacBooks and iPads.
-- Relevance: Core accessories necessary for enhancing the functionality and protection of Apple devices.

# Tablets, Printing & Image
-- Products: iPad cases, styluses, printers compatible with AirPrint, photo accessories.
-- Relevance: Essential for creative professionals and students who use iPads extensively.

# Watches & Gifts
-- Products: Smartwatches, Apple Watch accessories, luxury pens, tech gadgets, and gift sets.
-- Relevance: Appeals to tech-savvy consumers and Apple enthusiasts who are likely to invest in high-quality accessories and gifts that enhance their Apple experience.

# telephony

SELECT DISTINCT
    (product_category_name_english) AS Tech_category_name
FROM
    products p
        LEFT JOIN
    product_category_name_translation pt ON p.product_category_name = pt.product_category_name
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');


-- How many products of these tech categories have been sold (within the time window of the database snapshot)?
-- Total products sold
SELECT 
    COUNT(DISTINCT order_id) AS total_products_sold
FROM
    order_items;
# answer: total '98666'  products sold 

-- Tech products sold
SELECT 
    COUNT(DISTINCT order_id) AS tech_products_sold
FROM
    order_items oi
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');
# answer: 19647 tech_products_sold
 
 
SELECT 
    (SELECT 
            COUNT(DISTINCT order_id)
        FROM
            order_items) AS total_products_sold,
    (SELECT 
            COUNT(DISTINCT order_id)
        FROM
            order_items oi
                JOIN
            products p ON oi.product_id = p.product_id
                JOIN
            product_category_name_translation pct ON p.product_category_name = pct.product_category_name
        WHERE
            product_category_name_english IN ('audio' , 'electronics',
                'computers',
                'tablets_printing_image',
                'computers_accessories',
                'watches_gifts',
                'telephony')) AS tech_products_sold;

-- Percentage of sold tech products
SELECT 
    ROUND((tech_products_sold / total_products_sold) * 100,
            2) AS tech_products_percentage
FROM
    (SELECT 
        COUNT(DISTINCT order_id) AS tech_products_sold
    FROM
        order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
    WHERE
        product_category_name_english IN ('audio' , 
        'electronics', 
        'computers', 
        'tablets_printing_image', 
        'computers_accessories', 
        'watches_gifts',
        'telephony')) AS tech,
    (SELECT 
        COUNT(*) AS total_products_sold
    FROM
        order_items) AS total;
# Answer: '17.44' % tech_products_sold

-- What’s the average price of the products being sold?
SELECT 
    ROUND(AVG(price), 2) AS average_price
FROM
    order_items oi
        JOIN
    products p ON oi.product_id = p.product_id;
# answer: 120.65 average_price

SELECT 
    ROUND(AVG(price), 2) AS average_price_techproduct
FROM
    order_items oi
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');
-- answer average_price_techproduct ''132.33'


-- Are expensive tech products popular?
SELECT 
    CASE
        WHEN oi.price > 1000 THEN 'Expensive'
        ELSE 'Affordable'
    END AS price_category,
    COUNT(*) AS product_count
FROM
    order_items oi
        LEFT JOIN
    products p ON oi.product_id = p.product_id
        LEFT JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
GROUP BY price_category;
# answer 'Affordable' '21512', 'Expensive' '268'

-- =========================================================================================================================
-- 3.2. In relation to the sellers:
-- How many months of data are included in the magist database?
-- How many sellers are there? How many Tech sellers are there? What percentage of overall sellers are Tech sellers?
-- What is the total amount earned by all sellers? What is the total amount earned by all Tech sellers?
-- Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?

-- first and last order date
SELECT 
    MIN(order_purchase_timestamp) AS earliest_date,
    MAX(order_purchase_timestamp) AS latest_date
FROM
    orders;
# answer: earliest_date-'2016-09-04 23:15:19'/latest_date-'2018-10-17 19:30:18'

-- How many months of data are included in the Magist database?
SELECT 
    TIMESTAMPDIFF(MONTH,
        MIN(order_purchase_timestamp),
        MAX(order_purchase_timestamp)) AS months_of_data
FROM
    orders;
# answer 25 months
-- ========================================================================================================================
-- How many sellers are there? How many Tech sellers are there? What percentage of overall sellers are Tech sellers?
-- Total sellers
SELECT 
    COUNT(DISTINCT seller_id) AS total_sellers
FROM
    sellers;
# answer: 3095 total_sellers

-- Tech sellers
SELECT 
    COUNT(DISTINCT s.seller_id) AS tech_sellers
FROM
    sellers s
        JOIN
    order_items oi ON s.seller_id = oi.seller_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');
# answer : 516 tech_sellers.

-- Number of tech sellers per product category
SELECT 
    product_category_name_english,
    COUNT(DISTINCT seller_id) AS nr_tech_selllers_by_category
FROM
    order_items
        INNER JOIN
    products ON products.product_id = order_items.product_id
        INNER JOIN
    product_category_name_translation ON product_category_name_translation.product_category_name = products.product_category_name
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
GROUP BY product_category_name_english
ORDER BY nr_tech_selllers_by_category DESC;
# Answer:
-- 'computers_accessories' 287,
-- 'electronics' 149,
-- 'telephony' 149,
-- 'watches_gifts' 101,
-- 'audio' 36,
-- 'computers' 9,
-- 'tablets_printing_image' 6.


-- Percentage of tech sellers
SELECT 
    ROUND((tech_sellers / total_sellers) * 100, 2) AS tech_sellers_percentage
FROM
    (SELECT 
        COUNT(DISTINCT s.seller_id) AS tech_sellers
    FROM
        sellers s
    JOIN order_items oi ON s.seller_id = oi.seller_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
    WHERE
        product_category_name_english IN ('audio' , 
        'electronics', 
        'computers', 
        'tablets_printing_image', 
        'computers_accessories', 
        'watches_gifts', 
        'telephony')) AS tech,
    (SELECT 
        COUNT(*) AS total_sellers
    FROM
        sellers) AS total;
# Answer:16,67 % of tech sellers.

-- =======================================================================================================================
-- What is the total amount earned by all sellers? What is the total amount earned by all Tech sellers?
-- Total amount earned by all sellers
SELECT 
    ROUND(SUM(payment_value), 0) AS total_earnings
FROM
    order_payments;
# Answer :  total_earnings 16008872


-- Total amount earned per month by all sellers
SELECT 
    YEAR(o.order_purchase_timestamp) AS order_year,
    MONTH(o.order_purchase_timestamp) AS order_month,
    ROUND(SUM(op.payment_value), 2) AS monthly_income
FROM
    order_items oi
        JOIN
    orders o ON oi.order_id = o.order_id
        JOIN
    order_payments op ON o.order_id = op.order_id
GROUP BY order_year , order_month
ORDER BY order_year , order_month;

-- Total amount earned per month by tech sellers
SELECT 
    YEAR(o.order_purchase_timestamp) AS order_year,
    MONTH(o.order_purchase_timestamp) AS order_month,
    ROUND(SUM(op.payment_value), 2) AS monthly_income
FROM
    order_items oi
        LEFT JOIN
    orders o ON oi.order_id = o.order_id
        LEFT JOIN
    products p ON oi.product_id = p.product_id
        LEFT JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
        LEFT JOIN
    order_payments op ON o.order_id = op.order_id
WHERE
    pct.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
GROUP BY order_year , order_month
ORDER BY order_year , order_month;


-- Total amount earned by Tech sellers
SELECT 
    ROUND(SUM(oi.price), 0) AS tech_earnings
FROM
    order_items oi
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');
# answer: '2882054'  tech_earnings

SELECT 
    product_category_name_english,
    ROUND(SUM(price), 0) AS Total_Price,
    ROUND(SUM(price) / (SELECT 
                    SUM(price)
                FROM
                    order_items) * 100,
            2) AS Percentage
FROM
    order_items
        INNER JOIN
    products ON products.product_id = order_items.product_id
        INNER JOIN
    product_category_name_translation ON product_category_name_translation.product_category_name = products.product_category_name
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
GROUP BY product_category_name_english
ORDER BY Percentage DESC;

-- ========================================================================================================================
-- Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?
-- Average monthly income of all sellers
SELECT 
    ROUND(SUM(oi.price) / TIMESTAMPDIFF(MONTH,
                MIN(o.order_purchase_timestamp),
                MAX(o.order_purchase_timestamp)),
            0) AS avg_monthly_income
FROM
    order_items oi
        LEFT JOIN
    orders o ON oi.order_id = o.order_id;
#answer: 590941 avg_monthly_income


-- Average monthly income of Tech sellers
SELECT 
    ROUND(SUM(oi.price) / TIMESTAMPDIFF(MONTH,
                MIN(o.order_purchase_timestamp),
                MAX(o.order_purchase_timestamp)),
            0) AS avg_monthly_tech_income
FROM
    order_items oi
        JOIN
    orders o ON oi.order_id = o.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');
# Answer: '125307' avg_monthly_tech_income
-- ========================================================================================================================
-- 3.3. In relation to the delivery time:
-- What’s the average time between the order being placed and the product being delivered?
-- How many orders are delivered on time vs orders delivered with a delay?
-- Is there any pattern for delayed orders, e.g. big products being delayed more often?

-- What’s the average time between the order being placed and the product being delivered?
SELECT 
    ROUND(AVG(DATEDIFF(order_delivered_customer_date,
                    order_purchase_timestamp)),
            2) AS avg_delivery_time
FROM
    orders
WHERE
    order_status = 'delivered'
        AND order_purchase_timestamp IS NOT NULL
        AND order_delivered_customer_date IS NOT NULL;
-- Answer: avg_delivery_time 12.50 days

-- How many orders are delivered on time vs orders delivered with a delay?
SELECT 
    COUNT(CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1
    END) AS on_time_deliveries,
    COUNT(CASE
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
    END) AS delayed_deliveries
FROM
    orders
WHERE
    order_delivered_customer_date IS NOT NULL
        AND order_estimated_delivery_date IS NOT NULL;
-- Answer:
-- on_time_deliveries 88649
-- delayed_deliveries 7827

    
  -- Is there any pattern for delayed orders, e.g., big products being delayed more often?
SELECT 
    CASE
        WHEN
            DATEDIFF(order_delivered_customer_date,
                    order_estimated_delivery_date) >= 30
        THEN
            '> 1 Month Delay'
        WHEN
            DATEDIFF(order_delivered_customer_date,
                    order_estimated_delivery_date) >= 14
        THEN
            '> 14 Day Delay'
        WHEN
            DATEDIFF(order_delivered_customer_date,
                    order_estimated_delivery_date) >= 7
        THEN
            '> 7 Day Delay'
        WHEN
            DATEDIFF(order_delivered_customer_date,
                    order_estimated_delivery_date) > 0
        THEN
            '1-7 Day Delay'
        ELSE 'On Time'
    END AS delay_category,
    COUNT(*) AS total_orders
FROM
    orders
WHERE
    order_delivered_customer_date IS NOT NULL
        AND DATEDIFF(order_delivered_customer_date,
            order_estimated_delivery_date) > 0
GROUP BY delay_category
ORDER BY delay_category DESC;
    
SELECT 
    CASE
        WHEN
            DATEDIFF(o.order_delivered_customer_date,
                    o.order_estimated_delivery_date) >= 180
        THEN
            '> 6 Month Delay'
        WHEN
            DATEDIFF(o.order_delivered_customer_date,
                    o.order_estimated_delivery_date) <= 30
        THEN
            '> 1 Month Delay'
        WHEN
            DATEDIFF(o.order_delivered_customer_date,
                    o.order_estimated_delivery_date) >= 14
        THEN
            '> 14 Day Delay'
        WHEN
            DATEDIFF(o.order_delivered_customer_date,
                    o.order_estimated_delivery_date) >= 7
        THEN
            '> 7 Day Delay'
        WHEN
            DATEDIFF(o.order_delivered_customer_date,
                    o.order_estimated_delivery_date) > 0
        THEN
            '1-7 Day Delay'
        ELSE 'On Time'
    END AS delay_category,
    COUNT(*) AS total_orders,
    AVG(p.product_weight_g) AS avg_product_weight_g,
    pct.product_category_name_english AS product_category
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    o.order_delivered_customer_date IS NOT NULL
        AND DATEDIFF(o.order_delivered_customer_date,
            o.order_estimated_delivery_date) > 0
GROUP BY delay_category , pct.product_category_name_english
ORDER BY delay_category DESC , total_orders DESC , avg_product_weight_g , product_category;

-- ====================================================================================================================================================================
SELECT DISTINCT
    p.product_weight_g AS product_weight_g,
    COUNT(DATEDIFF(o.order_delivered_customer_date,
            o.order_estimated_delivery_date)) AS days_delayed,
    COUNT(*) AS total_orders,
    pct.product_category_name_english AS product_category
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    o.order_delivered_customer_date IS NOT NULL
        AND DATEDIFF(o.order_delivered_customer_date,
            o.order_estimated_delivery_date) > 0
GROUP BY product_weight_g , pct.product_category_name_english
ORDER BY product_weight_g DESC , days_delayed , product_category;
-- ==================================================================================================================================================================
-- Count fo products, tech products and tech product percentage
SELECT 
    total_products,
    total_tech_products,
    ROUND((total_tech_products / total_products) * 100,
            2) AS percentage_tech_products
FROM
    (SELECT 
        COUNT(DISTINCT oi.product_id) AS total_products,
            (SELECT 
                    COUNT(DISTINCT oi_sub.product_id)
                FROM
                    order_items oi_sub
                JOIN products p_sub ON oi_sub.product_id = p_sub.product_id
                JOIN product_category_name_translation pct_sub ON p_sub.product_category_name = pct_sub.product_category_name
                WHERE
                    pct_sub.product_category_name_english IN ('audio' ,
                    'electronics',
                    'computers', 
                    'tablets_printing_image', 
                    'computers_accessories', 
                    'watches_gifts',
                    'telephony')) AS total_tech_products
    FROM
        order_items oi) AS counts;
-- answer total_products'32951',total_tech_products '4716', percentage_tech_products 14.3%
-- =========================================================================================================================

SELECT 
    ROUND(SUM(payment_value), 0) AS total_revenue
FROM
    order_payments;
-- Answer: '16008872' total_revenue
-- =========================================================================================================================
-- ##### TOTAL REVENUE FOR THIS PERIOD '2017-04-01'- '2018-04-01
SELECT 
    ROUND(SUM(op.payment_value), 0) AS total_revenue
FROM
    order_payments op
        JOIN
    orders o ON op.order_id = o.order_id
WHERE
    o.order_purchase_timestamp >= '2017-04-01'
        AND o.order_purchase_timestamp < '2018-04-01';
-- Answer: total_revenue '9636694' for this '2017-04-01'- '2018-04-01';

-- TOTAL TECH PRODUCTS REVENUE==============================================================================================
SELECT 
    ROUND(SUM(op.payment_value), 0) AS total_revenue_techprod
FROM
    order_payments op
        JOIN
    orders o ON op.order_id = o.order_id
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    pct.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');
-- Answer: 4110775 total_revenue_techprod

-- TOTAL TECH PRODUCTS REVENUE FOR THE THIS PERIOD '2017-04-01'- '2018-04-01===============================================
SELECT 
    ROUND(SUM(op.payment_value), 0) AS total_revenue_techprod
FROM
    order_payments op
        JOIN
    orders o ON op.order_id = o.order_id
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    pct.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
        AND o.order_purchase_timestamp >= '2017-04-01'
        AND o.order_purchase_timestamp < '2018-04-01';
-- Answer: total_revenue_techprod '2595989'

-- ======================================================================================================================== 
-- Total revenue,percentage from tech products
WITH tech_revenue AS (
    SELECT ROUND(SUM(op.payment_value), 0) AS total_revenue_techprod
    FROM order_payments op
    JOIN orders o ON op.order_id = o.order_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
    WHERE pct.product_category_name_english IN (
        'audio', 'electronics', 'computers', 'tablets_printing_image', 'computers_accessories', 'watches_gifts', 'telephony'
    )
    AND o.order_purchase_timestamp >= '2017-04-01'
    AND o.order_purchase_timestamp < '2018-04-01'
),

-- Total revenue from all products
total_revenue AS (
    SELECT ROUND(SUM(op.payment_value), 0) AS total_revenue_all
    FROM order_payments op
    JOIN orders o ON op.order_id = o.order_id
    WHERE o.order_purchase_timestamp >= '2017-04-01'
    AND o.order_purchase_timestamp < '2018-04-01'
)
-- Calculate percentage
SELECT 
    t.total_revenue_techprod,
    a.total_revenue_all,
    ROUND((t.total_revenue_techprod / a.total_revenue_all) * 100, 0) AS percentage_techprod
FROM 
    tech_revenue t,
    total_revenue a;
-- Answer total_revenue_techprod 2595989,total_revenue_all  9636694, percentage_techprod 27%

-- =========================================================================================================================
-- Avg order price
SELECT 
    ROUND(AVG(total_order_price), 2) AS avg_order_price
FROM
    (SELECT 
        o.order_id, SUM(oi.price) AS total_order_price
    FROM
        orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id) AS order_totals;
-- Answer avg_order_price 137.75

-- ========================================================================================================================
-- Avg.order price for tech products 
SELECT 
    ROUND(AVG(total_order_price), 2) AS avg_order_price_tech
FROM
    (SELECT 
        o.order_id, SUM(oi.price) AS total_order_price
    FROM
        orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
    WHERE
        pct.product_category_name_english IN ('audio' , 
        'electronics',
        'computers', 
        'tablets_printing_image', 
        'computers_accessories', 
        'watches_gifts',
        'telephony')
    GROUP BY o.order_id) AS order_totals;
-- answer avg_order_price_tech 146.69
-- ========================================================================================================================
-- avg monthly revenue for this period '2017-04-01'- '2018-04-01'
SELECT 
    YEAR(o.order_purchase_timestamp) AS order_year,
    MONTH(o.order_purchase_timestamp) AS order_month,
    ROUND(AVG(op.payment_value), 0) AS avg_monthly_revenue
FROM
    order_payments op
        JOIN
    orders o ON op.order_id = o.order_id
WHERE
    o.order_purchase_timestamp >= '2017-04-01'
        AND o.order_purchase_timestamp < '2018-04-01'
GROUP BY order_year , order_month
ORDER BY order_year , order_month;

-- avg_monthly_revenue '2017-04-01'- '2018-04-01'===========================================================================
SELECT 
    ROUND(AVG(monthly_revenue), 0) AS avg_monthly_revenue
FROM
    (SELECT 
        YEAR(o.order_purchase_timestamp) AS order_year,
            MONTH(o.order_purchase_timestamp) AS order_month,
            SUM(op.payment_value) AS monthly_revenue
    FROM
        order_payments op
    JOIN orders o ON op.order_id = o.order_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE
        o.order_purchase_timestamp >= '2017-04-01'
            AND o.order_purchase_timestamp < '2018-04-01'
    GROUP BY order_year , order_month) AS monthly_revenue_data;
-- answer avg_monthly_revenue '1024347'

-- ## avg monthly revenue for tech orders ===================================================================================================================================
SELECT 
    ROUND(AVG(monthly_revenue), 0) AS avg_monthly_revenue_techord
FROM
    (SELECT 
        YEAR(o.order_purchase_timestamp) AS order_year,
            MONTH(o.order_purchase_timestamp) AS order_month,
            SUM(op.payment_value) AS monthly_revenue
    FROM
        order_payments op
    JOIN orders o ON op.order_id = o.order_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
    WHERE
        pct.product_category_name_english IN ('audio' , 
        'electronics', 
        'computers', 
        'tablets_printing_image', 
        'computers_accessories', 
        'watches_gifts', 
        'telephony')
            AND o.order_purchase_timestamp >= '2017-04-01'
            AND o.order_purchase_timestamp < '2018-04-01'
    GROUP BY order_year , order_month) AS monthly_revenue_data;
-- answer: avg_monthly_revenue_techord '216332'

-- ## avg_techorder_price_------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
    ROUND(SUM(op.payment_value) / COUNT(DISTINCT o.order_id),
            0) AS avg_techorder_price_
FROM
    order_payments op
        JOIN
    orders o ON op.order_id = o.order_id
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    pct.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
        AND o.order_purchase_timestamp >= '2017-04-01'
        AND o.order_purchase_timestamp < '2018-04-01';
-- Answer avg_techorder_price '212'
-- ========================================================================================================================
-- avg_delivery_time_days
SELECT AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS avg_delivery_time_days
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL;
-- answer avg_delivery_time_days 12.50 days

-- avg_estimated_delivery_time
SELECT AVG(DATEDIFF(order_estimated_delivery_date, order_purchase_timestamp)) AS avg_estimated_delivery_time
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
 -- ======================================================================================================================== 
  
-- Customer Distribution by city and state
SELECT 
    city, state, COUNT(customer_id) AS num_customers
FROM
    customers c
        JOIN
    geo ON c.customer_zip_code_prefix = geo.zip_code_prefix
GROUP BY geo.city , geo.state
ORDER BY num_customers DESC;
-- ========================================================================================================================
-- Customer Preferences most trending products
SELECT 
    pct.product_category_name_english AS product_category_name,
    COUNT(oi.order_id) AS num_purchases
FROM
    order_items oi
        JOIN
    products p ON oi.product_id = p.product_id
        LEFT JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
GROUP BY pct.product_category_name_english
ORDER BY num_purchases DESC;
-- ========================================================================================================================
-- Most trending tech products
SELECT 
    pct.product_category_name_english AS product_category_name,
    COUNT(DISTINCT oi.order_id) AS num_purchases
FROM
    order_items oi
        JOIN
    products p ON oi.product_id = p.product_id
        LEFT JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
GROUP BY pct.product_category_name_english
ORDER BY num_purchases DESC;
-- ========================================================================================================================
-- Total and Avg Shipping Costs
SELECT 
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    ROUND(SUM(oi.freight_value), 0) AS total_shipping_cost,
    ROUND(AVG(oi.freight_value), 2) AS avg_shipping_cost
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    sellers s ON oi.seller_id = s.seller_id
        JOIN
    customers c ON o.customer_id = c.customer_id
        JOIN
    geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
        JOIN
    order_payments op ON o.order_id = op.order_id
        JOIN
    order_reviews orv ON o.order_id = orv.order_id
WHERE
    o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL;
-- ========================================================================================================================
-- Avg shipping costs for tech products
SELECT 
    ROUND(AVG(freight_value), 2) AS avg_shipping_cost_techprod
FROM
    order_items oi
        JOIN
    products ON oi.product_id = products.product_id
        JOIN
    product_category_name_translation ON products.product_category_name = product_category_name_translation.product_category_name
WHERE
    product_category_name_translation.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');
-- answer avg_shipping_cost_techprod 17.56
-- ========================================================================================================================
-- total shipping cost for tech products

SELECT 
    ROUND(SUM(freight_value), 0) AS shipping_cost_techprod
FROM
    order_items
        JOIN
    products ON order_items.product_id = products.product_id
        JOIN
    product_category_name_translation ON products.product_category_name = product_category_name_translation.product_category_name
WHERE
    product_category_name_translation.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');
-- Answer:shipping_cost_techprod 382421
-- ========================================================================================================================
-- 6 Payment Methods
SELECT 
    payment_type, COUNT(order_id) AS num_payments
FROM
    order_payments
GROUP BY payment_type
ORDER BY num_payments DESC;
-- answer
-- payment_type	num_payments
-- credit_card	76795
-- boleto	19784
-- voucher	5775
-- debit_card	1529
-- not_defined	3

SELECT 
    oi.order_id, oi.product_id, oi.price, op.payment_value
FROM
    order_items oi
        JOIN
    order_payments op ON oi.order_id = op.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    pct.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');

SELECT 
    p.product_id,
    COUNT(oi.order_id) AS units_sold,
    ROUND(SUM(op.payment_value), 2) AS total_payment_value,
    oi.price AS unit_price,
    SUM(oi.price) AS total_price,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_value
FROM
    order_items oi
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    order_payments op ON oi.order_id = op.order_id
WHERE
    p.product_id = '06ef141d37f22c5742e445504b5805a7'
GROUP BY p.product_id , oi.price;


SELECT 
    product_category_name_english,
    p.product_id,
    COUNT(oi.order_id) AS units_sold,
    ROUND(SUM(op.payment_value), 2) AS total_payment_value,
    oi.price AS unit_price,
    SUM(oi.price) AS total_price,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_value
FROM
    order_items oi
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
        JOIN
    order_payments op ON oi.order_id = op.order_id
WHERE
    pct.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
        AND p.product_id = '06ef141d37f22c5742e445504b5805a7'
GROUP BY p.product_id , oi.price;
-- =========================================================================================================================

SELECT 
    ROUND(AVG(review_score), 1) AS avg_review_score
FROM
    order_reviews;
-- avg_review_score 4.1

SELECT 
    ROUND(AVG(review_score), 2) AS avg_review_score_techprod
FROM
    order_reviews
        JOIN
    orders ON order_reviews.order_id = orders.order_id
        JOIN
    order_items ON orders.order_id = order_items.order_id
        JOIN
    products ON order_items.product_id = products.product_id
        JOIN
    product_category_name_translation ON products.product_category_name = product_category_name_translation.product_category_name
WHERE
    product_category_name_translation.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');
-- answer: avg_review_score_techprod is 3.97

SELECT 
    review_comment_message, review_score
FROM
    order_reviews
WHERE
    review_comment_message IS NOT NULL;

SELECT DISTINCT
    product_category_name_english,
    review_comment_message,
    review_score
FROM
    order_reviews
        JOIN
    orders ON order_reviews.order_id = orders.order_id
        JOIN
    order_items ON orders.order_id = order_items.order_id
        JOIN
    products ON order_items.product_id = products.product_id
        JOIN
    product_category_name_translation ON products.product_category_name = product_category_name_translation.product_category_name
WHERE
    review_comment_message IS NOT NULL
        AND product_category_name_translation.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');
-- ====================================================================================================================

SELECT 
    ROUND(AVG(TIMESTAMPDIFF(HOUR,
                review_creation_date,
                review_answer_timestamp)),
            2) AS avg_response_time
FROM
    order_reviews;
-- avg_response_time - 75.11 hours

SELECT 
    ROUND(AVG(TIMESTAMPDIFF(HOUR,
                review_creation_date,
                review_answer_timestamp)),
            2) AS avg_response_time_techorders
FROM
    order_reviews
        JOIN
    orders ON order_reviews.order_id = orders.order_id
        JOIN
    order_items ON orders.order_id = order_items.order_id
        JOIN
    products ON order_items.product_id = products.product_id
        JOIN
    product_category_name_translation ON products.product_category_name = product_category_name_translation.product_category_name
WHERE
    product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony');
-- answer avg_response_time_techorders 71.53 hour


SELECT 
    seller_id,
    COUNT(order_items.order_id) AS num_orders,
    AVG(order_reviews.review_score) AS avg_review_score
FROM
    order_items
        JOIN
    order_reviews ON order_items.order_id = order_reviews.order_id
GROUP BY order_items.seller_id
ORDER BY num_orders DESC;


SELECT DISTINCT
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS num_orders,
    AVG(orw.review_score) AS avg_review_score,
    product_category_name_english
FROM
    order_items oi
        JOIN
    order_reviews orw ON oi.order_id = orw.order_id
        JOIN
    orders o ON oi.order_id = o.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    pct.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
GROUP BY oi.seller_id , product_category_name_english
ORDER BY num_orders DESC;



SELECT 
    COUNT(DISTINCT order_items.order_id) AS num_sales,
    pct.product_category_name_english
FROM
    order_items
        JOIN
    products p ON order_items.product_id = p.product_id
        JOIN
    orders o ON order_items.order_id = o.order_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    pct.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
GROUP BY pct.product_category_name_english
ORDER BY num_sales DESC;

-- most expensive tech products
SELECT 
    p.product_id,
    product_category_name_english,
    MAX(oi.price) AS max_price_techproducts
FROM
    order_items oi
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    pct.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
GROUP BY p.product_id , product_category_name_english
ORDER BY max_price_techproducts DESC
LIMIT 10;

-- Product Returns and Complaints
SELECT 
    COUNT(o.order_id) AS return_count
FROM
    orders o
WHERE
    o.order_status = 'canceled'
ORDER BY return_count DESC;
-- return_count 625

SELECT 
    product_category_name_english,
    COUNT(o.order_id) AS return_count_tech
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        RIGHT JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE
    o.order_status = 'canceled'
        AND pct.product_category_name_english IN ('audio' , 'electronics',
        'computers',
        'tablets_printing_image',
        'computers_accessories',
        'watches_gifts',
        'telephony')
GROUP BY product_category_name_english
ORDER BY return_count_tech DESC , product_category_name_english;

