DROP TABLE IF EXISTS temp_employees;

DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    employee_id VARCHAR(10) PRIMARY KEY,
    full_name VARCHAR(100),
    job_title VARCHAR(100),
    department VARCHAR(50),
    business_unit VARCHAR(100),
    gender VARCHAR(10),
    ethnicity VARCHAR(50),
    age INT,
    hire_date DATE,
    annual_salary INT,
    bonus_percent INT,
    country VARCHAR(50),
    city VARCHAR(50),
    exit_date DATE
);

-- Insert cleaned data into the final employees table - do this after the data cleaning and the verification
INSERT INTO employees (
    employee_id, full_name, job_title, department, business_unit, gender, ethnicity, age, hire_date, annual_salary, bonus_percent, country, city, exit_date
)
SELECT 
    employee_id, 
    SUBSTR(full_name, 1, 100), 
    SUBSTR(job_title, 1, 100), 
    SUBSTR(department, 1, 50), 
    SUBSTR(business_unit, 1, 100), 
    SUBSTR(gender, 1, 10), 
    SUBSTR(ethnicity, 1, 50), 
    age, 
    hire_date, 
    CAST(SUBSTR(CAST(annual_salary AS TEXT), 1, 20) AS INTEGER), 
    CAST(SUBSTR(CAST(bonus_percent AS TEXT), 1, 10) AS INTEGER), 
    SUBSTR(country, 1, 50), 
    SUBSTR(city, 1, 50), 
    exit_date
FROM temp_employees
WHERE employee_id IS NOT NULL
ORDER BY employee_id;

-- Start of data cleaning
-- Create a temporary table
CREATE TEMP TABLE temp_employees (
    employee_id VARCHAR(20),
    full_name VARCHAR(100),
    job_title VARCHAR(100),
    department VARCHAR(50),
    business_unit VARCHAR(100),
    gender VARCHAR(20),
    ethnicity VARCHAR(50),
    age INT,
    hire_date VARCHAR(20), -- Changed to VARCHAR to handle different formats
    annual_salary VARCHAR(20),
    bonus_percent VARCHAR(20),
    country VARCHAR(50),
    city VARCHAR(50),
    exit_date VARCHAR(20) -- Changed to VARCHAR to handle different formats
);

-- Import data into the temporary table
COPY temp_employees(employee_id, full_name, job_title, department, business_unit, gender, ethnicity, age, hire_date, annual_salary, bonus_percent, country, city, exit_date)
FROM 'C:/Users/aswds/Desktop/archive (1)/Employee Sample Data 1.csv' DELIMITER ',' CSV HEADER ENCODING 'LATIN1';


-- Identify the maximum numeric part of existing employee_id values
WITH max_id AS (
    SELECT COALESCE(MAX(CAST(SUBSTR(employee_id, 2) AS INTEGER)), 0) AS max_id
    FROM temp_employees
    WHERE employee_id IS NOT NULL
)
-- Step 2: Generate unique IDs for null employee_id values
UPDATE temp_employees
SET employee_id = (
    SELECT 'E' || LPAD((max_id + ROW_NUMBER() OVER (ORDER BY ctid))::TEXT, 5, '0')
    FROM max_id
)
WHERE employee_id IS NULL;


-- Inpute null values with default values for text columns
UPDATE temp_employees
SET 
    full_name = COALESCE(full_name, 'Unknown'),
    job_title = COALESCE(job_title, 'Not Specified'),
    department = COALESCE(department, 'Not Specified'),
    business_unit = COALESCE(business_unit, 'Not Specified'),
    gender = COALESCE(gender, 'Not Specified'),
    ethnicity = COALESCE(ethnicity, 'Not Specified'),
    country = COALESCE(country, 'Not Specified'),
    city = COALESCE(city, 'Not Specified');


-- Calculate median values for numeric columns
-- Clean annual_salary and bonus_percent columns by removing non-numeric characters
UPDATE temp_employees
SET 
    annual_salary = REGEXP_REPLACE(annual_salary::TEXT, '[^0-9]', '', 'g')::INTEGER,
    bonus_percent = REGEXP_REPLACE(bonus_percent::TEXT, '[^0-9]', '', 'g')::INTEGER;

-- Calculate median values for numeric columns
WITH medians AS (
    SELECT 
        percentile_cont(0.5) WITHIN GROUP (ORDER BY age) AS age_median,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY annual_salary::INTEGER) AS annual_salary_median,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY bonus_percent::INTEGER) AS bonus_percent_median
    FROM temp_employees
)
-- Inpute null values with median values for numeric columns
UPDATE temp_employees
SET 
    age = COALESCE(age, (SELECT age_median FROM medians)),
    annual_salary = COALESCE(annual_salary::INTEGER, (SELECT annual_salary_median FROM medians))::VARCHAR,
    bonus_percent = COALESCE(bonus_percent::INTEGER, (SELECT bonus_percent_median FROM medians))::VARCHAR;

-- Remove duplicate rows based on employee_id
DELETE FROM temp_employees
WHERE employee_id IN (
    SELECT employee_id
    FROM (
        SELECT employee_id, COUNT(*) AS count
        FROM temp_employees
        GROUP BY employee_id
        HAVING COUNT(*) > 1
    ) AS duplicates
)
AND ctid NOT IN (
    SELECT min(ctid)
    FROM temp_employees
    GROUP BY employee_id
);

-- Standardize text columns
UPDATE temp_employees
SET 
    full_name = INITCAP(TRIM(full_name)),
    job_title = INITCAP(TRIM(job_title)),
    department = INITCAP(TRIM(department)),
    business_unit = INITCAP(TRIM(business_unit)),
    gender = INITCAP(TRIM(gender)),
    ethnicity = INITCAP(TRIM(ethnicity)),
    country = INITCAP(TRIM(country)),
    city = INITCAP(TRIM(city));

-- Calculate the median hire date
WITH median_date AS (
    SELECT hire_date
    FROM temp_employees
    WHERE hire_date IS NOT NULL
    ORDER BY hire_date
    LIMIT 1 OFFSET (SELECT COUNT(*) FROM temp_employees WHERE hire_date IS NOT NULL) / 2
)
-- Impute null hire_date values with the median hire date
UPDATE temp_employees
SET hire_date = (SELECT hire_date FROM median_date)
WHERE hire_date IS NULL;


-- Convert hire_date from YYYY-MM-DD to MM/DD/YYYY
UPDATE temp_employees
SET hire_date = CASE 
                   WHEN hire_date::TEXT ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_CHAR(TO_DATE(hire_date, 'YYYY-MM-DD'), 'MM/DD/YYYY')
                   ELSE hire_date
                END;

-- Convert exit_date from YYYY-MM-DD to MM/DD/YYYY
UPDATE temp_employees
SET exit_date = CASE 
                   WHEN exit_date::TEXT ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_CHAR(TO_DATE(exit_date, 'YYYY-MM-DD'), 'MM/DD/YYYY')
                   ELSE exit_date
                END;

-- Convert the cleaned date columns to DATE type
ALTER TABLE temp_employees
ALTER COLUMN hire_date TYPE DATE USING TO_DATE(hire_date, 'MM/DD/YYYY'),
ALTER COLUMN exit_date TYPE DATE USING TO_DATE(exit_date, 'MM/DD/YYYY');



-- Calculate median values for age and annual_salary
WITH medians AS (
    SELECT 
        percentile_cont(0.5) WITHIN GROUP (ORDER BY age) AS age_median,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY annual_salary::INTEGER) AS annual_salary_median
    FROM temp_employees
)	
-- Replace outliers in age and annual_salary with median values
UPDATE temp_employees
SET 
    age = CASE 
            WHEN age < 18 OR age > 65 THEN (SELECT age_median FROM medians)
            ELSE age
          END,
    annual_salary = CASE 
                      WHEN annual_salary::INTEGER < 20000 OR annual_salary::INTEGER > 200000 
                      THEN (SELECT annual_salary_median FROM medians)::VARCHAR
                      ELSE annual_salary
                    END;


-- Ensure numeric columns are of correct data type

ALTER TABLE temp_employees
ALTER COLUMN age TYPE INTEGER USING age::INTEGER,
ALTER COLUMN annual_salary TYPE INTEGER USING annual_salary::INTEGER,
ALTER COLUMN bonus_percent TYPE INTEGER USING bonus_percent::INTEGER;


-- Verification queries

-- Check column definitions for the employees table
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'employees';

SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'temp_employees';

-- Increase the length of necessary columns
ALTER TABLE employees
ALTER COLUMN gender TYPE VARCHAR(20),
ALTER COLUMN bonus_percent TYPE VARCHAR(20);


-- Do not use this
-- Insert cleaned data into the main employees table
INSERT INTO employees
SELECT DISTINCT ON (employee_id) *
FROM temp_employees
WHERE employee_id IS NOT NULL
ORDER BY employee_id;


-- Verify data insertion
SELECT *
FROM employees
LIMIT 10;

SELECT *
FROM temp_employees
LIMIT 10;

-- Check for null values in each column
SELECT 
    SUM(CASE WHEN employee_id IS NULL THEN 1 ELSE 0 END) AS employee_id_nulls,
    SUM(CASE WHEN full_name IS NULL THEN 1 ELSE 0 END) AS full_name_nulls,
    SUM(CASE WHEN job_title IS NULL THEN 1 ELSE 0 END) AS job_title_nulls,
    SUM(CASE WHEN department IS NULL THEN 1 ELSE 0 END) AS department_nulls,
    SUM(CASE WHEN business_unit IS NULL THEN 1 ELSE 0 END) AS business_unit_nulls,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS gender_nulls,
    SUM(CASE WHEN ethnicity IS NULL THEN 1 ELSE 0 END) AS ethnicity_nulls,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS age_nulls,
    SUM(CASE WHEN hire_date IS NULL THEN 1 ELSE 0 END) AS hire_date_nulls,
    SUM(CASE WHEN annual_salary IS NULL THEN 1 ELSE 0 END) AS annual_salary_nulls,
    SUM(CASE WHEN bonus_percent IS NULL THEN 1 ELSE 0 END) AS bonus_percent_nulls,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS country_nulls,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS city_nulls,
    SUM(CASE WHEN exit_date IS NULL THEN 1 ELSE 0 END) AS exit_date_nulls
FROM temp_employees;


-- Check for duplicate rows based on employee_id
SELECT employee_id, COUNT(*)
FROM temp_employees
GROUP BY employee_id
HAVING COUNT(*) > 1;


-- Ensure numeric columns are of correct data type
ALTER TABLE temp_employees
ALTER COLUMN age TYPE INTEGER USING age::INTEGER,
ALTER COLUMN annual_salary TYPE INTEGER USING annual_salary::INTEGER,
ALTER COLUMN bonus_percent TYPE INTEGER USING bonus_percent::INTEGER;

-- Ensure date columns are of correct data type
ALTER TABLE temp_employees
ALTER COLUMN hire_date TYPE DATE USING TO_DATE(hire_date, 'MM/DD/YYYY'),
ALTER COLUMN exit_date TYPE DATE USING TO_DATE(exit_date, 'MM/DD/YYYY');


-- Identify outliers in age
SELECT *
FROM temp_employees
WHERE age < 18 OR age > 65;

-- Identify outliers in annual_salary
SELECT *
FROM temp_employees
WHERE annual_salary < 20000 OR annual_salary > 200000;


-- Identify rows with invalid hire_date or exit_date formats
SELECT employee_id, full_name, hire_date, exit_date
FROM temp_employees
WHERE (hire_date IS NOT NULL AND CAST(hire_date AS TEXT) !~ '^\d{2}/\d{2}/\d{4}$')
   OR (exit_date IS NOT NULL AND CAST(exit_date AS TEXT) !~ '^\d{2}/\d{2}/\d{4}$');

-- Ensure the date columns are VARCHAR
ALTER TABLE temp_employees
ALTER COLUMN hire_date TYPE VARCHAR(20),
ALTER COLUMN exit_date TYPE VARCHAR(20);








