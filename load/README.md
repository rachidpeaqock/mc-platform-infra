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

## The token

There is no load-test token, deliberately: every service validates a real Entra JWT for the one
tenant, in every profile (`TenantBoundaryTest` fails the build if that is loosened). So `TOKEN` is
a real user's bearer for `api://milestone-command`, valid for about an hour. The easiest source is
a signed-in Dashboards tab — DevTools → Application → Session storage → `mcToken`. A PM or Planner
role is needed for the writes.

If a token per hour becomes the reason the test is not run, the right fix is **not** a bypass
profile. It is the machine identity E7 already parks against "the first unattended path" —
`client_credentials` with a `loadtest` app role — and k6 fetching its own token from Entra. Same
trigger, same build, and the test then proves the machine path too.

## What the thresholds mean

| Metric | Promise | Why that number |
|---|---|---|
| `tree_ms` p95 < 1 s, p99 < 2.5 s | a PM opens a 5,000-row board in a second | 5,000 rows through `milestone_view` (variance and RAG computed in the database) serialised once; the client virtualises the rest (mc-dashboards, Sprint 24) |
| `summary_ms` p95 < 300 ms | the exec view is instant | one aggregate query |
| `detail_ms` p95 < 400 ms | a drawer opens before the eye moves | detail + dependencies + history are three requests fired together |
| `write_ms` p95 < 500 ms | a phone's replay is acknowledged fast enough not to retry | the write, the audit row, the idempotency claim and the ETag bump in one transaction |
| `server_errors` < 0.1 % | nothing 5xx's under a load a pilot will not reach | `field-sync` at 3 writes/s is ~10,000 an hour |

`write_conflicts` (409s) is reported, not thresholded: two crew leads moving the same date is a
real event and the 409 is the correct answer.

## Results

| Date | Where | tree p95 | summary p95 | detail p95 | write p95 | 5xx | Notes |
|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | not yet run — k6 and Docker are absent on the development machine; the first run is H4 |
