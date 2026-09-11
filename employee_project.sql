-- EMPLOYEE MANAGEMENT SYSTEM - COMPLETE MYSQL PROJECT
-- Built from the supplied 6 CSV files and project document

CREATE DATABASE IF NOT EXISTS employee_management_system;
USE employee_management_system;

SET FOREIGN_KEY_CHECKS = 0;
DROP PROCEDURE IF EXISTS GetEmployeePayrollDetails;
DROP VIEW IF EXISTS EmployeePayrollSummary;
DROP VIEW IF EXISTS DepartmentSalarySummary;
DROP TABLE IF EXISTS Payroll;
DROP TABLE IF EXISTS Leaves;
DROP TABLE IF EXISTS Qualification;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS SalaryBonus;
DROP TABLE IF EXISTS JobDepartment;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. TABLE CREATION
CREATE TABLE JobDepartment (
    Job_ID INT PRIMARY KEY,
    jobdept VARCHAR(50),
    name VARCHAR(100),
    description TEXT,
    salaryrange VARCHAR(50)
);

CREATE TABLE SalaryBonus (
    salary_ID INT PRIMARY KEY,
    Job_ID INT,
    amount DECIMAL(10,2),
    annual DECIMAL(10,2),
    bonus DECIMAL(10,2),
    CONSTRAINT fk_salary_job FOREIGN KEY (Job_ID) REFERENCES JobDepartment(Job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Employee (
    emp_ID INT PRIMARY KEY,
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    gender VARCHAR(10),
    age INT,
    contact_add VARCHAR(100),
    emp_email VARCHAR(100) UNIQUE,
    emp_pass VARCHAR(50),
    Job_ID INT,
    CONSTRAINT fk_employee_job FOREIGN KEY (Job_ID) REFERENCES JobDepartment(Job_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE Qualification (
    QualID INT PRIMARY KEY,
    Emp_ID INT,
    Position VARCHAR(50),
    Requirements VARCHAR(255),
    Date_In DATE,
    CONSTRAINT fk_qualification_emp FOREIGN KEY (Emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Leaves (
    leave_ID INT PRIMARY KEY,
    emp_ID INT,
    date DATE,
    reason TEXT,
    CONSTRAINT fk_leave_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Payroll (
    payroll_ID INT PRIMARY KEY,
    emp_ID INT,
    job_ID INT,
    salary_ID INT,
    leave_ID INT,
    date DATE,
    report TEXT,
    total_amount DECIMAL(10,2),
    CONSTRAINT fk_payroll_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_salary FOREIGN KEY (salary_ID) REFERENCES SalaryBonus(salary_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_leave FOREIGN KEY (leave_ID) REFERENCES Leaves(leave_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-
-- 3. DATA VALIDATION
SELECT 'JobDepartment' AS table_name, COUNT(*) AS row_count FROM JobDepartment
UNION ALL SELECT 'SalaryBonus', COUNT(*) FROM SalaryBonus
UNION ALL SELECT 'Employee', COUNT(*) FROM Employee
UNION ALL SELECT 'Qualification', COUNT(*) FROM Qualification
UNION ALL SELECT 'Leaves', COUNT(*) FROM Leaves
UNION ALL SELECT 'Payroll', COUNT(*) FROM Payroll;

-- 4. EMPLOYEE INSIGHTS
-- 1. Number of unique employees
SELECT COUNT(DISTINCT emp_ID) AS unique_employees FROM Employee;

-- 2. Departments with highest number of employees
SELECT jd.jobdept, COUNT(e.emp_ID) AS employee_count
FROM JobDepartment jd
JOIN Employee e ON jd.Job_ID = e.Job_ID
GROUP BY jd.jobdept
ORDER BY employee_count DESC;

-- 3. Average salary per department
SELECT jd.jobdept, ROUND(AVG(sb.amount),2) AS average_salary
FROM JobDepartment jd
JOIN SalaryBonus sb ON jd.Job_ID = sb.Job_ID
GROUP BY jd.Job_ID, jd.jobdept
ORDER BY average_salary DESC;

-- 4. Top 5 highest-paid employees
SELECT e.emp_ID, CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
       sb.amount AS salary
FROM Employee e
JOIN SalaryBonus sb ON e.Job_ID = sb.Job_ID
ORDER BY sb.amount DESC
LIMIT 5;

-- 5. Total salary expenditure
SELECT SUM(sb.amount) AS total_salary_expenditure
FROM Employee e
JOIN SalaryBonus sb ON e.Job_ID = sb.Job_ID;

-- 5. JOB ROLE AND DEPARTMENT ANALYSIS
-- 1. Number of job roles in each department
SELECT jobdept, COUNT(DISTINCT Job_ID) AS job_role_count
FROM JobDepartment
GROUP BY jobdept
ORDER BY job_role_count DESC;

-- 2. Average salary range per department
SELECT jobdept,
       ROUND(AVG(
           CASE
             WHEN salaryrange LIKE '%-%'
             THEN (CAST(SUBSTRING_INDEX(salaryrange, '-', 1) AS DECIMAL(10,2)) +
                   CAST(SUBSTRING_INDEX(salaryrange, '-', -1) AS DECIMAL(10,2))) / 2
             ELSE NULL
           END
       ),2) AS average_salary_range
FROM JobDepartment
GROUP BY jobdept;

-- 3. Job roles offering highest salary
SELECT jd.jobdept, jd.name AS job_role, sb.amount AS salary
FROM JobDepartment jd
JOIN SalaryBonus sb ON jd.Job_ID = sb.Job_ID
WHERE sb.amount = (SELECT MAX(amount) FROM SalaryBonus);

-- 4. Departments with highest total salary allocation
SELECT jd.jobdept, SUM(sb.amount) AS total_salary_allocation
FROM JobDepartment jd
JOIN SalaryBonus sb ON jd.Job_ID = sb.Job_ID
GROUP BY jd.jobdept
ORDER BY total_salary_allocation DESC;

-- 6. QUALIFICATION AND SKILLS ANALYSIS
-- 1. Employees with at least one qualification
SELECT COUNT(DISTINCT Emp_ID) AS employees_with_qualification
FROM Qualification;

-- 2. Positions requiring the most qualifications
SELECT Position, COUNT(*) AS qualification_count
FROM Qualification
GROUP BY Position
ORDER BY qualification_count DESC;

-- 3. Employees with the highest number of qualifications
SELECT e.emp_ID, CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
       COUNT(q.QualID) AS qualification_count
FROM Employee e
JOIN Qualification q ON e.emp_ID = q.Emp_ID
GROUP BY e.emp_ID, e.firstname, e.lastname
ORDER BY qualification_count DESC;

-- 7. LEAVE AND ABSENCE PATTERNS
-- 1. Year with the most employees taking leaves
SELECT YEAR(date) AS leave_year,
       COUNT(DISTINCT emp_ID) AS employees_taking_leave
FROM Leaves
GROUP BY YEAR(date)
ORDER BY employees_taking_leave DESC;

-- 2. Average number of leave records per employee by department
SELECT jd.jobdept,
       ROUND(COUNT(l.leave_ID) / NULLIF(COUNT(DISTINCT e.emp_ID),0),2) AS avg_leave_records_per_employee
FROM JobDepartment jd
JOIN Employee e ON jd.Job_ID = e.Job_ID
LEFT JOIN Leaves l ON e.emp_ID = l.emp_ID
GROUP BY jd.jobdept;

-- 3. Employees who have taken the most leaves
SELECT e.emp_ID, CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
       COUNT(l.leave_ID) AS leave_count
FROM Employee e
JOIN Leaves l ON e.emp_ID = l.emp_ID
GROUP BY e.emp_ID, e.firstname, e.lastname
ORDER BY leave_count DESC;

-- 4. Total company-wide leave records
SELECT COUNT(*) AS total_leave_records FROM Leaves;

-- 5. Leave days vs payroll amounts (record-level comparison)
SELECT l.leave_ID, l.emp_ID, l.date AS leave_date,
       p.payroll_ID, p.total_amount
FROM Leaves l
LEFT JOIN Payroll p ON l.leave_ID = p.leave_ID
ORDER BY l.date;

-- 8. PAYROLL AND COMPENSATION ANALYSIS
-- 1. Total monthly payroll processed
SELECT DATE_FORMAT(date, '%Y-%m') AS payroll_month,
       SUM(total_amount) AS total_monthly_payroll
FROM Payroll
GROUP BY DATE_FORMAT(date, '%Y-%m')
ORDER BY payroll_month;

-- 2. Average bonus per department
SELECT jd.jobdept, ROUND(AVG(sb.bonus),2) AS average_bonus
FROM JobDepartment jd
JOIN SalaryBonus sb ON jd.Job_ID = sb.Job_ID
GROUP BY jd.jobdept
ORDER BY average_bonus DESC;

-- 3. Department receiving highest total bonuses
SELECT jd.jobdept, SUM(sb.bonus) AS total_bonus
FROM JobDepartment jd
JOIN SalaryBonus sb ON jd.Job_ID = sb.Job_ID
GROUP BY jd.jobdept
ORDER BY total_bonus DESC
LIMIT 1;

-- 4. Average total_amount after leave deductions
SELECT ROUND(AVG(total_amount),2) AS average_payroll_amount FROM Payroll;

-- 9. USEFUL PROJECT VIEWS
CREATE OR REPLACE VIEW DepartmentSalarySummary AS
SELECT jd.jobdept,
       COUNT(DISTINCT e.emp_ID) AS employee_count,
       ROUND(AVG(sb.amount),2) AS average_salary,
       SUM(sb.amount) AS salary_allocation,
       SUM(sb.bonus) AS total_bonus
FROM JobDepartment jd
LEFT JOIN Employee e ON jd.Job_ID = e.Job_ID
LEFT JOIN SalaryBonus sb ON jd.Job_ID = sb.Job_ID
GROUP BY jd.Job_ID, jd.jobdept;

CREATE OR REPLACE VIEW EmployeePayrollSummary AS
SELECT e.emp_ID,
       CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
       jd.jobdept,
       jd.name AS job_role,
       sb.amount AS salary,
       sb.bonus,
       p.date AS payroll_date,
       p.total_amount
FROM Employee e
LEFT JOIN JobDepartment jd ON e.Job_ID = jd.Job_ID
LEFT JOIN SalaryBonus sb ON e.Job_ID = sb.Job_ID
LEFT JOIN Payroll p ON e.emp_ID = p.emp_ID;


SELECT * FROM DepartmentSalarySummary;
SELECT * FROM EmployeePayrollSummary;

-- 10. STORED PROCEDURE
DELIMITER $$
CREATE PROCEDURE GetEmployeePayrollDetails(IN p_Emp_ID INT)
BEGIN
    SELECT e.emp_ID,
           CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
           jd.jobdept,
           jd.name AS job_role,
           sb.amount AS salary,
           sb.bonus,
           p.payroll_ID,
           p.date AS payroll_date,
           p.report,
           p.total_amount,
           l.date AS leave_date,
           l.reason AS leave_reason
    FROM Employee e
    LEFT JOIN JobDepartment jd ON e.Job_ID = jd.Job_ID
    LEFT JOIN SalaryBonus sb ON e.Job_ID = sb.Job_ID
    LEFT JOIN Payroll p ON e.emp_ID = p.emp_ID
    LEFT JOIN Leaves l ON p.leave_ID = l.leave_ID
    WHERE e.emp_ID = p_Emp_ID;
END$$
DELIMITER ;

 CALL GetEmployeePayrollDetails(1);

-- END OF EMPLOYEE MANAGEMENT SYSTEM PROJECT