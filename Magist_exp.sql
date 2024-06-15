use magist;

select *
from orders;

-- 1. How many orders are there in the dataset? The orders table contains a row for each order, 
-- so this should be easy to find out!--
select count(distinct order_id) as total_orders from orders;
# answer: total orders are 99441
select count( order_id) as total_orders from order_items;
# answer: 112650
select count(distinct order_id) as t_order from order_items;
# answer: 98666



-- 2. Are orders actually delivered? Look at the columns in the orders table: one of them is called order_status. 
-- Most orders seem to be delivered, but some aren’t. Find out how many orders are delivered and how many are cancelled, 
-- unavailable, or in any other status by grouping and aggregating this column.
select 
    order_status, count(order_id) as order_status_count
from orders
group by order_status;
# Answers: delivered 96478,unavailable 609,shipped	1107,canceled	625,invoiced	314,processing 301,approved	2,created 5

select count(*) 
from orders 
where order_status = 'delivered';
# answer:delivered 96478

-- How many orders were delivered and how many undelivered: 
select 
    case
        when order_status = 'delivered' then 'delivered'
        else 'undelivered'
    end as delivery_status,
    count(*) as status_count
from orders
group by delivery_status;
# answer: delivered-96478
		-- undelivered-2963

-- 3. Is Magist having user growth? A platform losing users left and right isn’t going to be very useful 
-- to us. It would be a good idea to check for the number of orders grouped by year and month.
--  Tip: you can use the functions YEAR() and MONTH() to separate the year and the month of the order_purchase_timestamp.
select 
	year(order_purchase_timestamp) as year_,
	month(order_purchase_timestamp) as month_,
    count(customer_id) as nr_customers
from orders
group by year_,month_
order by year_,month_;

--- other way
select
    year_ord,
    month_ord,
    month_name,
    nr_customers
from (select
        year(order_purchase_timestamp) as year_ord,
        month(order_purchase_timestamp) as month_ord,
        date_format(order_purchase_timestamp, '%M') as month_name,
        count(customer_id) as nr_customers
    from orders
    group by year_ord, month_ord, month_name
) as subquery
order by year_ord, month_ord;




-- 4. How many products are there on the products table? (Make sure that there are no duplicate products.)
select count(distinct product_id) total_products
from products;
-- answer: 32951 products

-- 5. Which are the categories with the most products? Since this is an external database and has been partially 
-- anonymized, we do not have the names of the products. But we do know which categories products belong to. 
-- This is the closest we can get to knowing what sellers are offering in the Magist marketplace. By counting the 
-- rows in the products table and grouping them by categories, we will know how many products are offered in each category. 
-- This is not the same as how many products are actually sold by category. To acquire this insight we will have to combine 
-- multiple tables together: we’ll do this in the next lesson.
select product_category_name,
	count(distinct product_id) as nr_products
    from products
    group by product_category_name
    order by nr_products desc
    limit 10;

select product_category_name_english pt,
	count(distinct product_id) as nr_products
from products p
left join product_category_name_translation pt on p.product_category_name =pt.product_category_name
group by product_category_name_english
order by nr_products desc
limit 10;


    
-- 6. How many of those products were present in actual transactions? The products table is a “reference” of 
-- all the available products. Have all these products been involved in orders? Check out the order_items table to find out!
select count(distinct product_id) as nr_products
from order_items;
# answer: 32951
select count(distinct product_id) 
from products;
# answer:32951

-- orther option 
select count(distinct oi.product_id), count(distinct p.product_id)
from order_items oi
join products p 
using(product_id);

 # How many of those products were present in actual transactions? 
select product_category_name_translation.product_category_name_english, 
count(order_id) as order_quantity , 
(count(order_id) / (select count(*)  from order_items)*100) as percentage
from products
right join order_items
on products.product_id = order_items.product_id
join product_category_name_translation
on products.product_category_name = product_category_name_translation.product_category_name
where product_category_name_english in ('audio','consoles_games','electronics','pc_gamer','computers',
'tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony')
group by product_category_name_translation.product_category_name_english
order by count(order_id) desc; 

-- 7. what’s the price for the most expensive and cheapest products? Sometimes, having a broad range of prices is informative. 
-- Looking for the maximum and minimum values is also a good way to detect extreme outliers.
select
	max(price) as max_price,
    min(price) as min_price
from order_items;
# answer:  max_price 6735, min_price 0.85

select distinct product_id, price as max_min
from order_items
where price= (select max(price) from order_items) 
or price= (select min(price) from order_items);

-- other option 
select max(price) as max_and_min from order_items
union 
select min(price) from order_items;
(select product_id, price
from order_items
order by price asc
limit 1)
union
(select product_id, price
from order_items
order by price desc limit 1);

-- other option
select distinct pcnt.product_category_name_english , oi.price as min_max
from order_items oi 
join products p
    on p.product_id = oi.product_id 
    join product_category_name_translation pcnt on p.product_category_name = pcnt.product_category_name 
where price = (select min(price) as min_ from order_items oi) 
or 
price= (select max(price) as max_ from order_items oi);

-- 8. What are the highest and lowest payment values? Some orders contain multiple products. 
-- What’s the highest someone has paid for an order? Look at the order_payments table and try to find it out.
select
	max(payment_value) as highest_payment,
    min(payment_value) as lowest_payment
from order_payments;

select
	max(payment_value) as highest_payment,
    min(payment_value) as lowest_payment
from order_payments
where payment_value > 0;



select order_id,
    round(sum(payment_value),2) as highest_payment
from order_payments
group by order_id
order by highest_payment desc
limit 1;

-- total revenue
select round(sum(payment_value),0) as total_revenue
from order_payments;


#----------------------------------------------- Answer business questions ------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
-- 3.1. In relation to the products:
-- What categories of tech products does Magist have?
-- How many products of these tech categories have been sold (within the time window of the database snapshot)? What percentage does that represent from the overall number of products sold?
-- What’s the average price of the products being sold?
-- Are expensive tech products popular? *

select distinct product_category_name_english
from product_category_name_translation;

-- how many unique products_categories
select count(distinct product_category_name_english) as nr_prod_category
from product_category_name_translation;
# answer unique products 74 

-- -- What categories of products does Magist have?
select distinct product_category_name_english as nr_prod_category,
p.product_category_name
from products p
left join product_category_name_translation pt
on p.product_category_name = pt.product_category_name;

-- i have selected this tech categories 
-- 1. Audio
-- Products: Apple-compatible headphones, earphones, Bluetooth speakers, AirPods accessories.
-- Relevance: High demand among Apple users who prioritize quality audio experiences.
-- 2. Consoles & Games
-- Products: Game controllers, VR headsets compatible with iOS, Apple TV gaming accessories.
-- Relevance: Growing interest in mobile and home gaming, especially with Apple Arcade.
-- 3. Computers
-- Products: MacBook stands, cooling pads, docking stations, external monitors compatible with macOS.
-- Relevance: Essential for Apple users looking to enhance their productivity setups.
-- 4. PC Gamer
-- Products: High-performance gaming accessories that can be used with Mac devices.
-- Relevance: Appeals to a niche market of gamers who use Apple products.
-- 5. Electronics
-- Products: Smart home devices compatible with HomeKit, smartwatches, and other gadgets.
-- Relevance: Increasing adoption of smart home technology and wearables among Apple users.
-- 6. Computers Accessories
-- Products: Keyboards, mice, cables, adapters, protective cases, screen protectors for MacBooks and iPads.
-- Relevance: Core accessories necessary for enhancing the functionality and protection of Apple devices.
-- 7. Tablets, Printing & Image
-- Products: iPad cases, styluses, printers compatible with AirPrint, photo accessories.
-- Relevance: Essential for creative professionals and students who use iPads extensively.
-- Small Appliances
-- Products: Smart coffee makers, smart kitchen gadgets, smart air purifiers, robotic vacuums, and other small appliances that can be controlled via iOS apps or Apple HomeKit.
-- Relevance: Increasing interest in smart home integration and convenience. Apple users often seek appliances that can be controlled via their iPhone or iPad.
-- Watches & Gifts
-- Products: Smartwatches, Apple Watch accessories, luxury pens, tech gadgets, and gift sets.
-- Relevance: Appeals to tech-savvy consumers and Apple enthusiasts who are likely to invest in high-quality accessories and gifts that enhance their Apple experience.
select 
	distinct(product_category_name_english) as Tech_category_name
from products p
left join product_category_name_translation pt on p.product_category_name = pt.product_category_name
where product_category_name_english 
		in ('audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony');


-- How many products of these tech categories have been sold (within the time window of the database snapshot)?
-- Total products sold
select count(distinct order_id) as total_products_sold
from order_items;
# answer: total '98666'  products sold 

-- Tech products sold
select count(distinct order_id) as tech_products_sold
from order_items oi
join products p on oi.product_id = p.product_id
join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where product_category_name_english 
		in ('audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony');
# answer: '21344' tech_products_sold

select 
    (select count(distinct order_id) from order_items) as total_products_sold,
    (select count(distinct order_id)
     from order_items oi
     join products p on oi.product_id = p.product_id
     join product_category_name_translation pct on p.product_category_name = pct.product_category_name
     where product_category_name_english in ('audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony')
    ) as tech_products_sold;

-- Percentage of tech products sold
select round((tech_products_sold / total_products_sold) * 100,2) as tech_products_percentage
from 
    (select count(distinct order_id) as tech_products_sold
        from order_items oi
        join products p on oi.product_id = p.product_id
        join product_category_name_translation pct on p.product_category_name = pct.product_category_name
        where product_category_name_english 
            in ('audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony')
    ) as tech,
    (select count(*) as total_products_sold
        from order_items) as total;
# answer: '18.95' % tech_products_sold

-- What’s the average price of the products being sold?
select round(avg(price),2) as average_price
from order_items oi
join products p on oi.product_id = p.product_id;
# answer: 120.65 average_price

select round(avg(price),2) as average_price_techproduct
from order_items oi
join products p on oi.product_id = p.product_id
join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where product_category_name_english in ('audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image',
'computers_accessories','small_appliances','watches_gifts','telephony');
-- answer average_price_techproduct '136.91'


-- Are expensive tech products popular?
select
    case
        when oi.price > 1000 then 'Expensive'
        else 'Affordable'
    end as price_category,
    count(*) as product_count
from order_items oi
left join products p on oi.product_id = p.product_id
left join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where product_category_name_english 
            in ('audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony')
group by price_category;
# answer 'Affordable' 23288, 'Expensive' 317.


-- 3.2. In relation to the sellers:
-- How many months of data are included in the magist database?
-- How many sellers are there? How many Tech sellers are there? What percentage of overall sellers are Tech sellers?
-- What is the total amount earned by all sellers? What is the total amount earned by all Tech sellers?
-- Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?

-- first and last order date
select min(order_purchase_timestamp) as earliest_date, 
		max(order_purchase_timestamp) as latest_date
from orders;
# answer: earliest_date-'2016-09-04 23:15:19'/latest_date-'2018-10-17 19:30:18'

-- How many months of data are included in the Magist database?
select 
timestampdiff(month, min(order_purchase_timestamp), 
max(order_purchase_timestamp)) as months_of_data
from orders;
# answer 25 months

-- How many sellers are there? How many Tech sellers are there? What percentage of overall sellers are Tech sellers?

-- Total sellers
select count(distinct seller_id) as total_sellers
from sellers;
# answer: 3095 total_sellers

-- Tech sellers
select count(distinct s.seller_id) as tech_sellers
from sellers s
join order_items oi on s.seller_id = oi.seller_id
join products p on oi.product_id = p.product_id
join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where product_category_name_english 
in ('audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image',
'computers_accessories','small_appliances','watches_gifts','telephony');
# answer : 616 tech_sellers.

-- number of tech sellers per product category
select product_category_name_english, count(distinct seller_id) as nr_tech_selllers_by_category
from order_items
inner join products 
on products.product_id=order_items.product_id
inner join product_category_name_translation 
on product_category_name_translation.product_category_name=products.product_category_name 
where product_category_name_english in ('audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony')
group by product_category_name_english
order by nr_tech_selllers_by_category desc;


-- Percentage of tech sellers
select  round((tech_sellers / total_sellers) * 100,2) as tech_sellers_percentage
from (select count(distinct s.seller_id) as tech_sellers
    from sellers s
    join order_items oi on s.seller_id = oi.seller_id
    join products p on oi.product_id = p.product_id
	join product_category_name_translation pct on p.product_category_name = pct.product_category_name
    where product_category_name_english 
            in ('audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony')
) as tech,
(select count(*) as total_sellers
    from sellers) as total;
#answer:19.90 % tech sellers.

-- What is the total amount earned by all sellers? What is the total amount earned by all Tech sellers?
-- Total amount earned by all sellers
select round(sum( price),0) as total_earnings
from order_items;
#answer :  13591644 total_earnings

-- Total amount earned per month by all sellers
select 
    year(order_purchase_timestamp) as order_year,
    month(order_purchase_timestamp) as order_month,
    round(sum(oi.price), 2) as monthly_income
from order_items oi
join orders o on oi.order_id = o.order_id
group by order_year, order_month
order by order_year;

-- Total amount earned per month by tech sellers
select 
    year(o.order_purchase_timestamp) as order_year,
    month(o.order_purchase_timestamp) as order_month,
    round(sum(oi.price), 2) as monthly_income
from order_items oi
left join orders o on oi.order_id = o.order_id
left join products p on oi.product_id = p.product_id
left join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where pct.product_category_name_english in ('audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony')
group by order_year, order_month
order by order_year;


-- Total amount earned by Tech sellers
select round(sum( oi.price),0) as tech_earnings
from order_items oi
join products p on oi.product_id = p.product_id
join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where product_category_name_english 
in ('audio','consoles_games','electronics','pc_gamer','computers','
tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony');
# answer: 32231714  tech_earnings

SELECT 
    product_category_name_english,
    ROUND(SUM(price), 0) AS Total_Price,
    ROUND(SUM(price) / (SELECT SUM(price) FROM order_items) * 100, 2) AS Percentage 
FROM order_items
INNER JOIN products ON products.product_id = order_items.product_id
INNER JOIN product_category_name_translation ON product_category_name_translation.product_category_name = products.product_category_name 
WHERE product_category_name_english IN ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony')
GROUP BY product_category_name_english
order  by Percentage desc;


-- Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?
-- Average monthly income of all sellers
select round(sum(oi.price) / timestampdiff(month, min(o.order_purchase_timestamp), max(o.order_purchase_timestamp)),0) as avg_monthly_income
from order_items oi
left join orders o on oi.order_id = o.order_id;
#answer: 590941 avg_monthly_income


-- Average monthly income of Tech sellers
select round(sum(oi.price) / timestampdiff(month, min(o.order_purchase_timestamp), max(o.order_purchase_timestamp)),0) as avg_monthly_tech_income
from order_items oi
join orders o on oi.order_id = o.order_id
join products p on oi.product_id = p.product_id
join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where product_category_name_english 
            in ('audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony');
# answer: 140509 avg_monthly_tech_income

-- 3.3. In relation to the delivery time:
-- What’s the average time between the order being placed and the product being delivered?
-- How many orders are delivered on time vs orders delivered with a delay?
-- Is there any pattern for delayed orders, e.g. big products being delayed more often?

-- 1. What’s the average time between the order being placed and the product being delivered?
select avg(datediff(order_delivered_customer_date, order_purchase_timestamp))as avg_delivery_time
from orders;


-- 2. How many orders are delivered on time vs orders delivered with a delay?
SELECT 
    COUNT(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 END) AS on_time_deliveries,
    COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END) AS delayed_deliveries
FROM  orders
where order_delivered_customer_date is not null and order_estimated_delivery_date is not null;

    
  -- 3. is there any pattern for delayed orders, e.g., big products being delayed more often?
SELECT
    CASE 
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) >= 30 THEN '> 1 Month Delay'
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) >= 14 THEN '> 14 Day Delay'
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) >= 7 THEN '> 7 Day Delay'
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) > 0 THEN '1-7 Day Delay'
        ELSE 'On Time'
    END AS delay_category,
    COUNT(*) AS total_orders
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
AND DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) > 0
GROUP BY delay_category
ORDER BY delay_category DESC;
    
SELECT
    CASE 
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) >= 180 THEN '> 6 Month Delay'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) <= 30 THEN '> 1 Month Delay'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) >= 14 THEN '> 14 Day Delay'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) >= 7 THEN '> 7 Day Delay'
        WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0 THEN '1-7 Day Delay'
        ELSE 'On Time'
    END AS delay_category,
    COUNT(*) AS total_orders,
    AVG(p.product_weight_g) AS avg_product_weight_g,
    pct.product_category_name_english AS product_category
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE o.order_delivered_customer_date IS NOT NULL
    AND DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0
GROUP BY delay_category, pct.product_category_name_english
ORDER BY delay_category DESC, total_orders DESC, avg_product_weight_g, product_category;


select
    p.product_weight_g  as product_weight_g,
    datediff(o.order_estimated_delivery_date, o.order_delivered_customer_date) as days_delayed,
    count(*) as total_orders,
    pct.product_category_name_english as product_category
from orders o
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where o.order_delivered_customer_date is not null
    and datediff(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0
group by product_weight_g , days_delayed, pct.product_category_name_english
order by  product_weight_g desc,days_delayed,product_category;

SELECT round(SUM(payment_value),0) AS total_revenue
FROM order_payments;
-- '16008872' total_revenue

SELECT round(SUM(op.payment_value),0) AS total_tech_order_revenue
FROM order_payments op
JOIN order_items oi ON op.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE pct.product_category_name_english IN (
    'audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony');
--  total_tech_order_revenue '4534015'

SELECT
    p.product_weight_g AS product_weight_g,
    DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date) AS days_delayed,
    COUNT(*) AS total_orders,
    pct.product_category_name_english AS product_category
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE o.order_delivered_customer_date IS NOT NULL
    AND DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0
    AND pct.product_category_name_english IN (
        'audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony')
GROUP BY p.product_weight_g, days_delayed, pct.product_category_name_english
ORDER BY  p.product_weight_g DESC, days_delayed, product_category;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# -- Customer Analysis
-- 1 Customer Distribution by city and state
select city, state, count(customer_id) as num_customers
from customers c
join geo on c.customer_zip_code_prefix = geo.zip_code_prefix
group by geo.city, geo.state
order by num_customers desc;

-- 2 Customer Preferences most trending products
 select pct.product_category_name_english as product_category_name,
    count(oi.order_id) as num_purchases
from order_items oi
join products p on oi.product_id = p.product_id
left join product_category_name_translation pct on p.product_category_name = pct.product_category_name
group by pct.product_category_name_english
order by num_purchases desc;

-- most trending tech products
select pct.product_category_name_english as product_category_name,
    count(oi.order_id) as num_purchases
from order_items oi
join products p on oi.product_id = p.product_id
left join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where product_category_name_english 
		in ('audio','consoles_games','electronics','pc_gamer','computers','tablets_printing_image','computers_accessories','small_appliances','watches_gifts','telephony')
group by pct.product_category_name_english
order by num_purchases desc;


#--Order Analysis
-- 3 Order Volume and Frequency
select count(order_id) as total_orders
from orders;
-- answer 99441 total_orders

-- 4 Order Fulfillment and Delivery
select round(avg(timestampdiff(day, order_purchase_timestamp, order_delivered_customer_date)),2) as avg_delivery_time
from orders
where order_status = 'delivered';
-- answer 12.10 is avg_delivery_time

-- 5 Shipping Costs
select round(avg(freight_value),2) as avg_shipping_cost
from order_items;
-- answer avg_shipping_cost '19.99'


select round(avg(freight_value), 2) as avg_shipping_cost_techprod
from order_items oi
join products on oi.product_id = products.product_id
join product_category_name_translation on products.product_category_name = product_category_name_translation.product_category_name
where product_category_name_translation.product_category_name_english in ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 
'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony');
-- answer avg_shipping_cost_techprod 17.73

select round(sum(freight_value), 0) as shipping_cost_techprod
from order_items
join products on order_items.product_id = products.product_id
join product_category_name_translation on products.product_category_name = product_category_name_translation.product_category_name
where product_category_name_translation.product_category_name_english in ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 
'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony');
-- answer '418402.9'

select round(sum(freight_value),0) as shipping_cost
from order_items;
-- '2251909.54'

#-- Payment Analysis
-- 6 Payment Methods
select payment_type, count(order_id) as num_payments
from order_payments
group by payment_type
order by num_payments desc;
-- answer
-- payment_type	num_payments
-- credit_card	76795
-- boleto	19784
-- voucher	5775
-- debit_card	1529
-- not_defined	3


-- 7 Payment Installments
select round(avg(payment_installments),2) as avg_installments
from order_payments;
-- answer avg_installments is  2.85'


#-- Review and Customer Satisfaction Analysis
-- 8 Review Scores
select round(avg(review_score),1) as avg_review_score
from order_reviews;
-- avg_review_score 4.1

select round(avg(review_score),2) as avg_review_score_techprod
from order_reviews
join orders on order_reviews.order_id = orders.order_id
join order_items on orders.order_id = order_items.order_id
join products on order_items.product_id = products.product_id
join product_category_name_translation on products.product_category_name = product_category_name_translation.product_category_name
where product_category_name_translation.product_category_name_english in ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 
'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony');
-- answer: avg_review_score_techprod is 3.97



select review_comment_message, review_score
from order_reviews
where review_comment_message is not null;


select distinct product_category_name_english,
	review_comment_message, 
	review_score
from order_reviews
join orders on order_reviews.order_id = orders.order_id
join order_items on orders.order_id = order_items.order_id
join products on order_items.product_id = products.product_id
join product_category_name_translation on products.product_category_name = product_category_name_translation.product_category_name
where review_comment_message is not null and product_category_name_translation.product_category_name_english in ('audio', 'consoles_games', 'electronics', 
'pc_gamer', 'computers', 'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony');


-- 10 Response Time
select round(avg(timestampdiff(hour,review_creation_date,review_answer_timestamp)),2) as avg_response_time
from order_reviews;
-- avg_response_time - 75.11 hours

select round(avg(timestampdiff(hour,review_creation_date, review_answer_timestamp)),2) as avg_response_time_techorders
from order_reviews
join orders on order_reviews.order_id = orders.order_id
join order_items on orders.order_id = order_items.order_id
join products on order_items.product_id = products.product_id
join product_category_name_translation on products.product_category_name = product_category_name_translation.product_category_name
where product_category_name_english in ('audio', 'consoles_games', 'electronics', 
'pc_gamer', 'computers', 'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony');
-- answer avg_response_time_techorders 71.51 hour


# -- Seller Performance
-- 11 Seller Analysis
select seller_id, count(order_items.order_id) as num_orders, avg(order_reviews.review_score) as avg_review_score
from order_items
join order_reviews on order_items.order_id = order_reviews.order_id
group by order_items.seller_id
order by num_orders desc;


select distinct oi.seller_id, 
    count(oi.order_id) as num_orders, 
    avg(orw.review_score) as avg_review_score,
    product_category_name_english
from order_items oi 
join order_reviews orw on oi.order_id = orw.order_id 
join orders o on oi.order_id = o.order_id 
join products p on oi.product_id = p.product_id 
join product_category_name_translation pct on p.product_category_name = pct.product_category_name 
where pct.product_category_name_english in ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 
'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony') 
group by oi.seller_id,product_category_name_english 
order by num_orders desc;



# -- Product Performance
-- 12 Product Popularity
select 
    count(  order_items.order_id) as num_sales,
    pct.product_category_name_english
from order_items 
join products p on order_items.product_id = p.product_id 
join orders o on order_items.order_id = o.order_id  
join product_category_name_translation pct on p.product_category_name = pct.product_category_name  
where pct.product_category_name_english in ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 
'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony')  
group by pct.product_category_name_english
order by num_sales desc;

select price,
    count(order_items.order_id) as num_sales,
    pct.product_category_name_english
from order_items 
join products p on order_items.product_id = p.product_id 
join orders o on order_items.order_id = o.order_id  
join product_category_name_translation pct on p.product_category_name = pct.product_category_name  
where pct.product_category_name_english in ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony')  
group by pct.product_category_name_english,price
order by price desc;

-- most expensive tech products
select p.product_id, product_category_name_english,
    max(oi.price) as max_price_techproducts
from order_items oi
join products p on oi.product_id = p.product_id
join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where pct.product_category_name_english in ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony')
group by p.product_id, product_category_name_english
order by max_price_techproducts desc
limit 10;

-- Most expensive tech products with number of sales
select 
    p.product_id, 
    pct.product_category_name_english,
    count(distinct oi.order_id) as num_sales,
    max(oi.price) as max_price_techproducts
from order_items oi
join products p on oi.product_id = p.product_id
join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where pct.product_category_name_english in ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony')
group by p.product_id, pct.product_category_name_english
order by max_price_techproducts desc;


select count( distinct order_id) as total_nr_orders,
    round(sum(payment_value),1) as total_payment_value
    from order_payments;
-- answer total_nr_orders '99440', total_payment_value'16008872.1'

select 
    count(distinct op.order_id) as order_count,
    round(sum(op.payment_value), 1) as total_payment_value_techproducts
from order_payments op
join order_items oi on op.order_id = oi.order_id
join products p on oi.product_id = p.product_id
join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where pct.product_category_name_english in ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 
    'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony');
-- answer order_count '21344', total_payment_value_techproducts '4534014.6'
    

-- 13 Product Returns and Complaints
select 
    count(o.order_id) as return_count
from orders o
where o.order_status = 'canceled'  -- Assuming 'canceled' indicates a return
order by return_count desc;
-- return_count 625


select product_category_name_english,
    count(o.order_id) as return_count_tech
from orders o
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
right join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where o.order_status = 'canceled' and pct.product_category_name_english in ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony') -- Assuming 'canceled' indicates a return 
group by product_category_name_english
order by return_count_tech desc,product_category_name_english;


-- Geographic Challenges
select distinct city, state, 
round(avg(timestampdiff(day, orders.order_purchase_timestamp, orders.order_delivered_customer_date)),2) as avg_delivery_time
from orders
join customers on orders.customer_id = customers.customer_id
join geo on customers.customer_zip_code_prefix = geo.zip_code_prefix
where orders.order_status = 'delivered'
group by geo.city, geo.state
order by avg_delivery_time desc;

#-- Financial Analysis
-- 15 Revenue and Costs
select round(sum(order_items.price),2) as total_revenue,
 round(sum(order_items.freight_value),2) as total_shipping_cost
from order_items;

select 
    round(sum(oi.price), 0) as total_revenue_tech, 
    round(sum(oi.freight_value), 0) as total_shipping_cost_tech
from order_items oi
left join products p on oi.product_id = p.product_id
left join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where pct.product_category_name_english in ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 
'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony');



# -- Partnership Evaluation
-- 16 Delivery Performance
select avg(timestampdiff(day, orders.order_purchase_timestamp, orders.order_delivered_customer_date)) as avg_delivery_time
from orders
where orders.order_status = 'delivered';

-- 17 Customer Satisfaction
select round(avg(order_reviews.review_score),2) as avg_review_score
from order_reviews;


-- Cost-Benefit Analysis
select round(sum(order_items.price),2) as total_revenue, 
round(sum(order_items.freight_value),2) as total_shipping_cost, 
round(avg(order_reviews.review_score),2) as avg_review_score
from order_items
join orders on order_items.order_id = orders.order_id
join order_reviews on orders.order_id = order_reviews.order_id;
-- answer total_revenue '13477018.99',total_shipping_cost '2228735.69',avg_review_score '4.02'



select 
    round(sum(order_items.price), 2) as total_revenue_techprod, 
    round(sum(order_items.freight_value), 2) as total_shipping_cost_techprod, 
    round(avg(order_reviews.review_score), 2) as avg_review_score_techprodud
from order_items
join orders on order_items.order_id = orders.order_id
join order_reviews on orders.order_id = order_reviews.order_id
left join products p on order_items.product_id = p.product_id
left join product_category_name_translation pct on p.product_category_name = pct.product_category_name
where pct.product_category_name_english in ('audio', 'consoles_games', 'electronics', 'pc_gamer', 'computers', 
    'tablets_printing_image', 'computers_accessories', 'small_appliances', 'watches_gifts', 'telephony');
-- answer total_revenue_techprod '3213237.06'',total_shipping_cost_techprod '415819.93'',avg_review_score_techprodud ''3.97''.

