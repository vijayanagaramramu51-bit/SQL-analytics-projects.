-- QuickBite: MySQL 8.0+ table setup
CREATE DATABASE IF NOT EXISTS quickbite_analytics;
USE quickbite_analytics;
CREATE TABLE DIM_CUSTOMER (CustomerID INT NOT NULL, Customer_Name VARCHAR(50), City VARCHAR(30), Email VARCHAR(100), Phone VARCHAR(15), Member_Since DATE);
CREATE TABLE DIM_DELIVERY_AGENT (AgentID INT PRIMARY KEY, Agent_Name VARCHAR(50), City VARCHAR(30), Vehicle VARCHAR(20), Rating DECIMAL(3,1));
CREATE TABLE DIM_RESTAURANT (RestaurantID INT PRIMARY KEY, Restaurant_Name VARCHAR(50), City VARCHAR(30), Cuisine_Type VARCHAR(30), Avg_Rating DECIMAL(3,1), Opening_Year INT);
CREATE TABLE FACT_ORDERS (OrderID INT PRIMARY KEY, CustomerID INT, RestaurantID INT, AgentID INT, Order_Date DATE, Order_Amount DECIMAL(8,2), Delivery_Minutes INT, Rating DECIMAL(3,1), Payment_Mode VARCHAR(20));
-- CustomerID intentionally has no unique constraint because duplicate accounts are part of the source data.
