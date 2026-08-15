-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Predictive Maintenance
-- ============================================================================
USE DATABASE ELECTRONICS_MAINTENANCE;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_vietnam_electronics_maintenance_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('jonathan.asvestis@snowflake.com');

-- Alert: PERFORMANCE_ALERT
CREATE OR REPLACE ALERT APP.PERFORMANCE_ALERT
  WAREHOUSE = ELECTRONICS_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Predictive Maintenance performance below threshold'
IF (EXISTS (
  SELECT 1 FROM CURATED.PERFORMANCE_DASHBOARD
  WHERE 1=1 -- Condition: Key metric below threshold
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_vietnam_electronics_maintenance_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Predictive Maintenance: Predictive Maintenance performance below threshold',
    'Predictive Maintenance performance below threshold'
  );

ALTER ALERT APP.PERFORMANCE_ALERT RESUME;

-- Alert: ANOMALY_ALERT
CREATE OR REPLACE ALERT APP.ANOMALY_ALERT
  WAREHOUSE = ELECTRONICS_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Anomalous pattern detected'
IF (EXISTS (
  SELECT 1 FROM CURATED.PERFORMANCE_DASHBOARD
  WHERE 1=1 -- Condition: ML detects anomaly
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_vietnam_electronics_maintenance_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Predictive Maintenance: Anomalous pattern detected',
    'Anomalous pattern detected'
  );

ALTER ALERT APP.ANOMALY_ALERT RESUME;

