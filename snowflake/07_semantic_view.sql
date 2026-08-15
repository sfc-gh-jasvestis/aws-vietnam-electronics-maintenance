-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Predictive Maintenance
-- ============================================================================
USE DATABASE ELECTRONICS_MAINTENANCE;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.ELECTRONICS_MAINTENANCE_ANALYTICS
  COMMENT = 'Electronics Manufacturing predictive maintenance analytics'
AS
  TABLES (
    CURATED.PERFORMANCE_DASHBOARD AS performance_dashboard,CURATED.TREND_ANALYTICS AS trend_analytics,CURATED.FORECAST_INPUT AS forecast_input,CURATED.OPERATIONAL_RISK AS operational_risk
  );
