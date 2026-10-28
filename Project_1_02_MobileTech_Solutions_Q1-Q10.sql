-- MOBILE TECH RETAILERS — MySQL 8.0+
USE mobiletech_analytics;

-- Q1. Which states have active customers who have purchased cellphones since 2005?
-- No country restriction is stated. Country is shown to distinguish locations.
-- Active means a customer with at least one recorded purchase since 2005.
SELECT l.Country, l.State,
       COUNT(DISTINCT f.IdCustomer) AS ActivePurchasingCustomers
FROM FACT_TRANSACTIONS AS f
JOIN DIM_CUSTOMER AS c ON c.IdCustomer = f.IdCustomer
JOIN DIM_LOCATION AS l ON l.IdLocation = f.IdLocation
WHERE f.`Date` >= '2005-01-01'
GROUP BY l.Country, l.State
ORDER BY l.Country, l.State;

-- Q2. Which US state records the highest volume of Samsung cellphone sales?
-- Sum the units sold in each U.S. state and return the top state.
SELECT l.State,
       SUM(t.Quantity) AS TotalSamsungUnitsSold
FROM FACT_TRANSACTIONS AS t
JOIN DIM_LOCATION AS l ON l.IdLocation = t.IdLocation
JOIN DIM_MODEL AS m ON m.IdModel = t.IdModel
JOIN DIM_MANUFACTURER AS manu ON manu.IdManufacturer = m.IdManufacturer
WHERE manu.Manufacturer_Name = 'Samsung'
  AND l.Country IN ('USA', 'US')
GROUP BY l.State
ORDER BY TotalSamsungUnitsSold DESC, l.State ASC
LIMIT 1;

-- Q3. How many transactions have been made for each phone model, broken down by zip code and state?
SELECT mo.Model_Name, l.ZipCode, l.State,
       COUNT(*) AS TransactionCount
FROM FACT_TRANSACTIONS AS f
JOIN DIM_MODEL AS mo ON mo.IdModel = f.IdModel
JOIN DIM_LOCATION AS l ON l.IdLocation = f.IdLocation
GROUP BY mo.Model_Name, l.ZipCode, l.State
ORDER BY mo.Model_Name, l.State, l.ZipCode;

-- Q4. Which cellphone model is the most affordable, and what is its unit price?
SELECT Model_Name, Unit_Price
FROM DIM_MODEL
WHERE Unit_Price = (SELECT MIN(Unit_Price) FROM DIM_MODEL)
ORDER BY Model_Name;

-- Q5. Average selling price per model among the top five manufacturers by total units sold
-- CTE step 1: find the five manufacturers with the most units.
-- Main query: calculate each model's realized unit selling price for those manufacturers.
WITH TopFiveManufacturers AS (
    SELECT m.IdManufacturer, SUM(t.Quantity) AS TotalUnits
    FROM FACT_TRANSACTIONS AS t
    JOIN DIM_MODEL AS m ON m.IdModel = t.IdModel
    GROUP BY m.IdManufacturer
    ORDER BY TotalUnits DESC, m.IdManufacturer
    LIMIT 5
)
SELECT manu.Manufacturer_Name, m.Model_Name,
       SUM(t.TotalPrice) / NULLIF(SUM(t.Quantity), 0) AS AverageSellingPrice,
       SUM(t.Quantity) AS UnitsSold
FROM TopFiveManufacturers AS top5
JOIN DIM_MANUFACTURER AS manu ON manu.IdManufacturer = top5.IdManufacturer
JOIN DIM_MODEL AS m ON m.IdManufacturer = top5.IdManufacturer
JOIN FACT_TRANSACTIONS AS t ON t.IdModel = m.IdModel
GROUP BY manu.Manufacturer_Name, m.Model_Name
ORDER BY manu.Manufacturer_Name, m.Model_Name;
-- Q6. Customers with average spend above $500 during 2009
SELECT c.IdCustomer, c.Customer_Name,
       AVG(t.TotalPrice) AS AverageSpend
FROM FACT_TRANSACTIONS AS t
JOIN DIM_CUSTOMER AS c ON c.IdCustomer = t.IdCustomer
WHERE YEAR(t.`Date`) = 2009
GROUP BY c.IdCustomer, c.Customer_Name
HAVING AVG(t.TotalPrice) > 500
ORDER BY AverageSpend DESC, c.IdCustomer;

-- Q7. Did any model rank in the top five by units sold in all of 2008, 2009, and 2010?
-- Show the annual top-five rows and a coverage count so the answer is visible even if
-- no model qualifies in all three years. RANK retains ties at the fifth position.
WITH AnnualSales AS (
    SELECT d.`Year`, m.IdModel, m.Model_Name,
           SUM(t.Quantity) AS UnitsSold
    FROM FACT_TRANSACTIONS AS t
    JOIN DIM_MODEL AS m ON m.IdModel = t.IdModel
    JOIN DIM_DATE AS d ON d.`Date` = t.`Date`
    WHERE d.`Year` IN (2008, 2009, 2010)
    GROUP BY d.`Year`, m.IdModel, m.Model_Name
), RankedAnnualSales AS (
    SELECT AnnualSales.*,
           RANK() OVER (
               PARTITION BY AnnualSales.`Year`
               ORDER BY AnnualSales.UnitsSold DESC
           ) AS SalesRank
    FROM AnnualSales
), TopFiveByYear AS (
    SELECT *
    FROM RankedAnnualSales
    WHERE SalesRank <= 5
), ModelCoverage AS (
    SELECT IdModel, Model_Name,
           COUNT(DISTINCT `Year`) AS YearsInTopFive
    FROM TopFiveByYear
    GROUP BY IdModel, Model_Name
)
SELECT t.IdModel, t.Model_Name, t.`Year`, t.UnitsSold, t.SalesRank,
       c.YearsInTopFive,
       CASE WHEN c.YearsInTopFive = 3 THEN 'Yes' ELSE 'No' END AS TopFiveInAllThreeYears
FROM TopFiveByYear AS t
JOIN ModelCoverage AS c ON c.IdModel = t.IdModel
ORDER BY t.`Year`, t.SalesRank, t.Model_Name, t.IdModel;
-- Q8. Manufacturer ranked second in sales revenue in 2009 and in 2010
SELECT RankedRevenue.`Year`, RankedRevenue.Manufacturer_Name, RankedRevenue.Revenue
FROM (
    SELECT AnnualRevenue.*,
           DENSE_RANK() OVER (PARTITION BY AnnualRevenue.`Year` ORDER BY AnnualRevenue.Revenue DESC) AS RevenueRank
    FROM (
        SELECT d.`Year`, manu.IdManufacturer, manu.Manufacturer_Name,
               SUM(t.TotalPrice) AS Revenue
        FROM FACT_TRANSACTIONS AS t
        JOIN DIM_MODEL AS m ON m.IdModel = t.IdModel
        JOIN DIM_MANUFACTURER AS manu ON manu.IdManufacturer = m.IdManufacturer
        JOIN DIM_DATE AS d ON d.`Date` = t.`Date`
        WHERE d.`Year` IN (2009, 2010)
        GROUP BY d.`Year`, manu.IdManufacturer, manu.Manufacturer_Name
    ) AS AnnualRevenue
) AS RankedRevenue
WHERE RankedRevenue.RevenueRank = 2
ORDER BY RankedRevenue.`Year`;

-- Q9. Manufacturers with sales in 2010 but no recorded sales in 2009
-- For the supplied CSVs this correctly returns 0 rows: each 2010-selling manufacturer also has 2009 sales.
SELECT manu.IdManufacturer, manu.Manufacturer_Name
FROM DIM_MANUFACTURER AS manu
WHERE EXISTS (
    SELECT 1
    FROM FACT_TRANSACTIONS AS t
    JOIN DIM_MODEL AS m ON m.IdModel = t.IdModel
    WHERE m.IdManufacturer = manu.IdManufacturer
      AND YEAR(t.`Date`) = 2010
)
AND NOT EXISTS (
    SELECT 1
    FROM FACT_TRANSACTIONS AS t
    JOIN DIM_MODEL AS m ON m.IdModel = t.IdModel
    WHERE m.IdManufacturer = manu.IdManufacturer
      AND YEAR(t.`Date`) = 2009
)
ORDER BY manu.Manufacturer_Name;

-- Q10. Top 100 customers by lifetime spend: annual spend, quantity, averages, and year-over-year change
-- The average includes each calendar year in DIM_DATE; a year with no purchases counts as zero.
SELECT AnnualGrid.IdCustomer, c.Customer_Name, AnnualGrid.`Year`,
       AnnualGrid.AnnualSpend, AnnualGrid.AnnualQuantity,
       CASE
           WHEN PreviousYear.AnnualSpend IS NULL OR PreviousYear.AnnualSpend = 0 THEN NULL
           ELSE 100.0 * (AnnualGrid.AnnualSpend - PreviousYear.AnnualSpend) / PreviousYear.AnnualSpend
       END AS SpendChangePercent,
       AVG(AnnualGrid.AnnualSpend) OVER (PARTITION BY AnnualGrid.IdCustomer) AS AverageAnnualSpend,
       AVG(AnnualGrid.AnnualQuantity) OVER (PARTITION BY AnnualGrid.IdCustomer) AS AverageAnnualQuantity
FROM (
    SELECT TopCustomers.IdCustomer, CalendarYears.`Year`,
           COALESCE(AnnualSales.AnnualSpend, 0) AS AnnualSpend,
           COALESCE(AnnualSales.AnnualQuantity, 0) AS AnnualQuantity
    FROM (
        SELECT IdCustomer
        FROM FACT_TRANSACTIONS
        GROUP BY IdCustomer
        ORDER BY SUM(TotalPrice) DESC, IdCustomer
        LIMIT 100
    ) AS TopCustomers
    CROSS JOIN (SELECT DISTINCT `Year` FROM DIM_DATE) AS CalendarYears
    LEFT JOIN (
        SELECT t.IdCustomer, d.`Year`,
               SUM(t.TotalPrice) AS AnnualSpend,
               SUM(t.Quantity) AS AnnualQuantity
        FROM FACT_TRANSACTIONS AS t
        JOIN DIM_DATE AS d ON d.`Date` = t.`Date`
        GROUP BY t.IdCustomer, d.`Year`
    ) AS AnnualSales
      ON AnnualSales.IdCustomer = TopCustomers.IdCustomer
     AND AnnualSales.`Year` = CalendarYears.`Year`
) AS AnnualGrid
JOIN DIM_CUSTOMER AS c ON c.IdCustomer = AnnualGrid.IdCustomer
LEFT JOIN (
    SELECT t.IdCustomer, d.`Year`, SUM(t.TotalPrice) AS AnnualSpend
    FROM FACT_TRANSACTIONS AS t
    JOIN DIM_DATE AS d ON d.`Date` = t.`Date`
    GROUP BY t.IdCustomer, d.`Year`
) AS PreviousYear
  ON PreviousYear.IdCustomer = AnnualGrid.IdCustomer
 AND PreviousYear.`Year` = AnnualGrid.`Year` - 1
ORDER BY c.Customer_Name, AnnualGrid.IdCustomer, AnnualGrid.`Year`;
