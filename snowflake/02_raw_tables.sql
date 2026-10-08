-- Synthetic machine-day observations; no seeded predictions or invented asset counts.
-- Randomness is HASH-seeded so every rebuild is reproducible yet varied:
-- per-machine reliability/age, shift patterns, wear between PM visits, missed PM,
-- variable repair times, category-weighted root causes, plant-wide outages.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.MACHINES AS
WITH equipment AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS MACHINE_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 20))
), draws AS (
  SELECT MACHINE_INDEX,
         MOD(ABS(HASH(MACHINE_INDEX, 'region')), 1000000) / 1e6 AS U_REGION,
         MOD(ABS(HASH(MACHINE_INDEX, 'category')), 1000000) / 1e6 AS U_CATEGORY,
         MOD(ABS(HASH(MACHINE_INDEX, 'age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(MACHINE_INDEX, 'rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(MACHINE_INDEX, 'shift')), 1000000) / 1e6 AS U_SHIFT,
         MOD(ABS(HASH(MACHINE_INDEX, 'pm')), 1000000) / 1e6 AS U_PM,
         MOD(ABS(HASH(MACHINE_INDEX, 'discipline')), 1000000) / 1e6 AS U_DISCIPLINE
  FROM equipment
)
SELECT 'MAC-' || LPAD(MACHINE_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic machine ' || (MACHINE_INDEX + 1) AS NAME,
       CASE WHEN U_REGION < 0.35 THEN 'Ho Chi Minh City' WHEN U_REGION < 0.55 THEN 'Binh Duong'
            WHEN U_REGION < 0.75 THEN 'Hanoi' WHEN U_REGION < 0.90 THEN 'Dong Nai' ELSE 'Can Tho' END AS REGION,
       CASE WHEN U_CATEGORY < 0.35 THEN 'Pick and Place' WHEN U_CATEGORY < 0.60 THEN 'Reflow Oven'
            WHEN U_CATEGORY < 0.80 THEN 'AOI Station' ELSE 'Conveyor' END AS CATEGORY,
       MACHINE_INDEX,
       ROUND(1 + U_AGE * 11, 1) AS AGE_YEARS,
       -- Base daily failure probability 0.5%-4%; ~15% of machines are "bad actors" (x3).
       (0.005 + U_RATE * 0.035) * IFF(U_RATE > 0.85, 3, 1) AS BASE_FAILURE_RATE,
       IFF(U_SHIFT < 0.6, 24, 16) AS SHIFT_HOURS,
       7 * (1 + FLOOR(U_PM * 3)) AS PM_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS PM_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.SENSOR_READINGS AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), outages AS (
  -- Two regional power disturbances in the window.
  SELECT * FROM VALUES (23, 'Binh Duong', 4.0), (61, 'Ho Chi Minh City', 2.5) AS o(DAY_INDEX, REGION, HOURS)
), base AS (
  SELECT m.ID AS ENTITY_ID, m.MACHINE_INDEX, m.CATEGORY, m.REGION, m.AGE_YEARS,
         m.BASE_FAILURE_RATE, m.PM_INTERVAL_DAYS, m.PM_COMPLETION_PROB, d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         IFF(DAYOFWEEKISO(DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE())) = 7, 8.0, m.SHIFT_HOURS) AS PLANNED_HOURS,
         MOD(d.DAY_INDEX + m.MACHINE_INDEX * 5, m.PM_INTERVAL_DAYS) AS DAYS_SINCE_PM,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'fail')), 1000000) / 1e6 AS U_FAIL,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'repair')), 1000000) / 1e6 + 1e-6 AS U_REPAIR,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'cause')), 1000000) / 1e6 AS U_CAUSE,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'pmdone')), 1000000) / 1e6 AS U_PMDONE,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'units')), 1000000) / 1e6 AS U_UNITS,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'noise')), 1000000) / 1e6 AS U_NOISE,
         o.HOURS AS OUTAGE_HOURS
  FROM RAW.MACHINES m CROSS JOIN days d
  LEFT JOIN outages o ON o.DAY_INDEX = d.DAY_INDEX AND o.REGION = m.REGION
), pm AS (
  SELECT *,
         IFF(DAYS_SINCE_PM = 0, 1, 0) AS PM_DUE,
         IFF(DAYS_SINCE_PM = 0 AND U_PMDONE < PM_COMPLETION_PROB, 1, 0) AS PM_COMPLETED,
         -- Wear rises between visits; unreliable PM discipline adds carried-over wear.
         DAYS_SINCE_PM / PM_INTERVAL_DAYS + (1 - PM_COMPLETION_PROB) AS WEAR,
         -- Hot-season stress (Jun-Sep) on reflow ovens.
         IFF(CATEGORY = 'Reflow Oven' AND MONTH(EVENT_DATE) BETWEEN 6 AND 9, 1.4, 1.0) AS HEAT_FACTOR
  FROM base
), failures AS (
  SELECT *,
         LEAST(0.6, BASE_FAILURE_RATE * (0.4 + 1.6 * WEAR) * (1 + AGE_YEARS / 20) * HEAT_FACTOR) AS P_FAIL
  FROM pm
), events AS (
  SELECT *,
         CASE WHEN OUTAGE_HOURS IS NOT NULL THEN 1
              WHEN U_FAIL < P_FAIL / 4 THEN 2
              WHEN U_FAIL < P_FAIL THEN 1 ELSE 0 END AS FAILURE_COUNT
  FROM failures
), timed AS (
  SELECT *,
         -- Exponential repair durations; mean depends on category.
         CASE WHEN FAILURE_COUNT = 0 THEN 0.0
              WHEN OUTAGE_HOURS IS NOT NULL THEN OUTAGE_HOURS
              ELSE LEAST(PLANNED_HOURS - 0.5, ROUND(FAILURE_COUNT * (0.5 - LN(U_REPAIR) *
                   CASE CATEGORY WHEN 'Reflow Oven' THEN 4.5 WHEN 'Pick and Place' THEN 3.0
                                 WHEN 'AOI Station' THEN 1.5 ELSE 2.0 END), 1)) END AS DOWNTIME_HOURS
  FROM events
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE, PLANNED_HOURS, DOWNTIME_HOURS,
       PLANNED_HOURS - DOWNTIME_HOURS AS OPERATING_HOURS,
       FAILURE_COUNT,
       CASE WHEN FAILURE_COUNT = 0 THEN 'None'
            WHEN OUTAGE_HOURS IS NOT NULL THEN 'Power disturbance'
            WHEN CATEGORY = 'Reflow Oven' THEN IFF(U_CAUSE < 0.6, 'Thermal excursion', IFF(U_CAUSE < 0.85, 'Conveyor chain', 'Sensor fault'))
            WHEN CATEGORY = 'Pick and Place' THEN IFF(U_CAUSE < 0.45, 'Nozzle clog', IFF(U_CAUSE < 0.8, 'Feeder jam', 'Alignment'))
            WHEN CATEGORY = 'AOI Station' THEN IFF(U_CAUSE < 0.5, 'Sensor fault', IFF(U_CAUSE < 0.8, 'Software fault', 'Alignment'))
            ELSE IFF(U_CAUSE < 0.6, 'Bearing wear', 'Belt slip') END AS ROOT_CAUSE,
       PM_DUE, PM_COMPLETED,
       ROUND(OPERATING_HOURS * (40 + U_UNITS * 25)) AS TOTAL_UNITS,
       FLOOR(ROUND(OPERATING_HOURS * (40 + U_UNITS * 25)) *
             LEAST(0.995, GREATEST(0.80, 0.985 - 0.04 * WEAR - 0.03 * FAILURE_COUNT - 0.01 * U_NOISE))) AS GOOD_UNITS,
       100.0 * (PLANNED_HOURS - DOWNTIME_HOURS) / PLANNED_HOURS AS KPI_EQUIPMENT_UPTIME,
       ROUND(1.8 + 3.5 * WEAR + 1.5 * FAILURE_COUNT + U_NOISE * 0.8, 2) AS VIBRATION_MM_S,
       ROUND(52 + 6 * WEAR + IFF(HEAT_FACTOR > 1, 7, 0) + U_NOISE * 3, 1) AS TEMPERATURE_C,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM timed;

CREATE TABLE RAW.SPARE_PARTS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Reflow Oven' THEN 'Heater module' WHEN 'Pick and Place' THEN 'Nozzle set'
                     WHEN 'AOI Station' THEN 'Camera sensor' ELSE 'Drive belt' END AS PART_TYPE,
       1 + MOD(ABS(HASH(ID, 'req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'hand')), 5) AS ON_HAND_QTY,
       IFF(MOD(ABS(HASH(ID, 'hand')), 5) < 1 + MOD(ABS(HASH(ID, 'req')), 4),
           MOD(ABS(HASH(ID, 'order')), 3), 0) AS ON_ORDER_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.MACHINES;
