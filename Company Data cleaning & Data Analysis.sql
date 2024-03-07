SELECT * FROM company.companies;
SELECT * FROM company.employees;
SELECT * FROM company.functions;
SELECT * FROM company.salaries;

/*Construction Site Employee Data Cleaning */

------------------------------------------------------------------------------------------------------------------------------------------------

/***Creating Temp Tables***/

-- Joining all tables and create a new one
-- It's TEMPORARY table to merge data from multiple tables

SELECT *
	INTO emp_dataset
	FROM salaries
	LEFT JOIN companies
	ON salaries.comp_name = companies.company_name
	LEFT JOIN functions
	ON salaries.func_code = functions.function_code
	LEFT JOIN employees
	ON salaries.employee_id = employees.employee_code_emp;

------------------------------------------------------------------------------------------------------------------------------------------------

-- Selecting only relevant columns for further analysis
-- Creating an unique identifier code between the columns 'employee_id' and 'date' and call it 'id'
-- Converting the column 'date' to DATE type because it was previously configured as TIMESTAMP
-- Transforming this new table into a dataset (df_employee) for analysis

SELECT CONCAT(employee_id, CAST(date AS date)) AS id,
	   CAST(date AS date) AS month_year,
       employee_id, 
       employee_name, 
	   GEN(M_F), -- It's between brackets because SQL may identify 'GEN(M_F)' as a non-existent formula. We will change the name of this column later
	   age,
       salary,
       function_group, 
       company_name, 
       company_city, 
       company_state, 
       company_type, 
       const_site_category
INTO df_employee
FROM emp_dataset;

------------------------------------------------------------------------------------------------------------------------------------------------
/***Wrangling data***/
-- Starting by changing bad column names. In this case we'll change the GEN(M_F) column name to 'gender'

 ALTER TABLE company.employees;


------------------------------------------------------------------------------------------------------------------------------------------------

-- Use 'TRIM' to remove all unwanted spaces from all text columns. This is the beginning of standartization

UPDATE df_employee
SET		id = TRIM(id),
		employee_id	= TRIM(employee_id),
		employee_name = TRIM(employee_name),
		gender = TRIM(gender),
		function_group = TRIM(function_group),
		company_name = TRIM(company_name),
		company_city = TRIM(company_city),
		company_state = TRIM(company_state),
		company_type = TRIM(company_type),
		const_site_category = TRIM(const_site_category);

------------------------------------------------------------------------------------------------------------------------------------------------

-- Check for 'NULL' values

SELECT *
	FROM df_employee
	WHERE id IS NULL
	OR month_year IS NULL
	OR employee_id IS NULL
	OR employee_name IS NULL
	OR gender IS NULL
	OR age IS NULL
	OR salary IS NULL
	OR function_group IS NULL
	OR company_name IS NULL
	OR company_city IS NULL
	OR company_state IS NULL
	OR company_type IS NULL
	OR const_site_category IS NULL;

------------------------------------------------------------------------------------------------------------------------------------------------

-- Check for 'empty' values (maybe in other databases this step is not needed, but in this case null and empty are different things)

SELECT *
	FROM df_employee
	WHERE id = ' '
	OR month_year = ' '
	OR employee_id = ' '
	OR employee_name = ' '
	OR gender = ' '
	OR age = ' '
	OR salary = ' '
	OR function_group = ' '
	OR company_name = ' '
	OR company_city = ' '
	OR company_state = ' '
	OR company_type = ' '
	OR const_site_category = ' ';

------------------------------------------------------------------------------------------------------------------------------------------------

-- Confirm missing values in all columns

-- id

SELECT COUNT(id) AS count_missing_id
	FROM df_employee
	WHERE id = ' ';
		
-- month_year

SELECT COUNT(month_year) AS count_missing_month_year
	FROM df_employee
	WHERE month_year = ' ';

-- gender

SELECT COUNT(gender) AS count_missing_gender
	FROM df_employee
	WHERE gender = ' ';

-- age

SELECT COUNT(age) AS count_missing_age
	FROM df_employee
	WHERE age = ' ';

-- salary

SELECT COUNT(salary) AS count_missing_salary
	FROM df_employee
	WHERE salary = ' ';
	
-- function_group

SELECT COUNT(function_group) AS count_missing_function_group
	FROM df_employee
	WHERE function_group = ' ';

-- company_name

SELECT COUNT(company_name) AS count_missing_company_name
	FROM df_employee
	WHERE company_name = ' ';

-- company_city

SELECT COUNT(company_city) AS count_missing_company_city
	FROM df_employee
	WHERE company_city = ' ';

-- company_state

SELECT COUNT(company_state) AS count_missing_company_state
	FROM df_employee
	WHERE company_state = ' ';

-- company_type

SELECT COUNT(company_type) AS count_missing_company_type
	FROM df_employee
	WHERE company_type = ' ';

-- const_site_category

SELECT COUNT(const_site_category) AS count_missing_const_site_category
	FROM df_employee
	WHERE const_site_category = ' ';
	   

------------------------------------------------------------------------------------------------------------------------------------------------

-- Deleting rows of the detected missing values 

-- salary

DELETE FROM df_employee
WHERE salary = ' ';

-- const_site_category


DELETE FROM df_employee
WHERE const_site_category = ' ';

------------------------------------------------------------------------------------------------------------------------------------------------
-- Checking standartization

-- id [ok]

SELECT DISTINCT id
FROM df_employee
GROUP BY id;

-- month_year [create a new column (pay_month) where the day is droped]

ALTER TABLE df_employee
ADD COLUMN pay_month AS (LEFT(month_year,7));

-- gender [Transform 'M' in 'Male' and 'F' in 'Female'

UPDATE df_employee
SET gender = CASE gender
                 WHEN 'M' THEN 'Male'
                 WHEN 'F' THEN 'Female'
                 ELSE gender
             END;
			
-- age [ok]

SELECT DISTINCT age
FROM df_employee
GROUP BY age
ORDER BY age;


-- salary [delete the 1 mi salary because it was used only as a test by the H.R. department]

DELETE FROM df_employee
WHERE salary = 1000000;
	
-- function_group [ok]

SELECT DISTINCT function_group
FROM df_employee
GROUP BY function_group;

-- company_name [ok]

SELECT DISTINCT company_name
FROM df_employee
GROUP BY company_name
ORDER BY company_name;

-- company_city [correct typing]

UPDATE df_employee
SET company_city = 'Goiania'
WHERE company_city = 'Goianiaa';

-- company_state [correct upper case to proper case]

UPDATE df_employee
SET company_state = 'Goias'
WHERE company_state = 'GOIAS';

-- company_type [correct typing]

UPDATE df_employee
SET company_type = 'Construction Site'
WHERE company_type = 'Construction Sites';

-- const_site_category [correct typing]

UPDATE df_employee
SET const_site_category = 'Commercial'
WHERE const_site_category = 'Commerciall';


------------------------------------------------------------------------------------------------------------------------------------------------

-- Check for duplicated rows in 'id' column.

SELECT DISTINCT id ,COUNT(id) as duplicated
FROM df_employee
GROUP BY id
HAVING COUNT(id) > 1;

-- Removing duplicate rows by creating a CTE with the WINDOW function ROWNUMBER.
-- The duplicates are those that contain repeated employee_id and pay_month.
-- Afterwards, apply the DELETE statement with the condition that the row_num is greater than 1.

WITH rncte AS
			(SELECT *,
					ROW_NUMBER()
					OVER(
					PARTITION BY pay_month, employee_id
					ORDER BY employee_id) row_num
			FROM df_employee)
DELETE
FROM rncte
WHERE row_num > 1;

------------------------------------------------------------------------------------------------------------------------------------------------

-- Now we check one last time to ensure that the df_employees table is clean and ready to be used for analysis. 
-- We have done all of this without changing the actual database, which is very important.

SELECT * FROM df_employee;

/*

After cleaning the data we do an analysis to answer some simple questions */
-- How many employees do the companies have today?

SELECT COUNT(DISTINCT employee_id) AS employee_count 
FROM df_employee
WHERE pay_month = (SELECT MAX(pay_month) FROM df_employee);

-- Group them by company

SELECT company_name, COUNT(DISTINCT employee_id) AS employee_count
FROM df_employee
WHERE pay_month = (SELECT MAX(pay_month) FROM df_employee)
GROUP BY company_name
ORDER BY employee_count DESC;

------------------------------------------------------------------------------------------------------------------------------------------------

-- What is the total number of employees each city? Add a percentage column

SELECT company_city, 
	   COUNT(employee_id) AS employee_count,
	   COUNT(employee_id) * 100 / SUM(COUNT(employee_id)) OVER () AS percentage
FROM df_employee
WHERE pay_month = (SELECT MAX(pay_month) FROM df_employee)
GROUP BY company_city
ORDER BY employee_count DESC;

------------------------------------------------------------------------------------------------------------------------------------------------

-- What is the total number of employees each month?

SELECT pay_month, COUNT(DISTINCT employee_id) AS employee_count 
FROM df_employee
GROUP BY pay_month
ORDER BY pay_month ASC;

------------------------------------------------------------------------------------------------------------------------------------------------

-- What is the average number of employees each month?

SELECT (COUNT(employee_id) / COUNT(DISTINCT pay_month)) AS avg_employees_per_month
FROM df_employee;

------------------------------------------------------------------------------------------------------------------------------------------------

-- What is the minimum and maximum number of employees throughout all the months? In which months were they?

SELECT TOP (1) pay_month, COUNT(employee_id) AS count_employees_per_month
FROM df_employee
GROUP BY pay_month
ORDER BY count_employees_per_month ASC;


SELECT TOP (1) pay_month, COUNT(employee_id) AS count_employees_per_month
FROM df_employee
GROUP BY pay_month
ORDER BY count_employees_per_month DESC;

------------------------------------------------------------------------------------------------------------------------------------------------

-- What is the monthly average number of employees by function group?

SELECT function_group, (COUNT(employee_id) / COUNT(DISTINCT pay_month)) AS avg_employees_per_month
FROM df_employee
GROUP BY function_group
ORDER BY avg_employees_per_month DESC;

------------------------------------------------------------------------------------------------------------------------------------------------

-- What is the annual average salary?

SELECT LEFT(pay_month, 4) AS year, ROUND(AVG(salary),2) AS average_salary
FROM df_employee
GROUP BY LEFT(pay_month, 4)
ORDER BY year;

-- What is the monthly average salary?

SELECT pay_month, ROUND(AVG(salary),2) AS average_salary
FROM df_employee
GROUP BY pay_month
ORDER BY pay_month;

-- What is the average salary by city?

SELECT company_city, 
	   ROUND(AVG(salary),2) AS average_salary
FROM df_employee
GROUP BY company_city
ORDER BY average_salary DESC;

-- What is the average salary by state?

SELECT company_state, ROUND(AVG(salary),2) AS average_salary
FROM df_employee
GROUP BY company_state
ORDER BY average_salary DESC;

-- What is the  average salary by function group?

SELECT function_group, ROUND(AVG(salary),2) AS average_salary
FROM df_employee
GROUP BY function_group
ORDER BY average_salary DESC;

------------------------------------------------------------------------------------------------------------------------------------------------

-- What are the employees with the top 10 highest salaries in average?

SELECT TOP (10) employee_name, ROUND(AVG(salary),2) AS average_salary
FROM df_employee
WHERE pay_month = (SELECT MAX(pay_month) FROM df_employee)
GROUP BY employee_name
ORDER BY average_salary DESC;
