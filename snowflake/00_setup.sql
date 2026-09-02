-- Generated from generator/demo_specs/aws-vietnam-electronics-maintenance.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-vietnam-electronics-maintenance
-- This is the schema that is actually deployed for VIETNAM_ELECTRONICS_MAINTENANCE.

-- VIETNAM_ELECTRONICS_MAINTENANCE  (Predictive Maintenance)
-- generated from generator/demo_specs/aws-vietnam-electronics-maintenance.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS VIETNAM_ELECTRONICS_MAINTENANCE;
CREATE SCHEMA IF NOT EXISTS VIETNAM_ELECTRONICS_MAINTENANCE.RAW;
CREATE SCHEMA IF NOT EXISTS VIETNAM_ELECTRONICS_MAINTENANCE.CURATED;
CREATE SCHEMA IF NOT EXISTS VIETNAM_ELECTRONICS_MAINTENANCE.APP;
USE DATABASE VIETNAM_ELECTRONICS_MAINTENANCE;

-- 5 real regions; entity names carry their region so the two always agree
