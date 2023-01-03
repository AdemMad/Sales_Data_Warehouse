create database sales;

use sales;

--staging table--
drop table  if exists staging;
create table staging (
    Order_ID varchar (100),
    Order_Date date,
    Ship_Date date,
    Ship_Mode varchar (100),
    Customer_ID varchar (100),
    Customer_Name varchar (100),
    Segment varchar (100),
    Country varchar (100),
    City varchar (100),
    State varchar (100),
    Postal_Code int,
    Region varchar (100),
    Product_ID varchar (100),
    Category varchar (100),
    Sub_Category varchar (100), 
    Product_Name varchar (200), 
    Sales float,
    Quantity int,
    Discount float,
    Profit float
);

--orders table--
create table dim_orders (
    Order_SK int identity (1,1),
    Order_ID varchar (100),
    Order_Date date,
    Ship_Date date,
    Ship_Mode varchar (100),
    constraint pk_ord primary key (Order_SK)
);

insert into dim_orders
select distinct
    Order_ID,
    Order_Date,
    Ship_Date,
    Ship_Mode
from staging

--customers table--
create table dim_customers (
    Customer_SK int identity (1,1),
    Customer_ID varchar (100),
    Full_Name varchar (100),
    F_Name as substring (Full_Name, 0, charindex (' ', Full_Name)),
    L_Name  as ltrim(substring (Full_Name, charindex (' ', Full_Name), 20)),
    Segment varchar (100),
    constraint pk_cust primary key (Customer_SK)
);

insert into dim_customers
select distinct
    Customer_ID,
    Customer_Name,
    F_Name,
    L_Name
    Segment
from staging

--location table--
create table dim_location (
    Location_SK int identity (1,1),
    Country varchar (100),
    City varchar (100),
    State varchar (100),
    Postal_Code int,
    Region varchar (100),
    constraint pk_loc primary key (Location_SK)
);

insert into dim_location
select distinct
    Country,
    City,
    State,
    Postal_Code,
    Region
from staging


--product table--
create table dim_product (
    Product_SK int identity (1,1),
    Product_ID varchar (100),
    Category varchar (100),
    Sub_Category varchar (100), 
    Product_Name varchar (200), 
    constraint pk_prod primary key (Product_SK)
);

insert into dim_product
select distinct
    Product_ID,
    Category,
    Sub_Category, 
    Product_Name
from staging


--date table--
declare @start_date date = '2013-01-01'
declare @end_date date = '2018-01-01'
;with date_1  as (
select 1 as Date_SK, @start_date as date
union all
select Date_SK + 1, dateadd(DAY, +1, date)
from date_1 
where dateadd(DAY, +1, date) < @end_date
)

select Date_SK, date, year(date) as year, datename(month, date) as month_name , day(date) as day, case 
when month(date) between 1 and 3 then 'Q1'
when month(date) between 4 and 6 then 'Q2'
when month(date) between 7 and 9 then 'Q3'
else 'Q4' end as quarter,
datename(weekday, date) as day_name into dim_date
from date_1
order by 1
option (maxrecursion 0);


alter table dim_date
alter column Date_SK int not null;

alter table dim_date
add constraint pk_date primary key (Date_SK);

--create fact table
create table fact_table (
Order_SK int,
Customer_SK int,
Location_SK int,
Product_SK int,
Date_SK int,
constraint pk_fact primary key (Order_SK, Customer_SK, Location_SK, Product_SK, Date_SK),
constraint fk_ord foreign key (Order_SK) references dim_orders(Order_SK),
constraint fk_cust foreign key (Customer_SK) references dim_customers(Customer_SK),
constraint fk_loc foreign key (Location_SK) references dim_location(Location_SK),
constraint fk_prod foreign key (Product_SK) references dim_product(Product_SK),
constraint fk_date foreign key (Date_SK) references dim_date(Date_SK)
);

insert into fact_table
select b.Order_SK, c.Customer_SK, d.Location_SK, e.Product_SK, f.Date_SK
from staging a
left join dim_orders b on a.Order_ID=b.Order_ID
left join dim_customers c on a.Customer_ID=c.Customer_ID
left join dim_location d on a.Postal_Code=d.Postal_Code and a.City=d.City and a.State=d.State
left join dim_product e on a.Product_ID=e.Product_ID
left join dim_date f on a.Order_Date=b.Order_Date;