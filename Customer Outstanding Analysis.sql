
   --Customer Outstanding Analysis by Sales Representative
   --Focus: 90+ Days Outstanding


-- Preview source data
SELECT * 
FROM Dabur;

-- 1. Outstanding 90+ by Customer & SR

SELECT TOP 100
    a.Customer,
    ISNULL(s.SR, 'Manish') AS SR,
    SUM(a.[90 + ]) AS Outstanding_90Plus
FROM Agewise a
JOIN Dabur s 
    ON a.Customer = s.[Customer Name]
GROUP BY 
    a.Customer,
    s.SR
ORDER BY 
    Outstanding_90Plus DESC;


-- 2. Net Sales, 90+ Outstanding, and MTD Sales by Customer

SELECT TOP 100
    a.Customer,
    ISNULL(s.SR, 'Manish') AS SR,
    SUM(a.[90 + ]) AS Outstanding_90Plus,
    SUM(s.[Net Amount]) AS Total_Net_Sales,
    SUM(
        CASE 
            WHEN MONTH(s.Date) = MONTH(GETDATE()) 
             AND YEAR(s.Date) = YEAR(GETDATE()) 
            THEN s.[Net Amount] 
            ELSE 0 
        END
    ) AS MTD_Net_Sales
FROM Agewise a
JOIN Dabur s 
    ON a.Customer = s.[Customer Name]
GROUP BY 
    a.Customer,
    s.SR
ORDER BY 
    Outstanding_90Plus DESC;


-- 3. Net Sales, 90+ Outstanding, and MTD Sales by SR

SELECT 
    ISNULL(s.SR, 'Manish') AS SR,
    SUM(a.[90 + ]) AS Outstanding_90Plus,
    SUM(s.[Net Amount]) AS Total_Net_Sales,
    SUM(
        CASE 
            WHEN MONTH(s.Date) = MONTH(GETDATE()) 
             AND YEAR(s.Date) = YEAR(GETDATE()) 
            THEN s.[Net Amount]
            ELSE 0 
        END
    ) AS MTD_Net_Sales
FROM Agewise a
JOIN Dabur s 
    ON a.Customer = s.[Customer Name]
GROUP BY 
    s.SR
ORDER BY 
    Outstanding_90Plus DESC;

-- 4. Customer Activity Classification with 90+ Outstanding

SELECT  
    a.Customer,
    ISNULL(s.SR, 'Manish') AS SR,
    SUM(a.[90 + ]) AS Outstanding_90Plus,
    SUM(ISNULL(s.[Net Amount],0)) AS Total_Purchase,
    CASE 
        WHEN SUM(ISNULL(s.[Net Amount],0)) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS PurchaseStatus
FROM Agewise a
LEFT JOIN Dabur s 
    ON a.Customer = s.[Customer Name]
GROUP BY 
    a.Customer,
    s.SR
HAVING 
    SUM(a.[90 + ]) > 0
ORDER BY 
    Outstanding_90Plus DESC;


-- 5. SR-Level Summary with 90+ Outstanding and Activity

SELECT  
    ISNULL(s.SR, 'Manish') AS SR,
    COUNT(DISTINCT a.Customer) AS CustomerCount_Over90,
    SUM(a.[90 + ]) AS Outstanding_90Plus,
    SUM(ISNULL(s.[Net Amount],0)) AS Total_Sales,
    SUM(
        CASE 
            WHEN MONTH(s.Date) = MONTH(GETDATE()) 
             AND YEAR(s.Date) = YEAR(GETDATE()) 
            THEN ISNULL(s.[Net Amount],0)
            ELSE 0
        END
    ) AS MTD_Sales,
    COUNT(DISTINCT CASE 
        WHEN s.Date >= DATEADD(DAY, -60, GETDATE()) THEN a.Customer 
        END) AS Active_Customers,
    COUNT(DISTINCT CASE 
        WHEN s.Date < DATEADD(DAY, -60, GETDATE()) 
             OR s.Date IS NULL THEN a.Customer 
        END) AS Inactive_Customers
FROM Agewise a
LEFT JOIN Dabur s 
    ON a.Customer = s.[Customer Name]
GROUP BY 
    ISNULL(s.SR,'Manish')
HAVING 
    SUM(a.[90 + ]) > 0
ORDER BY 
    Outstanding_90Plus DESC;
