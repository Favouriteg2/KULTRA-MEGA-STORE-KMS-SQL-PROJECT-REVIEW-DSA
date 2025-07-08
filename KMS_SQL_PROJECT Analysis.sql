-- KMS Business Intelligence Analysis - SQL Solutions
-- Kultra Mega Stores Data Analysis (2009-2012)
-- Author: Business Intelligence Analyst
-- Date: July 2025

-- Note: This script assumes the data is loaded into a table called 'kms_orders'
-- Table structure based on the CSV file columns

/*
Table: kms_orders
Columns:
- row_id, order_id, order_date, order_priority, order_quantity
- sales, discount, ship_mode, profit, unit_price, shipping_cost
- customer_name, province, region, customer_segment
- product_category, product_sub_category, product_name
- product_container, product_base_margin, ship_date
*/

-- =============================================================================
-- CASE SCENARIO I - SQL SOLUTIONS
-- =============================================================================

-- Question 1: Which product category had the highest sales?
-- =============================================================================
SELECT 
    product_category,
    ROUND(SUM(sales), 2) as total_sales,
    COUNT(*) as order_count,
    ROUND(AVG(sales), 2) as avg_order_value
FROM kms_orders
GROUP BY product_category
ORDER BY total_sales DESC;

-- Answer verification query
SELECT 
    product_category,
    CONCAT('$', FORMAT(SUM(sales), 2)) as formatted_sales
FROM kms_orders
GROUP BY product_category
ORDER BY SUM(sales) DESC
LIMIT 1;

-- Question 2: Top 3 and Bottom 3 regions in terms of sales
-- =============================================================================

-- Top 3 regions
SELECT 
    region,
    ROUND(SUM(sales), 2) as total_sales,
    COUNT(DISTINCT order_id) as total_orders,
    COUNT(DISTINCT customer_name) as unique_customers,
    'TOP 3' as category
FROM kms_orders
GROUP BY region
ORDER BY total_sales DESC
LIMIT 3;

-- Bottom 3 regions
SELECT 
    region,
    ROUND(SUM(sales), 2) as total_sales,
    COUNT(DISTINCT order_id) as total_orders,
    COUNT(DISTINCT customer_name) as unique_customers,
    'BOTTOM 3' as category
FROM kms_orders
GROUP BY region
ORDER BY total_sales ASC
LIMIT 3;

-- Combined query for Top 3 and Bottom 3
WITH regional_sales AS (
    SELECT 
        region,
        ROUND(SUM(sales), 2) as total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(sales) DESC) as sales_rank_desc,
        ROW_NUMBER() OVER (ORDER BY SUM(sales) ASC) as sales_rank_asc,
        COUNT(DISTINCT order_id) as total_orders
    FROM kms_orders
    GROUP BY region
),
top_bottom AS (
    SELECT region, total_sales, total_orders, 'TOP 3' as category
    FROM regional_sales 
    WHERE sales_rank_desc <= 3
    
    UNION ALL
    
    SELECT region, total_sales, total_orders, 'BOTTOM 3' as category
    FROM regional_sales 
    WHERE sales_rank_asc <= 3
)
SELECT * FROM top_bottom
ORDER BY category DESC, total_sales DESC;

-- Question 3: Total sales of appliances in Ontario
-- =============================================================================
SELECT 
    region,
    product_sub_category,
    ROUND(SUM(sales), 2) as total_sales,
    COUNT(*) as order_count,
    ROUND(AVG(sales), 2) as avg_order_value,
    COUNT(DISTINCT customer_name) as unique_customers
FROM kms_orders
WHERE region = 'Ontario' 
    AND product_sub_category = 'Appliances'
GROUP BY region, product_sub_category;

-- Top appliances in Ontario by sales
SELECT 
    product_name,
    ROUND(SUM(sales), 2) as total_sales,
    COUNT(*) as order_count,
    ROUND(AVG(sales), 2) as avg_order_value
FROM kms_orders
WHERE region = 'Ontario' 
    AND product_sub_category = 'Appliances'
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 5;

-- Question 4: Bottom 10 customers analysis and recommendations
-- =============================================================================

-- Bottom 10 customers by sales
WITH customer_analysis AS (
    SELECT 
        customer_name,
        customer_segment,
        ROUND(SUM(sales), 2) as total_sales,
        ROUND(SUM(profit), 2) as total_profit,
        COUNT(DISTINCT order_id) as order_count,
        SUM(order_quantity) as total_quantity,
        ROUND(AVG(sales), 2) as avg_order_value
    FROM kms_orders
    GROUP BY customer_name, customer_segment
    ORDER BY total_sales ASC
    LIMIT 10
)
SELECT 
    customer_name,
    customer_segment,
    total_sales,
    total_profit,
    order_count,
    avg_order_value,
    CASE 
        WHEN total_profit < 0 THEN 'Loss-making customer'
        WHEN order_count = 1 THEN 'One-time buyer'
        WHEN avg_order_value < 100 THEN 'Low-value orders'
        ELSE 'Growth opportunity'
    END as customer_status
FROM customer_analysis;

-- Purchase patterns of bottom 10 customers
WITH bottom_customers AS (
    SELECT customer_name
    FROM (
        SELECT customer_name, SUM(sales) as total_sales
        FROM kms_orders
        GROUP BY customer_name
        ORDER BY total_sales ASC
        LIMIT 10
    ) b
)
SELECT 
    o.customer_segment,
    o.product_category,
    COUNT(*) as order_count,
    ROUND(SUM(o.sales), 2) as total_sales,
    ROUND(AVG(o.sales), 2) as avg_order_value
FROM kms_orders o
INNER JOIN bottom_customers bc ON o.customer_name = bc.customer_name
GROUP BY o.customer_segment, o.product_category
ORDER BY total_sales DESC;

-- Question 5: Shipping method with highest shipping cost
-- =============================================================================
SELECT 
    ship_mode,
    ROUND(SUM(shipping_cost), 2) as total_shipping_cost,
    ROUND(AVG(shipping_cost), 2) as avg_shipping_cost,
    COUNT(*) as order_count,
    ROUND(SUM(sales), 2) as total_sales,
    ROUND((SUM(shipping_cost) / SUM(sales)) * 100, 2) as shipping_cost_percentage
FROM kms_orders
GROUP BY ship_mode
ORDER BY total_shipping_cost DESC;

-- Shipping cost efficiency analysis
SELECT 
    ship_mode,
    ROUND(SUM(shipping_cost), 2) as total_cost,
    COUNT(*) as orders,
    ROUND(AVG(shipping_cost), 2) as avg_cost_per_order,
    ROUND(SUM(shipping_cost) / COUNT(*), 2) as cost_efficiency_ratio
FROM kms_orders
GROUP BY ship_mode
ORDER BY total_cost DESC;

-- =============================================================================
-- CASE SCENARIO II - SQL SOLUTIONS
-- =============================================================================

-- Question 6: Most valuable customers and their purchase patterns
-- =============================================================================

-- Top 10 most valuable customers by sales
WITH customer_metrics AS (
    SELECT 
        customer_name,
        customer_segment,
        ROUND(SUM(sales), 2) as total_sales,
        ROUND(SUM(profit), 2) as total_profit,
        COUNT(DISTINCT order_id) as order_count,
        SUM(order_quantity) as total_quantity,
        ROUND(AVG(sales), 2) as avg_order_value,
        ROUND((SUM(profit) / SUM(sales)) * 100, 2) as profit_margin,
        MIN(order_date) as first_order,
        MAX(order_date) as last_order
    FROM kms_orders
    GROUP BY customer_name, customer_segment
)
SELECT 
    customer_name,
    customer_segment,
    total_sales,
    total_profit,
    order_count,
    avg_order_value,
    profit_margin,
    DATEDIFF(last_order, first_order) as customer_lifespan_days
FROM customer_metrics
ORDER BY total_sales DESC
LIMIT 10;

-- Purchase patterns of top customers
WITH top_customers AS (
    SELECT customer_name
    FROM (
        SELECT customer_name, SUM(sales) as total_sales
        FROM kms_orders
        GROUP BY customer_name
        ORDER BY total_sales DESC
        LIMIT 10
    ) t
)
SELECT 
    o.product_category,
    COUNT(*) as order_count,
    ROUND(SUM(o.sales), 2) as total_sales,
    ROUND(AVG(o.sales), 2) as avg_order_value,
    COUNT(DISTINCT o.customer_name) as customer_count
FROM kms_orders o
INNER JOIN top_customers tc ON o.customer_name = tc.customer_name
GROUP BY o.product_category
ORDER BY total_sales DESC;

-- Question 7: Small business customer with highest sales
-- =============================================================================
SELECT 
    customer_name,
    ROUND(SUM(sales), 2) as total_sales,
    ROUND(SUM(profit), 2) as total_profit,
    COUNT(DISTINCT order_id) as order_count,
    ROUND(AVG(sales), 2) as avg_order_value,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) as profit_margin
FROM kms_orders
WHERE customer_segment = 'Small Business'
GROUP BY customer_name
ORDER BY total_sales DESC
LIMIT 1;

-- Top 5 small business customers
SELECT 
    customer_name,
    ROUND(SUM(sales), 2) as total_sales,
    ROUND(SUM(profit), 2) as total_profit,
    COUNT(DISTINCT order_id) as order_count
FROM kms_orders
WHERE customer_segment = 'Small Business'
GROUP BY customer_name
ORDER BY total_sales DESC
LIMIT 5;

-- Purchase breakdown for top small business customer
WITH top_sb_customer AS (
    SELECT customer_name
    FROM kms_orders
    WHERE customer_segment = 'Small Business'
    GROUP BY customer_name
    ORDER BY SUM(sales) DESC
    LIMIT 1
)
SELECT 
    o.product_category,
    ROUND(SUM(o.sales), 2) as category_sales,
    COUNT(*) as order_count,
    ROUND(AVG(o.sales), 2) as avg_order_value
FROM kms_orders o
INNER JOIN top_sb_customer t ON o.customer_name = t.customer_name
GROUP BY o.product_category
ORDER BY category_sales DESC;

-- Question 8: Corporate customer with most orders (2009-2012)
-- =============================================================================
SELECT 
    customer_name,
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(SUM(sales), 2) as total_sales,
    ROUND(SUM(profit), 2) as total_profit,
    MIN(YEAR(order_date)) as first_year,
    MAX(YEAR(order_date)) as last_year
FROM kms_orders
WHERE customer_segment = 'Corporate'
    AND YEAR(order_date) BETWEEN 2009 AND 2012
GROUP BY customer_name
ORDER BY total_orders DESC
LIMIT 1;

-- Top 5 corporate customers by order count
SELECT 
    customer_name,
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(SUM(sales), 2) as total_sales,
    ROUND(SUM(profit), 2) as total_profit
FROM kms_orders
WHERE customer_segment = 'Corporate'
    AND YEAR(order_date) BETWEEN 2009 AND 2012
GROUP BY customer_name
ORDER BY total_orders DESC
LIMIT 5;

-- Yearly breakdown for top corporate customer
WITH top_corporate AS (
    SELECT customer_name
    FROM kms_orders
    WHERE customer_segment = 'Corporate'
    GROUP BY customer_name
    ORDER BY COUNT(DISTINCT order_id) DESC
    LIMIT 1
)
SELECT 
    YEAR(o.order_date) as order_year,
    COUNT(DISTINCT o.order_id) as orders_per_year,
    ROUND(SUM(o.sales), 2) as sales_per_year
FROM kms_orders o
INNER JOIN top_corporate t ON o.customer_name = t.customer_name
GROUP BY YEAR(o.order_date)
ORDER BY order_year;

-- Question 9: Most profitable consumer customer
-- =============================================================================
SELECT 
    customer_name,
    ROUND(SUM(profit), 2) as total_profit,
    ROUND(SUM(sales), 2) as total_sales,
    COUNT(DISTINCT order_id) as order_count,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) as profit_margin,
    ROUND(AVG(sales), 2) as avg_order_value
FROM kms_orders
WHERE customer_segment = 'Consumer'
GROUP BY customer_name
ORDER BY total_profit DESC
LIMIT 1;

-- Top 5 most profitable consumer customers
SELECT 
    customer_name,
    ROUND(SUM(profit), 2) as total_profit,
    ROUND(SUM(sales), 2) as total_sales,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) as profit_margin,
    COUNT(DISTINCT order_id) as order_count
FROM kms_orders
WHERE customer_segment = 'Consumer'
GROUP BY customer_name
ORDER BY total_profit DESC
LIMIT 5;

-- Question 10: Customers who returned items (negative profit analysis)
-- =============================================================================

-- Customers with negative profit transactions
SELECT 
    customer_name,
    customer_segment,
    COUNT(*) as negative_transactions,
    ROUND(SUM(profit), 2) as total_loss,
    ROUND(SUM(sales), 2) as sales_amount,
    ROUND(AVG(profit), 2) as avg_loss_per_transaction
FROM kms_orders
WHERE profit < 0
GROUP BY customer_name, customer_segment
ORDER BY total_loss ASC
LIMIT 10;

-- Loss analysis by customer segment
SELECT 
    customer_segment,
    COUNT(*) as loss_transactions,
    COUNT(DISTINCT customer_name) as customers_affected,
    ROUND(SUM(profit), 2) as total_loss,
    ROUND(AVG(profit), 2) as avg_loss_per_transaction,
    ROUND(SUM(sales), 2) as sales_with_losses
FROM kms_orders
WHERE profit < 0
GROUP BY customer_segment
ORDER BY total_loss ASC;

-- Overall loss summary
SELECT 
    COUNT(*) as total_loss_transactions,
    COUNT(DISTINCT customer_name) as customers_with_losses,
    ROUND(SUM(profit), 2) as total_loss_amount,
    ROUND(SUM(sales), 2) as sales_amount_with_losses,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM kms_orders), 2) as loss_transaction_percentage
FROM kms_orders
WHERE profit < 0;

-- Question 11: Shipping cost efficiency vs Order Priority
-- =============================================================================

-- Shipping method usage by order priority
SELECT 
    order_priority,
    ship_mode,
    COUNT(*) as order_count,
    ROUND(AVG(shipping_cost), 2) as avg_shipping_cost,
    ROUND(SUM(shipping_cost), 2) as total_shipping_cost,
    ROUND(SUM(sales), 2) as total_sales,
    ROUND((SUM(shipping_cost) / SUM(sales)) * 100, 2) as shipping_cost_percentage
FROM kms_orders
GROUP BY order_priority, ship_mode
ORDER BY order_priority, total_shipping_cost DESC;

-- Priority vs shipping method efficiency analysis
WITH priority_shipping AS (
    SELECT 
        order_priority,
        ship_mode,
        COUNT(*) as orders,
        ROUND(AVG(shipping_cost), 2) as avg_cost
    FROM kms_orders
    GROUP BY order_priority, ship_mode
),
priority_totals AS (
    SELECT 
        order_priority,
        COUNT(*) as total_orders
    FROM kms_orders
    GROUP BY order_priority
)
SELECT 
    ps.order_priority,
    ps.ship_mode,
    ps.orders,
    pt.total_orders,
    ROUND((ps.orders * 100.0) / pt.total_orders, 2) as percentage_of_priority_orders,
    ps.avg_cost,
    CASE 
        WHEN ps.order_priority IN ('Critical', 'High') AND ps.ship_mode = 'Express Air' THEN 'Appropriate'
        WHEN ps.order_priority = 'Low' AND ps.ship_mode = 'Delivery Truck' THEN 'Cost-effective'
        WHEN ps.order_priority IN ('Critical', 'High') AND ps.ship_mode = 'Delivery Truck' THEN 'Too slow for priority'
        WHEN ps.order_priority = 'Low' AND ps.ship_mode = 'Express Air' THEN 'Unnecessarily expensive'
        ELSE 'Standard'
    END as efficiency_assessment
FROM priority_shipping ps
JOIN priority_totals pt ON ps.order_priority = pt.order_priority
ORDER BY ps.order_priority, ps.orders DESC;

-- Shipping efficiency recommendations
SELECT 
    'Critical/High Priority using Express Air' as metric,
    CONCAT(
        ROUND(
            (SELECT COUNT(*) FROM kms_orders 
             WHERE order_priority IN ('Critical', 'High') AND ship_mode = 'Express Air') * 100.0 /
            (SELECT COUNT(*) FROM kms_orders 
             WHERE order_priority IN ('Critical', 'High')), 2
        ), '%'
    ) as current_percentage,
    'Should be >50%' as recommendation
UNION ALL
SELECT 
    'Low Priority using Delivery Truck' as metric,
    CONCAT(
        ROUND(
            (SELECT COUNT(*) FROM kms_orders 
             WHERE order_priority = 'Low' AND ship_mode = 'Delivery Truck') * 100.0 /
            (SELECT COUNT(*) FROM kms_orders 
             WHERE order_priority = 'Low'), 2
        ), '%'
    ) as current_percentage,
    'Should be >30%' as recommendation;

-- =============================================================================
-- SUMMARY QUERIES AND BUSINESS INSIGHTS
-- =============================================================================

-- Overall business metrics
SELECT 
    COUNT(DISTINCT order_id) as total_orders,
    COUNT(DISTINCT customer_name) as unique_customers,
    ROUND(SUM(sales), 2) as total_sales,
    ROUND(SUM(profit), 2) as total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) as overall_profit_margin,
    ROUND(AVG(sales), 2) as avg_order_value,
    ROUND(SUM(shipping_cost), 2) as total_shipping_cost,
    MIN(order_date) as earliest_order,
    MAX(order_date) as latest_order
FROM kms_orders;

-- Key findings summary
SELECT 
    (SELECT product_category FROM kms_orders GROUP BY product_category ORDER BY SUM(sales) DESC LIMIT 1) as top_product_category,
    (SELECT region FROM kms_orders GROUP BY region ORDER BY SUM(sales) DESC LIMIT 1) as top_region,
    (SELECT customer_segment FROM kms_orders GROUP BY customer_segment ORDER BY SUM(sales) DESC LIMIT 1) as top_customer_segment,
    (SELECT ship_mode FROM kms_orders GROUP BY ship_mode ORDER BY SUM(shipping_cost) DESC LIMIT 1) as most_expensive_shipping,
    (SELECT customer_name FROM kms_orders GROUP BY customer_name ORDER BY SUM(sales) DESC LIMIT 1) as top_customer;

-- Customer segment performance
SELECT 
    customer_segment,
    COUNT(DISTINCT customer_name) as customer_count,
    COUNT(DISTINCT order_id) as order_count,
    ROUND(SUM(sales), 2) as total_sales,
    ROUND(SUM(profit), 2) as total_profit,
    ROUND(AVG(sales), 2) as avg_order_value,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) as profit_margin
FROM kms_orders
GROUP BY customer_segment
ORDER BY total_sales DESC;

-- Regional performance analysis
SELECT 
    region,
    COUNT(DISTINCT customer_name) as customer_count,
    COUNT(DISTINCT order_id) as order_count,
    ROUND(SUM(sales), 2) as total_sales,
    ROUND(SUM(profit), 2) as total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) as profit_margin
FROM kms_orders
GROUP BY region
ORDER BY total_sales DESC;

-- =============================================================================
-- DATA QUALITY AND VALIDATION QUERIES
-- =============================================================================

-- Check for data quality issues
SELECT 
    'Total Records' as metric,
    COUNT(*) as value
FROM kms_orders
UNION ALL
SELECT 
    'Records with NULL sales',
    COUNT(*)
FROM kms_orders
WHERE sales IS NULL
UNION ALL
SELECT 
    'Records with negative sales',
    COUNT(*)
FROM kms_orders
WHERE sales < 0
UNION ALL
SELECT 
    'Records with NULL profit',
    COUNT(*)
FROM kms_orders
WHERE profit IS NULL
UNION ALL
SELECT 
    'Records with negative profit (potential returns)',
    COUNT(*)
FROM kms_orders
WHERE profit < 0;

-- Date range validation
SELECT 
    MIN(order_date) as earliest_date,
    MAX(order_date) as latest_date,
    DATEDIFF(MAX(order_date), MIN(order_date)) as days_span,
    COUNT(DISTINCT YEAR(order_date)) as years_covered
FROM kms_orders;

-- =============================================================================
-- END OF SQL ANALYSIS
-- =============================================================================


