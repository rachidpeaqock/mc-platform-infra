# Milestone Command — Deprecation Policy

**Published:** 2026-09-18 (Sprint 24) · **Applies to:** every `/api/v1/**` path the gateway routes, every client the platform ships, every database the services own

This is the promise the platform makes to anything that calls it, including its own front ends. It
is short because most of it is already enforced by something in the code — the OpenAPI contract
tests, the gateway's version gate, the migration rule — and a policy that says more than the
machinery enforces is a policy that will be found out.

---

## 1. What is a contract

Each service publishes one OpenAPI document (`/v3/api-docs`), pinned in its repo at
`api/openapi.json` with a **semantic version** in `info.version`, and a test that fails the build
if the running service disagrees with the pinned file (`OpenApiContractTest`, every service). The
pinned versions today: milestone-service **2.11.0**, identity **1.1.0**, template **1.0.0**,
integration **1.0.0**.

| Change | Version bump | Who has to act |
|---|---|---|
| A new optional field, a new endpoint, a new enum value a client can ignore | **minor** (2.10 → 2.11) | nobody — clients built against 2.10 keep working |
| A bug fix that changes no shape | **patch** | nobody |
| Removing a field or endpoint, making a field required, changing a type or a meaning, narrowing what an endpoint accepts | **major** — and a major is a new path prefix, `/api/v2/…` | every client, within the window in §3 |

⚠️ **A new enum value is a minor change for the server and can be a breaking one for a client** that
`switch`es on the enum without a default. That is the client's defect, not the server's, and the
reason every client on this platform renders an unknown reason code rather than failing on it —
the catalogue comes from the server, and "Marine access" in every stub is a code no client build
ever knew, there to prove it.

## 2. What is never changed in place

- **`/api/v1` shapes.** A breaking change is `/api/v2`, served *alongside* v1 for the window in §3.
  The gateway routes by path prefix, so both exist at once with no service knowing about the other.
- **The audit trail's meaning.** `milestone_log` rows are immutable in the database (`REVOKE
  DELETE`, trigger on `UPDATE`, V3). No API version will ever expose a way to change one; a v2
  that did would be a different product.
- **The variance and RAG definitions.** They are computed in `milestone_view` and nowhere else
  (ArchUnit forbids a Java method that computes them). Changing the view is a **major** for every
  client at once and gets its own announcement, because it changes the product's central number.
- **The `Idempotency-Key`, `If-Match` and `X-Client-Version` headers.** Their names and semantics
  are the platform's, not a version's.

## 3. The window

| | |
|---|---|
| **Notice** | A deprecation is announced when the replacement ships, never before. The announcement is a `Deprecation: true` and a `Sunset: <http-date>` header on every response from the deprecated path (RFC 8594), plus a line in the release notes and this file's §6 |
| **Overlap** | **90 days minimum** from the first `Sunset` header to removal. Both versions are served for the whole window |
| **Removal** | The old path answers `410 Gone` with a problem body naming the replacement — for another 90 days — then the route is deleted from the gateway |
| **Extension** | Any client still on the old path at day 60 (the gateway logs `X-Client-Version` per route) extends the window; nobody is surprised by a removal they were still calling |

For the platform's **own front ends** the window can be shorter *in practice*, because they are
redeployed on every push and there is no old bundle anyone can keep: a Static Web App serves the
latest build to everyone on next load. Field is the exception — see §4.

## 4. Clients that cannot be redeployed: Field

A phone keeps whatever build it has until its owner updates it, which on a crew's personal device
can be never. Two rules handle that, and both are already built:

1. **Every Field build sends `X-Client-Version: mc-field/<semver>`** from its first request. It has
   done so since the first sprint it existed, so there is no build in the wild that cannot be gated.
2. **The gateway refuses a version below the floor with `426 Upgrade Required`**
   (`ClientVersionGate`), and Field shows a blocking upgrade screen on a 426. The floor is
   configuration — `CLIENT_MINIMUM_MC-FIELD=0.3.0` on the gateway — so raising it is a restart,
   not a release.

Policy: **the floor is raised only for a defect that damages data** (a build that writes a wrong
reason, drops an audit entry, or replays an outbox twice). It is not raised to retire an API version
— that is what the 90-day window and the `410` are for. A Field build older than the current API's
window keeps working until the path it calls is gone; then it gets a `410` and shows the same
upgrade screen.

## 5. Database migrations: expand, then contract

The API window exists because clients cannot all change at once. The same is true of the
service and its database during a deployment: `job-migrate-<svc>` runs **before** the new image
rolls (runbook §2), and the previous revision must keep working against the migrated schema
until the roll completes — or is rolled back (runbook §3).

So a migration that **removes or renames** ships in two releases, never one:

| Release | Migration | Code |
|---|---|---|
| N | add the new column / table; backfill; keep the old | writes both, reads new |
| N+1 (after N is everywhere) | drop the old | reads and writes new only |

A migration that only **adds** ships in one. Flyway migrations are forward-only; there are no
down scripts, and the audit trail's immutability rule is one of the reasons why.

## 6. Deprecations in effect

| Path / field | Deprecated since | Sunset | Replacement | Notes |
|---|---|---|---|---|
| — | — | — | — | Nothing is deprecated. Every path is `/api/v1` and every contract is at its first major |

## 7. How to deprecate something (the checklist)

1. Ship the replacement; bump the contract (minor if additive, or open `/api/v2`).
2. Add `Deprecation` and `Sunset` headers on the old path — in the service, so they are in the
   contract file and the contract test sees them.
3. Add the row to §6 and a line to the release notes.
4. At day 60: `az containerapp logs show -n ca-api-gateway … | grep 'X-Client-Version'` on the old
   route. Anyone still there gets a message and an extension.
5. At Sunset: the old path answers `410` with the replacement in the problem body.
6. Ninety days later: remove the route and the code. Move the §6 row to a "removed" line.
