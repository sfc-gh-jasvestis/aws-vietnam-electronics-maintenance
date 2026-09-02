# Predictive Maintenance

**Vietnam - Electronics Manufacturing**
Use case: Predictive Maintenance

> Predictive Maintenance for Vietnam - ML.FORECAST and Dynamic Tables power real-time predictive maintenance intelligence for electronics manufacturing in Bac Ninh & Vinh Phuc.

## Why Snowflake

Snowflake delivers predictive maintenance intelligence for Vietnamese electronics manufacturing - Dynamic Tables maintain real-time dashboards, ML.FORECAST projects key metrics, and Cortex AI generates recommendations

- **ML.FORECAST for predictive maintenance** - Only demo for Vietnamese electronics manufacturing
- **ML.ANOMALY_DETECTION early warning** - Detects deviations before impact
- **AI recommendations** - Cortex AI actionable guidance
- **Vietnamese context** - Local names, VND economics

## What is deployed

| | |
|---|---|
| Database | `VIETNAM_ELECTRONICS_MAINTENANCE` |
| Service | `VIETNAM_ELECTRONICS_MAINTENANCE_APP` |
| Compute pool | `SEA_DEMOS_VIETNAM_POOL` |
| Dimension table | `RAW.DOCUMENTS` (20 rows) |
| Fact table | `RAW.METRICS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | VND (₫) |

Regions in play: Ho Chi Minh City, Hanoi, Binh Duong, Dong Nai, Can Tho
Segments: Pick and Place, Reflow Oven, AOI Station, Conveyor

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh VIETNAM_ELECTRONICS_MAINTENANCE
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Equipment Uptime | `96.4%` | average per event |
| Unplanned Stops | `14` | total across Documents |
| MTBF (Avg) | `847 hrs` | average per event |
| Equipment Managed | `2,400` | total across Documents |
| Predicted Failures (7d) | `6` | total across Documents |
| Parts on Order | `24` | total across Documents |
| Spare Coverage | `91%` | average per event |


## Demo flow

1. Overview
2. Analytics
3. AI Intelligence
4. Ask AI
5. Architecture

## Talking points

- **100K operations** - tracked in Bac Ninh & Vinh Phuc
- **500K metrics** - time-series data points
- **5K assets** - monitored
- **100 docs** - searchable

## Business impact

- Vietnam electronics manufacturing sector growing rapidly (GSO Vietnam)
- AI improves outcomes 15-30% (McKinsey)
- Vietnam FDI strong in this sector (MPI)
- Real-time analytics reduces response 60-80% (Gartner)

---
Generated from `generator/demo_specs/aws-vietnam-electronics-maintenance.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-vietnam-electronics-maintenance` instead.
