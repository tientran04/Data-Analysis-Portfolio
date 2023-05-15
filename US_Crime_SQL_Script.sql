
-- 1. INTRODUCTION
-- Crimes have become a problem in morden society since there are more and more crimes nowadays.
-- In this project, I will apply SQL skills to analyze crime dataset in order to understand the behaviours of criminals.

-- 2. DATASET
-- The dataset used in this project is the Crime Dataset of the City of Los Angeles from 2020 until present.
-- Data source: https://catalog.data.gov/dataset/crime-data-from-2020-to-present

-- 3. DATA PREPARATION
-- 3.1. DATA IMPORT
-- Since the data is stored in CSV file, I will create a table in SQL and import the data from CSV file.
-- Below are sripts that I used to create table and import data.
-- Create table
CREATE TABLE IF NOT EXISTS us_crime (
	dr_no VARCHAR(10),
	date_rptd DATE,
	date_occ DATE,
	time_occ TIME,
	area VARCHAR(2),
	area_name VARCHAR(128),
	rpt_dist_no VARCHAR(10),
	part_1_2 VARCHAR(1),
	crm_cd VARCHAR(3),
	crm_cd_desc VARCHAR(256),
	monocodes VARCHAR(128),
	vict_age INTEGER,
	vict_sex VARCHAR(1),
	vict_descent VARCHAR(1),
	premis_cd VARCHAR(3),
	premis_desc VARCHAR(256),
	weapon_used_cd VARCHAR(3),
	weapon_desc VARCHAR(256),
	status VARCHAR(2),
	status_desc VARCHAR(128),
	crm_cd1 VARCHAR(3),
	crm_cd2 VARCHAR(3),
	crm_cd3 VARCHAR(3),
	crm_cd4 VARCHAR(3),
	location VARCHAR(128),
	cross_street VARCHAR(128),
	lat FLOAT,
	lon FLOAT,
	PRIMARY KEY (dr_no)
	)
	
-- Import data
COPY us_crime
FROM 'C:\Users\Admin\Desktop\Case Study\US Crime\Crime_Data_from_2020_to_Present.csv'
DELIMITER ','
CSV HEADER;


-- 4. DATA MANIPULATION AND ANALYSIS
-- Since the year 2023 is still going, I will exclude 2023 data from my analysis.

-- 4.1. CRIME CASES AND PERCENTAGE CHANGE FROM 2020 TO 2022
SELECT  year_occ, 
		total_cases, 
		(total_cases*1.0/ FIRST_VALUE(total_cases) OVER(ORDER BY year_occ) - 1) AS pct_compared_2020
FROM
(
	SELECT  DATE_PART('year', date_occ) AS year_occ, 
			COUNT(dr_no) AS total_cases
	FROM us_crime
	WHERE DATE_PART('year', date_occ) BETWEEN 2020 AND 2022
	GROUP BY year_occ
) a;

-- The number of crime cases increased from 199,057 cases in 2020 to 232,443 cases in 2022.
-- Compared to 2020, the total cases in 2021 increased 4.94% and the total cases in 2022 increased 16.77%.


-- 4.2 MONTHLY CASES ANALYSIS
SELECT  month_occ,
		MAX(CASE WHEN year_occ = 2020 THEN total_cases END) AS year_2020,
		MAX(CASE WHEN year_occ = 2021 THEN total_cases END) AS year_2021,
		MAX(CASE WHEN year_occ = 2022 THEN total_cases END) AS year_2022,
		SUM(total_cases) AS total_cases,
		AVG(total_cases) AS avg_cases
FROM
(
	SELECT  DATE_PART('year', date_occ) AS year_occ,
			DATE_PART('month', date_occ) AS month_occ,
			COUNT(dr_no) AS total_cases
	FROM us_crime
	WHERE DATE_PART('year', date_occ) BETWEEN 2020 AND 2022
	GROUP BY 1, 2
) a
GROUP BY 1
ORDER BY 1;

-- The cases fluctuates over months, so there is no correlation between month and cases happened.


-- 4.3. WEEKDAY CASES ANALYSIS
SELECT  weekday,
		day_name,
		avg_cases,
		avg_cases - MIN(avg_cases) OVER() AS diff_vs_min,
		avg_cases*1.0/MIN(avg_cases) OVER() - 1 AS diff_vs_min_pct
FROM
(
	SELECT  weekday,
			day_name,
			AVG(total_cases) AS avg_cases
	FROM
	(
		SELECT  date_occ,
				EXTRACT( ISODOW FROM date_occ) AS weekday,
				TO_CHAR(date_occ, 'Day') as day_name,
				COUNT(dr_no) AS total_cases
		FROM us_crime
		WHERE DATE_PART('year', date_occ) BETWEEN 2020 AND 2022
		GROUP BY 1, 2, 3
	) a
	GROUP BY 1, 2
	ORDER BY 1
) aa
ORDER BY 1;


-- Friday is the day of the week that has most cases, followed by Saturday.


-- 4.4. HOURLY CASE ANALYSIS
SELECT  hour_occ,
		AVG(total_cases) AS avg_cases
FROM
(
	SELECT  date_occ,
			DATE_PART('hour', time_occ) AS hour_occ,
			COUNT(dr_no) AS total_cases
	FROM us_crime
	WHERE DATE_PART('year', date_occ) BETWEEN 2020 AND 2022
	GROUP BY 1, 2
) a
GROUP BY 1
ORDER BY 1;

-- Criminals tend to commit to a crime at 12PM until midnight.


-- 4.5. DISTRIBUTION BY AREA IN 2022
SELECT  area_name,
		total_cases,
		total_cases*1.0/SUM(total_cases) OVER(PARTITION BY year_occ) AS pct
FROM
(
	SELECT  DATE_PART('year', date_occ) AS year_occ,
			area_name, 
			COUNT(dr_no) AS total_cases
	FROM us_crime
	WHERE DATE_PART('year', date_occ) = 2022
	GROUP BY 1,2 
	ORDER BY 1, 3 DESC
) a;

-- In 2022, Central is the area that has most frequent crime with 7.56% of total cases, followed by 77th Street, Southwest, Pacific and Hollywood areas.


-- 4.6. TOP FIVE CRIME TYPES IN 2022
SELECT  crm_cd_desc, 
		COUNT(dr_no) AS total_cases,
		COUNT(dr_no)*1.0/(SELECT COUNT(dr_no) FROM us_crime 
					  WHERE DATE_PART('year', date_occ) = 2022) AS pct
FROM us_crime
WHERE DATE_PART('year', date_occ) = 2022
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- In 2022, Vehicle Stolen is the most frequent crime type happened, accounted for 10.61% of total cases, followed by Theft of Identity, Battery - Simple Assault, Burglary From Vehicle and Burglary.


-- 4.7. VICTIM DISTRIBUTION BY AGE GROUP IN 2022
/* I will classify age into following groups for this analysis.
- Children: 1 to 12 years old
- Adolescents: 13 to 17 years old
- Young Adults: 18 to 35 years old
- Middle-aged Adults: 36 to 55 years old
- Older Adults: > 55 years old
*/

SELECT 
	CASE
		WHEN vict_age BETWEEN 1 AND 12 THEN 'Children'
		WHEN vict_age BETWEEN 13 AND 17 THEN 'Adolescents'
		WHEN vict_age BETWEEN 18 AND 35 THEN 'Young Adults'
		WHEN vict_age BETWEEN 36 AND 55 THEN 'Middle-aged Adults'
		WHEN vict_age > 55 THEN 'Older Adults'
	END AS age_group,
	COUNT(dr_no) AS total_cases,
	COUNT(dr_no)* 1.0/(SELECT COUNT(dr_no) FROM us_crime WHERE vict_age > 0
								 AND DATE_PART('year', date_occ) = 2022) AS pct
FROM us_crime
WHERE vict_age > 0 AND DATE_PART('year', date_occ) = 2022
GROUP BY 1
ORDER BY 3 DESC;

-- In 2022, Young Adults is the most target victims for criminals with 43.92%, followed by Middle-aged Adults with 35.68% and Older Adults with 16.89%.


-- 5. CONCLUSIONS
/* From the analysis, there are useful insights as followings.
- Crime cases have increased more in 2022 compared with 2021.
- There is no clear relationship between crime and month during a year.
- Friday and Saturday are two days with the most crimes.
- Criminals tend to commit to a crime at 12PM until midnight.
- In 2022:
	Central, 77th Street, Southwest, Pacific and Hollywood are top five ares having the most cases, accounted for almost 30% of total cases.
	Vehicle Stolen and Theft of Identity are the two most happened crime types, accounted for nearly 20% of total cases.
	Young Adults (age from 18 to 35) and Middle-aged Adults (age from 36 to 55) are the two most target victims, accounted for around 80% of total cases.
*/