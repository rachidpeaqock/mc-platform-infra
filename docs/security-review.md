# Milestone Command — Security Review

**Performed:** 2026-09-18 (Sprint 24) · **Scope:** the five services' authentication and
authorization, the gateway as the public edge (code and the live `ca-api-gateway`), the four
front ends' dependencies, secrets handling in the repos and the Bicep · **Out of scope, and why:**
a penetration test of the deployed estate (needs `platform.bicep` applied — H4), the Entra tenant
configuration itself (the registrations were made by hand and are not in any repo)

The method: read every `SecurityConfig`, every `@PreAuthorize`, every CORS and error-handling
setting; probe the one thing that is live from outside with read-only requests; audit
dependencies; then fix what could be fixed in code and record what could not.

---

## 1. Findings

Severity is what it would have cost, not how hard it was to find.

| # | Severity | Finding | Status |
|---|---|---|---|
| F1 | **High** (availability of Field) | **A native Field build would have been CORS-refused on its first request.** Capacitor presents `https://localhost` (Android) or `capacitor://localhost` (iOS) as the origin, and the webview enforces CORS. The gateway admitted `http://localhost:*` — a scheme is part of an origin — and `*.azurestaticapps.net`. Neither matches; the preflight fails and nothing is logged server-side. H1 (the APK on a phone) would have found it; the fix is one line and a test | ✅ Fixed — gateway `ac01ea5`, `CorsPolicyTest.nativeWebviewOriginsAreAdmitted` |
| F2 | **Medium** (drift) | **The live gateway is behind `main`.** Its preflight offers `GET,POST,PATCH,DELETE,OPTIONS` — no `PUT`, which template-service saves need — so the deployed Templates app cannot save a template today. The image in ACR is current; nothing rolls it to the container app because `CONTAINER_APPS_RG` is unset. Not a code defect: it is the gap the migrate-then-deploy step closes | ⬜ H4 — runbook §1.4/§2; one `az containerapp update` or the variable |
| F3 | **Low** | `Access-Control-Allow-Credentials: true` offered to a *pattern* of origins. The platform authenticates with a bearer header, never a cookie, so nothing needs it, and credentials-plus-pattern is the combination the CORS spec warns about | ✅ Fixed — off, `CorsPolicyTest.noCredentialsFlag` |
| F4 | **Low** | The default CORS list admits `https://*.azurestaticapps.net` — every static site in Azure, not the platform's four. Acceptable while the token is the real gate (a foreign page cannot obtain a user's token; it lives in the app's own session storage), and unnecessary once the hostnames are known | ✅ Fixed — the `azure` profile reads an exact list from `CORS_ALLOWED_ORIGINS`; `platform.bicep` fills it from the four sites plus the two native origins; `AzureProfileRoutingTest.corsOriginsAreExactInTheCloud` proves a third `azurestaticapps.net` host is refused and the verb list survived the override |
| F5 | **Info** | No automated dependency updates anywhere; `npm audit --omit=dev` is clean on all four front ends today, and Maven has never been audited (no local JVM) | ✅ `dependabot.yml` in all eleven repos: Maven / npm / Actions, weekly, minor+patch grouped, framework majors excluded |
| F6 | **Info** | Identity-service has no `ApiExceptionHandler`; it relies on Boot's default error rendering | No change — Boot 4 defaults omit message and stack trace (`include-message: never`), and the service has no domain exceptions to shape |

## 2. What was checked and held

Recorded so the next review does not repeat the reading, and so a regression has a sentence to
be measured against.

**Authentication.** All five services pin `issuer-uri` to one tenant with the `/v2.0` suffix and
validate `aud` against both `api://milestone-command` and the client id (a v2 token carries the
client id). `TenantBoundaryTest` in each service fails the build on `/common` or `/organizations`.
The gateway does the same and, on a forged token, answers `401` with the generic
`error_description="Failed to validate the token"` — no hint whether issuer, signature or audience
failed.

**Authorization.** Every `@PostMapping` / `@PutMapping` / `@PatchMapping` / `@DeleteMapping` across
the services carries a `@PreAuthorize` (checked mechanically, 0 unguarded). Roles come from the
token's `roles` claim; ownership checks (`@milestoneAuth.canChangeRealDate`) consult the row. The
gateway does **not** authorize — by design (MC-203): it authenticates, and each service authorizes
for itself, so a caller reaching a service directly gains nothing.

**The edge, live (`ca-api-gateway`, read-only probes).** Without a token: `/actuator/health` (200,
group names only) and `/actuator/info` (200, empty) are the only public paths; `/actuator/gateway/
routes`, `/actuator/metrics`, `/actuator/env`, `/v3/api-docs`, any `/api/**` and any unknown path
are `401` — deny by default. `TRACE` is `400`. Plain HTTP is a `301` to HTTPS. Every response
carries HSTS (1 year, subdomains), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`,
`Referrer-Policy: no-referrer`, `Cache-Control: no-store`. A preflight from a foreign origin is `403`.

**Inside the environment.** Only the gateway has external ingress in `platform.bicep`; the four
services are internal, so their `/v3/api-docs` (public on the service, for the contract bootstrap)
is reachable from inside the environment and nowhere else. Locally, compose exposes every port — a
development topology, and documented as one.

**Writes.** `If-Match` is mandatory on every mutation (`428` without it); `Idempotency-Key` is
claimed on a pre-minted id so a replay returns the first outcome; the rate limiter caps writes per
caller at 60/min with a burst of 40 and tracks at most 10,000 callers. Request bodies are bounded
(`@Size` on every string, 25 MB multipart on the P6 upload, 5,000 rows per template).

**Error rendering.** No handler catches `Exception`; unhandled errors fall to Boot's defaults, which
omit the message and the stack trace. Domain errors are RFC 9457 problem bodies with stable codes.

**Data.** The audit trail is `REVOKE DELETE` + an `UPDATE` trigger; re-baseline is a distinct,
role-gated act; variance and RAG are computed in one view. Evidence blobs: no public access on the
account, digest-checked, read only through the service's role check. One database and one login
per service, `REVOKE ALL ON SCHEMA public FROM PUBLIC`, no cross-database grants — in compose and
in the cloud bootstrap job alike.

**Secrets.** No credential in any repo (`grep` for literal passwords finds only compose's
`POSTGRES_PASSWORD: mc`, the local development database). Bicep declares no secret value; the
database passwords are generated into Key Vault by a loop that never prints them, and the one key
Bicep can read (the storage account's) is written to the vault inside ARM. GitHub holds identifiers
as variables and the SWA tokens as per-repo secrets; the Azure deploy identity is OIDC with no
stored credential. Logging: no statement logs a token, an `Authorization` header or a password.

**Front-end dependencies.** `npm audit --omit=dev`: 0 / 0 / 0 / 0 across shell, dashboards,
templates, field, at the time of review.

## 3. Not reviewed, and what would review it

| Area | Why not here | What would |
|---|---|---|
| Penetration test of the deployed estate | Four of five services and the database do not exist in Azure yet | Apply `platform.bicep` (runbook §1), then a scoped test of the gateway's public surface and the SWAs; the probes in §2 are the first ten minutes of it |
| Maven dependency audit | No JVM on the development machine | Dependabot (F5) from its first Monday; `mvn dependency-check` in `java-service.yml` is a follow-up if the PRs show a pattern |
| Entra registration settings | Not in any repo | A read-through of the API and Web registrations against README "Identity": v2 tokens, PKCE only, six roles, no implicit flow, no client secret |
| Field on a device | H1 | The APK; F1 removed the one failure this review could see from here |
| Rate limiting under load | Needs the stack | `load/pm-tree.js` at 3 writes/s is under the limit by design; a second scenario at 2/s per VU from one caller would be the test |

## 4. What changed

| Repo | Commit | |
|---|---|---|
| `mc-api-gateway` | `ac01ea5` | F1, F3, F4 — three CORS changes, three tests (55 tests) |
| `mc-platform-infra` | this | `platform.bicep` passes `CORS_ALLOWED_ORIGINS`; this document; `dependabot.yml` |
| all eleven repos | — | `dependabot.yml` (F5) |
