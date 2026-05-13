-- ============================================================
-- Healthcare Claims & Cost Analysis — SQL Scripts
-- Dataset: HCUP / Kaggle Healthcare Insurance Dataset
-- Author: [Your Name]
-- Tools: PostgreSQL / MySQL compatible
-- ============================================================


-- ============================================================
-- STEP 1: CREATE TABLES
-- ============================================================

CREATE TABLE claims (
    claim_id          VARCHAR(20) PRIMARY KEY,
    patient_id        VARCHAR(20),
    provider_id       VARCHAR(20),
    provider_type     VARCHAR(50),    -- 'General Hospital', 'Private Clinic', etc.
    claim_type        VARCHAR(30),    -- 'Inpatient', 'Outpatient', 'Emergency', etc.
    procedure_code    VARCHAR(20),
    procedure_name    VARCHAR(100),
    claim_date        DATE,
    service_date      DATE,
    processed_date    DATE,
    claim_amount      NUMERIC(12,2),
    approved_amount   NUMERIC(12,2),
    denial_reason     VARCHAR(100),
    claim_status      VARCHAR(20),    -- 'Approved', 'Denied', 'Pending'
    region            VARCHAR(20),    -- 'Northeast', 'South', 'Midwest', 'West'
    icd10_code        VARCHAR(20),
    diagnosis_name    VARCHAR(100)
);

CREATE TABLE providers (
    provider_id       VARCHAR(20) PRIMARY KEY,
    provider_name     VARCHAR(100),
    provider_type     VARCHAR(50),
    region            VARCHAR(20),
    state             VARCHAR(5),
    accreditation     VARCHAR(30)
);


-- ============================================================
-- STEP 2: DATA CLEANING
-- ============================================================

-- 2a. Check for nulls across key columns
SELECT
    COUNT(*)                                            AS total_rows,
    COUNT(*) FILTER (WHERE claim_id IS NULL)            AS null_claim_id,
    COUNT(*) FILTER (WHERE patient_id IS NULL)          AS null_patient_id,
    COUNT(*) FILTER (WHERE claim_amount IS NULL)        AS null_amount,
    COUNT(*) FILTER (WHERE claim_date IS NULL)          AS null_date,
    COUNT(*) FILTER (WHERE claim_status IS NULL)        AS null_status,
    COUNT(*) FILTER (WHERE procedure_code IS NULL)      AS null_procedure
FROM claims;

-- 2b. Remove duplicate claims (keep first submitted)
DELETE FROM claims
WHERE claim_id IN (
    SELECT claim_id FROM (
        SELECT
            claim_id,
            ROW_NUMBER() OVER (
                PARTITION BY patient_id, procedure_code, service_date
                ORDER BY claim_date ASC
            ) AS rn
        FROM claims
    ) sub
    WHERE rn > 1
);

-- 2c. Remove invalid amounts (negative or zero)
DELETE FROM claims
WHERE claim_amount <= 0
   OR approved_amount < 0;

-- 2d. Cap outlier claim amounts (flag amounts > 3 std deviations)
UPDATE claims
SET claim_amount = (
    SELECT AVG(claim_amount) + 3 * STDDEV(claim_amount) FROM claims
)
WHERE claim_amount > (
    SELECT AVG(claim_amount) + 3 * STDDEV(claim_amount) FROM claims
);

-- 2e. Fill missing processing days
UPDATE claims
SET processed_date = claim_date + INTERVAL '18 days'
WHERE processed_date IS NULL
  AND claim_date IS NOT NULL;

-- 2f. Standardize claim status labels
UPDATE claims
SET claim_status = CASE
    WHEN LOWER(claim_status) IN ('approved','paid','accepted') THEN 'Approved'
    WHEN LOWER(claim_status) IN ('denied','rejected','declined') THEN 'Denied'
    WHEN LOWER(claim_status) IN ('pending','in review','processing') THEN 'Pending'
    ELSE 'Unknown'
END;


-- ============================================================
-- STEP 3: KPI QUERIES
-- ============================================================

-- 3a. Overall claim stats
SELECT
    COUNT(*)                                            AS total_claims,
    ROUND(SUM(claim_amount) / 1e9, 2)                  AS total_cost_billion,
    ROUND(AVG(claim_amount) / 1000, 1)                 AS avg_cost_k,
    ROUND(
        COUNT(*) FILTER (WHERE claim_status = 'Denied') * 100.0
        / NULLIF(COUNT(*), 0), 1
    )                                                   AS denial_rate_pct,
    ROUND(AVG(processed_date - claim_date), 1)         AS avg_processing_days
FROM claims;

-- 3b. Denial rate by claim type
SELECT
    claim_type,
    COUNT(*)                                            AS total_claims,
    COUNT(*) FILTER (WHERE claim_status = 'Denied')    AS denied_claims,
    ROUND(
        COUNT(*) FILTER (WHERE claim_status = 'Denied') * 100.0
        / NULLIF(COUNT(*), 0), 1
    )                                                   AS denial_rate_pct
FROM claims
GROUP BY claim_type
ORDER BY denial_rate_pct DESC;


-- ============================================================
-- STEP 4: TOP PROCEDURES BY COST
-- ============================================================

SELECT
    procedure_code,
    procedure_name,
    COUNT(*)                                            AS claim_count,
    ROUND(AVG(claim_amount) / 1000, 1)                 AS avg_cost_k,
    ROUND(SUM(claim_amount) / 1e6, 1)                  AS total_cost_million,
    ROUND(
        COUNT(*) FILTER (WHERE claim_status = 'Denied') * 100.0
        / NULLIF(COUNT(*), 0), 1
    )                                                   AS denial_rate_pct
FROM claims
GROUP BY procedure_code, procedure_name
ORDER BY avg_cost_k DESC
LIMIT 10;


-- ============================================================
-- STEP 5: DENIAL RATE BY PROVIDER TYPE
-- ============================================================

SELECT
    c.provider_type,
    COUNT(*)                                            AS total_claims,
    COUNT(*) FILTER (WHERE c.claim_status = 'Denied')  AS denied_claims,
    ROUND(
        COUNT(*) FILTER (WHERE c.claim_status = 'Denied') * 100.0
        / NULLIF(COUNT(*), 0), 1
    )                                                   AS denial_rate_pct,
    ROUND(AVG(c.claim_amount) / 1000, 1)               AS avg_claim_cost_k
FROM claims c
GROUP BY c.provider_type
ORDER BY denial_rate_pct DESC;


-- ============================================================
-- STEP 6: MONTHLY CLAIM VOLUME & COST TREND
-- ============================================================

SELECT
    TO_CHAR(claim_date, 'YYYY-MM')                      AS month,
    claim_type,
    COUNT(*)                                            AS total_claims,
    ROUND(AVG(claim_amount) / 1000, 1)                 AS avg_cost_k,
    ROUND(SUM(claim_amount) / 1e6, 1)                  AS total_cost_million,
    ROUND(
        COUNT(*) FILTER (WHERE claim_status = 'Denied') * 100.0
        / NULLIF(COUNT(*), 0), 1
    )                                                   AS denial_rate_pct
FROM claims
WHERE claim_date >= '2023-07-01'
  AND claim_date <  '2024-07-01'
GROUP BY TO_CHAR(claim_date, 'YYYY-MM'), claim_type
ORDER BY month, claim_type;


-- ============================================================
-- STEP 7: REGIONAL COST ANALYSIS
-- ============================================================

SELECT
    region,
    COUNT(*)                                            AS total_claims,
    ROUND(AVG(claim_amount) / 1000, 1)                 AS avg_cost_k,
    ROUND(SUM(claim_amount) / 1e6, 1)                  AS total_cost_million,
    ROUND(
        COUNT(*) FILTER (WHERE claim_status = 'Denied') * 100.0
        / NULLIF(COUNT(*), 0), 1
    )                                                   AS denial_rate_pct
FROM claims
GROUP BY region
ORDER BY total_cost_million DESC;


-- ============================================================
-- STEP 8: ANOMALY DETECTION
-- ============================================================

-- 8a. Duplicate billing — same patient, procedure, date from different providers
SELECT
    patient_id,
    procedure_code,
    procedure_name,
    service_date,
    COUNT(DISTINCT provider_id)                         AS provider_count,
    COUNT(*)                                            AS claim_count,
    ROUND(SUM(claim_amount) / 1000, 1)                 AS total_billed_k
FROM claims
GROUP BY patient_id, procedure_code, procedure_name, service_date
HAVING COUNT(DISTINCT provider_id) > 1
ORDER BY total_billed_k DESC;

-- 8b. Upcoding — claims significantly above average for same procedure
SELECT
    c.claim_id,
    c.patient_id,
    c.provider_id,
    c.procedure_name,
    c.claim_amount,
    avg_costs.avg_cost,
    ROUND((c.claim_amount - avg_costs.avg_cost) / avg_costs.avg_cost * 100, 1) AS pct_above_avg
FROM claims c
JOIN (
    SELECT procedure_code, AVG(claim_amount) AS avg_cost
    FROM claims
    GROUP BY procedure_code
) avg_costs ON c.procedure_code = avg_costs.procedure_code
WHERE c.claim_amount > avg_costs.avg_cost * 1.5   -- 50% above average
  AND c.claim_status = 'Approved'
ORDER BY pct_above_avg DESC
LIMIT 50;

-- 8c. High-frequency same-day claims — potential unbundling
SELECT
    patient_id,
    provider_id,
    service_date,
    COUNT(*)                                            AS procedures_same_day,
    ROUND(SUM(claim_amount) / 1000, 1)                 AS total_billed_k
FROM claims
GROUP BY patient_id, provider_id, service_date
HAVING COUNT(*) >= 4
ORDER BY procedures_same_day DESC;

-- 8d. Total estimated savings from anomalies
SELECT
    'Duplicate Billing'         AS anomaly_type,
    ROUND(SUM(claim_amount) / 1e6, 1) AS flagged_amount_million
FROM claims c
WHERE EXISTS (
    SELECT 1 FROM claims c2
    WHERE c2.patient_id = c.patient_id
      AND c2.procedure_code = c.procedure_code
      AND c2.service_date = c.service_date
      AND c2.provider_id <> c.provider_id
)
UNION ALL
SELECT
    'Upcoded Procedures',
    ROUND(SUM(c.claim_amount - avg_c.avg_cost) / 1e6, 1)
FROM claims c
JOIN (SELECT procedure_code, AVG(claim_amount) AS avg_cost FROM claims GROUP BY procedure_code) avg_c
    ON c.procedure_code = avg_c.procedure_code
WHERE c.claim_amount > avg_c.avg_cost * 1.5;


-- ============================================================
-- STEP 9: YoY DENIAL RATE COMPARISON
-- ============================================================

SELECT
    provider_type,
    ROUND(
        COUNT(*) FILTER (
            WHERE claim_status = 'Denied'
            AND EXTRACT(YEAR FROM claim_date) = 2023
        ) * 100.0
        / NULLIF(COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM claim_date) = 2023), 0), 1
    )                                                   AS denial_rate_fy2223,
    ROUND(
        COUNT(*) FILTER (
            WHERE claim_status = 'Denied'
            AND EXTRACT(YEAR FROM claim_date) = 2024
        ) * 100.0
        / NULLIF(COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM claim_date) = 2024), 0), 1
    )                                                   AS denial_rate_fy2324
FROM claims
GROUP BY provider_type
ORDER BY denial_rate_fy2324 DESC;


-- ============================================================
-- STEP 10: SUMMARY VIEW FOR DASHBOARD
-- ============================================================

CREATE OR REPLACE VIEW vw_claims_summary AS
SELECT
    c.claim_type,
    c.provider_type,
    c.region,
    c.procedure_name,
    TO_CHAR(c.claim_date, 'YYYY-MM')                    AS month,
    COUNT(*)                                            AS total_claims,
    ROUND(AVG(c.claim_amount) / 1000, 1)               AS avg_cost_k,
    ROUND(SUM(c.claim_amount) / 1e6, 1)                AS total_cost_million,
    ROUND(
        COUNT(*) FILTER (WHERE c.claim_status = 'Denied') * 100.0
        / NULLIF(COUNT(*), 0), 1
    )                                                   AS denial_rate_pct,
    ROUND(AVG(c.processed_date - c.claim_date), 1)     AS avg_processing_days
FROM claims c
GROUP BY
    c.claim_type,
    c.provider_type,
    c.region,
    c.procedure_name,
    TO_CHAR(c.claim_date, 'YYYY-MM');

-- Query the summary view (used to feed Tableau / Power BI)
SELECT * FROM vw_claims_summary
ORDER BY month, claim_type;
