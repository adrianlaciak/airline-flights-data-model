# Airline Flights Data Model

This repository contains SQL scripts that transform and analyze airline flight datasets.  
It includes data cleaning, relational modeling, indexing for performance, analytical queries, and stored procedures for flight insights.

## Features

- **Data cleaning and transformation**
  - Renames tables and columns for clarity
  - Sets appropriate data types
  - Removes duplicate records

- **Relational database model**
  - `Airlines`, `Cities`, `Flights`, `FlightSchedules`, `Tickets` tables
  - Foreign key constraints to maintain referential integrity

- **Data population**
  - Inserts data from raw dataset into normalized tables
  - Cleans up string formats (removes underscores, standardizes text)

- **Indexes**
  - Optimizes query performance with targeted indexing

- **Analytical queries**
  - Average ticket prices by route and class
  - Price distribution by booking days in advance
  - Flight counts per airline
  - Flight duration statistics by stops and time of day
  - Median ticket price calculations

- **Views and stored procedures**
  - `v_FlightDetails` view for consolidated reporting
  - `GetCheapestFlights` procedure for quick price lookup
  - Query to rank cheapest airlines by route

## Requirements

- Microsoft SQL Server (tested with T-SQL syntax)
- A raw dataset matching the structure of `RawFlights` (or `airlines_flights_data` before renaming)

## Usage

1. **Prepare the database**
   ```sql
   CREATE DATABASE AirlineFlightsDB;
   USE AirlineFlightsDB;
