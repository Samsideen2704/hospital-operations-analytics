-- ============================================================
-- Project: Hospital Operations & Resource Management Analytics
-- Script: 01_data_import.sql
--
-- Purpose:
--   Create the database and import seven tables from CSV files.
--
-- Requirements:
--   - MySQL Server and MySQL Workbench
--   - The project CSV files stored locally
--   - LOCAL INFILE enabled for the server and client connection
--
-- Instructions:
--   1. Replace YOUR_DATA_FOLDER in each import path with the
--      location of your CSV files.
--   2. Run this script against a fresh project database.
--   3. Check the imported row counts before running the audit
--      and data-cleaning scripts.
--
-- Note:
--   This script imports seven tables, not all 19 project tables due to heavy size, 
--   The remaining 12 tables were imported using the table import wizard.
--   It is intended for a fresh database; existing tables may
--   cause CREATE TABLE statements to fail.
-- ============================================================




CREATE DATABASE IF NOT EXISTS hospital_operations_analysis;

USE hospital_operations_analysis;

SHOW VARIABLES LIKE 'local_infile';

-- CREATE DATABASE TABLES (LARGE FILES) --

-- Patient table --
CREATE TABLE patient (
    patient_id INT,
    gender VARCHAR(20),
    date_of_birth DATE,
    blood_group VARCHAR(10),
    city VARCHAR(100),
    contact_number VARCHAR(30)
);

DESCRIBE patient ;


LOAD DATA LOCAL INFILE 'YOUR_DATA_FOLDER/patient.csv'
INTO TABLE patient
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    patient_id,
    gender,
    date_of_birth,
    blood_group,
    city,
    contact_number
);


-- Admission table--

CREATE TABLE admission (
    admission_id INT,
    admission_date DATE,
    discharge_date DATE,
    admission_type VARCHAR(50),
    admission_status VARCHAR(50),
    patient_id INT,
    department_id INT,
    ward_id INT,
    bed_id INT,
    disease_id INT
);

DESCRIBE admission ;

LOAD DATA LOCAL INFILE 'YOUR_DATA_FOLDER/admission.csv'
INTO TABLE admission
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    admission_id,
    admission_date,
    discharge_date,
    admission_type,
    admission_status,
    patient_id,
    department_id,
    ward_id,
    bed_id,
    disease_id
);


-- billing table

CREATE TABLE billing (
    bill_id INT,
    bill_date DATE,
    total_amount DECIMAL(12,2),
    insurance_covered_amount DECIMAL(12,2),
    patient_payable_amount DECIMAL(12,2),
    payment_status VARCHAR(50),
    payment_mode VARCHAR(50),
    admission_id INT
);

DESCRIBE billing;

LOAD DATA LOCAL INFILE 'YOUR_DATA_FOLDER/billing.csv'
INTO TABLE billing
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    bill_id,
    bill_date,
    total_amount,
    insurance_covered_amount,
    patient_payable_amount,
    payment_status,
    payment_mode,
    admission_id
);


-- billing_detail table

CREATE TABLE billing_detail (
    billing_detail_id INT,
    charge_type VARCHAR(50),
    reference_id DECIMAL(12,2),
    amount DECIMAL(12,2),
    bill_id INT
);

DESCRIBE billing_detail;

LOAD DATA LOCAL INFILE 'YOUR_DATA_FOLDER/billing_detail.csv'
INTO TABLE billing_detail
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    billing_detail_id,
    charge_type,
    @reference_id,
    amount,
    bill_id
)
SET reference_id = NULLIF(TRIM(@reference_id), '');



-- patient_insurance table

CREATE TABLE patient_insurance (
    patient_insurance_id INT,
    policy_number VARCHAR(100),
    coverage_percentage DECIMAL(5,2),
    policy_start_date DATE,
    policy_end_date DATE,
    patient_id INT,
    insurance_provider_id INT
);

LOAD DATA LOCAL INFILE 'YOUR_DATA_FOLDER/patient_insurance.csv'
INTO TABLE patient_insurance
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    patient_insurance_id,
    policy_number,
    coverage_percentage,
    policy_start_date,
    policy_end_date,
    patient_id,
    insurance_provider_id
);


-- patient_diagnostic table 

CREATE TABLE patient_diagnostic (
    patient_diagnostic_id INT,
    test_date DATE,
    result_status VARCHAR(50),
    admission_id INT,
    test_id INT,
    doctor_id INT
);

LOAD DATA LOCAL INFILE 'YOUR_DATA_FOLDER/patient_diagnostic.csv'
INTO TABLE patient_diagnostic
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    patient_diagnostic_id,
    test_date,
    result_status,
    admission_id,
    test_id,
    doctor_id
);


-- prescription table
CREATE TABLE prescription (
    prescription_id INT,
    dosage VARCHAR(100),
    frequency VARCHAR(100),
    duration_days INT,
    admission_id INT,
    drug_id INT
);


LOAD DATA LOCAL INFILE 'YOUR_DATA_FOLDER/prescription.csv'
INTO TABLE prescription
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    prescription_id,
    dosage,
    frequency,
    duration_days,
    admission_id,
    drug_id
);



-- ============================================================
-- VALIDATE IMPORTED ROW COUNTS
-- ============================================================

SELECT 'patient' AS table_name, COUNT(*) AS row_count
FROM patient

UNION ALL

SELECT 'admission', COUNT(*)
FROM admission

UNION ALL

SELECT 'billing', COUNT(*)
FROM billing

UNION ALL

SELECT 'billing_detail', COUNT(*)
FROM billing_detail

UNION ALL

SELECT 'patient_insurance', COUNT(*)
FROM patient_insurance

UNION ALL

SELECT 'patient_diagnostic', COUNT(*)
FROM patient_diagnostic

UNION ALL

SELECT 'prescription', COUNT(*)
FROM prescription;
