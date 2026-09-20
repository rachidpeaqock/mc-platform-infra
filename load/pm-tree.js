// ============================================================
// Sprint 24 — k6: the PM board at 5,000 milestones
// ============================================================
// What the two apps actually do, at the rate a pilot does it, against a
// project the size the plan worried about. Three scenarios run together:
//
//   pm-board    PMs opening the hierarchy: GET the whole tree, then the
//               summary, then one milestone's detail (the drawer).
//               Every tree read is 5,000 rows through milestone_view.
//   field-sync  Crew leads' phones replaying their outbox: POST real-date
//               with If-Match, a reason and a note — the write path with
//               the audit trail, ShedLock and the ETag check on it.
//   exec        The executive view refreshing the summary, cheap and often.
//
// Thresholds are the promise, not a measurement: a PM waits under a second
// for a 5,000-row board at p95, a phone's write is acknowledged under
// half a second, and nothing 5xx's. A failed threshold fails the run.
//
//   docker compose up -d && docker compose --profile migrate run --rm migrate
//   docker compose exec -T postgres psql -U milestone_svc -d milestone_db < load/seed-5000.sql
//   TOKEN=$(...) k6 run load/pm-tree.js
//
// TOKEN is a real bearer for the API — the gateway validates it against
// Entra whichever profile it runs, so there is no "load-test token". Two
// sources: a signed-in Dashboards tab (sessionStorage.mcToken), or the
// machine identity — "Milestone Command Automation", client credentials,
// the SERVICE role — which is what .github/workflows/load.yml mints and
// is the unattended path. SERVICE may read everything and change a real
// date, and nothing else (ServiceRoleTest in mc-milestone-service), which
// is exactly the set this script uses.
// Against Azure: BASE_URL=https://ca-api-gateway.<env-domain> — and read
// runbook §6 first, because this WILL trip the postgres-cpu alert on a
// B1ms, which is one of the things it is for.

import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Trend, Rate } from 'k6/metrics';

const BASE = __ENV.BASE_URL || 'http://localhost:8080';
const PROJECT = __ENV.PROJECT || 'a0000000-0000-4000-8000-00000000f5e0';
const TOKEN = __ENV.TOKEN;
if (!TOKEN) {
  throw new Error('TOKEN is required: a bearer token the gateway accepts (see the header of this file).');
}

const auth = { Authorization: `Bearer ${TOKEN}`, Accept: 'application/json' };
const json = { ...auth, 'Content-Type': 'application/json' };

const treeMs = new Trend('tree_ms', true);
const summaryMs = new Trend('summary_ms', true);
const detailMs = new Trend('detail_ms', true);
const writeMs = new Trend('write_ms', true);
const conflicts = new Rate('write_conflicts');   // 409s — expected under contention, counted, not failed
const rateLimited = new Rate('rate_limited');    // 429s — the gateway's per-caller ceiling, see WRITES_PER_MINUTE
const serverErrors = new Rate('server_errors');

// ⚠️ The gateway caps one caller at 60 writes a minute (burst 40) — B14,
// sized for a phone replaying an outbox, and deliberately not raised for
// this test: a run that bypassed it would prove nothing about the
// platform a crew lead meets. One token is one caller, so the default is
// under that ceiling: 48 a minute (0.8/s), still ~2,900 an hour from a
// single identity. A run with many tokens (many callers) can go higher.
// Per minute because k6's rate is an integer — the first run failed on 0.8.
const WRITES_PER_MINUTE = Number(__ENV.WRITES_PER_MINUTE || 48);

export const options = {
  // k6 names the median 'med' and reports p(99) only when asked.
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
  scenarios: {
    'pm-board': {
      executor: 'ramping-vus',
      exec: 'pmBoard',
      startVUs: 2,
      stages: [
        { duration: '30s', target: 10 },
        { duration: '2m', target: 10 },
        { duration: '30s', target: 25 },   // a Monday morning
        { duration: '1m', target: 25 },
        { duration: '30s', target: 0 },
      ],
    },
    'field-sync': {
      executor: 'constant-arrival-rate',
      exec: 'fieldSync',
      rate: WRITES_PER_MINUTE, timeUnit: '1m',   // see WRITES_PER_MINUTE — one caller stays under the gateway's ceiling
      duration: '4m30s',
      preAllocatedVUs: 10, maxVUs: 40,
    },
    exec: {
      executor: 'constant-vus',
      exec: 'execView',
      vus: 5,
      duration: '4m30s',
    },
  },
  thresholds: {
    tree_ms: ['p(95)<1000', 'p(99)<2500'],
    summary_ms: ['p(95)<300'],
    detail_ms: ['p(95)<400'],
    write_ms: ['p(95)<500'],
    server_errors: ['rate<0.001'],
    rate_limited: ['rate<0.01'],          // a 429 means the run was misconfigured, not that the platform failed
    http_req_failed: ['rate<0.05'],       // 409s count as "failed" to k6; the conflicts rate below is the honest number
  },
};

/**
 * Before any VU starts: announce the caller, and refuse to run without the
 * fixture. /me is identity-service's just-in-time provisioning — after this
 * call the automation has a name on the platform, so the activity rows the
 * writes below leave read "Automation (fad7865a)" rather than a bare oid.
 */
export function setup() {
  // A cold identity-service is a 504 at the gateway, not a bad token;
  // give it the thirty seconds a Spring Boot start takes before deciding.
  let me;
  for (let attempt = 0; attempt < 6; attempt++) {
    me = http.get(`${BASE}/api/v1/me`, { headers: auth });
    if (me.status === 200 || me.status === 401 || me.status === 403) break;
    sleep(10);
  }
  if (me.status !== 200) {
    throw new Error(`/me answered ${me.status}: ${me.status === 401 || me.status === 403 ? 'the token is not accepted here' : 'the platform did not answer'} (${BASE}).`);
  }
  const project = http.get(`${BASE}/api/v1/projects/${PROJECT}`, { headers: auth });
  if (project.status !== 200) {
    throw new Error(`project ${PROJECT} answered ${project.status}: run load/seed-5000.sql (job-seed-load on Azure) first.`);
  }
  console.log(`running as ${me.json().displayName} against ${project.json().name}; writes at ${WRITES_PER_MINUTE}/min`);
}

/** Milestone ids as seed-5000.sql minted them: d…3 + hex(n), n in 1..5000. */
function milestoneId(n) {
  return 'd0000000-0000-4000-8000-3' + n.toString(16).padStart(11, '0');
}

function note5xx(res) {
  serverErrors.add(res.status >= 500);
}

export function pmBoard() {
  group('open the hierarchy', () => {
    const tree = http.get(`${BASE}/api/v1/projects/${PROJECT}/milestones`, { headers: auth, tags: { name: 'tree' } });
    treeMs.add(tree.timings.duration);
    note5xx(tree);
    check(tree, {
      'tree 200': (r) => r.status === 200,
      'tree has 5,000 milestones': (r) => {
        try {
          const body = r.json();
          let n = 0;
          for (const p of body.phases) for (const w of p.workPackages) n += w.milestones.length;
          return n === 5000;
        } catch { return false; }
      },
    });

    const summary = http.get(`${BASE}/api/v1/projects/${PROJECT}/summary`, { headers: auth, tags: { name: 'summary' } });
    summaryMs.add(summary.timings.duration);
    note5xx(summary);
    check(summary, { 'summary 200': (r) => r.status === 200 });
  });

  group('open a drawer', () => {
    const id = milestoneId(1 + Math.floor(Math.random() * 5000));
    const detail = http.get(`${BASE}/api/v1/milestones/${id}`, { headers: auth, tags: { name: 'detail' } });
    detailMs.add(detail.timings.duration);
    note5xx(detail);
    check(detail, { 'detail 200 with an ETag': (r) => r.status === 200 && !!r.headers['Etag'] });
  });

  sleep(3 + Math.random() * 5);   // a PM reads before clicking again
}

export function fieldSync() {
  // Only pending, never the same row twice in a second on purpose: the
  // 409 path is real and should appear, but this test is about throughput,
  // not about manufacturing conflicts.
  const n = 1 + Math.floor(Math.random() * 5000);
  const id = milestoneId(n);

  const current = http.get(`${BASE}/api/v1/milestones/${id}`, { headers: auth, tags: { name: 'detail' } });
  note5xx(current);
  if (current.status !== 200) return;
  const etag = current.headers['Etag'];
  const m = current.json();
  if (m.status === 'done') return;

  // Move the forecast a day, with a reason and a note — what a crew lead
  // records on site. The idempotency key is per attempt, as the phone's is.
  const real = new Date(m.realDate);
  real.setDate(real.getDate() + 1);
  const body = JSON.stringify({
    realDate: real.toISOString().slice(0, 10),
    status: 'pending',
    reason: 'weather',
    note: 'k6 load test',
    app: 'field',
  });
  const res = http.post(`${BASE}/api/v1/milestones/${id}/real-date`, body, {
    headers: { ...json, 'If-Match': etag, 'Idempotency-Key': `k6-${__VU}-${__ITER}-${Date.now()}` },
    tags: { name: 'real-date' },
  });
  writeMs.add(res.timings.duration);
  note5xx(res);
  conflicts.add(res.status === 409);
  rateLimited.add(res.status === 429);
  check(res, { 'real-date 200 or 409': (r) => r.status === 200 || r.status === 409 });
}

export function execView() {
  const summary = http.get(`${BASE}/api/v1/projects/${PROJECT}/summary`, { headers: auth, tags: { name: 'summary' } });
  summaryMs.add(summary.timings.duration);
  note5xx(summary);
  check(summary, { 'summary 200': (r) => r.status === 200 });
  sleep(10);   // the exec view refreshes on an interval, not a click
}

export function handleSummary(data) {
  const p = (m, q) => (data.metrics[m] ? Math.round(data.metrics[m].values[q]) : '—');
  const lines = [
    '',
    'Sprint 24 — 5,000 milestones',
    `  tree     p50 ${p('tree_ms', 'med')} ms   p95 ${p('tree_ms', 'p(95)')} ms   p99 ${p('tree_ms', 'p(99)')} ms`,
    `  summary  p50 ${p('summary_ms', 'med')} ms   p95 ${p('summary_ms', 'p(95)')} ms`,
    `  detail   p50 ${p('detail_ms', 'med')} ms   p95 ${p('detail_ms', 'p(95)')} ms`,
    `  write    p50 ${p('write_ms', 'med')} ms   p95 ${p('write_ms', 'p(95)')} ms   conflicts ${data.metrics.write_conflicts ? (data.metrics.write_conflicts.values.rate * 100).toFixed(1) : '—'} %`,
    `  5xx rate ${data.metrics.server_errors ? (data.metrics.server_errors.values.rate * 100).toFixed(3) : '—'} %   429 rate ${data.metrics.rate_limited ? (data.metrics.rate_limited.values.rate * 100).toFixed(1) : '—'} %`,
    '',
  ];
  return { stdout: lines.join('\n'), 'load/last-run.json': JSON.stringify(data, null, 2) };
}
