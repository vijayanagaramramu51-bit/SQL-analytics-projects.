-- QUICKBITE ANALYTICS — MySQL 8.0+
USE quickbite_analytics;

-- Q1. Which cities recorded at least one order in 2022, and what were their total order counts and total revenue?
-- FACT_ORDERS has no city column, so restaurant City represents the order city.
SELECT r.City, COUNT(*) AS TotalOrders,
       SUM(f.Order_Amount) AS TotalRevenue
FROM FACT_ORDERS AS f
JOIN DIM_RESTAURANT AS r ON r.RestaurantID = f.RestaurantID
WHERE f.Order_Date >= '2022-01-01' AND f.Order_Date < '2023-01-01'
GROUP BY r.City
ORDER BY TotalOrders DESC, r.City;

-- Q2. Which cuisine type generates the highest total revenue and order volume across the platform?
SELECT r.Cuisine_Type, SUM(f.Order_Amount) AS TotalRevenue,
       COUNT(*) AS OrderCount
FROM FACT_ORDERS AS f
JOIN DIM_RESTAURANT AS r ON r.RestaurantID = f.RestaurantID
GROUP BY r.Cuisine_Type
ORDER BY TotalRevenue DESC, OrderCount DESC;

-- Q3. Each restaurant's total orders, total revenue, and average order value, ranked by revenue
SELECT r.RestaurantID, r.Restaurant_Name,
       COUNT(f.OrderID) AS TotalOrders,
       COALESCE(SUM(f.Order_Amount), 0) AS TotalRevenue,
       AVG(f.Order_Amount) AS AverageOrderValue
FROM DIM_RESTAURANT AS r
LEFT JOIN FACT_ORDERS AS f ON f.RestaurantID = r.RestaurantID
GROUP BY r.RestaurantID, r.Restaurant_Name
ORDER BY TotalRevenue DESC, r.RestaurantID;

-- Q4. Highest single order amount ever recorded per restaurant
-- The correlated MAX returns every order tied for the restaurant's highest amount.
SELECT r.RestaurantID, r.Restaurant_Name, r.Cuisine_Type,
       f.OrderID, f.Order_Amount
FROM FACT_ORDERS AS f
JOIN DIM_RESTAURANT AS r ON r.RestaurantID = f.RestaurantID
WHERE f.Order_Amount = (
    SELECT MAX(f2.Order_Amount)
    FROM FACT_ORDERS AS f2
    WHERE f2.RestaurantID = f.RestaurantID
)
ORDER BY r.Restaurant_Name, f.OrderID;
-- Q5. Top 10 customers by lifetime spend, with city, order count, and amount spent
SELECT c.CustomerID, c.Customer_Name, c.City,
       COUNT(f.OrderID) AS TotalOrders,
       SUM(f.Order_Amount) AS LifetimeSpend
FROM DIM_CUSTOMER AS c
JOIN FACT_ORDERS AS f ON f.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.Customer_Name, c.City
ORDER BY LifetimeSpend DESC, c.CustomerID
LIMIT 10;

-- Q6. Total deliveries and average delivery time for each delivery agent
SELECT a.AgentID, a.Agent_Name,
       COUNT(f.OrderID) AS DeliveriesCompleted,
       AVG(f.Delivery_Minutes) AS AverageDeliveryMinutes
FROM DIM_DELIVERY_AGENT AS a
LEFT JOIN FACT_ORDERS AS f ON f.AgentID = a.AgentID
GROUP BY a.AgentID, a.Agent_Name
ORDER BY DeliveriesCompleted DESC, a.AgentID;

-- Q7. Average delivery time per city, fastest first
-- Restaurant City is used as the order-side city; the fact table has no city column.
SELECT r.City, AVG(f.Delivery_Minutes) AS AverageDeliveryMinutes
FROM FACT_ORDERS AS f
JOIN DIM_RESTAURANT AS r ON r.RestaurantID = f.RestaurantID
GROUP BY r.City
ORDER BY AverageDeliveryMinutes, r.City;

-- Q8. Restaurants with 2023 orders and no 2022 orders
SELECT r.RestaurantID, r.Restaurant_Name, r.City
FROM DIM_RESTAURANT AS r
WHERE EXISTS (
    SELECT 1 FROM FACT_ORDERS AS f
    WHERE f.RestaurantID = r.RestaurantID
      AND f.Order_Date >= '2023-01-01' AND f.Order_Date < '2024-01-01'
)
AND NOT EXISTS (
    SELECT 1 FROM FACT_ORDERS AS f
    WHERE f.RestaurantID = r.RestaurantID
      AND f.Order_Date >= '2022-01-01' AND f.Order_Date < '2023-01-01'
)
ORDER BY r.Restaurant_Name;

-- Q9. Customers with more than five orders and average order value above ₹600
SELECT c.CustomerID, c.Customer_Name,
       COUNT(f.OrderID) AS TotalOrders,
       AVG(f.Order_Amount) AS AverageOrderValue
FROM DIM_CUSTOMER AS c
JOIN FACT_ORDERS AS f ON f.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.Customer_Name
HAVING COUNT(f.OrderID) > 5 AND AVG(f.Order_Amount) > 600
ORDER BY TotalOrders DESC, c.CustomerID;

-- Q10. Total revenue, total orders, and average order value for each year 2020–2023
SELECT YEAR(f.Order_Date) AS `Year`,
       SUM(f.Order_Amount) AS TotalRevenue,
       COUNT(*) AS TotalOrders,
       AVG(f.Order_Amount) AS AverageOrderValue
FROM FACT_ORDERS AS f
WHERE f.Order_Date >= '2020-01-01' AND f.Order_Date < '2024-01-01'
GROUP BY YEAR(f.Order_Date)
ORDER BY `Year`;

-- Q11. Highest average order rating restaurant(s) per cuisine, with total orders
SELECT RankedRatings.Cuisine_Type, RankedRatings.RestaurantID,
       RankedRatings.Restaurant_Name, RankedRatings.AverageOrderRating,
       RankedRatings.TotalOrders
FROM (
    SELECT RestaurantRatings.*,
           RANK() OVER (PARTITION BY RestaurantRatings.Cuisine_Type
                        ORDER BY RestaurantRatings.AverageOrderRating DESC) AS RatingRank
    FROM (
        SELECT r.Cuisine_Type, r.RestaurantID, r.Restaurant_Name,
               AVG(f.Rating) AS AverageOrderRating,
               COUNT(f.OrderID) AS TotalOrders
        FROM DIM_RESTAURANT AS r
        JOIN FACT_ORDERS AS f ON f.RestaurantID = r.RestaurantID
        GROUP BY r.Cuisine_Type, r.RestaurantID, r.Restaurant_Name
    ) AS RestaurantRatings
) AS RankedRatings
WHERE RankedRatings.RatingRank = 1
ORDER BY RankedRatings.Cuisine_Type;

-- Q12. Transaction count, total revenue, and revenue share by payment mode
SELECT f.Payment_Mode,
       COUNT(*) AS TransactionCount,
       SUM(f.Order_Amount) AS TotalRevenue,
       100.0 * SUM(f.Order_Amount) /
           (SELECT SUM(Order_Amount) FROM FACT_ORDERS) AS RevenueSharePercent
FROM FACT_ORDERS AS f
GROUP BY f.Payment_Mode
ORDER BY TotalRevenue DESC;
-- Q13. Restaurant(s) with the highest percentage revenue growth from 2022 to 2023
-- Restaurants with zero 2022 revenue have undefined percentage growth and are excluded.
-- RANK returns every restaurant tied for the highest growth.
WITH RevenueByYear AS (
    SELECT f.RestaurantID,
           SUM(CASE WHEN f.Order_Date >= '2022-01-01' AND f.Order_Date < '2023-01-01'
                    THEN f.Order_Amount ELSE 0 END) AS Revenue2022,
           SUM(CASE WHEN f.Order_Date >= '2023-01-01' AND f.Order_Date < '2024-01-01'
                    THEN f.Order_Amount ELSE 0 END) AS Revenue2023
    FROM FACT_ORDERS AS f
    WHERE f.Order_Date >= '2022-01-01' AND f.Order_Date < '2024-01-01'
    GROUP BY f.RestaurantID
), Growth AS (
    SELECT RestaurantID, Revenue2022, Revenue2023,
           100.0 * (Revenue2023 - Revenue2022) / NULLIF(Revenue2022, 0) AS GrowthPercent
    FROM RevenueByYear
    WHERE Revenue2022 > 0
), RankedGrowth AS (
    SELECT Growth.*,
           RANK() OVER (ORDER BY Growth.GrowthPercent DESC) AS GrowthRank
    FROM Growth
)
SELECT r.RestaurantID, r.Restaurant_Name,
       g.Revenue2022, g.Revenue2023, g.GrowthPercent
FROM RankedGrowth AS g
JOIN DIM_RESTAURANT AS r ON r.RestaurantID = g.RestaurantID
WHERE g.GrowthRank = 1
ORDER BY r.RestaurantID;
-- Q14. Annual orders and revenue for the five customers with most total orders
SELECT c.CustomerID, c.Customer_Name,
       YEAR(f.Order_Date) AS `Year`,
       COUNT(f.OrderID) AS Orders,
       SUM(f.Order_Amount) AS Revenue
FROM (
    SELECT CustomerID
    FROM FACT_ORDERS
    GROUP BY CustomerID
    ORDER BY COUNT(*) DESC, CustomerID
    LIMIT 5
) AS TopFiveCustomers
JOIN DIM_CUSTOMER AS c ON c.CustomerID = TopFiveCustomers.CustomerID
JOIN FACT_ORDERS AS f ON f.CustomerID = TopFiveCustomers.CustomerID
WHERE f.Order_Date >= '2020-01-01' AND f.Order_Date < '2024-01-01'
GROUP BY c.CustomerID, c.Customer_Name, YEAR(f.Order_Date)
ORDER BY c.Customer_Name, `Year`;

-- Q15. Agent count, orders delivered, and average orders per agent by assigned city
SELECT a.City,
       COUNT(DISTINCT a.AgentID) AS AssignedAgents,
       COUNT(f.OrderID) AS TotalOrdersDelivered,
       COUNT(f.OrderID) / NULLIF(COUNT(DISTINCT a.AgentID), 0) AS AverageOrdersPerAgent
FROM DIM_DELIVERY_AGENT AS a
LEFT JOIN FACT_ORDERS AS f ON f.AgentID = a.AgentID
GROUP BY a.City
ORDER BY a.City;

-- Q16. Customers sharing name and email but assigned different CustomerIDs
SELECT Customer_Name, Email,
       COUNT(DISTINCT CustomerID) AS DistinctCustomerIDCount,
       GROUP_CONCAT(DISTINCT CustomerID ORDER BY CustomerID SEPARATOR ', ') AS CustomerIDs
FROM DIM_CUSTOMER
GROUP BY Customer_Name, Email
HAVING COUNT(DISTINCT CustomerID) > 1
ORDER BY Customer_Name, Email;

-- Q17. Agents completing more than 50 orders on a single calendar day
-- Source note: the supplied CSV has 87 rows for AgentID 7 on 2023-03-15; the brief says 85.
SELECT a.AgentID, a.Agent_Name,
       DATE(f.Order_Date) AS OrderDate,
       COUNT(*) AS OrderCount
FROM FACT_ORDERS AS f
JOIN DIM_DELIVERY_AGENT AS a ON a.AgentID = f.AgentID
GROUP BY a.AgentID, a.Agent_Name, DATE(f.Order_Date)
HAVING COUNT(*) > 50
ORDER BY OrderCount DESC, OrderDate, a.AgentID;

-- Q18. Orders with an amount more than three times the platform-wide average
SELECT f.OrderID, f.CustomerID, f.RestaurantID, f.Order_Date,
       f.Order_Amount,
       (SELECT AVG(Order_Amount) FROM FACT_ORDERS) AS PlatformAverage
FROM FACT_ORDERS AS f
WHERE f.Order_Amount > 3 * (SELECT AVG(Order_Amount) FROM FACT_ORDERS)
ORDER BY f.Order_Amount DESC;

-- Q19. Orders over 180 delivery minutes, with restaurant, agent, city, and time
SELECT f.OrderID, r.Restaurant_Name, a.Agent_Name,
       r.City, f.Delivery_Minutes
FROM FACT_ORDERS AS f
JOIN DIM_RESTAURANT AS r ON r.RestaurantID = f.RestaurantID
JOIN DIM_DELIVERY_AGENT AS a ON a.AgentID = f.AgentID
WHERE f.Delivery_Minutes > 180
ORDER BY f.Delivery_Minutes DESC;

-- Q20. Orders placed before the customer's Member_Since date
-- Source note: CSV comparison finds 4,016 matching rows; the anomaly guide says 15.
SELECT f.OrderID, f.CustomerID, c.Customer_Name,
       c.Member_Since, f.Order_Date
FROM FACT_ORDERS AS f
JOIN DIM_CUSTOMER AS c ON c.CustomerID = f.CustomerID
WHERE f.Order_Date < c.Member_Since
ORDER BY f.Order_Date, f.OrderID;

-- Q21. List orders placed by duplicate CustomerIDs with order details and both IDs.
-- CTE step 1: find each duplicate name/email group and its presumed original ID.
-- CTE step 2: map each other ID in the group to that presumed original.
-- The lowest ID is used only as a display convention for the original account.
WITH DuplicateGroups AS (
    SELECT Customer_Name, Email,
           MIN(CustomerID) AS OriginalCustomerID
    FROM DIM_CUSTOMER
    GROUP BY Customer_Name, Email
    HAVING COUNT(DISTINCT CustomerID) > 1
), DuplicateAccounts AS (
    SELECT dg.Customer_Name, dg.Email,
           dg.OriginalCustomerID,
           c.CustomerID AS DuplicateCustomerID
    FROM DuplicateGroups AS dg
    JOIN DIM_CUSTOMER AS c
      ON c.Customer_Name <=> dg.Customer_Name
     AND c.Email <=> dg.Email
     AND c.CustomerID <> dg.OriginalCustomerID
)
SELECT da.Customer_Name, da.Email,
       da.OriginalCustomerID, da.DuplicateCustomerID,
       f.CustomerID AS TransactionCustomerID,
       f.OrderID, f.Order_Date, f.RestaurantID, f.AgentID,
       f.Order_Amount, f.Delivery_Minutes, f.Rating, f.Payment_Mode
FROM DuplicateAccounts AS da
JOIN FACT_ORDERS AS f ON f.CustomerID = da.DuplicateCustomerID
ORDER BY da.Customer_Name, da.OriginalCustomerID,
         da.DuplicateCustomerID, f.Order_Date, f.OrderID;