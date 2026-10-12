-- DATA TABLE AUDIT -- Lets check the tables for inconsistencies and data quality

-- 1. ADMISSION TABLE --

-- Check missing values
SELECT
    COUNT(*) AS total_rows,
    COUNT(admission_id) AS admission_id_filled,
    COUNT(admission_date) AS admission_date_filled,
    COUNT(discharge_date) AS discharge_date_filled,
    COUNT(admission_type) AS admission_type_filled,
    COUNT(admission_status) AS admission_status_filled,
    COUNT(patient_id) AS patient_id_filled,
    COUNT(department_id) AS department_id_filled,
    COUNT(ward_id) AS ward_id_filled,
    COUNT(bed_id) AS bed_id_filled,
    COUNT(disease_id) AS disease_id_filled
FROM admission;

-- Duplicate admissions.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT admission_id) AS unique_admission_ids
FROM admission;

-- Check the admission dates (records where the discharge date is before the admission date).
SELECT
    COUNT(*) AS invalid_date_records
FROM admission
WHERE discharge_date < admission_date;

-- Check for impossible patient dates (whether a patient's date of birth occurs after their admission date.)

SELECT 
	COUNT(*) AS impossible_patient_date_record
FROM admission AS adm
JOIN patient AS pat
    ON adm.patient_id = pat.patient_id
WHERE pat.date_of_birth > adm.admission_date;


-- Let's inspect the impossible patient records (1630 records)
SELECT
    adm.admission_id,
    adm.patient_id,
    pat.date_of_birth,
    adm.admission_date,
    adm.discharge_date
FROM admission adm
JOIN patient pat
    ON adm.patient_id = pat.patient_id
WHERE pat.date_of_birth > adm.admission_date
LIMIT 20;


SELECT
    MIN(date_of_birth) AS earliest_dob,
    MAX(date_of_birth) AS latest_dob
FROM patient;

SELECT
    YEAR(pat.date_of_birth) AS birth_year,
    COUNT(*) AS invalid_records
FROM admission adm
JOIN patient pat
    ON adm.patient_id = pat.patient_id
WHERE pat.date_of_birth > adm.admission_date
GROUP BY YEAR(pat.date_of_birth)
ORDER BY birth_year;


SELECT
    YEAR(adm.admission_date) AS admission_year,
    YEAR(pat.date_of_birth) AS birth_year,
    COUNT(*) AS invalid_records
FROM admission adm
JOIN patient pat
    ON adm.patient_id = pat.patient_id
WHERE pat.date_of_birth > adm.admission_date
GROUP BY
    YEAR(adm.admission_date),
    YEAR(pat.date_of_birth)
ORDER BY
    admission_year,
    birth_year;
    
    
    SELECT
    MIN(TIMESTAMPDIFF(YEAR, pat.date_of_birth, adm.admission_date)) AS minimum_age,
    MAX(TIMESTAMPDIFF(YEAR, pat.date_of_birth, adm.admission_date)) AS maximum_age,
    AVG(TIMESTAMPDIFF(YEAR, pat.date_of_birth, adm.admission_date)) AS average_age
FROM admission adm
JOIN patient pat
    ON adm.patient_id = pat.patient_id
WHERE pat.date_of_birth > adm.admission_date;


SELECT
    COUNT(*) AS invalid_admission_records,
    COUNT(DISTINCT adm.patient_id) AS affected_patients
FROM admission adm
JOIN patient pat
    ON adm.patient_id = pat.patient_id
WHERE pat.date_of_birth > adm.admission_date;



SELECT
    COUNT(*) AS affected_patients,
    SUM(
        CASE
            WHEN valid_admissions > 0 THEN 1
            ELSE 0
        END
    ) AS patients_with_valid_admissions
FROM (
    SELECT
        adm.patient_id,
        SUM(
            CASE
                WHEN pat.date_of_birth <= adm.admission_date THEN 1
                ELSE 0
            END
        ) AS valid_admissions
    FROM admission adm
    JOIN patient pat
        ON adm.patient_id = pat.patient_id
    GROUP BY adm.patient_id
    HAVING SUM(
        CASE
            WHEN p.date_of_birth > a.admission_date THEN 1
            ELSE 0
        END
    ) > 0
) x;


-- Check admission status values
SELECT
    admission_status,
    COUNT(*) AS record_count
FROM admission
GROUP BY admission_status
ORDER BY record_count DESC;


-- Check admission_type
SELECT
    admission_type,
    COUNT(*) AS record_count
FROM admission
GROUP BY admission_type
ORDER BY record_count DESC;


-- Check the foreign-key relationships in admission table

-- admission - patient table check
SELECT COUNT(*) AS foreign_patient_ids
FROM admission adm
LEFT JOIN patient pat
    ON adm.patient_id = pat.patient_id
WHERE pat.patient_id IS NULL;

-- admission - department table check
SELECT COUNT(*) AS foreign_department_ids
FROM admission adm
LEFT JOIN department dep
    ON adm.department_id = dep.department_id
WHERE dep.department_id IS NULL;

-- admission - ward table check
SELECT COUNT(*) AS foreign_ward_ids
FROM admission adm
LEFT JOIN ward wd
    ON adm.ward_id = wd.ward_id
WHERE wd.ward_id IS NULL;

-- admission - bed table check
SELECT COUNT(*) AS foreign_bed_ids
FROM admission adm
LEFT JOIN bed bd
    ON adm.bed_id = bd.bed_id
WHERE bd.bed_id IS NULL;

-- admission - disease table check
SELECT COUNT(*) AS foreign_disease_ids
FROM admission adm
LEFT JOIN disease dis
    ON adm.disease_id = dis.disease_id
WHERE dis.disease_id IS NULL;


-- 2. BED TABLE

-- check for missing values 
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT bed_id) AS unique_bed_ids,
    COUNT(bed_id) AS bed_id_filled,
    COUNT(bed_number) AS bed_number_filled,
    COUNT(bed_status) AS bed_status_filled,
    COUNT(ward_id) AS ward_id_filled
FROM bed;


-- check for duplicates
SELECT
    bed_number,
    COUNT(*) AS number_of_beds
FROM bed
GROUP BY bed_number
HAVING COUNT(*) > 1;


-- check bed status consistencies
SELECT 
	bed_status,
    COUNT(*) AS bed_count
FROM bed
GROUP BY bed_status
ORDER BY bed_status;


-- check the bed - ward relationships

SELECT COUNT(*) AS foreign_ward_ids
FROM bed bd
JOIN ward wd
ON bd.ward_id = wd.ward_id
WHERE wd.ward_id IS NULL;



-- 3. BILLING TABLE --
-- check for missing values and duplicates
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT bill_id) AS unique_bills,
    COUNT(bill_id) AS bill_id_filled,
    COUNT(bill_date) AS bill_date_filled,
    COUNT(total_amount) AS total_amount_filled,
    COUNT(insurance_covered_amount) AS insurance_covered_filled,
    COUNT(patient_payable_amount) AS patient_payable_filled,
    COUNT(payment_status) AS payment_status_filled,
    COUNT(payment_mode) AS payment_mode_filled,
    COUNT(admission_id) AS admission_id_filled
FROM billing;

-- check payment status
SELECT 
	payment_status,
    COUNT(*) AS bill_count
FROM billing
GROUP BY payment_status
ORDER BY payment_status;

-- check payment mode
SELECT 
	payment_mode,
    COUNT(*) AS bill_count
FROM billing
GROUP BY payment_mode
ORDER BY payment_mode;


-- check billing amount
SELECT
    MIN(total_amount) AS min_total_amount,
    MIN(insurance_covered_amount) AS min_insurance_covered,
    MIN(patient_payable_amount) AS min_patient_payable
FROM billing;


-- total amount CHECK
SELECT 
	COUNT(*) AS mismatched_billing
FROM billing
WHERE ROUND(insurance_covered_amount + patient_payable_amount ,2)
	<>ROUND(total_amount,2);
    
-- check billing and admission table relationships
SELECT 
	COUNT(*) AS foreign_admission_id
    FROM billing AS bl
	LEFT JOIN admission AS adm
    ON bl.admission_id = adm.admission_id
WHERE adm.admission_id IS NULL;

-- CHECK duplicate admission id
SELECT
    COUNT(DISTINCT admission_id) AS admissions_with_bills,
    COUNT(*) AS total_bills
FROM billing;


-- 4. billing detail table

-- check for missing values and duplicates
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT billing_detail_id) AS unique_rows,
    COUNT(billing_detail_id) AS detail_id_filled,
    COUNT(charge_type) AS charge_type_filled,
    COUNT(reference_id) AS reference_id_filled,
    COUNT(amount) AS amount_filled,
    COUNT(bill_id) AS bill_id_filled
FROM billing_detail;

-- check charge types

SELECT
    charge_type,
    COUNT(*) AS detail_count,
    COUNT(reference_id) AS reference_id_filled
FROM billing_detail
GROUP BY charge_type
ORDER BY charge_type;

-- check charge amounts

SELECT
    MIN(amount) AS minimum_amount,
    MAX(amount) AS maximum_amount,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN amount <= 0 THEN 1 ELSE 0 END) AS zero_or_negative_amounts
FROM billing_detail;


-- check that every billing detail belongs to a valid bill
SELECT 
	COUNT(*) AS foreign_bill_ids
	FROM billing_detail bd
	LEFT JOIN billing bl
	ON bd.bill_id = bl.bill_id
WHERE bl.bill_id IS NULL;


-- let's check whether the sum of each bill's billing details matches the bill's total_amount.
SELECT
    COUNT(*) AS mismatched_bills
FROM billing bl
JOIN (
    SELECT
        bill_id,
        ROUND(SUM(amount), 2) AS detail_total
    FROM billing_detail
    GROUP BY bill_id
) bd
    ON bl.bill_id = bd.bill_id
WHERE ROUND(bl.total_amount, 2) <> bd.detail_total;


-- lets look at a few bills side-by-side
SELECT
    bl.bill_id,
    bl.total_amount,
    ROUND(SUM(bd.amount), 2) AS detail_total,
    ROUND(bl.total_amount - SUM(bd.amount), 2) AS difference
FROM billing bl
JOIN billing_detail bd
    ON bl.bill_id = bd.bill_id
GROUP BY bl.bill_id, bl.total_amount
LIMIT 10;

-- Let's check whether every bill has at least one detail record.
SELECT
    COUNT(*) AS bills_without_details
FROM billing bl
LEFT JOIN billing_detail bd
    ON bl.bill_id = bd.bill_id
WHERE bd.bill_id IS NULL;

-- lets check for duplicate record
SELECT
    charge_type,
    amount,
    reference_id,
    bill_id,
    COUNT(*) AS duplicate_count
FROM billing_detail
GROUP BY
    charge_type,
    amount,
    reference_id,
    bill_id
HAVING COUNT(*) > 1
LIMIT 10;


-- 5. department table checks

SELECT
    COUNT(*) AS total_rows,
    COUNT(department_id) AS department_id_filled,
    COUNT(department_name) AS department_name_filled,
    COUNT(department_type) AS department_type_filled,
    COUNT(floor_number) AS floor_number_filled,
    COUNT(status) AS status_filled
FROM department;

-- check for duplicates
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT department_id) AS unique_department_ids
FROM department;

-- check duplicate department name
SELECT
    department_name,
    COUNT(*) AS department_count
FROM department
GROUP BY department_name
HAVING COUNT(*) > 1;

SELECT
    status,
    COUNT(*) AS department_count
FROM department
GROUP BY status
ORDER BY status;


SELECT
    department_type,
    COUNT(*) AS department_count
FROM department
GROUP BY department_type
ORDER BY department_type;


SELECT
    MIN(floor_number) AS minimum_floor,
    MAX(floor_number) AS maximum_floor,
    COUNT(DISTINCT floor_number) AS unique_floors
FROM department;


SELECT
    floor_number, department_name,
    COUNT(*) AS department_count
FROM department
GROUP BY floor_number, department_name
ORDER BY floor_number;


SELECT
    department_type,
    GROUP_CONCAT(department_name ORDER BY department_name SEPARATOR ', ') AS departments
FROM department
GROUP BY department_type
ORDER BY department_type;


-- diagnostic test table check
SELECT
    COUNT(*) AS total_rows,
    COUNT(test_id) AS test_id_filled,
    COUNT(test_name) AS test_name_filled,
    COUNT(test_category) AS test_category_filled,
    COUNT(standard_cost) AS standard_cost_filled,
    COUNT(department_id) AS department_id_filled
FROM diagnostic_test;

-- check for duplicate test IDs

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT test_id) AS unique_test_ids
FROM diagnostic_test;


-- Next: check for duplicate test names
SELECT
    test_name,
    COUNT(*) AS test_count
FROM diagnostic_test
GROUP BY test_name
HAVING COUNT(*) > 1;


-- check the test categories
SELECT
    test_category,
    COUNT(*) AS test_count
FROM diagnostic_test
GROUP BY test_category
ORDER BY test_category;


-- check the standard costs
SELECT
    MIN(standard_cost) AS minimum_cost,
    MAX(standard_cost) AS maximum_cost,
    SUM(CASE WHEN standard_cost <= 0 THEN 1 ELSE 0 END) AS zero_or_negative_costs
FROM diagnostic_test;


-- check relationship with department table
SELECT COUNT(*) AS foreign_department_ids
FROM diagnostic_test dt
LEFT JOIN department dpt
    ON dt.department_id = dpt.department_id
WHERE dpt.department_id IS NULL;



-- disease table check
SELECT
    COUNT(*) AS total_rows,
    COUNT(disease_id) AS disease_id_filled,
    COUNT(disease_name) AS disease_name_filled
FROM disease;


-- check for duplicates
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT disease_id) AS unique_disease_ids
FROM disease;


SELECT
    disease_name,
    COUNT(*) AS disease_count
FROM disease
GROUP BY disease_name
HAVING COUNT(*) > 1;


SELECT
    disease_id,
    disease_name
FROM disease
ORDER BY disease_id;

-- check for blank or whitespace-only disease names
SELECT
    COUNT(*) AS blank_or_whitespace_names
FROM disease
WHERE TRIM(disease_name) = '';


-- doctor table check
SELECT
    COUNT(*) AS total_rows,
    COUNT(doctor_id) AS doctor_id_filled,
    COUNT(employee_id) AS employee_id_filled
FROM doctor;

-- check for duplicate doctor IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT doctor_id) AS unique_doctor_ids
FROM doctor;


-- check the employee relationship
SELECT COUNT(*) AS orphan_employee_ids
FROM doctor doc
LEFT JOIN employee emp
    ON doc.employee_id = emp.employee_id
WHERE emp.employee_id IS NULL;


SELECT
    employee_id,
    COUNT(*) AS doctor_count
FROM doctor
GROUP BY employee_id
HAVING COUNT(*) > 1;



-- check drug table

-- missing value check--
SELECT
    COUNT(*) AS total_rows,
    COUNT(drug_id) AS drug_id_filled,
    COUNT(drug_name) AS drug_name_filled,
    COUNT(drug_category) AS drug_category_filled,
    COUNT(manufacturer_id) AS manufacturer_id_filled
FROM drug;

-- check for duplicate
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT drug_id) AS unique_drug_ids
FROM drug;

-- check for duplicate drug names
SELECT
    drug_name,
    COUNT(*) AS drug_count
FROM drug
GROUP BY drug_name
HAVING COUNT(*) > 1;

-- investigate the duplicate drug names
SELECT
    drug_name,
    drug_category,
    manufacturer_id,
    COUNT(*) AS drug_count
FROM drug
GROUP BY
    drug_name,
    drug_category,
    manufacturer_id
HAVING COUNT(*) > 1
ORDER BY drug_name;


-- check the manufacturer relationship
SELECT COUNT(*) AS foreign_manufacturer_ids
FROM drug drg
LEFT JOIN drug_manufacturer dm
    ON drg.manufacturer_id = dm.manufacturer_id
WHERE dm.manufacturer_id IS NULL;


-- check drug categories
SELECT
    drug_category,
    COUNT(*) AS drug_count
FROM drug
GROUP BY drug_category
ORDER BY drug_category;


SELECT
    manufacturer_id,
    COUNT(*) AS drug_count
FROM drug
GROUP BY manufacturer_id
ORDER BY drug_count DESC;


-- check for blank or whitespace-only drug names
SELECT
    COUNT(*) AS blank_or_whitespace_names
FROM drug
WHERE TRIM(drug_name) = '';


-- drug inventory table CHECK
SELECT
    COUNT(*) AS total_rows,
    COUNT(inventory_id) AS inventory_id_filled,
    COUNT(drug_id) AS drug_id_filled
FROM drug_inventory;

-- duplicate check
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT inventory_id) AS unique_inventory_ids
FROM drug_inventory;


-- check the relationship with drug table --
SELECT COUNT(*) AS foreign_drug_ids
FROM drug_inventory di
LEFT JOIN drug drg
    ON di.drug_id = drg.drug_id
WHERE drg.drug_id IS NULL;

-- check the inventory quantity values
SELECT
    MIN(current_stock) AS minimum_quantity,
    MAX(current_stock) AS maximum_quantity,
    SUM(CASE WHEN current_stock < 0 THEN 1 ELSE 0 END) AS negative_quantities
FROM drug_inventory;


-- compare current stock with the reorder level
SELECT
    COUNT(*) AS below_or_at_reorder_level
FROM drug_inventory
WHERE current_stock <= reorder_level;


SELECT
    inventory_status,
    COUNT(*) AS inventory_count
FROM drug_inventory
GROUP BY inventory_status
ORDER BY inventory_status;


SELECT
    inventory_status,
    COUNT(*) AS status_mismatches
FROM drug_inventory
WHERE
    (current_stock <= reorder_level AND inventory_status <> 'Low')
    OR
    (current_stock > reorder_level AND inventory_status <> 'Normal')
GROUP BY inventory_status;



-- check drug manufacturer table

SELECT
    COUNT(*) AS total_rows,
    COUNT(manufacturer_id) AS manufacturer_id_filled,
    COUNT(manufacturer_name) AS manufacturer_name_filled
FROM drug_manufacturer;

-- check for duplicates
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT manufacturer_id) AS unique_manufacturer_ids
FROM drug_manufacturer;


-- check for duplicate manufacturer names
SELECT
    manufacturer_name,
    COUNT(*) AS manufacturer_count
FROM drug_manufacturer
GROUP BY manufacturer_name
HAVING COUNT(*) > 1;


SELECT
    manufacturer_name,
    manufacturer_id
FROM drug_manufacturer
WHERE manufacturer_name IN (
    'Dhar Ltd',
    'Behl Ltd',
    'Chowdhury Ltd',
    'Din PLC',
    'Johal PLC'
)
ORDER BY manufacturer_name, manufacturer_id;


-- check for blank/whitespace-only manufacturer names
SELECT
    COUNT(*) AS blank_or_whitespace_names
FROM drug_manufacturer
WHERE TRIM(manufacturer_name) = '';


-- check employee table
SELECT
    COUNT(*) AS total_rows,
    COUNT(employee_id) AS employee_id_filled
FROM employee;

-- duplicates CHECK 
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT employee_id) AS unique_employee_ids
FROM employee;

DESCRIBE employee;

-- check missing data

SELECT
    COUNT(*) AS total_rows,
    COUNT(employee_id) AS employee_id_filled,
    COUNT(employee_name) AS employee_name_filled,
    COUNT(gender) AS gender_filled,
    COUNT(role) AS role_filled,
    COUNT(employment_type) AS employment_type_filled,
    COUNT(date_of_joining) AS date_of_joining_filled,
    COUNT(department_id) AS department_id_filled
FROM employee;

-- check employee roles

SELECT
    role,
    COUNT(*) AS employee_count
FROM employee
GROUP BY role
ORDER BY employee_count DESC;

-- check employment types

SELECT
    employment_type,
    COUNT(*) AS employee_count
FROM employee
GROUP BY employment_type
ORDER BY employment_type;


-- check employee gender

SELECT
    gender,
    COUNT(*) AS employee_count
FROM employee
GROUP BY gender
ORDER BY gender;


-- check department relationship

SELECT COUNT(*) AS foreign_department_ids
FROM employee e
LEFT JOIN department d
    ON e.department_id = d.department_id
WHERE d.department_id IS NULL;


-- investigate date of joining

SELECT
    date_of_joining,
    COUNT(*) AS employee_count
FROM employee
GROUP BY date_of_joining
ORDER BY date_of_joining
LIMIT 10;


SELECT
    COUNT(*) AS invalid_joining_dates
FROM employee
WHERE STR_TO_DATE(date_of_joining, '%Y-%m-%d') IS NULL;


-- INSURANCE PROVIDER TABLE

SELECT
    COUNT(*) AS total_rows,
    COUNT(insurance_provider_id) AS provider_id_filled,
    COUNT(provider_name) AS provider_name_filled,
    COUNT(DISTINCT insurance_provider_id) AS unique_insurance_provider
FROM insurance_provider;

-- check duplicate names
SELECT
    provider_name,
    COUNT(*) AS provider_count
FROM insurance_provider
GROUP BY provider_name
HAVING COUNT(*) > 1;

-- check blank space in names
SELECT
    COUNT(*) AS blank_or_whitespace_names
FROM insurance_provider
WHERE TRIM(provider_name) = '';


-- PATIENT TABLE CHECK

SELECT
    COUNT(*) AS total_rows,
    COUNT(patient_id) AS patient_id_filled,
    COUNT(blood_group) AS blood_group_filled,
    COUNT(city) AS city_filled,
    COUNT(gender) AS gender_filled,
    COUNT(date_of_birth) AS date_of_birth_filled,
    COUNT(contact_number) AS contact_number_filled
FROM patient;

-- duplicate CHECK
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT patient_id) AS unique_patient_ids
FROM patient;

-- check patient gender
SELECT 
	COUNT(*) AS patient_count,
    gender
FROM patient
GROUP BY gender;

-- check bloodgroups
SELECT
	blood_group,
	COUNT(*) AS blood_group_count
FROM patient
GROUP BY blood_group
ORDER BY blood_group;


-- check cities

SELECT
    city,
    COUNT(*) AS patient_count
FROM patient
GROUP BY city
ORDER BY patient_count DESC;


SELECT
    COUNT(DISTINCT city) AS unique_cities
FROM patient;


-- check blank space

SELECT
	COUNT(*) AS blank_whitespace
FROM patient
WHERE TRIM(city) = '';

-- check patient DOB

SELECT
    MIN(date_of_birth) AS earliest_dob,
    MAX(date_of_birth) AS latest_dob
FROM patient;


SELECT
    COUNT(*) AS future_dob_patients
FROM patient
WHERE date_of_birth > CURDATE();

-- check the contact numbers
SELECT
    contact_number,
    COUNT(*) AS patient_count
FROM patient
GROUP BY contact_number
ORDER BY patient_count DESC
LIMIT 10;

-- check how many contact numbers contain alphabetic characters
SELECT
    COUNT(*) AS numbers_with_letters
FROM patient
WHERE contact_number REGEXP '[A-Za-z]';

-- check how many contact numbers have extensions
SELECT
    COUNT(*) AS numbers_with_extensions
FROM patient
WHERE contact_number REGEXP '[xX]';

-- are any contact numbers duplicated between patients?
SELECT
    COUNT(*) AS duplicate_contact_numbers
FROM (
    SELECT
        contact_number
    FROM patient
    GROUP BY contact_number
    HAVING COUNT(*) > 1
) AS duplicates;


-- PATIENT DIAGNOSTIC TABLE CHECK

DESCRIBE patient_diagnostic;

-- check missing values

SELECT
    COUNT(*) AS total_rows,
    COUNT(patient_diagnostic_id) AS diagnostic_id_filled,
    COUNT(test_date) AS test_date_filled,
    COUNT(result_status) AS result_status_filled,
    COUNT(admission_id) AS admission_id_filled,
    COUNT(test_id) AS test_id_filled,
    COUNT(doctor_id) AS doctor_id_filled
FROM patient_diagnostic;

-- duplicate CHECK TABLE
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT patient_diagnostic_id) AS unique_diagnostic_ids
FROM patient_diagnostic;

SELECT
    result_status,
    COUNT(*) AS result_count
FROM patient_diagnostic
GROUP BY result_status
ORDER BY result_status;

-- check that every diagnostic record links to a valid admission
SELECT COUNT(*) AS foreign_admission_ids
FROM patient_diagnostic pd
LEFT JOIN admission a
    ON pd.admission_id = a.admission_id
WHERE a.admission_id IS NULL;


-- check the diagnostic test relationship
SELECT COUNT(*) AS foreign_test_ids
FROM patient_diagnostic pd
LEFT JOIN diagnostic_test dt
    ON pd.test_id = dt.test_id
WHERE dt.test_id IS NULL;


-- check the doctor table relationship
SELECT COUNT(*) as foreign_doctor_id
FROM patient_diagnostic pd
LEFT JOIN doctor d
ON pd.doctor_id = d.doctor_id
WHERE d.doctor_id IS NULL;


-- PATIENT INSURANCE TABLE --
DESCRIBE patient_insurance;

-- check for complete data
SELECT 
	COUNT(patient_insurance_id) AS pi_filled,
	COUNT(policy_number) AS pn_filled,
	COUNT(coverage_percentage) AS cp_filled,
    COUNT(policy_start_date) AS psd_filled,
    COUNT(policy_end_date) AS ped_filled,
    COUNT(patient_id) AS pi_filled,
    COUNT(insurance_provider_id) AS ipi_filled
FROM patient_insurance;


-- check for duplicate
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT patient_insurance_id) AS unique_insurance_ids
FROM patient_insurance;

-- check policy numbers
SELECT
    COUNT(*) AS total_policies,
    COUNT(DISTINCT policy_number) AS unique_policy_numbers
FROM patient_insurance;

-- identify repeated policies
SELECT
    policy_number,
    COUNT(*) AS policy_count
FROM patient_insurance
GROUP BY policy_number
HAVING COUNT(*) > 1
ORDER BY policy_count DESC;


SELECT
    policy_number,
    patient_id,
    insurance_provider_id,
    policy_start_date,
    policy_end_date,
    coverage_percentage
FROM patient_insurance
WHERE policy_number IN (
    'POL00703928',
    'POL21840563',
    'POL06140712',
    'POL63965333'
)
ORDER BY policy_number, patient_id;


SELECT
    MIN(coverage_percentage) AS minimum_coverage,
    MAX(coverage_percentage) AS maximum_coverage,
    SUM(
        CASE
            WHEN coverage_percentage < 0
              OR coverage_percentage > 100
            THEN 1
            ELSE 0
        END
    ) AS invalid_coverage_records
    
FROM patient_insurance;


-- check policy dates
SELECT
    COUNT(*) AS invalid_policy_dates
FROM patient_insurance
WHERE policy_end_date < policy_start_date;

-- check the patient relationship
SELECT COUNT(*) AS orphan_patient_ids
FROM patient_insurance pi
LEFT JOIN patient p
    ON pi.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- check the insurance-provider relationship
SELECT COUNT(*) AS orphan_provider_ids
FROM patient_insurance pi
LEFT JOIN insurance_provider ip
    ON pi.insurance_provider_id = ip.insurance_provider_id
WHERE ip.insurance_provider_id IS NULL;


-- PRESCRIPTION TABLE CHECK
DESCRIBE prescription;	

SELECT
    COUNT(*) AS total_rows,
    COUNT(prescription_id) AS prescription_id_filled,
    COUNT(dosage) AS dosage_filled,
    COUNT(frequency) AS frequency_filled,
    COUNT(duration_days) AS duration_filled,
    COUNT(admission_id) AS admission_id_filled,
    COUNT(drug_id) AS drug_id_filled
FROM prescription;

-- CHECK ZERO DURATIONS
SELECT COUNT(*) AS negative_duration_days
FROM prescription
WHERE duration_days <= 0;

SELECT 
	MIN(duration_days) AS min_duration,
	MAX(duration_days) AS max_duration
FROM prescription;

-- check relationship with admissions
SELECT COUNT(*) AS orphan_admission_ids
FROM prescription p
LEFT JOIN admission a
    ON p.admission_id = a.admission_id
WHERE a.admission_id IS NULL;

-- check drug relationsip
SELECT COUNT(*) AS orphan_drug_id
FROM prescription p
JOIN drug d
ON p.drug_id = d.drug_id
WHERE d.drug_id IS NULL;

-- check prescription frequencies
SELECT
    frequency,
    COUNT(*) AS prescription_count
FROM prescription
GROUP BY frequency
ORDER BY frequency;


-- check dosage values
SELECT
	dosage,
    COUNT(*) AS prescription_count
FROM prescription
GROUP BY dosage
ORDER BY prescription_count;


SELECT
    admission_id,
    drug_id,
    dosage,
    frequency,
    duration_days,
    COUNT(*) AS prescription_count
FROM prescription
GROUP BY
    admission_id,
    drug_id,
    dosage,
    frequency,
    duration_days
HAVING COUNT(*) > 1
LIMIT 10;  


-- STAFF ASSIGNMENT TABLE CHECK 

DESCRIBE staff_assignment;

-- check for missing VALUES
SELECT
    COUNT(*) AS total_rows,
    COUNT(assignment_id) AS assignment_id_filled,
    COUNT(employee_id) AS employee_id_filled,
    COUNT(ward_id) AS ward_id_filled,
    COUNT(shift) AS shift_filled
FROM staff_assignment;

-- check employee relationship
SELECT COUNT(*) AS orphan_employee_ids
FROM staff_assignment sa
LEFT JOIN employee e
    ON sa.employee_id = e.employee_id
WHERE e.employee_id IS NULL;

-- check ward relationship
SELECT COUNT(*) AS orphan_ward_ids
FROM staff_assignment sa
LEFT JOIN ward w
    ON sa.ward_id = w.ward_id
WHERE w.ward_id IS NULL;

-- check shift values
SELECT
    shift,
    COUNT(*) AS assignment_count
FROM staff_assignment
GROUP BY shift
ORDER BY shift;


-- WARD TABLE 
DESCRIBE ward;

SELECT
    COUNT(*) AS total_rows,
    COUNT(ward_id) AS ward_id_filled,
    COUNT(ward_name) AS ward_name_filled,
    COUNT(ward_type) AS ward_type_filled,
    COUNT(total_beds) AS total_beds_filled,
    COUNT(department_id) AS department_id_filled
FROM ward;

-- check duplicate ward names
SELECT
    ward_name,
    COUNT(*) AS ward_count
FROM ward
GROUP BY ward_name
HAVING COUNT(*) > 1;


-- check ward types

SELECT
    ward_type,
    COUNT(*) AS ward_count
FROM ward
GROUP BY ward_type
ORDER BY ward_type;

-- check bed capacity

SELECT
    MIN(total_beds) AS minimum_beds,
    MAX(total_beds) AS maximum_beds,
    SUM(CASE WHEN total_beds <= 0 THEN 1 ELSE 0 END) AS invalid_bed_counts
FROM ward;

-- check department relationship

SELECT COUNT(*) AS foreign_department_id
FROM ward w
LEFT JOIN department d
ON w.department_id = d.department_id
WHERE d.department_id IS NULL;