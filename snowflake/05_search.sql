-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Predictive Maintenance
-- ============================================================================
USE DATABASE ELECTRONICS_MAINTENANCE;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.ELECTRONICS_MAINTENANCE_SEARCH
  ON CONTENT
  ATTRIBUTES DOC_TYPE, CATEGORY
  WAREHOUSE = ELECTRONICS_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.DOCUMENTS
);
