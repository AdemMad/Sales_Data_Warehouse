-- Create dimension tables
CREATE TABLE DimLocation (
Location_Key INT PRIMARY KEY IDENTITY(1,1), Country VARCHAR(50),
City VARCHAR(50),
State VARCHAR(50),
Postal_Code VARCHAR(50),
Region VARCHAR(50),
IsCurrent BIT,
ValidFrom DATE,
ValidTo DATE
);

CREATE TABLE DimCustomer (
Customer_Key INT PRIMARY KEY IDENTITY(1,1),
Customer_ID INT UNIQUE,
Customer_Name VARCHAR(50),
Segment VARCHAR(50),
Location_Key INT,
FOREIGN KEY (Location_Key) REFERENCES DimLocation(Location_Key), IsCurrent BIT,
ValidFrom DATE,
ValidTo DATE
);

CREATE TABLE DimProduct (
Product_Key INT PRIMARY KEY IDENTITY(1,1), Product_ID INT UNIQUE,
Category VARCHAR(50),
Sub_Category VARCHAR(50),
Product_Name VARCHAR(50),
IsCurrent BIT,
ValidFrom DATE,
ValidTo DATE
);

--Create DimDate table
CREATE TABLE DimDate (
TimeDimID INT IDENTITY(1,1) PRIMARY KEY, FullDate DATE NOT NULL,
Year INT NOT NULL,
Quarter INT NOT NULL,
Month INT NOT NULL,
MonthName VARCHAR(9) NOT NULL,
Week INT NOT NULL,
DayOfYear INT NOT NULL,
DayOfMonth INT NOT NULL,
DayOfWeek INT NOT NULL,
WeekdayName VARCHAR(9) NOT NULL, IsWeekend BIT NOT NULL
);
 
 -- Create fact table
CREATE TABLE FactSales ( Order_ID INT PRIMARY KEY, Customer_Key INT, Product_Key INT, Date_Key INT,
Sales DECIMAL(18,2),
Quantity INT,
Discount DECIMAL(18,2),
Profit DECIMAL(18,2),
FOREIGN KEY (Customer_Key) REFERENCES DimCustomer(Customer_Key), FOREIGN KEY (Product_Key) REFERENCES DimProduct(Product_Key), FOREIGN KEY (Date_Key) REFERENCES DimDate(Date_Key)
);

-- Insert data into dimension tables
INSERT INTO DimLocation (Country, City, State, Postal_Code, Region, IsCurrent, ValidFrom, ValidTo)
SELECT DISTINCT
Country, City, State, Postal_Code, Region,
1 as IsCurrent,
CAST(GETDATE() AS DATE) as ValidFrom, '9999-12-31' as ValidTo
FROM Data;
INSERT INTO DimCustomer (Customer_ID, Customer_Name, Segment, Location_Key, IsCurrent, ValidFrom, ValidTo)
SELECT DISTINCT
Customer_ID,
Customer_Name,
Segment,
DimLocation.Location_Key,
1 as IsCurrent,
CAST(GETDATE() AS DATE) as ValidFrom, '9999-12-31' as ValidTo
FROM Data
JOIN DimLocation ON Data.Country = DimLocation.Country AND Data.City = DimLocation.City
AND Data.State = DimLocation.State
AND Data.Postal_Code = DimLocation.Postal_Code
AND Data.Region = DimLocation.Region;

INSERT INTO DimProduct (Product_ID, Category, Sub_Category, Product_Name, IsCurrent, ValidFrom, ValidTo)
SELECT DISTINCT
Product_ID,
Category,
Sub_Category,
Product_Name,
1 as IsCurrent,
CAST(GETDATE() AS DATE) as ValidFrom, '9999-12-31' as ValidTo
FROM Data;
--Populate TimeDim table
;WITH cte AS (
    SELECT
DATEADD(day, number, '2010-01-01') as FullDate FROM
master..spt_values WHERE
type = 'P' AND
number <= DATEDIFF(day, '2010-01-01', '2025-01-01')
)

INSERT INTO DimDate (FullDate, Year, Quarter, Month, MonthName, Week, DayOfYear, DayOfMonth, DayOfWeek, WeekdayName, IsWeekend)
SELECT
FullDate,
YEAR(FullDate) as Year,
DATEPART(quarter, FullDate) as Quarter, MONTH(FullDate) as Month,
DATENAME(month, FullDate) as MonthName, DATEPART(week, FullDate) as Week, DATEPART(dayofyear, FullDate) as DayOfYear, DAY(FullDate) as DayOfMonth, DATEPART(weekday, FullDate) as DayOfWeek, DATENAME(weekday, FullDate) as WeekdayName, CASE
WHEN DATENAME(weekday, FullDate) IN ('Saturday', 'Sunday') THEN 1
ELSE 0
END as IsWeekend
FROM
cte
-- Insert data into fact table
INSERT INTO FactSales (Order_ID, Customer_Key, Product_Key, Date_Key, Sales, Quantity, Discount, Profit)
SELECT
Order_ID, DimCustomer.Customer_Key, DimProduct.Product_Key, DimDate.Date_Key,

         Sales,
        Quantity,
        Discount,
        Profit
FROM Data
JOIN DimCustomer ON Data.Customer_ID = DimCustomer.Customer_ID JOIN DimProduct ON Data.Product_ID = DimProduct.Product_ID JOIN DimDate ON Data.Order_Date = DimDate.Order_Date;
-- Update the IsCurrent, ValidTo values for the previous name
UPDATE DimCustomer
SET IsCurrent = 0, ValidTo = GETDATE()
WHERE Customer_Key = [specific customer key] and IsCurrent = 1;
-- Insert a new row with the new name
INSERT INTO DimCustomer (Customer_Key, Customer_ID, Customer_Name, Segment, Location_Key, IsCurrent, ValidFrom, ValidTo)
VALUES ([specific customer key], [customer_id], [new_name], [segment], [location_key], 1, GETDATE(), '9999-12-31')
