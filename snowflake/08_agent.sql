-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Predictive Maintenance
-- ============================================================================
USE DATABASE ELECTRONICS_MAINTENANCE;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.ELECTRONICS_MAINTENANCE_AGENT
  COMMENT = 'Predictive Maintenance AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'ELECTRONICS_MAINTENANCE.APP.ELECTRONICS_MAINTENANCE_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'ELECTRONICS_MAINTENANCE.SEARCH.ELECTRONICS_MAINTENANCE_SEARCH', TOOL_DESCRIPTION => 'Search documents for Electronics Manufacturing information')
  )
  SYSTEM_PROMPT = 'You are the Predictive Maintenance Agent for Vietnamese electronics manufacturing operations in Bac Ninh & Vinh Phuc.';
