-- ADMISSION AND PATIENT ANALYSIS ? --

-- What is the total number of admissions --
SELECT
    COUNT(*) AS total_admissions
FROM admission_clean_view;   -- 45,000 -- TOTAL ADMISSIONS


-- How many individual patients are represented in those 45,000 admissions?

SELECT 
	COUNT(DISTINCT patient_id) AS total_unique_patients
FROM admission_clean_view;   -- 23275 --


-- what proprtion of admissions are elective and emergency ?
SELECT 
	admission_type,
    COUNT(*) AS admission_count,
    
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2) AS admission_percentage
        
FROM admission_clean_view
GROUP BY admission_type
ORDER BY admission_count DESC;


-- Holw long are patients staying in the hospital (LOS)?

SELECT
    admission_id,
    admission_date,
    discharge_date,
    DATEDIFF(discharge_date, admission_date) AS length_of_stay
FROM admission_clean_view
LIMIT 10;

-- what is the average length of stay (LOS) at the hospital ?
SELECT
	ROUND(
		AVG(DATEDIFF(discharge_date, admission_date))
		,2) AS length_of_stay
FROM admission_clean_view;  -- 5.16 days --


-- What is the median LOS ?

WITH los AS (
    SELECT
        DATEDIFF(discharge_date, admission_date) AS length_of_stay
    FROM admission_clean_view
),
ranked AS (
    SELECT
        length_of_stay,
        ROW_NUMBER() OVER (ORDER BY length_of_stay) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM los
)
SELECT
    AVG(length_of_stay) AS median_length_of_stay
FROM ranked
WHERE row_num IN (
    FLOOR((total_rows + 1) / 2),
    CEIL((total_rows + 1) / 2)
);


-- Which department handles most admissions ?
SELECT 
	d.department_name,
    a.department_id,
    COUNT(*) AS admission_count,
    ROUND(
		COUNT(*) * 100 / SUM(COUNT(*)) OVER()
        , 2 ) AS admission_percentage
FROM admission_clean_view a
JOIN department d
ON a.department_id = d.department_id
GROUP BY a.department_id, d.department_name
ORDER BY admission_count DESC;


-- how long do patients typically stay in each department?
SELECT 
	d.department_name,
    a.department_id,
	ROUND(
		AVG(
		DATEDIFF(a.discharge_date, a.admission_date))
        ,2 ) AS average_length_of_stay
FROM admission_clean_view a
JOIN department d
ON a.department_id = d.department_id
GROUP BY a.department_id, d.department_name
ORDER BY average_length_of_stay DESC;


-- How does admission activity change over time?
SELECT 
	YEAR(admission_date) AS year_of_admission,
    COUNT(*) AS admission_count
FROM admission_clean_view
GROUP BY year_of_admission
ORDER BY year_of_admission;

-- what are the earliest and latest admission dates?
SELECT 	
		MIN(admission_date) AS earliest_admission,
        MAX(admission_date) AS latest_admission
FROM admission_clean_view;
        
-- How does admission activity change month by month between 2020 and 2025?        
 SELECT 
		YEAR(admission_date) AS year_of_admission,
        MONTHNAME(admission_date) AS admission_month,
        MONTH(admission_date) AS month_num,
        COUNT(*) AS admission_count
FROM admission_clean_view
GROUP BY year_of_admission, admission_month, month_num
ORDER BY year_of_admission, month_num;


-- Does length of stay differ between Emergency and Elective admissions?
  SELECT 
		admission_type,
        ROUND(
			AVG(
			DATEDIFF(discharge_date, admission_date))
			,2 ) AS average_length_of_stay
FROM admission_clean_view  
GROUP BY admission_type;


-- Length of stay (LOS) by Department and Admission Type
SELECT 
		d.department_name,
        a.admission_type,
        COUNT(*) AS admission_count,
        ROUND(
			AVG(
			DATEDIFF(a.discharge_date, a.admission_date))
			,2 ) AS average_length_of_stay
FROM admission_clean_view  a
JOIN department d
ON a.department_id = d.department_id
GROUP BY d.department_name, a.admission_type
ORDER BY d.department_name, a.admission_type;


-- BED CAPACITY 
-- How many beds does the hospital have in total?
SELECT
    COUNT(*) AS total_wards,
    SUM(total_beds) AS total_bed_capacity
FROM ward;

-- How many of the hospital beds are currently recorded as Available and Occupied
SELECT 
	bed_status,
    COUNT(*) AS bed_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_beds
FROM bed
GROUP BY bed_status
ORDER BY bed_count;

-- which ward are those occupied and available beds located ?.

SELECT
    w.ward_name,
    w.ward_type,
    w.total_beds AS ward_capacity,
    SUM(CASE WHEN b.bed_status = 'Occupied' THEN 1 ELSE 0 END) AS occupied_beds,
    SUM(CASE WHEN b.bed_status = 'Available' THEN 1 ELSE 0 END) AS available_beds
FROM ward w
JOIN bed b
    ON w.ward_id = b.ward_id
GROUP BY
    w.ward_name,
    w.ward_type,
    w.total_beds
ORDER BY
    occupied_beds DESC;
    

-- bed occupancy rate by ward
SELECT
    w.ward_name,
    w.ward_type,
    w.total_beds AS ward_capacity,
    SUM(CASE WHEN b.bed_status = 'Occupied' THEN 1 ELSE 0 END) AS occupied_beds,
    SUM(CASE WHEN b.bed_status = 'Available' THEN 1 ELSE 0 END) AS available_beds,
    ROUND(
			SUM(CASE WHEN b.bed_status = 'Occupied' THEN 1 ELSE 0 END)
            * 100 / w.total_beds , 2 
            ) AS recorded_occupancy_rate
            
FROM ward w
JOIN bed b
    ON w.ward_id = b.ward_id
GROUP BY
    w.ward_name,
    w.ward_type,
    w.total_beds
ORDER BY
    recorded_occupancy_rate DESC;
    
    
-- Occupancy rate by each ward type

SELECT 
		w.ward_type,
        COUNT(b.bed_id) AS total_bed_capacity,
        SUM(CASE WHEN b.bed_status = 'Occupied' THEN 1 ELSE 0 END) AS occupied_beds,
        SUM(CASE WHEN b.bed_status = 'Available' THEN 1 ELSE 0 END) AS available_beds,
        ROUND(
			SUM(CASE WHEN b.bed_status = 'Occupied' THEN 1 ELSE 0 END)
            * 100 / COUNT(b.bed_id) , 2 
            ) AS recorded_occupancy_rate
        
FROM ward w
JOIN bed b
ON w.ward_id = b.ward_id
GROUP BY w.ward_type
ORDER BY recorded_occupancy_rate DESC;


-- WORKFORCE ANALYSIS?

-- How many employees do we have?
SELECT
COUNT(*) AS total_employees   
FROM employee_clean_view;   -- 500 employees --


-- What roles make up the hospital workforce?
SELECT
	role, 
	COUNT(*) AS employee_count,
    
	ROUND(
	COUNT(*) * 100 / SUM(COUNT(*)) OVER()
	, 2) AS percentage_workforce
FROM employee_clean_view
GROUP BY role
ORDER BY percentage_workforce;


-- How is the workforce split between Full-time and Contract employees?

SELECT 
	employment_type,
    COUNT(*) AS employee_count,
	
    ROUND(
	COUNT(*) * 100 / SUM(COUNT(*)) OVER()
	, 2) AS percentage_workforce
FROM employee_clean_view
GROUP BY employment_type
ORDER BY percentage_workforce;


-- How are employees distributed across hospital departments?

SELECT
    d.department_name,
    COUNT(*) AS employee_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_workforce
FROM employee_clean_view e
JOIN department d
    ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY employee_count DESC;


-- How are staff assignments distributed across morning, evening and night shifts?

SELECT 
	shift,
    COUNT(*) AS assignment_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_assignment
FROM staff_assignment s
JOIN employee_clean_view e
ON s.employee_id = e.employee_id
GROUP BY shift
ORDER BY assignment_count;


-- How are staff assignments distributed across wards?

SELECT 
	w.ward_name,
    w.ward_type,
    COUNT(s.assignment_id) AS staff_assignment,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_assignment
FROM staff_assignment s
JOIN ward w
ON s.ward_id = w.ward_id
GROUP BY w.ward_name, w.ward_type
ORDER BY staff_assignment;


-- DIAGNOSTICS
-- How many diagnostic tests are being performed, and what types of tests are being used?--
SELECT 
COUNT(*) AS total_diagnostics
FROM patient_diagnostic;

-- What types of diagnostic tests are being performed most often?
SELECT 
		dt.test_name,
        dt.test_category,
        COUNT(*) AS diagnostic_test_count,
        ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_diagnostic_test
    
FROM diagnostic_test dt
JOIN patient_diagnostic pd
ON dt.test_id = pd.test_id
GROUP BY dt.test_name, dt.test_category
ORDER BY percentage_diagnostic_test;


-- -- What category of diagnostic tests are being performed most often?
SELECT 
		dt.test_category,
        COUNT(*) AS diagnostic_test_count,
        ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_diagnostic_test
    
FROM diagnostic_test dt
JOIN patient_diagnostic pd
ON dt.test_id = pd.test_id
GROUP BY dt.test_category
ORDER BY percentage_diagnostic_test;


-- What proportion of diagnostic results are recorded as Normal and Abnormal?
SELECT 
		result_status,
        COUNT(*) AS diagnostic_test_count,
        ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_diagnostic_test
    
FROM patient_diagnostic 
GROUP BY result_status
ORDER BY diagnostic_test_count;


-- Does the proportion of abnormal results differ between Pathology and Radiology?
SELECT
		pd.result_status,
        dt.test_category,
        COUNT(*) test_count,
	ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY dt.test_category),
        2
    ) AS percentage_in_category
    
FROM patient_diagnostic pd	
JOIN diagnostic_test dt
ON pd.test_id = dt.test_id
GROUP BY pd.result_status, dt.test_category
ORDER BY dt.test_category, test_count;


-- Which departments generate the most diagnostic-test activity?
SELECT
		d.department_name,
        d.department_type,
        COUNT(*) AS test_count,
        
	ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2) AS percentage_test_count
    
FROM patient_diagnostic pd
JOIN diagnostic_test dt
ON pd.test_id = dt.test_id
JOIN department d
ON d.department_id= dt.department_id
GROUP BY d.department_name, d.department_type
ORDER BY test_count;  


-- PHARMACY (PRESCRIPTION AND DRUGS)

-- What are the total prescription?
SELECT
    COUNT(*) AS total_prescriptions
FROM prescription;

-- Which drug categories are being prescribed most often?
SELECT
    d.drug_category,
    COUNT(*) AS prescription_count,
    
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_prescriptions
    
FROM prescription p
JOIN drug d
    ON p.drug_id = d.drug_id
GROUP BY d.drug_category
ORDER BY prescription_count DESC;


-- How many drugs is available in each category?
SELECT
    drug_category,
    COUNT(*) AS drug_count,
    
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_drug
    
FROM drug 
GROUP BY drug_category
ORDER BY drug_count DESC;


-- How many drugs are currently at or below their reorder level?
SELECT 
		COUNT(*) AS drugs_at_or_below_reorder
FROM drug_inventory
WHERE inventory_status = 'Low';


-- Which drug categories have the most low-stock items?
SELECT 
		d.drug_category,
        COUNT(*) AS low_stuck_drugs
FROM drug d
JOIN drug_inventory di
ON d.drug_id = di.drug_id
WHERE di.inventory_status = 'Low'
GROUP BY d.drug_category
ORDER BY low_stuck_drugs;


-- What percentage of drugs in each category are classified as Low inventory?
SELECT
    d.drug_category,
    COUNT(*) AS total_drugs,
    
    SUM(
        CASE WHEN di.inventory_status = 'Low' THEN 1 ELSE 0 END
        ) AS low_stock_drugs,
    
    ROUND(
        SUM(CASE WHEN di.inventory_status = 'Low' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*) , 2 
        ) AS low_stock_percentage
    
FROM drug_inventory di
JOIN drug d
    ON di.drug_id = d.drug_id
GROUP BY d.drug_category;






