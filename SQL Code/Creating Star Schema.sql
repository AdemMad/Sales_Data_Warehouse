drop database if exists sales_DB;
create database sales_DB;

use sales_DB;
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
    Postal_Code varchar (100),
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

update staging
set Postal_Code = '05408'
where Order_ID = 'US-2016-165505' and city = 'burlington' and state = 'vermont' and region = 'east';

--orders table--
drop table  if exists dim_orders;
create table dim_orders (
    Order_SK int identity (1,1),
    Order_ID varchar (100),
    Order_Date date,
    Ship_Date date,
    Ship_Mode varchar (100),
    constraint pk_ord primary key (Order_SK)
);


--customers table--
drop table  if exists dim_customers;
create table dim_customers (
    Customer_SK int identity (1,1),
    Customer_ID varchar (100),
    Full_Name varchar (100),
    F_Name as cast(substring (Full_Name, 0, charindex (' ', Full_Name)) as varchar (100)),
    L_Name  as cast(ltrim(substring (Full_Name, charindex (' ', Full_Name), 20)) as varchar (100)),
    Segment varchar (100),
    constraint pk_cust primary key (Customer_SK)
);


--location table--
drop table if exists dim_location;
create table dim_location (
    Location_SK int identity (1,1),
    Country varchar (100),
    City varchar (100),
    State varchar (100),
    Postal_Code varchar (100),
    Region varchar (100),
    constraint pk_loc primary key (Location_SK)
);


--product table--
drop table if exists dim_product;
create table dim_product (
    Product_SK int identity (1,1),
    Product_ID varchar (100),
    Category varchar (100),
    Sub_Category varchar (100), 
    Product_Name varchar (200), 
    constraint pk_prod primary key (Product_SK)
);


--date table--
drop table if exists dim_date;
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

--create fact table--
drop table if exists fact_table;
create table fact_table (
    Order_SK int,
    Customer_SK int,
    Location_SK int,
    Product_SK int,
    Date_SK int,
    Sales float,
    Quantity int,
    Discount float,
    Profit float
    constraint fk_ord foreign key (Order_SK) references dim_orders(Order_SK),
    constraint fk_cust foreign key (Customer_SK) references dim_customers(Customer_SK),
    constraint fk_loc foreign key (Location_SK) references dim_location(Location_SK),
    constraint fk_prod foreign key (Product_SK) references dim_product(Product_SK),
    constraint fk_date foreign key (Date_SK) references dim_date(Date_SK)
);

insert into fact_table
select 
b.Order_SK, 
c.Customer_SK, 
d.Location_SK, 
e.Product_SK, 
f.Date_SK, 
round(a.Sales, 2) as Sales, 
a.Quantity, round(a.Discount, 2) as Discount, 
round(a.Profit, 2) as Profit
from staging a
left join dim_orders b on a.Order_ID=b.Order_ID
left join dim_customers c on a.Customer_ID=c.Customer_ID
left join dim_location d on a.Postal_Code=d.Postal_Code and a.City=d.City and a.State=d.State and a.Region=d.Region
left join dim_product e on a.Product_ID=e.Product_ID and a.Product_Name=e.Product_Name and a.Category=e.Category and a.Sub_Category=e.Sub_Category
left join dim_date f on a.Order_Date=f.Date;
