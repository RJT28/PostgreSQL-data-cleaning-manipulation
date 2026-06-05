# 🗄️ PostgreSQL Employee Data Cleaning & Analysis

A complete end-to-end PostgreSQL project that ingests raw employee CSV data, runs a structured data cleaning pipeline, and derives analytical insights through feature engineering and aggregation queries.

---

## 📁 Repository Structure

```
PostgreSQL-data-cleaning-manipulation/
│
├── employee - data cleaningt.sql        # Data cleaning pipeline (ingestion → validation → transformation)
├── Data Pipeline - preparation and manipulation.sql   # Feature engineering & analytical queries
└── Employee Sample Data 1.csv           # Raw source dataset
```

---

## 📊 Dataset

The raw dataset is a CSV file containing employee records with the following fields:

| Column | Type | Description |
|---|---|---|
| `employee_id` | VARCHAR | Unique employee identifier |
| `full_name` | VARCHAR | Employee full name |
| `job_title` | VARCHAR | Job title |
| `department` | VARCHAR | Department name |
| `business_unit` | VARCHAR | Business unit |
| `gender` | VARCHAR | Gender |
| `ethnicity` | VARCHAR | Ethnicity |
| `age` | INT | Age in years |
| `hire_date` | DATE | Date of hiring |
| `annual_salary` | INT | Annual salary (USD) |
| `bonus_percent` | INT | Bonus percentage |
| `country` | VARCHAR | Country of employment |
| `city` | VARCHAR | City of employment |
| `exit_date` | DATE | Date of exit (NULL if still active) |

---

## 🧹 File 1 — `employee - data cleaningt.sql`

This script handles the full data cleaning pipeline using a **staging → production** pattern.

### Pipeline Steps

**1. Staging Table Creation**
- A temporary table `temp_employees` is created with flexible `VARCHAR` types for date and numeric columns to safely handle raw, inconsistently formatted CSV data.

**2. Data Ingestion**
- Raw CSV is loaded via `COPY` into `temp_employees` with `LATIN1` encoding to handle special characters.

**3. Null Handling**
- **Text columns** (`full_name`, `job_title`, `department`, etc.) → imputed with descriptive defaults (e.g., `'Unknown'`, `'Not Specified'`).
- **Numeric columns** (`age`, `annual_salary`, `bonus_percent`) → imputed with **median values** using `PERCENTILE_CONT(0.5)`.
- **Date columns** (`hire_date`, `exit_date`) → null `hire_date` values imputed with the **median hire date**.

**4. Missing ID Generation**
- Employees with `NULL` `employee_id` are assigned a new unique ID in the format `E00001`, `E00002`, etc., continuing from the highest existing ID in the dataset.

**5. Duplicate Removal**
- Duplicate rows identified by `employee_id` are removed, keeping only the first occurrence by `ctid`.

**6. Text Standardization**
- All text columns are cleaned with `INITCAP(TRIM(...))` to normalize casing and remove leading/trailing whitespace.

**7. Numeric Cleaning**
- Non-numeric characters stripped from `annual_salary` and `bonus_percent` using `REGEXP_REPLACE`.
- Columns then cast to `INTEGER`.

**8. Date Normalization**
- Dates in `YYYY-MM-DD` format are converted to `MM/DD/YYYY`, then the columns are altered to proper `DATE` type.

**9. Outlier Handling**
- `age` values outside `[18, 65]` → replaced with the median age.
- `annual_salary` values outside `[20,000, 200,000]` → replaced with the median salary.

**10. Production Load**
- Cleaned and validated records from `temp_employees` are inserted into the permanent `employees` table, filtering out any remaining `NULL` employee IDs and enforcing field length constraints.

**11. Verification**
- Post-load checks for null counts per column, duplicate IDs, invalid date formats, and data type confirmation across both tables.

---

## ⚙️ File 2 — `Data Pipeline - preparation and manipulation.sql`

This script performs feature engineering and runs analytical queries on the cleaned `employees` table.

### Feature Engineering

**Tenure** — Computes each employee's years of service. Uses `exit_date` for former employees and defaults to the current date for active ones.

**Age Groups** — Bins employees into age brackets: `18-25`, `26-35`, `36-45`, `46-55`, `56-65`, `65+`.

**Salary Bands** — Categorizes annual salary into: `<50K`, `50K-100K`, `100K-150K`, `>150K`.

### Analytical Queries

**Departmental Statistics**
- Per-department aggregation: employee count, average salary, median age (`PERCENTILE_CONT`), and average tenure.

**Monthly Hiring Trends**
- Count of hires per month using `DATE_TRUNC('month', hire_date)`, ordered chronologically.

**Yearly Hiring Trends**
- Count of hires per year using `DATE_TRUNC('year', hire_date)`, ordered chronologically.

---

## 🚀 Getting Started

### Prerequisites
- PostgreSQL 12+
- A PostgreSQL client (e.g., pgAdmin, DBeaver, psql CLI)

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/RJT28/PostgreSQL-data-cleaning-manipulation.git
   ```

2. **Update the CSV path** in `employee - data cleaningt.sql`
   ```sql
   -- Replace this with your local path to the CSV
   FROM 'C:/your/path/to/Employee Sample Data 1.csv'
   ```

3. **Run the cleaning script first**
   ```
   employee - data cleaningt.sql
   ```

4. **Run the analysis script**
   ```
   Data Pipeline - preparation and manipulation.sql
   ```

---

## 🛠️ Technologies

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![pgAdmin](https://img.shields.io/badge/pgAdmin-316192?style=for-the-badge&logo=postgresql&logoColor=white)

- **PostgreSQL** — Core database engine
- **pgAdmin** — Query execution and database management
- **SQL** — DDL, DML, window functions, CTEs, regex, date functions

---

## 👤 Author

**Roy** — [GitHub](https://github.com/RJT28)
