-- ADMISSION TABLE --

-- CREATE A CLEAN ADMISSION TABLE -- 

CREATE TABLE admission_clean AS
SELECT *
FROM admission;

SELECT COUNT(*) AS total_rows
FROM admission_clean;

-- Add a data-quality flag to the new table
ALTER TABLE admission_clean
ADD COLUMN data_quality_flag VARCHAR(50);


SELECT COUNT(*) AS total_rows
FROM admission_clean;


-- data quality flag
SELECT
    a.admission_id,
    a.patient_id,
    a.admission_date,
    p.date_of_birth,
    CASE
        WHEN p.date_of_birth > a.admission_date
            THEN 'DOB_AFTER_ADMISSION'
        ELSE 'OK'
    END AS data_quality_flag
    
FROM admission_clean a
JOIN patient p
    ON a.patient_id = p.patient_id
LIMIT 20;


SELECT
    data_quality_flag,
    COUNT(*) AS row_count
FROM (
    SELECT
        CASE
            WHEN p.date_of_birth > a.admission_date
                THEN 'DOB_AFTER_ADMISSION'
            ELSE 'OK'
END AS data_quality_flag
        
    FROM admission_clean a
    JOIN patient p
        ON a.patient_id = p.patient_id
) AS quality_check
GROUP BY data_quality_flag;


-- check when DOB is after admission date
SELECT
    a.admission_id,
    a.patient_id,
    a.admission_date,
    p.date_of_birth,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, a.admission_date) AS age_at_admission
FROM admission_clean a
JOIN patient p
    ON a.patient_id = p.patient_id
WHERE p.date_of_birth > a.admission_date
ORDER BY a.admission_date
LIMIT 20;


-- CREATE A CLEAN ADMISSION TABLE VIEW
CREATE OR REPLACE VIEW admission_clean_view AS
SELECT
    a.admission_id,
    a.patient_id,
    a.admission_date,
    a.discharge_date,
    a.admission_type,
    a.admission_status,
    a.department_id,
    a.ward_id,
    a.bed_id,
    a.disease_id,

    CASE
        WHEN p.date_of_birth > a.admission_date
            THEN NULL
        ELSE TIMESTAMPDIFF(YEAR, p.date_of_birth, a.admission_date)
    END AS age_at_admission,

    CASE
        WHEN p.date_of_birth > a.admission_date
            THEN 'DOB_AFTER_ADMISSION'
        ELSE 'OK'
    END AS data_quality_flag

FROM admission a
JOIN patient p
ON a.patient_id = p.patient_id;

    
 -- VERIFY THE VIEW TABLE   
SELECT
    data_quality_flag,
    COUNT(*) AS row_count
FROM admission_clean_view
GROUP BY data_quality_flag ;	


-- BILLING DETAIL CHECK	

-- create the billing reconciliation view
CREATE OR REPLACE VIEW billing_reconciliation_view AS
SELECT
    b.bill_id,
    b.admission_id,
    b.total_amount,
    COALESCE(SUM(bd.amount), 0) AS detail_total_amount,
    b.total_amount - COALESCE(SUM(bd.amount), 0) AS difference_amount,

    CASE
        WHEN b.total_amount = COALESCE(SUM(bd.amount), 0)
            THEN 'RECONCILED'
        ELSE 'MISMATCH'
    END AS reconciliation_status

FROM billing b
LEFT JOIN billing_detail bd
    ON b.bill_id = bd.bill_id
GROUP BY
    b.bill_id,
    b.admission_id,
    b.total_amount;
 
-- CHECK BILL RECONCILIATION STATUS
SELECT 
reconciliation_status, 
COUNT(*) AS rc_count
FROM billing_reconciliation_view
GROUP BY reconciliation_status;


-- IDENTIFY RECONCILLED BILLS
SELECT
    bill_id,
    admission_id,
    total_amount,
    detail_total_amount,
    difference_amount
FROM billing_reconciliation_view
WHERE reconciliation_status = 'RECONCILED';


-- PATIENT CONTACT NUMBERS CLEAN

SELECT
    contact_number
FROM patient
WHERE contact_number LIKE '%x%'
   OR contact_number LIKE '%X%'
LIMIT 20;


SELECT
    contact_number AS original_contact,
    
    TRIM(
        SUBSTRING_INDEX(
            LOWER(contact_number),
            'x',
            1
        )
    ) AS phone_number,
    
    TRIM(
        SUBSTRING_INDEX(
            LOWER(contact_number),
            'x',
            -1
        )
    ) AS extension

FROM patient
WHERE contact_number LIKE '%x%'
   OR contact_number LIKE '%X%'
LIMIT 20;


SELECT
    CASE
        WHEN contact_number LIKE '%x%'
          OR contact_number LIKE '%X%'
            THEN 'HAS_EXTENSION'
        ELSE 'NO_EXTENSION'
    END AS phone_type,
    COUNT(*) AS patient_count
FROM patient
GROUP BY phone_type;


-- CREATE THE PATIENT CLEAN VIEW
CREATE OR REPLACE VIEW patient_clean_view AS
SELECT
    patient_id,
    gender,
    date_of_birth,
    blood_group,
    city,

    contact_number AS original_contact_number,

    TRIM(
        SUBSTRING_INDEX(
            LOWER(contact_number),
            'x',
            1
        )
    ) AS phone_number,

    CASE
        WHEN contact_number LIKE '%x%'
          OR contact_number LIKE '%X%'
        THEN TRIM(
            SUBSTRING_INDEX(
                LOWER(contact_number),
                'x',
                -1
            )
        )
        ELSE NULL
    END AS phone_extension

FROM patient;


SELECT COUNT(*) AS patient_count
FROM patient_clean_view;


-- RECREATE THE PATIENT CLEAN VIEW
CREATE OR REPLACE VIEW patient_clean_view AS
SELECT
    patient_id,
    gender,
    date_of_birth,
    blood_group,
    city,

    contact_number AS original_contact_number,

    REPLACE(
        TRIM(
            SUBSTRING_INDEX(
                LOWER(contact_number),
                'x',
                1
            )
        ),
        '.',
        '-'
    ) AS phone_number,

    CASE
        WHEN contact_number LIKE '%x%'
          OR contact_number LIKE '%X%'
        THEN TRIM(
            SUBSTRING_INDEX(
                LOWER(contact_number),
                'x',
                -1
            )
        )
        ELSE NULL
    END AS phone_extension

FROM patient;

-- VERIFY THE NEW CONTACT NUMBER
SELECT
    original_contact_number,
    phone_number,
    phone_extension
FROM patient_clean_view
WHERE original_contact_number LIKE '%.%'
LIMIT 10;


-- EMPLOYEE JOINING DATE CLEAN

SELECT
    date_of_joining
FROM employee
LIMIT 10;

-- CREATE A CLEAN EMPLOYEE VIEW

CREATE OR REPLACE VIEW employee_clean_view AS
SELECT
    employee_id,
    employee_name,
    gender,
    role,
    employment_type,
	STR_TO_DATE(date_of_joining,'%Y-%m-%d') AS date_of_joining,
    department_id
FROM employee;


SELECT
    employee_id,
    date_of_joining
FROM employee_clean_view
LIMIT 10;


DESCRIBE employee_clean_view;

SELECT COUNT(*) AS employee_count
FROM employee_clean_view;
