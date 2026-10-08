-- ============================================================================
-- 07_deploy_app.sql - deploy the repaired Next.js app to SPCS.
-- Replace placeholders through snowflake/run_intelligence.py --files 07_deploy_app.sql
-- (validated __DEMO_DB__ / __DEMO_WH__). Build and push the image first:
--   snow spcs image-registry login -c <connection>
--   docker build --platform linux/amd64 -t <repository_url>/vn-maint-app:v1 app
--   docker push <repository_url>/vn-maint-app:v1
-- Uses the existing compute pool SEA_DEMOS_VIETNAM_POOL (shared, already running).
-- ============================================================================
CREATE IMAGE REPOSITORY IF NOT EXISTS APP.IMAGES;

CREATE SERVICE IF NOT EXISTS APP.REPAIR_VN_MAINT_APP
  IN COMPUTE POOL SEA_DEMOS_VIETNAM_POOL
  QUERY_WAREHOUSE = __DEMO_WH__
  FROM SPECIFICATION
$$
spec:
  containers:
    - name: app
      image: /__DEMO_DB__/app/images/vn-maint-app:v1
      env:
        SNOWFLAKE_DATABASE: __DEMO_DB__
        SNOWFLAKE_SCHEMA: CURATED
        SNOWFLAKE_WAREHOUSE: __DEMO_WH__
      resources:
        requests: {cpu: 0.1, memory: 384M}
        limits: {cpu: 1, memory: 1G}
      readinessProbe: {port: 8080, path: /}
  endpoints:
    - name: app
      port: 8080
      public: true
$$;
