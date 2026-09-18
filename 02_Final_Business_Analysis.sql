/*
============================================================
PROJECT 2: EMPLOYEE PERFORMANCE ANALYTICS
============================================================
Database : employee_performance_analytics
Period   : 2019 - 2026
Tools    : PostgreSQL | Power BI
============================================================
*/


/*
============================================================
TABLE 1: EMPLOYEES
============================================================
*/

CREATE TABLE employees (
    employee_id TEXT,
    employee_name TEXT,
    gender TEXT,
    age INTEGER,
    department_id INTEGER,
    job_level TEXT,
    employment_type TEXT,
    join_date DATE,
    city TEXT,
    work_mode TEXT
);


/*
============================================================
TABLE 2: DEPARTMENTS
============================================================
*/

CREATE TABLE departments (
    department_id INTEGER,
    department_name TEXT,
    business_unit TEXT
);


/*
============================================================
TABLE 3: PERFORMANCE_REVIEWS
============================================================
*/

CREATE TABLE performance_reviews (
    employee_id TEXT,
    review_date DATE,
    performance_rating NUMERIC(3,1),
    performance_category TEXT,
    review_type TEXT
);


/*
============================================================
TABLE 4: ATTENDANCE
============================================================
*/

CREATE TABLE attendance (
    employee_id TEXT,
    month DATE,
    working_days INTEGER,
    absent_days INTEGER,
    overtime_hours NUMERIC(5,2),
    days_present INTEGER
);


/*
============================================================
TABLE 5: TRAINING
============================================================
*/

CREATE TABLE training (
    employee_id TEXT,
    training_date DATE,
    training_name TEXT,
    training_hours NUMERIC(5,2),
    completion_status TEXT,
    assessment_score NUMERIC(5,2)
);


/*
============================================================
TABLE 6: COMPENSATION
============================================================
*/

CREATE TABLE compensation (
    employee_id TEXT,
    effective_date DATE,
    annual_salary NUMERIC(12,2),
    annual_bonus NUMERIC(12,2),
    change_reason TEXT
);


/*
============================================================
TABLE 7: EMPLOYEE_EVENTS
============================================================
*/

CREATE TABLE employee_events (
    employee_id TEXT,
    event_date DATE,
    event_type TEXT,
    old_department_id INTEGER,
    new_department_id INTEGER,
    event_reason TEXT
);

/*
========================================
             Tabel View
========================================*/

SELECT*FROM employees 
SELECT*FROM departments
SELECT*FROM performance_reviews
SELECT*FROM attendance
SELECT*FROM training
SELECT*FROM compensation
SELECT*FROM employee_events 



/*
========================================
 HR ANALYTICS — BUSINESS QUESTIONS
========================================*/




/*
=========================================
ANALYTICS AREA 1 — EMPLOYEE OVERVIEW
========================================*/

/*---------------------------------------
    Q1 — Total Employees
-----------------------------------------*/


SELECT COUNT(employee_id)AS Total_Employees
FROM employees;


/*----------------------------------------
   Q2 — Gender Distribution
------------------------------------------*/

SELECT gender,
       COUNT(employee_id)AS Total_Employees
FROM employees
GROUP BY gender
ORDER BY Total_Employees DESC

/*----------------------------------------
   Q3 — Employment Type Distribution
------------------------------------------*/


SELECT employment_type,
       COUNT(employee_id)AS Total_Employees
FROM employees
GROUP BY employment_type
ORDER BY Total_Employees DESC

/*-----------------------------------------
   Q4 — Work Mode Distribution
-------------------------------------------*/

SELECT work_mode,
       COUNT(employee_id)AS Total_Employees
FROM employees
GROUP BY work_mode
ORDER BY Total_Employees DESC


/*-----------------------------------------
   Q5. Employee Distribution by Job Level
------------------------------------------*/


SELECT job_level,
       COUNT(employee_id)AS Total_Employees
FROM employees
GROUP BY job_level
ORDER BY Total_Employees DESC

/*-----------------------------------------
   Q6 — Department Distribution
------------------------------------------*/

SELECT d.department_name,
      COUNT(e.employee_id)AS Total_Employees
FROM employees e
JOIN departments d
ON e.department_id=d.department_id
GROUP BY d.department_name
ORDER BY Total_Employees DESC



/*========================================================
   ANALYTICS AREA 1 — EMPLOYEE OVERVIEW 
========================================================*/
/*========================
     Key Insights
==========================


1. Technology is the largest department with 660 employees,
   followed by Sales (523) and Operations (507).

2. Human Resources is the smallest department with 215 employees,
   indicating a relatively lean HR workforce.

3. The workforce has a relatively balanced gender distribution:
   Female – 1,554 | Male – 1,531 | Non-Binary – 115.

4. Permanent employees dominate the workforce with 2,636 employees
   (82.4%), followed by Contract employees (440) and Interns (124).

5. Hybrid is the most common work mode with 1,492 employees (46.6%),
   followed by Office (1,222) and Remote (472).

6. Analyst (622), Associate (585), and Senior Analyst (523) are
   the largest job-level groups, indicating a strong junior-to-
   mid-level workforce base.
*/




/*=====================================================
   ANALYTICS AREA 2 — WORKFORCE & DEPARTMENT ANALYSIS
=======================================================*/

/*------------------------------------------------
   Q7 — Department Total Current Salary Expense
--------------------------------------------------*/

WITH latest_salary AS
(
    SELECT
        employee_id,
        annual_salary,
        ROW_NUMBER() OVER
        (
            PARTITION BY employee_id
            ORDER BY effective_date DESC
        ) AS rn
    FROM compensation
)

SELECT
    d.department_name,
    SUM(ls.annual_salary) AS total_salary_expense
FROM departments d
JOIN employees e
    ON d.department_id = e.department_id
JOIN latest_salary ls
    ON e.employee_id = ls.employee_id
   AND ls.rn = 1
GROUP BY d.department_name
ORDER BY total_salary_expense DESC;

/*-----------------------------------------
   Q8 — Salary Range by Department
-------------------------------------------*/

SELECT d.department_name,
       MAX(c.annual_salary)AS highest_salary,
	   MIN(c.annual_salary)AS lowest_salary
FROM departments d
JOIN employees e
ON d.department_id=e.department_id
JOIN compensation c
ON e.employee_id=c.employee_id
GROUP BY d.department_name




/*========================================================
   ANALYTICS AREA 2 — WORKFORCE & DEPARTMENT ANALYSIS 
========================================================*/

/*========================
     Key Insights
==========================


1. Product has the highest current average salary at ₹89,307.12,
   while Marketing has the lowest at ₹79,628.71.

2. Senior Managers have the highest current average salary at
   ₹178,377.59, while Associates have the lowest at ₹46,964.17.

3. Senior Manager has the widest salary range at ₹150,055,
   followed by Manager at ₹114,759.

4. The salary range generally becomes wider at higher job levels,
   indicating greater variation in compensation among senior roles.
*/


/*===================================
     Business Recommendations
=====================================
1. Review compensation structures across departments, especially
   Marketing, to assess whether salary levels are competitive
   relative to similar roles and job levels.

2. Review salary progression across job levels to ensure that
   compensation growth is aligned with employee responsibilities,
   experience, and career progression.

3. Investigate the wide salary ranges at senior job levels to
   understand differences in experience, role scope, and individual
   performance.

4. Use department and job-level salary benchmarks during future
   compensation reviews to identify potential pay inconsistencies
   and support more structured salary decisions.
*/





/*========================================================
   ANALYTICS AREA 3 — CAREER GROWTH & PROMOTION ANALYTICS
==========================================================*/

/*----------------------------------------------------------
   Q9 - Employee-wise: Time to First Promotion 
----------------------------------------------------------*/

SELECT
    e.employee_id,
    e.join_date,
    MIN(ev.event_date) AS first_promotion_date,
    MIN(ev.event_date) - e.join_date AS days_to_first_promotion
FROM employees e
JOIN employee_events ev
    ON e.employee_id = ev.employee_id
WHERE ev.event_type = 'Promotion'
GROUP BY
    e.employee_id,
    e.join_date
ORDER BY days_to_first_promotion;

/*--------------------------------------------------------------------
   Q10 - Employee-wise: Employees Waiting Over 3 Years for Promotion 
----------------------------------------------------------------------*/

WITH promotion_data AS (
    SELECT
        e.employee_id,
        e.join_date,
        MIN(ev.event_date) AS first_promotion_date,
        MIN(ev.event_date) - e.join_date AS days_to_first_promotion
    FROM employees e
    JOIN employee_events ev
        ON e.employee_id = ev.employee_id
    WHERE ev.event_type = 'Promotion'
    GROUP BY e.employee_id, e.join_date
)

SELECT
    employee_id,
    join_date,
    first_promotion_date,
    days_to_first_promotion
FROM promotion_data
WHERE days_to_first_promotion > 1095
ORDER BY days_to_first_promotion DESC;


/*------------------------------------------
   Q11 - Department-wise: Promotion Rate
-------------------------------------------*/

WITH total_employees AS
(
    SELECT
        d.department_name,
        COUNT(e.employee_id) AS total_employees
    FROM employees e
    JOIN departments d
        ON e.department_id = d.department_id
    GROUP BY d.department_name
),

promotion_report AS
(
    SELECT
        d.department_name,
        COUNT(DISTINCT ev.employee_id) AS promoted_employees
    FROM employee_events ev
    JOIN departments d
        ON ev.new_department_id = d.department_id
    WHERE ev.event_type = 'Promotion'
    GROUP BY d.department_name
)

SELECT
    t.department_name,
    t.total_employees,
    COALESCE(p.promoted_employees, 0) AS promoted_employees,
    ROUND(
        COALESCE(p.promoted_employees, 0) * 100.0
        / NULLIF(t.total_employees, 0),
        2
    ) AS promotion_rate
FROM total_employees t
LEFT JOIN promotion_report p
    ON t.department_name = p.department_name
ORDER BY promotion_rate DESC;

/*-----------------------------------------
   Q12 - Job Level-wise: Promotion Rate
-------------------------------------------*/

WITH total_employees AS
(
    SELECT
        job_level,
        COUNT(employee_id) AS total_employees
    FROM employees
    GROUP BY job_level
),

promotion_report AS
(
    SELECT
        e.job_level,
        COUNT(DISTINCT ev.employee_id) AS promoted_employees
    FROM employee_events ev
    JOIN employees e
        ON ev.employee_id = e.employee_id
    WHERE ev.event_type = 'Promotion'
    GROUP BY e.job_level
)

SELECT
    t.job_level,
    t.total_employees,
    COALESCE(p.promoted_employees, 0) AS promoted_employees,
    ROUND(
        COALESCE(p.promoted_employees, 0) * 100.0
        / NULLIF(t.total_employees, 0),
        2
    ) AS promotion_rate
FROM total_employees t
LEFT JOIN promotion_report p
    ON t.job_level = p.job_level
ORDER BY promotion_rate DESC;

/*---------------------------------------------------------
   Q13 - Job Level-wise: Average Time to First Promotion 
----------------------------------------------------------*/
WITH promotion AS
(
SELECT e.employee_id,
      MIN(ev.event_date)AS first_promotion_date
FROM employees e
JOIN employee_events ev
ON e.employee_id = ev.employee_id
WHERE ev.event_type='Promotion'
GROUP BY e.employee_id
),promotion_days AS
(
SELECT p.employee_id,
        e.job_level,
		e.join_date,
       (p.first_promotion_date - e.join_date)AS days_to_first_promotion
FROM promotion p
JOIN employees e
    ON p.employee_id = e.employee_id
)
SELECT job_level,
	AVG(days_to_first_promotion)AS avg_days_to_first_promotion
FROM promotion_days
GROUP BY job_level
ORDER BY avg_days_to_first_promotion



/*---------------------------------------------------------
  Q14 - Department-wise: Average Time to First Promotion
----------------------------------------------------------*/
WITH promotion AS
(
SELECT e.employee_id,
      d.department_name,
      MIN(ev.event_date)AS first_promotion_date
FROM employees e
JOIN employee_events ev
ON e.employee_id = ev.employee_id
JOIN departments d
ON e.department_id=d.department_id
WHERE ev.event_type='Promotion'
GROUP BY e.employee_id,d.department_name
),promotion_days AS
(
SELECT p.employee_id,
       p.department_name,
		e.join_date,
       (p.first_promotion_date - e.join_date)AS days_to_first_promotion
FROM promotion p
JOIN employees e
ON p.employee_id= e.employee_id
)
SELECT department_name,
	AVG(days_to_first_promotion)AS avg_days_to_first_promotion
FROM promotion_days
GROUP BY department_name
ORDER BY avg_days_to_first_promotion DESC




/*------------------------------------------------------------
  Q15 - Job Level-wise: Early Promotion Rate Within 2 Years
--------------------------------------------------------------*/

WITH total_employees AS
(
    SELECT
        job_level,
        COUNT(employee_id) AS total_employees
    FROM employees
    GROUP BY job_level
),

early_promotions AS
(
    SELECT
        e.job_level,
        COUNT(DISTINCT e.employee_id) AS early_promoted_employees
    FROM employees e
    JOIN employee_events ev
        ON e.employee_id = ev.employee_id
    WHERE ev.event_type = 'Promotion'
      AND ev.event_date <= e.join_date + INTERVAL '2 years'
    GROUP BY e.job_level
)

SELECT
    t.job_level,
    t.total_employees,
    ep.early_promoted_employees,
    ep.early_promoted_employees * 100.0 / t.total_employees AS early_promotion_rate
FROM total_employees t
JOIN early_promotions ep
    ON t.job_level = ep.job_level
ORDER BY early_promotion_rate DESC;




/*========================================================
   ANALYTICS AREA 3 — CAREER GROWTH & PROMOTION
========================================================*/

/*========================
     Key Insights
==========================

1. Promotion rates vary considerably across departments.
   Finance has the highest promotion rate at 20.78%, while
   Human Resources has the lowest at 15.81%.

2. Finance leads departmental promotion performance despite
   having one of the smaller workforce sizes, suggesting a
   relatively higher rate of internal career progression.

3. Promotion rates vary across job levels. 
Managers have the highest promotion rate at 21.07%, while Analysts have the lowest at 17.04%, a gap of 4.03 percentage points.

4. Average promotion time varies significantly by job level.
   Senior Managers have the longest average promotion time
   at approximately 959 days, while Executives have the shortest
   at approximately 761 days.

5. Department-level average promotion time also varies.
   Human Resources has the longest average promotion time at
   approximately 961 days, while Technology has the shortest
   at approximately 780 days.

6. The variation in promotion timing and promotion rates across
   departments and job levels indicates that career progression
   is not uniform throughout the organization.
*/

/*==============================
     Business Recommendations
================================
1. Review promotion practices in departments with lower promotion
   rates, particularly Human Resources, to identify potential
   career progression gaps.

2. Study the promotion processes used by higher-performing
   departments such as Finance and Sales to identify practices
   that could be applied more broadly.

3. Review career progression for Analyst-level employees, who
   have the lowest promotion rate, and provide clearer skill
   development and promotion pathways.

4. Investigate the relatively long promotion timelines for
   Senior Managers and employees in Human Resources to determine
   whether organizational structure or limited higher-level
   positions are slowing progression.

5. Establish clear promotion criteria, career paths, and regular
   progression reviews to improve transparency and consistency
   across departments and job levels.
*/




/*==========================================================
      ANALYTICS AREA 4 — EMPLOYEE RETENTION & TURNOVER
==========================================================*/

/*--------------------------------------------------------
  Q16 - Department-wise: Employee Turnover 
----------------------------------------------------------*/


WITH attrition_report AS
(
    SELECT d.department_name,
	     COUNT(DISTINCT ev.employee_id)AS total_employees
FROM employees e
JOIN employee_events ev
ON e.employee_id=ev.employee_id
JOIN departments d
ON e.department_id=d.department_id
WHERE ev.event_type='Resignation'
GROUP BY d.department_name
)
SELECT
      department_name,
      total_employees
FROM attrition_report
ORDER BY total_employees DESC;

/*--------------------------------------------------------
   Q17 - Department-wise: Overall Resignation Rate
          Across Available Employee Data
----------------------------------------------------------*/

WITH total_employees AS
(
    SELECT
        d.department_name,
        COUNT(DISTINCT e.employee_id) AS total_employees
    FROM employees e
    JOIN departments d
        ON e.department_id = d.department_id
    GROUP BY d.department_name
),

resigned_employees AS
(
    SELECT
        d.department_name,
        COUNT(DISTINCT ev.employee_id) AS resigned_employees
    FROM employees e
    JOIN departments d
        ON e.department_id = d.department_id
    JOIN employee_events ev
        ON e.employee_id = ev.employee_id
    WHERE ev.event_type = 'Resignation'
    GROUP BY d.department_name
)

SELECT
    t.department_name,
    t.total_employees,
    COALESCE(r.resigned_employees, 0) AS resigned_employees,
    ROUND(
        COALESCE(r.resigned_employees, 0) * 100.0
        / t.total_employees,
        2
    ) AS attrition_rate
FROM total_employees t
LEFT JOIN resigned_employees r
    ON t.department_name = r.department_name
ORDER BY attrition_rate DESC;


/*--------------------------------------------------------
   Q18 - Job Level-wise: Attrition Rate 
----------------------------------------------------------*/
WITH total_employees AS
(
    SELECT job_level,
        COUNT(DISTINCT employee_id) AS total_employees
 FROM employees 
GROUP BY job_level
),

resigned_employees AS
(
    SELECT
        e.job_level,
        COUNT(DISTINCT ev.employee_id) AS resigned_employees
    FROM employees e
    JOIN employee_events ev
        ON e.employee_id = ev.employee_id
    WHERE ev.event_type = 'Resignation'
    GROUP BY e.job_level
)

SELECT
    t.job_level,
    t.total_employees,
    COALESCE(r.resigned_employees, 0) AS resigned_employees,
    ROUND(
        COALESCE(r.resigned_employees, 0) * 100.0
        / t.total_employees,
        2
    ) AS attrition_rate
FROM total_employees t
LEFT JOIN resigned_employees r
    ON t.job_level =r.job_level
ORDER BY attrition_rate DESC;



/*========================================================
   ANALYTICS AREA 4 — EMPLOYEE RETENTION & TURNOVER
========================================================*/

/*====================
    Key Insights
======================
1. Technology has the highest number of resignations with 97
   employees, followed by Operations (87) and Sales (76).

2. Customer Support has the highest attrition rate at 17.18%,
   closely followed by Operations at 17.16%.

3. Finance has the lowest attrition rate at 13.33%, indicating
   comparatively stronger employee retention.

4. Attrition varies considerably across departments, with a
   3.85 percentage-point gap between the highest and lowest
   department attrition rates.

5. Manager-level employees have the highest attrition rate at
   18.13%, followed by Analysts at 16.56%.

6. Associate employees have the lowest attrition rate at 13.68%,
   followed by Specialists at 13.92%.

7. The highest resignation count does not necessarily indicate
   the highest attrition rate. Technology has the most
   resignations (97), but its attrition rate is 14.70%, while
   Customer Support has fewer resignations (72) but the highest
   attrition rate (17.18%).
*/

/*==============================
    Business Recommendations
================================
1. Investigate the causes of high attrition in Customer Support
   and Operations, where attrition rates are above 17%.

2. Conduct a focused review of Manager-level retention, as
   Managers have the highest attrition rate at 18.13%.

3. Analyze employee feedback, workload, compensation, and career
   progression in high-attrition departments and job levels.

4. Study retention practices in lower-attrition departments such
   as Finance and consider whether successful practices can be
   applied elsewhere.

5. Track both resignation counts and attrition rates together
   when evaluating retention problems, because workforce size
   can make raw resignation counts misleading.
*/





/*========================================================
      ANALYTICS AREA 5 — COMPENSATION ANALYTICS
==========================================================*/

/*----------------------------------------------------------
   Q19 - Department-wise: Average Salary
------------------------------------------------------------*/

WITH latest_salary AS
(
    SELECT
        employee_id,
        annual_salary,
        ROW_NUMBER() OVER
        (
            PARTITION BY employee_id
            ORDER BY effective_date DESC
        ) AS rn
    FROM compensation
)

SELECT
    d.department_name,
    ROUND(AVG(s.annual_salary), 2) AS avg_salary
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
JOIN latest_salary s
    ON e.employee_id = s.employee_id
   AND s.rn = 1
GROUP BY d.department_name
ORDER BY avg_salary DESC;


/*--------------------------------------------------------
   Q20 - Job Level-wise: Average Salary 
----------------------------------------------------------*/

WITH latest_salary AS
(
    SELECT
        employee_id,
        annual_salary,
        ROW_NUMBER() OVER
        (
            PARTITION BY employee_id
            ORDER BY effective_date DESC
        ) AS rn
    FROM compensation
)

SELECT
    e.job_level,
    ROUND(AVG(s.annual_salary), 2) AS avg_salary
FROM employees e
JOIN latest_salary s
    ON e.employee_id = s.employee_id
   AND s.rn = 1
GROUP BY e.job_level
ORDER BY avg_salary DESC;


/*--------------------------------------------------------
   Q21 - Job Level-wise: Salary Range 
----------------------------------------------------------*/

WITH latest_salary AS
(
    SELECT
        employee_id,
        annual_salary,
        ROW_NUMBER() OVER
        (
            PARTITION BY employee_id
            ORDER BY effective_date DESC
        ) AS rn
    FROM compensation
)

SELECT
    e.job_level,
    MAX(s.annual_salary) AS highest_salary,
    MIN(s.annual_salary) AS lowest_salary,
    MAX(s.annual_salary) - MIN(s.annual_salary) AS salary_range
FROM employees e
JOIN latest_salary s
    ON e.employee_id = s.employee_id
   AND s.rn = 1
GROUP BY e.job_level
ORDER BY salary_range DESC;


/*--------------------------------------------------------
   Q22 - Tenure-wise: Average Current Salary 
----------------------------------------------------------*/

WITH tenure_report AS
(
    SELECT
        employee_id,
        join_date,
       EXTRACT(
    YEAR FROM AGE(DATE '2026-12-31', join_date)
) AS tenure_years
    FROM employees
),

tenure_group AS
(
    SELECT
        employee_id,
        CASE
            WHEN tenure_years < 2 THEN 'Less than 2 years'
            WHEN tenure_years BETWEEN 2 AND 4 THEN '2-4 years'
            WHEN tenure_years BETWEEN 5 AND 7 THEN '5-7 years'
            ELSE '8+ years'
        END AS tenure_group
    FROM tenure_report
),

latest_salary AS
(
    SELECT
        employee_id,
        annual_salary,
        ROW_NUMBER() OVER
        (
            PARTITION BY employee_id
            ORDER BY effective_date DESC
        ) AS rn
    FROM compensation
)

SELECT
    tg.tenure_group,
    ROUND(AVG(ls.annual_salary), 2) AS avg_salary
FROM tenure_group tg
JOIN latest_salary ls
    ON tg.employee_id = ls.employee_id
   AND ls.rn = 1
GROUP BY tg.tenure_group
ORDER BY avg_salary DESC;

/*------------------------------------------------------------
  Q23 — Employee Salary More Than Average Salary by Job-Level
--------------------------------------------------------------*/

WITH latest_salary AS
(
    SELECT
        employee_id,
        annual_salary,
        effective_date,
        ROW_NUMBER() OVER
        (
            PARTITION BY employee_id
            ORDER BY effective_date DESC
        ) AS rn
    FROM compensation
),

salary_data AS
(
    SELECT
        employee_id,
        annual_salary
    FROM latest_salary
    WHERE rn = 1
),

job_level_salary AS
(
    SELECT
        e.employee_id,
        e.job_level,
        s.annual_salary,
        AVG(s.annual_salary) OVER
        (
            PARTITION BY e.job_level
        ) AS job_level_avg_salary
    FROM employees e
    JOIN salary_data s
        ON e.employee_id = s.employee_id
)

SELECT
    employee_id,
    job_level,
    annual_salary,
    ROUND(job_level_avg_salary, 2) AS job_level_avg_salary
FROM job_level_salary
WHERE annual_salary > job_level_avg_salary
ORDER BY job_level_avg_salary DESC;


/*--------------------------------------------------------
  Q24 - Employee-wise: Salary Growth from First to Latest
----------------------------------------------------------*/
WITH growth_report AS
(
    SELECT
        employee_id,
        effective_date,
        annual_salary,
        ROW_NUMBER() OVER
        (
            PARTITION BY employee_id
            ORDER BY effective_date ASC
        ) AS rn
    FROM compensation
),

growth_rate AS
(
    SELECT
        employee_id,
        effective_date,
        annual_salary,
        ROW_NUMBER() OVER
        (
            PARTITION BY employee_id
            ORDER BY effective_date DESC
        ) AS rn
    FROM compensation
)

SELECT
    f.employee_id,
    f.annual_salary AS first_salary,
    l.annual_salary AS latest_salary,

    l.annual_salary - f.annual_salary AS salary_growth,

   ROUND(
    (
        (l.annual_salary - f.annual_salary)
        * 100.0
        / NULLIF(f.annual_salary, 0)
    ), 2
) AS growth_percent

FROM growth_report f

JOIN growth_rate l
    ON f.employee_id = l.employee_id

WHERE f.rn = 1
  AND l.rn = 1

ORDER BY growth_percent DESC;



/*========================================================
   ANALYTICS AREA 5 — COMPENSATION ANALYTICS
========================================================*/

/*=================
   Key Insights
===================

1. Product has the highest average salary among departments at
   ₹89,307.12, while Marketing has the lowest at ₹79,628.71.
   The difference between the two is approximately ₹9,678.

2. Average salary varies substantially by job level. Senior Managers
   have the highest average salary at ₹178,377.59, while Associates
   have the lowest at ₹46,964.17.

3. Senior Manager has the widest salary range at ₹150,055,
   followed by Manager at ₹114,759, indicating considerable
   salary variation within these job levels.

4. Average salary differs across tenure groups in the available
   analysis. Employees with 5–7 years of tenure have the highest
   average salary at ₹105,040.09, followed by 2–4 years at
   ₹80,103.69 and less than 2 years at ₹65,416.27.
*/

/*============================
    Business Recommendations
==============================

1. Review compensation levels in lower-average-salary departments,
   particularly Marketing, against comparable roles and job levels.

2. Use job-level salary bands to maintain structured and consistent
   compensation progression across the organization.

3. Investigate the wide salary ranges within Senior Manager and
   Manager levels to understand differences in role scope,
   experience, and responsibilities.

4. Review salary progression across tenure groups to ensure that
   compensation growth remains aligned with experience and career
   progression.
*/





/*==================================================================
      ANALYTICS AREA 6- Employee Performance / Business Analysis
====================================================================*/


/*--------------------------------------------------------
  Q25 - Department-wise: Average Performance Rating 
----------------------------------------------------------*/
WITH latest_review AS
(
    SELECT
        employee_id,
        performance_rating,
        ROW_NUMBER() OVER
        (
            PARTITION BY employee_id
            ORDER BY review_date DESC
        ) AS rn
    FROM performance_reviews
)
SELECT
    d.department_name,
    ROUND(AVG(lr.performance_rating), 2) AS avg_performance_rating
FROM departments d
JOIN employees e
    ON d.department_id = e.department_id
JOIN latest_review lr
    ON e.employee_id = lr.employee_id
   AND lr.rn = 1
GROUP BY d.department_name
ORDER BY avg_performance_rating DESC;

/*--------------------------------------------------------
   Q26 - Job Level-wise: Average Performance Rating 
----------------------------------------------------------*/

WITH latest_review AS
(
    SELECT
        employee_id,
        performance_rating,
        ROW_NUMBER() OVER
        (
            PARTITION BY employee_id
            ORDER BY review_date DESC
        ) AS rn
    FROM performance_reviews
)
SELECT
    e.job_level,
    ROUND(AVG(lr.performance_rating), 2) AS avg_performance_rating
FROM employees e
JOIN latest_review lr
    ON e.employee_id = lr.employee_id
   AND lr.rn = 1
GROUP BY e.job_level
ORDER BY avg_performance_rating DESC;

/*----------------------------------------------------------
   Q27 - Overall: Employees by Current Performance Category
------------------------------------------------------------*/

WITH latest_review AS
(
    SELECT
        employee_id,
        performance_category,
        ROW_NUMBER() OVER
        (
            PARTITION BY employee_id
            ORDER BY review_date DESC
        ) AS rn
    FROM performance_reviews
)
SELECT
    performance_category,
    COUNT(employee_id) AS total_employees
FROM latest_review
WHERE rn = 1
GROUP BY performance_category
ORDER BY total_employees DESC;

/*-----------------------------------------------------------
  Q28 - Department-wise: Performance Category Distribution 
-------------------------------------------------------------*/

WITH latest_review AS
(
    SELECT
        employee_id,
        review_date,
        performance_rating,
        performance_category,
        ROW_NUMBER() OVER
        (
            PARTITION BY employee_id
            ORDER BY review_date DESC
        ) AS rn
    FROM performance_reviews
)

SELECT
    d.department_name,
    lr.performance_category,
    COUNT(lr.employee_id) AS total_employees
FROM latest_review lr
JOIN employees e
    ON lr.employee_id = e.employee_id
JOIN departments d
    ON e.department_id = d.department_id
WHERE lr.rn = 1
GROUP BY
    d.department_name,
    lr.performance_category
ORDER BY
    d.department_name,
    total_employees DESC;
	


/*========================================================
   ANALYTICS AREA 6 — EMPLOYEE PERFORMANCE
========================================================*/

/*====================
    Key Insights
======================

1. Product has the highest average performance rating among
   departments at 3.22, while Marketing has the lowest at 2.97.

2. Average performance ratings vary across departments, with
   a 0.25-point difference between the highest and lowest
   department averages.

3. Managers have the highest average performance rating among
   job levels at 3.21, while Analysts have the lowest at 3.02.

4. Most employees fall into the "Meets Expectations" category,
   with 1,691 employees, followed by "Exceeds Expectations"
   with 693 employees.

5. 441 employees are classified as "Needs Improvement", while
   209 employees are classified as "Outstanding", indicating
   that performance improvement remains relevant for a portion
   of the workforce.
*/

/*===========================
   Business Recommendations
=============================

1. Identify and study practices followed by higher-performing
   departments such as Product and apply relevant practices
   across lower-performing departments.

2. Provide targeted coaching and development plans for employees
   in the "Needs Improvement" category.

3. Recognize and retain high-performing employees in the
   "Outstanding" and "Exceeds Expectations" categories.

4. Review performance patterns at the job-level to identify
   levels where additional training or managerial support may
   improve performance.
*/





/*==================================================================
      ANALYTICS AREA 7 - TRAINING & DEVELOPMENT
====================================================================*/

/*-------------------------------------------------------------
  Q29 - Department-wise: Employees Participating in Training 
---------------------------------------------------------------*/
SELECT d.department_name,
       COUNT(DISTINCT t.employee_id)AS total_employee
FROM departments d
JOIN employees e
ON d.department_id=e.department_id
JOIN training t
ON e.employee_id=t.employee_id
GROUP BY d.department_name
ORDER BY total_employee DESC


/*--------------------------------------------------------
   Q30 - Overall: Training Completion Rate 
----------------------------------------------------------*/
SELECT 
   ROUND(
SUM(
   CASE 
       WHEN completion_status='Completed' THEN 1 ELSE 0 END)
     *100.0/COUNT(*),2
   )AS completion_rate
FROM training

/*--------------------------------------------------------
    Q31 - Department-wise: Training Completion Rate 
----------------------------------------------------------*/

SELECT d.department_name,
   ROUND(
SUM(
   CASE 
       WHEN completion_status='Completed' THEN 1 ELSE 0 END)
     *100.0/COUNT(*),2
   )AS completion_rate
FROM departments d
JOIN employees e
ON d.department_id=e.department_id
JOIN training t
ON e.employee_id=t.employee_id
GROUP BY d.department_name
ORDER BY completion_rate DESC

/*--------------------------------------------------------
   Q32 - Department-wise: Average Training Hours 
----------------------------------------------------------*/

SELECT d.department_name,
         ROUND(AVG(t.training_hours),3)AS avg_training_hours
FROM departments d
JOIN employees e
ON d.department_id=e.department_id
JOIN training t
ON e.employee_id=t.employee_id
GROUP BY d.department_name
ORDER BY avg_training_hours DESC

/*--------------------------------------------------------
  Q33 - Training-wise: Average Assessment Score 
----------------------------------------------------------*/

SELECT training_name,
      ROUND(AVG(assessment_score),4)AS avg_assessment_score
FROM training 
GROUP BY training_name
ORDER BY avg_assessment_score DESC

/*--------------------------------------------------------
  Q34 - Completion Status-wise: Average Assessment Score 
----------------------------------------------------------*/
SELECT completion_status,
      ROUND(AVG(assessment_score),2)AS avg_assessment_score
FROM training 
GROUP BY completion_status
ORDER BY avg_assessment_score DESC



/*========================================================
   ANALYTICS AREA 7 — TRAINING & DEVELOPMENT
========================================================*/

/*================
    Key Insights
==================

1. Technology has the highest training participation with
   485 employees, while Human Resources has the lowest with
   156 employees.

2. The overall training completion rate is 72.30%.

3. Product has the highest departmental training completion
   rate at 74.38%, while Operations has the lowest at 70.79%.
   This represents a 3.59 percentage-point difference.

4. Average training hours are relatively consistent across
   departments. Marketing has the highest average at 16.259
   hours, while Finance has the lowest at 15.145 hours.

5. Power BI Fundamentals has the highest average assessment
   score at 78.46, while Advanced Excel has the lowest at
   76.87. The difference is relatively small.

6. Completed training records have an average assessment score
   of 77.75. Assessment scores are not available for Cancelled,
   In Progress, or No Show records in the Q40 output.
*/

/*===========================
   Business Recommendations
=============================
1. Review training access and participation in departments with
   lower participation, particularly Human Resources.

2. Identify the reasons behind lower completion rates in
   departments such as Operations and introduce appropriate
   measures to improve completion.

3. Review training schedules and workload constraints to reduce
   barriers to training completion.

4. Study high-performing training programs such as Power BI
   Fundamentals and Leadership Essentials to identify effective
   training practices.

5. Review Advanced Excel training content and delivery methods
   to identify opportunities to improve assessment performance.

6. Track training participation, completion rate, training hours,
   and assessment scores together to evaluate training
   effectiveness more comprehensively.
*/




/*==================================================================
      ANALYTICS AREA 8 - ATTENDANCE
====================================================================*/

/*--------------------------------------------------------
  Q35 - Department-wise: Average Attendance Rate 
----------------------------------------------------------*/

SELECT
    d.department_name,
    ROUND(
        AVG(t.days_present * 100.0 / t.working_days),
        2
    ) AS avg_attendance_rate
FROM departments d
JOIN employees e
    ON d.department_id = e.department_id
JOIN attendance t
    ON e.employee_id = t.employee_id
GROUP BY d.department_name
ORDER BY avg_attendance_rate DESC;

/*--------------------------------------------------------
 Q36 - Department-wise: Average Present Days 
----------------------------------------------------------*/
 SELECT
    d.department_name,
    ROUND(
        AVG(t.days_present),2
    ) AS avg_present_days
FROM departments d
JOIN employees e
    ON d.department_id = e.department_id
JOIN attendance t
    ON e.employee_id = t.employee_id
GROUP BY d.department_name
ORDER BY avg_present_days DESC;


/*--------------------------------------------------------
  Q37 - Department-wise: Average Absent Days 
----------------------------------------------------------*/
SELECT
    d.department_name,
    ROUND(
        AVG(t.absent_days),2
    ) AS avg_absent_days
FROM departments d
JOIN employees e
    ON d.department_id = e.department_id
JOIN attendance t
    ON e.employee_id = t.employee_id
GROUP BY d.department_name
ORDER BY  avg_absent_days DESC;


/*--------------------------------------------------------
  Q38 - Department-wise: Average Overtime Hours 
----------------------------------------------------------*/
SELECT
    d.department_name,
    ROUND(
        AVG(t.overtime_hours),2
    ) AS avg_overtime_hours
FROM departments d
JOIN employees e
    ON d.department_id = e.department_id
JOIN attendance t
    ON e.employee_id = t.employee_id
GROUP BY d.department_name
ORDER BY avg_overtime_hours DESC;


/*--------------------------------------------------------
  Q39 - Employee-wise: Lowest Attendance Rate 
----------------------------------------------------------*/
SELECT
       employee_id,
    ROUND(
	   SUM(days_present) * 100.0 / SUM(working_days),2
	   )AS attendance_rate
FROM attendance 
GROUP BY employee_id
ORDER BY attendance_rate ASC;


/*--------------------------------------------------------
   Q40 - Employee-wise: Total Overtime Hours
----------------------------------------------------------*/

SELECT
       employee_id,
   SUM(overtime_hours)AS total_overtime_hours
FROM attendance 
GROUP BY employee_id
ORDER BY total_overtime_hours DESC;


/*--------------------------------------------------------
   Q41 - Employee-wise: Total Absent Days 
----------------------------------------------------------*/

SELECT
       employee_id,
   SUM(absent_days)AS total_absent_days
FROM attendance 
GROUP BY employee_id
ORDER BY total_absent_days DESC;



/*--------------------------------------------------------
   Q42 — Overtime vs Attendance by Employee
----------------------------------------------------------*/

WITH employee_attendance AS
(
    SELECT
        employee_id,
        SUM(overtime_hours) AS total_overtime_hours,
        ROUND(
            SUM(days_present) * 100.0 / SUM(working_days),
            2
        ) AS attendance_rate
    FROM attendance
    GROUP BY employee_id
),
company_average AS
(
    SELECT
        AVG(attendance_rate) AS avg_attendance,
        AVG(total_overtime_hours) AS avg_overtime
    FROM employee_attendance
)
SELECT
    e.employee_id,
    e.attendance_rate,
    e.total_overtime_hours
FROM employee_attendance e
CROSS JOIN company_average a
WHERE e.attendance_rate > a.avg_attendance
  AND e.total_overtime_hours > a.avg_overtime
ORDER BY e.total_overtime_hours DESC;



/*------------------------------------------------------------------
   Q43 - Department-wise: Absenteeism Rate 
--------------------------------------------------------------------*/

SELECT d.department_name,
    ROUND(
	   SUM(t.absent_days) * 100.0 / SUM(t.working_days),2
	   )AS absenteeism_rate
FROM departments d
JOIN employees e
    ON d.department_id = e.department_id
JOIN attendance t
    ON e.employee_id = t.employee_id
GROUP BY d.department_name
ORDER BY absenteeism_rate DESC;


/*------------------------------------------------------------------
   Q44 — High Overtime + High Absenteeism by Department
--------------------------------------------------------------------*/

WITH department_attendance AS
(
    SELECT
        d.department_name,
        ROUND(AVG(t.overtime_hours), 2) AS avg_overtime_hours,
        ROUND(
            SUM(t.absent_days) * 100.0 / SUM(t.working_days),
            2
        ) AS absenteeism_rate
    FROM departments d
    JOIN employees e
        ON d.department_id = e.department_id
    JOIN attendance t
        ON e.employee_id = t.employee_id
    GROUP BY d.department_name
),
department_average AS
(
    SELECT
        AVG(avg_overtime_hours) AS overall_avg_overtime,
        AVG(absenteeism_rate) AS overall_avg_absenteeism
    FROM department_attendance
)
SELECT
    d.department_name,
    d.avg_overtime_hours,
    d.absenteeism_rate
FROM department_attendance d
CROSS JOIN department_average a
WHERE d.avg_overtime_hours > a.overall_avg_overtime
  AND d.absenteeism_rate > a.overall_avg_absenteeism
ORDER BY d.avg_overtime_hours DESC;

/*--------------------------------------------------
  Q45 - Department-wise: Attendance Rate 
----------------------------------------------------*/

SELECT
       d.department_name,
    ROUND(
	   SUM(t.days_present) * 100.0 / SUM(t.working_days),2
	   )AS attendance_rate
FROM departments d
JOIN employees e
    ON d.department_id = e.department_id
JOIN attendance t
    ON e.employee_id = t.employee_id
GROUP BY d.department_name
ORDER BY attendance_rate DESC;


/*---------------------------------------------------------------
   Q46 - Department-wise: Attendance & Absenteeism
-----------------------------------------------------------------*/

SELECT
       d.department_name,
    ROUND(
	   SUM(t.days_present) * 100.0 /  SUM(t.working_days),
	       2
	   )AS attendance_rate,
	ROUND(
        SUM(t.absent_days) * 100.0 / SUM(t.working_days),
            2
        ) AS absenteeism_rate
FROM departments d
JOIN employees e
    ON d.department_id = e.department_id
JOIN attendance t
    ON e.employee_id = t.employee_id
GROUP BY d.department_name
ORDER BY attendance_rate DESC,
         absenteeism_rate ASC;
		 


/*========================================================
   ANALYTICS AREA 8 — ATTENDANCE & WORKFORCE PRODUCTIVITY
==========================================================*/

/*================
  Key Insights
==================

1. Customer Support has the highest average attendance rate
   at 93.81%, while Human Resources and Product have the
   lowest at 93.66%.

2. Average attendance rates are relatively consistent across
   departments, with only a 0.15 percentage-point difference
   between the highest and lowest departments.

3. Human Resources and Product have the highest average absent
   days at 1.26 days, while Customer Support has the lowest
   at 1.23 days.

4. Operations has the highest average overtime hours at 8.06
   hours, followed by Customer Support at 8.00 hours.
   Product has the lowest average overtime at 5.16 hours.

5. The employee-level analysis identifies an employee with an
   attendance rate of 78.05%, highlighting a potential
   individual attendance concern.

6. The high-overtime employee analysis identifies an employee
   with 698.10 total overtime hours, indicating a significant
   workload or work-hour concentration at the individual level.

7. The high-absenteeism analysis identifies an employee with
   140 total absent days, highlighting a significant
   individual-level absenteeism case.

8. Department-level absenteeism rates range from 6.16% in
   Customer Support to 6.31% in Product, showing relatively
   small variation across departments.

9. Operations records the highest average overtime at 8.06 hours
   while its absenteeism rate is 6.27%, indicating that overtime
   and absenteeism should be reviewed together rather than
   independently.

10. Overall, department-level attendance is relatively stable,
    but employee-level analysis reveals specific attendance,
    absenteeism, and overtime cases that may require attention.
*/

/*===========================
   Business Recommendations
=============================

1. Investigate individual employees with unusually low attendance
   or high absenteeism to understand whether workload, scheduling,
   leave patterns, or other workplace factors are contributing.

2. Review workload and staffing in Operations and Customer Support,
   where average overtime hours are among the highest.

3. Monitor employees with exceptionally high overtime hours to
   reduce the risk of workload imbalance and operational dependency
   on individual employees.

4. Review attendance patterns in departments with comparatively
   higher absenteeism, particularly Product and Human Resources.

5. Use attendance, absenteeism, and overtime together when
   evaluating workforce productivity instead of relying on a
   single metric.

6. Establish regular attendance and overtime monitoring so that
   potential workforce issues can be identified before they
   become larger operational problems.
*/

