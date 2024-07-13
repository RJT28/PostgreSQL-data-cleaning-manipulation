-- Calculate tenure for each employee
ALTER TABLE employees ADD COLUMN tenure INT;

UPDATE employees
SET tenure = DATE_PART('year', AGE(hire_date, COALESCE(exit_date, CURRENT_DATE)));

-- Create age groups
ALTER TABLE employees ADD COLUMN age_group VARCHAR(20);

UPDATE employees
SET age_group = CASE
    WHEN age BETWEEN 18 AND 25 THEN '18-25'
    WHEN age BETWEEN 26 AND 35 THEN '26-35'
    WHEN age BETWEEN 36 AND 45 THEN '36-45'
    WHEN age BETWEEN 46 AND 55 THEN '46-55'
    WHEN age BETWEEN 56 AND 65 THEN '56-65'
    ELSE '65+'
END;

-- Create salary bands
ALTER TABLE employees ADD COLUMN salary_band VARCHAR(20);

UPDATE employees
SET salary_band = CASE
    WHEN annual_salary < 50000 THEN '<50K'
    WHEN annual_salary BETWEEN 50000 AND 100000 THEN '50K-100K'
    WHEN annual_salary BETWEEN 100001 AND 150000 THEN '100K-150K'
    ELSE '>150K'
END;


-- Departmental statistics
-- Departmental statistics with median calculation
SELECT 
    department,
    COUNT(*) AS employee_count,
    AVG(annual_salary) AS avg_salary,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY age) AS median_age,
    AVG(tenure) AS avg_tenure
FROM employees
GROUP BY department;


-- Monthly hiring trends
SELECT 
    DATE_TRUNC('month', hire_date) AS month,
    COUNT(*) AS hires
FROM employees
GROUP BY month
ORDER BY month;

-- Yearly hiring trends
SELECT 
    DATE_TRUNC('year', hire_date) AS year,
    COUNT(*) AS hires
FROM employees
GROUP BY year
ORDER BY year;

