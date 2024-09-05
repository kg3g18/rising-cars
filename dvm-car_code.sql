/*Create a visualisation that shows the correlation between the number of new car model releases versus the growth in sales volume from 2017 to 2019. Include sales each year for reference*/
/*CSV Output: sales_volume_new_releasesv2.csv*/

WITH cte_1 AS (
	SELECT 
		Maker,
		SUM(Releases) AS Releases
	FROM(
		SELECT 
			Maker,
			Genmodel,
			Genmodel_ID,
			MIN(Year) AS Release_Year,
			CASE WHEN MIN(Year) BETWEEN 2017 AND 2019 THEN 1
			ELSE 0
			END AS Releases
		FROM dbo.prices
		GROUP BY Maker, Genmodel, Genmodel_ID) AS t
	GROUP BY Maker),

	cte_2 AS (SELECT
		Maker,		
		SUM(Y_2019) AS '2019',
		SUM(Y_2018) AS '2018',
		SUM(Y_2017) AS '2017',
		(SUM(Y_2019) + SUM(Y_2018) + SUM(Y_2017)) AS Total_Sales,
		CASE WHEN SUM(Y_2019) > 0 AND SUM(Y_2017) > 0 THEN
			ROUND(((SUM(Y_2019) - SUM(Y_2017))/ SUM(Y_2017)),4)
		ELSE 0
		END AS 'Vol_Gro%'
	FROM dbo.sales
	GROUP BY Maker)

SELECT 
	cte_1.Maker,
	cte_1.Releases,
	cte_2.[2019],
	cte_2.[2018],
	cte_2.[2017],
	cte_2.Total_Sales,
	cte_2.[Vol_Gro%]
FROM cte_1
LEFT JOIN cte_2 ON cte_1.Maker = cte_2.Maker
WHERE cte_2.[2017] > 100 AND cte_2.[2019] > 100
ORDER BY Releases DESC

/*Show the total sales volume of each Maufacturer between 2017 and 2019 and their average price*/
/*CSV Output: highest_selling_average.csv*/

WITH cte_1 AS (
	SELECT
		TOP 10 Maker,
		SUM(Y_2019) AS '2019',
		SUM(Y_2018) AS '2018',
		SUM(Y_2017) AS '2017',
		(SUM(Y_2019) + SUM(Y_2018) + SUM(Y_2017)) AS Total_Sales
	FROM dbo.sales 
	GROUP BY Maker
	ORDER BY Total_Sales DESC),

cte_2 AS (
	SELECT
		Maker,
		AVG(Entry_price) AS Average_price
	FROM dbo.prices
	WHERE Year BETWEEN 2017 AND 2019
	GROUP BY Maker)

SELECT
	cte_1.Maker,
	cte_1.[2019],
	cte_1.[2018],
	cte_1.[2017],
	cte_1.[Total_Sales],
	cte_2.[Average_price]
FROM cte_1
LEFT JOIN cte_2 ON cte_1.Maker = cte_2.Maker 
				OR cte_2.Maker LIKE cte_1.Maker + '%'
ORDER BY Total_Sales DESC

/*Show the total sales volume growth of each Maufacturer between 2017 and 2019*/
/*CSV Output: highest_growers.csv*/

SELECT
	TOP 10 Maker,
	CASE WHEN SUM(Y_2019) > 0 AND SUM(Y_2017) > 0 THEN
			ROUND(((SUM(Y_2019) - SUM(Y_2017))/ SUM(Y_2017)*100),2)
		ELSE 0
		END AS 'Vol_Gro%',
	SUM(Y_2019) AS '2019',
	SUM(Y_2017) AS '2017'
FROM dbo.sales
GROUP BY Maker
ORDER BY [Vol_Gro%] DESC

-- Cars with no sales in 2017 are exlcuded to avoid anomalies.

/*Create a visualisation to show sales volume by each engine size + fuel type between 2017 and 2019. Include sales per car to allow comparison*/
/*CSV Output: sales_by_type.csv*/

SELECT 
	c.Engine,
	c.Fuel_type,
	COUNT(*) AS No_Cars,
	SUM(Y_2019)	AS '2019',
	SUM(Y_2018)	AS '2018',
	SUM(Y_2017)	AS '2017',
	(SUM(Y_2019) + SUM(Y_2018) + SUM(Y_2017)) AS Total_Sales,
	ROUND(((SUM(Y_2019) + SUM(Y_2018) + SUM(Y_2017))/ COUNT(*)), 0) AS Sales_Per_Car
FROM(
	SELECT
		Maker,
		Genmodel,
		Genmodel_ID,
		Fuel_type,
		CASE WHEN ROUND(Engine_size, -2) <= 1000 THEN '< 1.0L'
		WHEN ROUND(Engine_size, -2) BETWEEN 1100 AND 2000 THEN '1.1 - 2.0L'
		WHEN ROUND(Engine_size, -2) BETWEEN 2100 AND 3000 THEN '2.1L - 3.0L'
		WHEN ROUND(Engine_size, -2) > 3000 THEN '> 3.0L'
		ELSE 'Other'
		END AS Engine
	FROM dbo.trim) AS c
LEFT JOIN dbo.sales s ON c.Genmodel_ID = s.Genmodel_ID
GROUP BY c.Engine, c.Fuel_type
ORDER BY Sales_Per_Car DESC

/*Show the fuel types of cars being sold by the top growing manufacturers between 2017 and 2019*/
/*CSV Output: highest_growers_by_fuel_type.csv*/

SELECT 
	Maker,
	SUM(Petrol_Cars) AS Petrol_Cars,
	SUM(Diesel_Cars) AS Diesel_Cars,
	SUM(Other_Cars) AS Other_Cars,
	SUM(REX_Cars) AS REX_Cars
FROM (	
	SELECT
		Maker,
		CASE WHEN Fuel_type = 'Petrol' THEN 1
		ELSE 0 
		END AS Petrol_Cars,
		CASE WHEN Fuel_type = 'Diesel' THEN 1
		ELSE 0 
		END AS Diesel_Cars,
		CASE WHEN Fuel_type = 'Other' THEN 1
		ELSE 0 
		END AS Other_Cars,
		CASE WHEN Fuel_type = 'Electric Diesel REX' THEN 1
		ELSE 0 
		END AS REX_Cars
	FROM dbo.trim) c
	WHERE Maker IN (SELECT
		TOP 10 Maker
	FROM dbo.sales
	GROUP BY Maker
	ORDER BY CASE WHEN SUM(Y_2019) > 0 AND SUM(Y_2017) > 0 THEN
				ROUND(((SUM(Y_2019) - SUM(Y_2017))/ SUM(Y_2017)*100),2)
			ELSE 0
			END DESC)
GROUP BY Maker

/*Show the emissions of cars being sold by the top growing manufacturers between 2017 and 2019*/
/*CSV Output: highest_growers_by_emissions.csv*/

SELECT
	Maker,
	AVG(Gas_emission) AS Average_Emissions
FROM dbo.trim
WHERE Maker IN (SELECT 
		TOP 10 Maker
	FROM dbo.sales
	GROUP BY Maker
	ORDER BY CASE WHEN SUM(Y_2019) > 0 AND SUM(Y_2017) > 0 THEN
			ROUND(((SUM(Y_2019) - SUM(Y_2017))/ SUM(Y_2017)*100),2)
			ELSE 0
			END DESC)
GROUP BY Maker

/*Compare the average price of new releases versus cars released prior to 2017*/
/*CSV Output: average_prices.csv*/

WITH cte_1 AS (
	SELECT 
		Maker,
		Genmodel,
		Genmodel_ID,
		MIN(Year) AS Release_Year,
		CASE WHEN MIN(Year) BETWEEN 2017 AND 2019 THEN 1
		ELSE 0
		END AS Releases
	FROM dbo.prices 
	GROUP BY Maker, Genmodel, Genmodel_ID),

cte_2 AS (
	SELECT 
		* 
	FROM dbo.prices)

SELECT 
	'New Releases' AS Release_Type,
	AVG(cte_2.Entry_price) AS Average_Price
FROM cte_2 
INNER JOIN cte_1 ON cte_2.Genmodel_ID  = cte_1.Genmodel_ID 
				AND cte_1.Release_Year = cte_2.Year
UNION ALL
SELECT
	'Existing Releases' AS Release_Type,
	AVG(cte_2.Entry_price) AS Average_Price
FROM cte_2
INNER JOIN cte_1 ON cte_2.Genmodel_ID = cte_1.Genmodel_ID
				AND cte_1.Release_Year NOT BETWEEN 2017 AND 2019
WHERE cte_2.Year BETWEEN 2017 AND 2019