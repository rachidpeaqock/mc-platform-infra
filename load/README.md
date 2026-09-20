# Load test — the PM board at 5,000 milestones

Two files. `seed-5000.sql` puts a 5,000-milestone project (`LOAD-5K`, id `…f5e0`) into
`milestone_db`; `pm-tree.js` is the k6 script that reads it the way Dashboards does and writes to
it the way Field does, with the thresholds the platform promises.

## Against the compose stack

```bash
docker compose up -d
docker compose --profile migrate run --rm migrate
docker compose exec -T postgres psql -U milestone_svc -d milestone_db < load/seed-5000.sql   # → milestones | 5000
TOKEN=<bearer> k6 run load/pm-tree.js
```

## Against Azure (runbook §6 first — this trips the postgres-cpu alert on purpose)

```bash
# seed through the bootstrap job's image, or psql with the admin from the vault (runbook §5 step 3)
BASE_URL=https://ca-api-gateway.<env-domain>.azurecontainerapps.io TOKEN=<bearer> k6 run load/pm-tree.js
```

## Unattended, from a runner

```bash
gh workflow run load.yml                 # seed LOAD-5K through job-seed-load, then run
gh workflow run load.yml -f seed=false   # the fixture is already there
gh run download -n load-last-run         # the k6 summary as JSON
```

`load.yml` runs as the **machine identity** (runbook §11): "Milestone Command Automation", client
credentials, the application-only `SERVICE` role — every read plus the real-date change, and nothing
else, which is exactly this script's footprint. The secret is read from the vault on the runner and
masked; no person's token is involved. The script calls `/me` first so identity-service names the
caller ("Automation (fad7865a)") before its first write lands in anyone's activity feed.

## The token, by hand

There is no load-test token, deliberately: every service validates a real Entra JWT for the one
tenant, in every profile (`TenantBoundaryTest` fails the build if that is loosened). Two sources:
a signed-in Dashboards tab — DevTools → Application → Session storage → `mcToken` (PM or Planner
for the writes) — or the machine identity's, minted with a throwaway secret as runbook §11 shows.

## The write rate

The gateway caps **one caller** at 60 writes a minute (burst 40), sized for a phone replaying its
outbox. One token is one caller, so `WRITES_PER_MINUTE` defaults to 48 — under the ceiling, still
~2,900 an hour from a single identity — and 429s are a threshold: a run that hit the limiter was
misconfigured, and says so. The limiter is not raised for the test on purpose. A pilot's hundred
crew leads are a hundred callers; that shape needs a hundred tokens, not a higher ceiling.

## What the thresholds mean

| Metric | Promise | Why that number |
|---|---|---|
| `tree_ms` p95 < 1 s, p99 < 2.5 s | a PM opens a 5,000-row board in a second | 5,000 rows through `milestone_view` (variance and RAG computed in the database) serialised once; the client virtualises the rest (mc-dashboards, Sprint 24) |
| `summary_ms` p95 < 300 ms | the exec view is instant | one aggregate query |
| `detail_ms` p95 < 400 ms | a drawer opens before the eye moves | detail + dependencies + history are three requests fired together |
| `write_ms` p95 < 500 ms | a phone's replay is acknowledged fast enough not to retry | the write, the audit row, the idempotency claim and the ETag bump in one transaction |
| `server_errors` < 0.1 % | nothing 5xx's under a load a pilot will not reach | `field-sync` at 48 writes/min from one caller is ~2,900 an hour |
| `rate_limited` < 1 % | the run stayed under the gateway's per-caller ceiling | a 429 is the test misconfigured, not the platform failing — see "The write rate" |

`write_conflicts` (409s) is reported, not thresholded: two crew leads moving the same date is a
real event and the 409 is the correct answer.

## Results

| Date | Where | tree p95 | summary p95 | detail p95 | write p95 | 5xx | Notes |
|---|---|---|---|---|---|---|---|
| 2026-09-20 10:45 UTC | Azure dev, from a GitHub runner, as the machine identity, V13 | **16,115** | **12,480** | **6,480** | **7,294** | **52.1 %** | ❌ every threshold. Postgres B1ms at 78–86 % CPU for the whole window, every app idle at 0.1 core / 1 replica; successful responses median 6.3 s, failures ~145 ms (breaker open). Cause: `biz_days()` walked the span day by day and `milestone_view` called it three times a row → V14 |
