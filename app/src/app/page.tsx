'use client';

import { useEffect, useState } from 'react';
import { AppLayout } from '@/components/AppLayout';
import { KPICard } from '@/components/KPICard';
import { Chart } from '@/components/Chart';
import { DataTable } from '@/components/DataTable';
import { AskAI } from '@/components/AskAI';
import { ActionMemo } from '@/components/ActionMemo';

interface MaintenanceData {
  kpiCards: { title: string; value: string }[];
  timeseries: { period: string; value: number | null }[];
  categories: { category: string; count: number | null }[];
  entities: Record<string, string | number | null>[];
  pmYield: { name: string; compliance: number; yield: number }[];
  sourceWatermark: string | null;
  rawWatermark: string | null;
  requestedAt: string;
  stale: boolean;
  pipelineBehind: boolean;
  risk: Record<string, string | number | null>[];
  holdout: { n: number | null; baseRate: number | null; precision: number | null; recall: number | null } | null;
  forecast: { period: string; value: number | null; lower: number | null; upper: number | null }[];
}

const pct = (value: number | null) => (value === null ? 'n/a' : `${(value * 100).toFixed(0)}%`);

export default function HomePage() {
  const [data, setData] = useState<MaintenanceData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    setError(null);
    setData(null);
    fetch('/api/data', { cache: 'no-store', signal: controller.signal })
      .then(async (response) => {
        if (!response.ok) throw new Error('Data request failed');
        const payload = await response.json();
        if (!Array.isArray(payload.kpiCards) || !Array.isArray(payload.entities)) throw new Error('Invalid contract');
        return payload;
      })
      .then(setData)
      .catch(() => {
        if (!controller.signal.aborted) setError('Snowflake data is unavailable. No fallback values are displayed.');
      })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [attempt]);

  const kpiVal = (title: string) => data?.kpiCards.find((card) => card.title === title)?.value ?? 'Unavailable';
  const executive = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {['Equipment Uptime', 'Unplanned Stops', 'MTBF (Avg)', 'Equipment Managed'].map((title) => (
          <KPICard key={title} title={title} value={kpiVal(title)} status="neutral" />
        ))}
      </div>
      <p className="text-sm text-slate-600">Uptime = operating / planned hours. MTBF = operating hours / failure count. All observations in the snapshot are included.</p>
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Chart data={data?.timeseries ?? []} type="line" xKey="period" yKeys={[{ key: 'value', name: 'Uptime %' }]} title="Daily Equipment Uptime" />
        <Chart data={data?.categories ?? []} type="bar" xKey="category" yKeys={[{ key: 'count', name: 'Downtime hours' }]} title="Recorded Downtime by Root Cause" />
      </div>
      <DataTable columns={[
        { key: 'id', header: 'Machine' }, { key: 'name', header: 'Name' }, { key: 'region', header: 'Region' },
        { key: 'category', header: 'Equipment type' }, { key: 'uptime', header: 'Uptime (%)' },
        { key: 'mtbf', header: 'MTBF (hours)' }, { key: 'events', header: 'Machine-days' },
        { key: 'failures', header: 'Unplanned stops' },
      ]} data={data?.entities ?? []} title="Equipment observations" />
    </div>
  );
  const predictive = (
    <div className="space-y-4">
      <h2 className="font-semibold">7-day failure risk and downtime forecast</h2>
      <p className="text-sm text-slate-600">
        Synthetic data has no run-to-failure history, so this predicts the probability of an unplanned stop in the next
        7 days (Snowflake ML classification) rather than remaining useful life.
      </p>
      {data?.holdout ? (
        <p role="status" className="text-sm text-slate-700">
          Out-of-time holdout ({data.holdout.n} machine-days): precision {pct(data.holdout.precision)} and recall{' '}
          {pct(data.holdout.recall)} at a 0.5 threshold, versus a {pct(data.holdout.baseRate)} base failure rate.
        </p>
      ) : (
        <p role="status">Model outputs are not deployed. Run snowflake/05_ml.sql.</p>
      )}
      <DataTable columns={[
        { key: 'id', header: 'Machine' }, { key: 'band', header: 'Risk band' },
        { key: 'probability', header: 'P(stop in 7 days)' }, { key: 'scoredAsOf', header: 'Scored as of' },
      ]} data={data?.risk ?? []} title="Failure risk by machine" />
      <Chart data={data?.forecast ?? []} type="line" xKey="period"
        yKeys={[{ key: 'value', name: 'Forecast' }, { key: 'lower', name: 'Lower' }, { key: 'upper', name: 'Upper' }]}
        title="Fleet downtime forecast, next 14 days (hours)" />
    </div>
  );
  const planning = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <KPICard title="Parts on Order" value={kpiVal('Parts on Order')} />
        <KPICard title="Spare Coverage" value={kpiVal('Spare Coverage')} />
      </div>
      <Chart data={data?.pmYield ?? []} type="scatter" xKey="compliance" yKeys={[{ key: 'yield', name: 'Yield (%)' }]} title="PM compliance (%) vs Yield (%) by machine" />
      <p className="text-sm text-slate-600">Synthetic associations are not evidence that maintenance caused a yield improvement.</p>
      <ActionMemo persona={{ name: 'Hoang Duc Minh', role: 'Maintenance Director (fictional persona)' }} context={{}}
        onGenerate={async () => {
          const r = await fetch('/api/ask', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ mode: 'memo' }) });
          if (!r.ok) throw new Error('memo failed');
          const j = await r.json();
          return { subject: 'Draft maintenance actions (synthetic data, human review required)', body: j.answer, urgency: 'review', actions: [] };
        }} />
      <p role="status" className="text-sm text-slate-600">Draft generated by AI_COMPLETE from the KPI, failure and root-cause tables only. No notification is sent.</p>
    </div>
  );
  const ai = (
    <div className="space-y-4">
      <p role="status">Answers come from AI_COMPLETE, which summarises the results of fixed read-only queries. The SQL behind each answer is shown below it. Natural-language-to-SQL (Cortex Analyst) is not part of this pilot.</p>
      <div className="h-[500px]">
        <AskAI title="Ask AI" mode="advisor" sampleQuestions={['Which machines have the most unplanned stops?', 'How is equipment uptime calculated?']}
          onSubmit={async (question) => {
            const r = await fetch('/api/ask', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ question }) });
            if (!r.ok) throw new Error('ask failed');
            const j = await r.json();
            return { answer: j.answer, sql: j.sql };
          }} />
      </div>
    </div>
  );
  const architecture = (
    <div className="space-y-4">
      <h2 className="font-semibold">Implementation and validation status</h2>
      <p>Core source: synthetic machines, daily observations and spares. Curated dynamic tables compute numerator/denominator metrics and are suspended after on-demand initialization.</p>
      <p>Application: Next.js server queries the explicit curated contract. Request time and source observation watermark are separate.</p>
      <p>ML: SNOWFLAKE.ML.CLASSIFICATION failure-risk model evaluated on a time-based holdout, plus a 14-day downtime FORECAST with prediction intervals.</p>
      <p>AI: /api/ask runs allow-listed SQL and summarises only those rows with AI_COMPLETE; the SQL and sources are returned with every answer.</p>
      <p>QuickSight: Snowflake DIRECT_QUERY dashboard (downtime by machine, daily uptime) rendered in the cloud via a PAT-only service user. Q answers remain untested.</p>
      <p>Still incomplete: Cortex Search, semantic view/agent, anomaly detection, AWS ingestion and notifications. This page is not an end-to-end certification.</p>
    </div>
  );
  const tabs = [
    { id: 'executive-cockpit', label: 'Executive Cockpit', icon: '', content: executive },
    { id: 'predictive', label: 'Predictive', icon: '', content: predictive },
    { id: 'planning', label: 'PM Planning', icon: '', content: planning },
    { id: 'ask-ai', label: 'Ask AI', icon: '', content: ai },
    { id: 'architecture', label: 'Architecture & Data', icon: '', content: architecture },
  ].map((tab) => ({ ...tab, content: tab.id === 'architecture' ? tab.content : (
    <div className="space-y-4">
      <p className="text-sm text-slate-600">Synthetic demo data. On-demand snapshots are not live customer operations.</p>
      {loading ? <p role="status">Loading Snowflake data...</p> : error ? (
        <div role="alert" className="rounded border border-red-200 p-4">
          <p>{error}</p>
          <button className="mt-3 rounded border px-3 py-2" onClick={() => setAttempt((value) => value + 1)}>Retry data connection</button>
        </div>
      ) : !data?.entities.length ? <p role="status">No equipment observations are available in this snapshot.</p> : (
        <>
          <p className="text-sm">Observation watermark: {data.sourceWatermark ?? 'Unavailable'}. Request time: {data.requestedAt}.</p>
          {(data.stale || data.pipelineBehind) && <p role="status" className="text-amber-700">Stale or lagging snapshot. Refresh the on-demand pipeline before presenting current results.</p>}
          {tab.content}
        </>
      )}
    </div>
  ) }));
  return <AppLayout title="Vietnam Electronics Maintenance" tabs={tabs} />;
}
