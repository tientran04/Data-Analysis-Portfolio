/* 
1. INTRODUCTION
In this project, I will apply my SQL skill to perform Exploratory Data Analysis.
Skills covered in this project include data import, data manipulation and analysis.

2. DATASET
The dataset used in this project is the Crime Dataset of the City of Los Angeles from 2020 until April 2023.
Data source: https://catalog.data.gov/dataset/crime-data-from-2020-to-present

3. DATA PREPARATION
Since the data is stored in CSV file, I need to create a table in SQL and import the data from CSV file.
Below are sripts that I used to create table and import data.

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
*/

-- 4. DATA MANIPULATION AND ANALYSIS

-- 4.1. NUMBER OF CRIME CASES IN THE DATASET

SELECT COUNT(dr_no)
FROM us_crime;

-- There are 690,454 crime cases occured in the City of Los Angeles from 2020 until April 2023.


-- 4.2. TOTAL CRIME CASES IN 2020, 2021 AND 2022

SELECT DATE_PART('year', date_occ) AS year_occ, COUNT(dr_no) AS total_cases
FROM us_crime
WHERE DATE_PART('year', date_occ) != '2023'
GROUP BY year_occ;

-- The number of crime cases increased over years from 100,057 cases in 2020 to 232,443 cases in 2022.


-- 4.3. DAILY CASES IN EACH YEAR

WITH date_case AS (
	SELECT DATE_PART('year', date_occ) AS year_occ, date_occ, COUNT(dr_no) AS total_case
	FROM us_crime
	GROUP BY date_occ, year_occ)

SELECT year_occ, ROUND(AVG(total_case)) AS daily_case
FROM date_case
GROUP BY year_occ

-- Daily cases increased from 544 cases in 2020 to 637 cases in 2022.


-- 4.4. TIME OF THE DAY THAT CRIMINALS TEND TO COMMIT TO A CRIME

/* In order to analyze crime cases based on time, I will classify time into 4 groups as followings and 
analyze the data according to these group.
Time in a day:
- Morning: from 06:00 to 11:59.
- Afternoon: from 12:00 to 17:59.
- Evening: from 18:00 to 23:59.
- Night: from 00:00 to 05:59.
*/

SELECT 
	CASE
		WHEN time_occ BETWEEN '06:00:00' AND '11:59:00' THEN 'Morning'
		WHEN time_occ BETWEEN '12:00:00' AND '17:59:00' THEN 'Afternoon'
		WHEN time_occ BETWEEN '18:00:00' AND '23:59:00' THEN 'Evening'
		WHEN time_occ BETWEEN '00:00:00' AND '05:59:00' THEN 'Night'
		END AS time_group,
	COUNT(dr_no) AS total_cases
FROM us_crime
GROUP BY time_group;

-- During the day, criminals tend to commit to a crime in the afternoon and evening more than in morning and night time.


-- 4.5. TOP 5 AREAS THAT CRIME OCCURED THE MOST IN 2022

SELECT area_name, 
	   COUNT(dr_no) AS total_cases, 
	   ROUND(COUNT(dr_no) * 100.0 / (SELECT COUNT(dr_no) FROM us_crime 
									 WHERE DATE_PART('year', date_occ) = '2022'), 2) AS percentage
FROM us_crime
WHERE DATE_PART('year', date_occ) = '2022'
GROUP BY area_name
ORDER BY total_cases DESC
LIMIT 5;

-- In 2022, Central is the area that has most frequent crime with 7.56% of total cases, followed by 77th Street, Southwest, Pacific and Hollywood areas.


-- 4.6. TOP 5 CRIME TYPES

SELECT crm_cd_desc, COUNT(dr_no) AS total_cases
FROM us_crime
--WHERE DATE_PART('year', date_occ) = '2022'
GROUP BY crm_cd_desc
ORDER BY total_cases DESC
LIMIT 5;

-- From 2022 until present, Vehicle Stolen is the most frequent crime type happened in the City of Los Angeles with 74,370 cases.


-- 4.7. VICTIM DISTRIBUTION BY AGE GROUP

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
	ROUND(COUNT(dr_no) * 100.0 / (SELECT COUNT(dr_no) FROM us_crime WHERE vict_age > 0), 2) AS percentage
FROM us_crime
WHERE vict_age > 0
GROUP BY age_group
ORDER BY percentage DESC;

-- Young Adults is the most target victims for criminals with 43.54%, followed by Middle-aged Adults with 35.91% and Older Adults with 17.12%.


-- 4.8. TOP 5 POPULAR WEAPONS

SELECT weapon_desc, COUNT(dr_no) AS total_cases,
	   ROUND(COUNT(dr_no) * 100.0 / (SELECT COUNT(dr_no) FROM us_crime), 2) AS percentage
FROM us_crime
WHERE weapon_desc IS NOT NULL
GROUP BY weapon_desc
ORDER BY total_cases DESC
LIMIT 5;

-- The most popular weapon that criminals used the most is their arm, followed by other weapons, verbal threat, hand gun and semi-automatic pistol.
