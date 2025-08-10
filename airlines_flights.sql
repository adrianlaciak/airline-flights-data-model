-- Renaming the table for clarity
EXEC sp_rename 'airlines_flights_data', 'RawFlights'

-- Setting the correct data types for columns
ALTER TABLE RawFlights
ALTER COLUMN price INT;

ALTER TABLE RawFlights
ALTER COLUMN days_left INT;

ALTER TABLE RawFlights
ALTER COLUMN duration FLOAT;

ALTER TABLE RawFlights
ALTER COLUMN class VARCHAR(50);

ALTER TABLE RawFlights
ALTER COLUMN destination_city VARCHAR(50);

ALTER TABLE RawFlights
ALTER COLUMN arrival_time NVARCHAR(50);

ALTER TABLE RawFlights
ALTER COLUMN stops VARCHAR(50);

ALTER TABLE RawFlights
ALTER COLUMN departure_time NVARCHAR(50);

ALTER TABLE RawFlights
ALTER COLUMN source_city VARCHAR(50);

ALTER TABLE RawFlights
ALTER COLUMN flight NVARCHAR(50);

ALTER TABLE RawFlights
ALTER COLUMN airline NVARCHAR(50);

-- Renaming the 'index' column to 'id' for better clarity
EXEC sp_rename 'RawFlights.index', 'id', 'COLUMN';

-- Removing duplicate rows from the dataset
DELETE FROM RawFlights
WHERE id NOT IN (
	SELECT min(id)
	FROM RawFlights
	GROUP BY airline, flight, departure_time, destination_city
);

-- Creating the relational data model
CREATE TABLE Airlines (
	AirlineID INT IDENTITY PRIMARY KEY,
	AirlineName NVARCHAR(50) UNIQUE
);

CREATE TABLE Cities (
	CityID INT IDENTITY PRIMARY KEY,
	City NVARCHAR(50) UNIQUE);

CREATE TABLE Flights (
	FlightID INT IDENTITY PRIMARY KEY,
	AirlineID INT FOREIGN KEY REFERENCES Airlines(AirlineID),
	FlightCode NVARCHAR(50),
	SourceCityID INT FOREIGN KEY REFERENCES Cities(CityID),
	DestinationCityID INT FOREIGN KEY REFERENCES Cities(CityID)
);

CREATE TABLE FlightSchedules (
	ScheduleID INT IDENTITY PRIMARY KEY,
	FlightID INT FOREIGN KEY REFERENCES Flights(FlightID),
	DepartureTime NVARCHAR(50),
	ArrivalTime NVARCHAR(50),
	Stops NVARCHAR(50),
	Duration FLOAT
);

CREATE TABLE Tickets (
	TicketID INT IDENTITY PRIMARY KEY,
	ScheduleID INT FOREIGN KEY REFERENCES FlightSchedules(ScheduleID),
	Class NVARCHAR(50),
	DaysLeft INT,
	Price INT
);

-- Inserting data into related tables
INSERT INTO Airlines (AirlineName)
SELECT DISTINCT airline
FROM RawFlights
WHERE airline IS NOT NULL;

UPDATE Airlines
SET AirlineName = REPLACE(AirlineName, '_', ' ')

INSERT INTO Cities (City)
SELECT DISTINCT source_city
FROM RawFlights
WHERE source_city IS NOT NULL
UNION
SELECT DISTINCT destination_city
FROM RawFlights
WHERE destination_city IS NOT NULL;

INSERT INTO Flights (AirlineID, FlightCode, SourceCityID, DestinationCityID)
SELECT
	a.AirlineID,
	r.flight,
	sc.CityID,
	dc.CityID
FROM RawFlights  r
INNER JOIN Airlines  a ON a.AirlineName = r.airline
INNER JOIN Cities  sc ON sc.City = r.source_city
INNER JOIN Cities  dc ON dc.City = r.destination_city;

INSERT INTO FlightSchedules (FlightID, DepartureTime, ArrivalTime, Stops, Duration)
SELECT
	f.FlightID,
	r.departure_time,
	r.arrival_time,
	r.stops,
	r.duration
FROM Flights  f
INNER JOIN RawFlights  r
ON f.FlightCode = r.flight;

UPDATE FlightSchedules
SET 
	DepartureTime = REPLACE(DepartureTime, '_', ' '),
	ArrivalTime = REPLACE(ArrivalTime, '_', ' '),
	Stops = REPLACE(Stops, '_', ' ');

INSERT INTO Tickets (ScheduleID, Class, DaysLeft, Price)
SELECT
	s.ScheduleID,
	r.class,
	r.days_left,
	r.price
FROM FlightSchedules  s
INNER JOIN Flights  f
ON f.FlightID = s.FlightID
INNER JOIN RawFlights  r
ON f.FlightCode = r.flight;

-- Creating indexes to optimize query performance
CREATE INDEX IX_Tickets_ScheduleID 
	ON Tickets(ScheduleID);

CREATE INDEX IX_Flights_AirlineID
	ON Flights(AirlineID);

CREATE INDEX IX_FlightSchedules_FlightID
	ON FlightSchedules(FlightID);

CREATE INDEX IX_Flights_SourceCityID
	ON Flights(SourceCityID);

CREATE INDEX IX_Flights_DestinationCityID
	ON Flights(DestinationCityID);

-- Calculating average ticket prices for each source-destination city pair, segmented by class
SELECT
	sc.City AS 'Source city',
	dc.City AS 'Destination city',
	AVG(t.Price) AS 'Average ticket price'
FROM Tickets  t
INNER JOIN FlightSchedules  fs
ON t.ScheduleID = fs.ScheduleID
INNER JOIN Flights  f
ON fs.FlightID = f.FlightID
INNER JOIN Cities  sc
ON f.SourceCityID = sc.CityID
INNER JOIN Cities  dc
ON f.DestinationCityID = dc.CityID
GROUP BY sc.City, dc.City
ORDER BY sc.City, dc.City;

-- Calculating average ticket prices per class with breakdown by days left before the flight
SELECT
	Class,
	DaysLeft AS 'Days Left',
	AVG(Price) AS 'Average ticket price'
FROM Tickets
GROUP BY Class, DaysLeft
ORDER BY Class DESC, DaysLeft;

-- Airlines with the highest number of flights
SELECT
	a.AirlineName AS Airline,
	COUNT(f.FlightCode) AS 'Number of flights'
FROM Flights  f
LEFT JOIN Airlines  a
ON f.AirlineID = a.AirlineID
GROUP BY AirlineName
ORDER BY 'Number of flights' DESC;

-- Calculating average, minimum, and maximum ticket prices per class within each airline
SELECT
	a.AirlineName AS Airline,
	t.Class,
	AVG(t.Price) AS 'Average price',
	MIN(t.Price) AS 'Minimum price',
	MAX(t.Price) AS 'Maximum price'
FROM Tickets  t
INNER JOIN FlightSchedules  fs
ON t.ScheduleID = fs.ScheduleID
INNER JOIN Flights  f
ON fs.FlightID = f.FlightID
INNER JOIN Airlines  a
ON f.AirlineID = a.AirlineID
GROUP BY a.AirlineName, t.Class
ORDER BY AirlineName, 'Average price';

-- Calculating average flight duration based on number of stops and differences according to departure time of day
SELECT
	DepartureTime AS 'Departure Time',
	Stops,
	CAST(AVG(Duration) AS DECIMAL(10, 2)) AS 'Average duration'
FROM FlightSchedules
GROUP BY DepartureTime, Stops
ORDER BY CASE DepartureTime
	WHEN 'Early Morning' THEN 1
	WHEN 'Morning' THEN 2
	WHEN 'Afternoon' THEN 3
	WHEN 'Evening' THEN 4
	WHEN 'Night' THEN 5
	WHEN 'Late Night' THEN 6
	END, 
CASE Stops
	WHEN 'zero' THEN 1
	WHEN 'one' THEN 2
	WHEN 'two or more' THEN 3
	END;
	SELECT * FROM RawFlights

-- Calculating median ticket price based on days left until the flight
SELECT DISTINCT 
	DaysLeft AS 'Days left',
	Class,
	PERCENTILE_CONT(0.5) 
	WITHIN GROUP (ORDER BY Price)
	OVER (PARTITION BY DaysLeft, Class) AS 'Median price'
FROM Tickets
ORDER BY DaysLeft;

-- Creating a view that consolidates all relevant data into one report
CREATE VIEW v_FlightDetails AS
SELECT
	t.TicketID AS 'Ticket ID',
	a.AirlineName AS 'Airline',
	f.FlightCode AS 'Flight code',
	sc.City AS 'Source city',
	dc.City AS 'Duration city',
	s.DepartureTime AS 'Departure time',
	s.ArrivalTime AS 'Arrival time',
	s.Stops,
	s.Duration,
	t.Class,
	t.DaysLeft AS 'Days left',
	t.Price
FROM Tickets  t
INNER JOIN FlightSchedules  s ON t.ScheduleID = s.ScheduleID
INNER JOIN Flights  f ON s.FlightID = f.FlightID
INNER JOIN Airlines  a ON f.AirlineID = a.AirlineID
INNER JOIN Cities  sc ON f.SourceCityID = sc.CityID
INNER JOIN Cities  dc ON f.DestinationCityID = dc.CityID;

-- Cheapest flights search procedure
CREATE PROCEDURE GetCheapestFlights
	@SourceCity NVARCHAR(50),
	@DestinationCity NVARCHAR(50)
AS
BEGIN
	SELECT TOP 5
		a.AirlineName,
		f.FlightCode,
		t.Price,
		t.Class,
		fs.DepartureTime
	FROM Tickets  t
	INNER JOIN FlightSchedules  fs ON t.ScheduleID = fs.ScheduleID
	INNER JOIN Flights  f ON fs.FlightID = f.FlightID
	INNER JOIN Airlines  a ON f.AirlineID = a.AirlineID
	INNER JOIN Cities  sc ON f.SourceCityID = sc.CityID
	INNER JOIN Cities  dc ON f.DestinationCityID = dc.CityID
	WHERE sc.City = @SourceCity AND dc.City = @DestinationCity
	ORDER BY Price ASC;
END;

-- Cheapest flights from Delhi to Mumbai
EXEC dbo.GetCheapestFlights
	@SourceCity = 'Delhi',
	@DestinationCity = 'Mumbai';

-- Ranking the cheapest airlines by city
WITH AvgPrices AS (
    SELECT
        a.AirlineName,
        sc.City AS SourceCity,
        dc.City AS DestinationCity,
        AVG(t.Price) AS AvgPrice
    FROM Tickets t
    JOIN FlightSchedules fs ON t.ScheduleID = fs.ScheduleID
    JOIN Flights f ON fs.FlightID = f.FlightID
    JOIN Airlines a ON f.AirlineID = a.AirlineID
    JOIN Cities sc ON f.SourceCityID = sc.CityID
    JOIN Cities dc ON f.DestinationCityID = dc.CityID
    GROUP BY a.AirlineName, sc.City, dc.City
)
SELECT *
FROM (
    SELECT *,
           RANK() OVER (PARTITION BY SourceCity, DestinationCity ORDER BY AvgPrice ASC) AS PriceRank
    FROM AvgPrices
) ranked
WHERE PriceRank = 1
ORDER BY SourceCity, DestinationCity;