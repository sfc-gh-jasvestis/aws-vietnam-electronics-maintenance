# Predictive Maintenance

**Vietnam - Electronics Manufacturing**
Use case: Predictive Maintenance

> Predictive maintenance for a synthetic fleet of 20 SMT machines in Vietnam. Dynamic tables, a holdout-evaluated failure-risk classifier, a downtime forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile machine KPIs from RAW sensor data, with checks in `run_core.py`
- **Failure-risk classification** gives a holdout-evaluated next-7-day failure risk per machine
- **Downtime forecast** projects 14 days of fleet downtime with prediction intervals
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations. The memo is written by Amazon Bedrock.
- **Live AWS ingestion**: IoT Core feeds S3, then Snowpipe auto-ingest, then an alert and email

## What is built (pilot)

| | |
|---|---|
| Dimension table | `RAW.MACHINES` (20 rows) |
| Fact table | `RAW.SENSOR_READINGS` (1,800 machine-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `DOWNTIME_CAUSES`, `TREND_ANALYSIS` |
| ML | `ML.FAILURE_RISK_SCORES`, `ML.FAILURE_RISK_HOLDOUT_METRICS`, `ML.DOWNTIME_FORECAST` |

Regions: Ho Chi Minh City, Hanoi, Binh Duong, Dong Nai, Can Tho.
Machine types: Pick and Place, Reflow Oven, AOI Station, Conveyor.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value in validated build |
|---|---|
| Equipment Uptime | 98.7% |
| Unplanned Stops | 181 |
| MTBF (Avg) | 185.9 hrs |
| Equipment Managed | 20 |
| Parts on Order | 4 |
| Spare Coverage | 66.7% |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded.

## Demo flow

1. Overview: KPIs and downtime by machine (also in QuickSight)
2. Predictive: holdout metrics, risk bands, 14-day downtime forecast, vibration anomalies
3. PM Planning: Generate a memo, written by Amazon Bedrock Claude from Snowflake tables only
4. Live IoT: run `python aws/publish_telemetry.py --count 20`. About 20-60 s later the messages appear (IoT Core, then S3, then Snowpipe). Then run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight: the same Snowflake tables through DIRECT_QUERY; risk and IoT visuals
7. Architecture: what runs where

## Talking points

- Uptime ranges from 94.6% to 99.96% by machine. Downtime is concentrated in a few machines.
- The risk model is evaluated on a time-based holdout: precision 0.60 and recall 0.53 at 0.5, against a 0.38 base rate. Present it as triage, not a guarantee.
- Regional power outages are excluded from failure labels.

## Business impact

Use only the sourced references in `README.md` (Business context). Unsourced industry percentages have been removed.

---
Hand-maintained during the 2026-10 repair. It supersedes the generated version.
