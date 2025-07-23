-- View everything in the table
SELECT * FROM dbo.company

-- Update column definitions
ALTER TABLE dbo.company
ALTER COLUMN Miti VARCHAR(10) NOT NULL

ALTER TABLE dbo.company
ALTER COLUMN Rate DECIMAL(18, 2) NULL

ALTER TABLE dbo.company
ALTER COLUMN VAT_Amount DECIMAL(18, 2) NULL

ALTER TABLE dbo.company
ALTER COLUMN Net_Amount DECIMAL(18, 2) NULL

-- Total net sales
SELECT 
  SUM(COALESCE(Net_Amount, 0)) AS TotalNetSale
FROM dbo.company

-- Net sales by month and year
SELECT
  YEAR(Date) AS SaleYear,
  MONTH(Date) AS SaleMonth,
  SUM(COALESCE(Net_Amount,0)) AS TotalNetSale
FROM dbo.company
GROUP BY YEAR(Date), MONTH(Date)
ORDER BY SaleYear, SaleMonth

-- Total order days per customer
SELECT
  Customer_Name,
  COUNT(DISTINCT CAST(Date AS DATE)) AS OrderDays
FROM dbo.company
GROUP BY Customer_Name
ORDER BY OrderDays DESC

-- Monthly growth calculation
WITH MonthlySales AS (
  SELECT
    YEAR(Date) AS Year,
    MONTH(Date) AS Month,
    SUM(COALESCE(Net_Amount,0)) AS TotalNet
  FROM dbo.company
  GROUP BY YEAR(Date), MONTH(Date)
)
SELECT
  Year,
  Month,
  TotalNet,
  LAG(TotalNet) OVER (ORDER BY Year, Month) AS PrevMonthNet,
  CASE 
    WHEN LAG(TotalNet) OVER (ORDER BY Year, Month) = 0 THEN NULL
    ELSE ROUND(
      (TotalNet - LAG(TotalNet) OVER (ORDER BY Year, Month)) * 100.0 /
      LAG(TotalNet) OVER (ORDER BY Year, Month), 2)
  END AS Month_GrowthPct
FROM MonthlySales
ORDER BY Year, Month

-- Total orders and sales per month
SELECT
  DATEFROMPARTS(YEAR([Date]), MONTH([Date]), 1) AS MonthStart,
  COUNT(DISTINCT Sales_No) AS OrdersPerMonth,
  SUM(COALESCE(Net_Amount,0)) AS SalesPerMonth
FROM dbo.company
GROUP BY DATEFROMPARTS(YEAR([Date]), MONTH([Date]), 1)
ORDER BY MonthStart

-- Top 10 best-selling items
SELECT TOP 10
  Item_Code,
  Item_Name,
  SUM(COALESCE(Quantity,0)) AS TotalUnitsSold
FROM dbo.company
GROUP BY Item_Code, Item_Name
ORDER BY TotalUnitsSold DESC

-- Top 10 customers by net spend
SELECT TOP 10
  Customer_Code,
  Customer_Name,
  ROUND(SUM(COALESCE(Net_Amount,0)), 2) AS TotalNetSpend
FROM dbo.company
GROUP BY Customer_Code, Customer_Name
ORDER BY TotalNetSpend DESC

-- Top 10 items by revenue
SELECT TOP 10
  Item_Code,
  Item_Name,
  SUM(COALESCE(Net_Amount,0)) AS TotalRevenue
FROM dbo.company
GROUP BY Item_Code, Item_Name
ORDER BY TotalRevenue DESC

-- Low-velocity products
SELECT TOP 10
  Item_Code,
  Item_Name,
  SUM(COALESCE(Quantity,0)) AS TotalUnitsSold
FROM dbo.company
GROUP BY Item_Code, Item_Name
ORDER BY TotalUnitsSold ASC

-- Price vs volume per item
WITH ItemStats AS (
  SELECT
    Item_Code,
    Item_Name,
    AVG(COALESCE(Net_Amount,0) / NULLIF(COALESCE(Quantity,1),0)) AS AvgUnitPrice,
    SUM(COALESCE(Quantity,0)) AS TotalUnitsSold
  FROM dbo.company
  GROUP BY Item_Code, Item_Name
)
SELECT * FROM ItemStats

-- One-time vs repeat buyers
WITH CustomerOrderCounts AS (
  SELECT
    Customer_Code,
    Customer_Name,
    COUNT(DISTINCT Sales_No) AS OrderCount
  FROM dbo.company
  GROUP BY Customer_Code, Customer_Name
),
LabeledCustomers AS (
  SELECT
    Customer_Code,
    Customer_Name,
    OrderCount,
    CASE 
      WHEN OrderCount = 1 THEN 'One-Time'
      ELSE 'Repeat'
    END AS BuyerType
  FROM CustomerOrderCounts
)
SELECT
  BuyerType,
  COUNT(*) AS NumCustomers,
  SUM(OrderCount) AS TotalOrders,
  ROUND(AVG(OrderCount), 2) AS AvgOrdersPerCust
FROM LabeledCustomers
GROUP BY BuyerType

-- Top channels by sales
SELECT
  Chanel,
  ROUND(SUM(COALESCE(Net_Amount, 0)), 2) AS TotalNetSales,
  COUNT(DISTINCT CAST([Date] AS DATE)) AS DistinctOrders
FROM dbo.company
WHERE Chanel IS NOT NULL
GROUP BY Chanel
ORDER BY TotalNetSales DESC

-- Monthly sales by sales officer
WITH MonthCalc AS (
  SELECT
    DATEFROMPARTS(YEAR([Date]), MONTH([Date]), 1) AS MonthStart,
    Chanel,
    CAST([Date] AS DATE) AS SalesDate,
    Net_Amount
  FROM dbo.company
  WHERE Chanel IS NOT NULL
)
SELECT
  MonthStart,
  Chanel,
  COUNT(DISTINCT SalesDate) AS ActiveSalesDays,
  SUM(COALESCE(Net_Amount, 0)) AS SalesPerMonth
FROM MonthCalc
GROUP BY MonthStart, Chanel
ORDER BY MonthStart ASC, SalesPerMonth DESC

-- Buyer type by channel
WITH CustomerOrderCounts AS (
  SELECT
    Chanel,
    Customer_Code,
    Customer_Name,
    COUNT(DISTINCT CAST([Date] AS DATE)) AS OrderDays
  FROM dbo.company
  WHERE Chanel IS NOT NULL
  GROUP BY Chanel, Customer_Code, Customer_Name
),
LabeledCustomers AS (
  SELECT
    Chanel,
    Customer_Code,
    Customer_Name,
    OrderDays,
    CASE 
      WHEN OrderDays = 1 THEN 'One-Time'
      ELSE 'Repeat'
    END AS BuyerType
  FROM CustomerOrderCounts
)
SELECT
  Chanel,
  BuyerType,
  COUNT(*) AS NumCustomers,
  SUM(OrderDays) AS TotalOrderDays,
  ROUND(AVG(OrderDays * 1.0), 2) AS AvgOrderDaysPerCust
FROM LabeledCustomers
GROUP BY Chanel, BuyerType
ORDER BY Chanel, BuyerType

-- Avg deal size and growth rate
WITH MonthlyStats AS (
  SELECT
    Chanel,
    DATEFROMPARTS(YEAR(Date), MONTH(Date), 1) AS MonthStart,
    COUNT(DISTINCT CAST(Date AS DATE)) AS ActiveOrderDays,
    COUNT(DISTINCT Customer_Code) AS UniqueCustomers,
    SUM(COALESCE(Net_Amount, 0)) AS TotalSales
  FROM dbo.company
  WHERE Chanel IS NOT NULL
  GROUP BY Chanel, DATEFROMPARTS(YEAR(Date), MONTH(Date), 1)
),
WithGrowth AS (
  SELECT *,
    LAG(TotalSales) OVER (PARTITION BY Chanel ORDER BY MonthStart) AS PrevMonthSales
  FROM MonthlyStats
)
SELECT
  Chanel,
  MonthStart,
  ActiveOrderDays,
  UniqueCustomers,
  TotalSales,
  ROUND(CASE 
    WHEN ActiveOrderDays = 0 THEN 0
    ELSE TotalSales * 1.0 / ActiveOrderDays
  END, 2) AS AvgDealSize,
  ROUND(CASE 
    WHEN PrevMonthSales IS NULL OR PrevMonthSales = 0 THEN NULL
    ELSE (TotalSales - PrevMonthSales) * 100.0 / PrevMonthSales
  END, 2) AS SalesGrowthPercent
FROM WithGrowth
ORDER BY Chanel, MonthStart

-- Sales officers who perform best per product
WITH RankedSales AS (
  SELECT
    Item_Name,
    Chanel,
    COUNT(DISTINCT Sales_No) AS Orders,
    SUM(COALESCE(Net_Amount, 0)) AS TotalSales,
    ROW_NUMBER() OVER (PARTITION BY Item_Name ORDER BY SUM(COALESCE(Net_Amount, 0)) DESC) AS RankPerProduct
  FROM dbo.company
  WHERE Chanel IS NOT NULL
  GROUP BY Item_Name, Chanel
)
SELECT
  Item_Name,
  Chanel,
  Orders,
  TotalSales
FROM RankedSales
WHERE RankPerProduct = 1
ORDER BY TotalSales DESC
