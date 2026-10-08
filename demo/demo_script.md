# Predictive Maintenance

**Vietnam - Electronics Manufacturing**
Use case: Predictive Maintenance

> Predictive maintenance for a synthetic fleet of 20 SMT machines in Vietnam. Dynamic tables, a holdout-evaluated failure-risk classifier, a downtime forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile machine KPIs from RAW sensor data, with checks in `run_core.py`
- **Failure-risk classification** gives a holdout-evaluated next-7-day failure risk per machine
- **Downtime forecast** projects 14 days of fleet downtime with prediction intervals
- **Grounded AI** runs allow-listed queries summarised by `AI_COMPLETE`; the app shows the SQL and sources

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

1. Overview: KPIs and downtime by machine
2. Analytics: daily uptime trend and root causes
3. Predictive: holdout metrics, risk bands, 14-day downtime forecast
4. Ask AI: grounded answers with SQL shown
5. Architecture: what is built and what is not yet built

## Talking points

- Uptime ranges from 94.6% to 99.96% by machine. Downtime is concentrated in a few machines.
- The risk model is evaluated on a time-based holdout: precision 0.60 and recall 0.53 at 0.5, against a 0.38 base rate. Present it as triage, not a guarantee.
- Regional power outages are excluded from failure labels.

## Business impact

Use only the sourced references in `README.md` (Business context). Unsourced industry percentages have been removed.

---
Hand-maintained during the 2026-10 repair. It supersedes the generated version.
