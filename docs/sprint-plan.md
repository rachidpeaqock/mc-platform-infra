# Milestone Command — Sprint Plan

**Backlog, epics, and sprint-by-sprint breakdown**

**Written:** 2026-08-15 · Derived from [`platform-architecture.md`](./platform-architecture.md) · Companion to [`backend-architecture.md`](./backend-architecture.md) and [`azure-deployment-plan.md`](./azure-deployment-plan.md)

---

## How to read this

**A sprint here is a unit of scope, not a calendar promise.** One sprint ≈ **10 focused working days**. On a personal project the calendar stretches — a sprint might take three weeks of evenings. What must not stretch is the *ordering* and the *definition of done*: those are what keep the architecture intact when the work is spread over months.

**Near-term sprints are detailed; later ones are outlined.** Sprints 0–9 have full stories and acceptance criteria. Sprints 10+ carry goals and story titles, to be refined as they approach. Writing 24 sprints of detailed stories now would be planning theatre — half of it would be wrong by the time you got there.

**Estimation:** story points, Fibonacci (1, 2, 3, 5, 8, 13). Assumed velocity **~20 points per sprint** for one focused developer. Recalibrate after Sprint 2 with your real numbers.

**This is a living document.** Every story carries a status, updated at each sprint close.

| | Meaning |
|---|---|
| ✅ | Done |
| 🔄 | In progress |
| ⬜ | To do |
| ➡️ | Carried to a later sprint (with a reason) |
| ❌ | Dropped (with a reason) |

**Rule at sprint close:** anything not Done is carried forward with an explicit `➡️ Sprint N` and a one-line note. Nothing silently disappears — a story that keeps slipping should be visible as a story that keeps slipping.

---

## Personas

| # | Persona | Who they are | Their app |
|---|---|---|---|
| **P1** | **Sponsor / Executive** | Reads project health in 30 seconds, decides where to intervene | Dashboards → Executive |
| **P2** | **Project Manager** | Owns the schedule, updates forecasts, re-baselines, answers for slippage | Dashboards → PM |
| **P3** | **Field crew lead** | On site, on a phone, gloves half off, poor signal | Field (mobile) |
| **P4** | **Planner** | Sets up projects from templates, owns the hierarchy | Templates |
| **P5** | **Admin** | Manages users, roles, reason codes, work calendars | Templates / admin views |
| **P6** | **Platform consumer** | A developer building a *new* app or integration on this system | The API + event stream |

**P6 is the persona that makes this a platform.** If no story is ever written for them, this is an app with three views ([architecture §0](./platform-architecture.md#0-design-stance--this-is-a-platform-not-an-app)).

---

## Epic roadmap

| Epic | Name | Sprints | Points | Ships when done |
|---|---|---|---|---|
| **E0** | Prerequisites and accounts | 0 | 8 | Nothing — unblocks everything |
| **E1** | Front-end split | 1–3 | 60 | 4 deployable apps, still on `localStorage` |
| **E2** | Platform foundations | 4–5 | 42 | Gateway + registry + CI + fitness functions |
| **E3** | Milestone core service | 6–9 | 85 | **Dashboards running on a real database** |
| **E4** | Field native app | 10–12 | 62 | App on real phones, offline-capable |
| **E5** | Activity and real-time | 13–14 | 38 | Live sync across web and mobile |
| **E6** | Templates service | 15–16 | 36 | Planners create real projects from templates |
| **E7** | Identity service | 17 | 20 | Platform-grade auth; a 4th consumer is possible |
| **E8** | AI service | 18–20 | 55 | Reason suggestion, narratives, NL query |
| **E9** | Integration (Camel) | 21–22 | 40 | P6 in and out |
| **E10** | Production hardening | 23–24 | 35 | Backups, alerts, load tested, runbook |

**≈ 481 points ≈ 24 sprints.** The first genuinely valuable release is the end of **Sprint 9**.

---

## Definition of Ready

A story enters a sprint only when:

- [ ] It states a persona, an action, and a *why* that isn't a restatement of the action
- [ ] Acceptance criteria are written and testable
- [ ] Its API contract impact is known (new endpoint? version bump? event schema change?)
- [ ] Dependencies are done or explicitly stubbed
- [ ] It fits in one sprint — if not, split it

## Definition of Done

Every story, no exceptions. **The last four are what keep the architecture from eroding** ([§8f](./platform-architecture.md#8f-platform-mechanics--how-new-consumers-arrive)):

- [ ] Code merged, PR reviewed (by you, a day later, honestly)
- [ ] Unit tests for domain logic; integration tests for anything touching the database
- [ ] No new build warnings
- [ ] Deployed to `dev` and manually exercised
- [ ] **The OpenAPI spec is regenerated and published**
- [ ] **Any new endpoint carries a version from its first commit**
- [ ] **Any event schema change passes the compatibility gate**
- [ ] **If the story introduces a rule that could be violated later, a fitness function enforces it**

---

# Sprint 0 — Prerequisites

**Goal:** every account, tool and lead-time item is in place so nothing blocks later.

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-001** | As a **developer**, I install **JDK 25** and set `JAVA_HOME`, so Spring Boot 4 builds at all. | 1 | ➡️ **Sprint 4**, rescoped — **JDK 25 turned out not to be required.** Boot 4.0's baseline is JDK 17 and JDK 17 is already installed. What remains is fixing `PATH` (resolves to Java 8) and `JAVA_HOME` (points at 19), and that isn't needed until backend work starts. |
| **MC-002** | As a **developer**, I create the Azure subscription, resource groups, and a `dev` Container Apps environment. | 3 | ✅ **Done, minus Container Apps** — subscription (Free Trial, spending limit ON), `rg-milestone-command-dev`, providers registered, Entra registrations, GitHub OIDC. **Container Apps deliberately not created**: it bills by the hour whether or not anything runs, the trial credit expires after 30 days, and there is nothing to deploy until Sprint 17. |
| **MC-003** | As a **developer**, I create the GitHub repos so structure exists before code does. | 2 | ✅ **Done**, rescoped — `gh` 2.97.0 installed and authenticated as `rachidpeaqock` (`repo`, `workflow`, `write:packages`). Repos created **per sprint** rather than 15 empty ones up front; `mc-design-system` is live. |
| **MC-004** | As a **developer**, I start **Apple Developer Program enrolment** and decide **App Store vs MDM distribution**. | 2 | ➡️ **Deferred past all epics** (decided 2026-08-24). Replaced in the meantime by a web CI build for `mc-field` — see Epic E4. |

~~⚠️ **MC-004 is the one that bites if deferred.** Enrolment and certificates take weeks and block Sprint 12. Start it now, when it costs nothing.~~

**Superseded 2026-08-24.** The advice was sound for the original plan and no longer applies: Sprint 12 was unblocked by splitting *writing* the native features from *shipping* them, and Field's code is now compiled by a web CI build instead. The warning is struck through rather than deleted — the reasoning was right at the time, and a tracker that quietly rewrites its own history is worth less than one that shows where it changed its mind.

---

# Epic E1 — Front-end split

*No backend required. Everything still runs on `localStorage`. This proves the package discipline while the stakes are near zero.*

## Sprint 1 — Design system extraction ✅ **COMPLETE**

**Goal:** one npm package, consumed by one app, published by CI.
**Package:** [`@rachidpeaqock/design-system@0.1.0`](https://github.com/rachidpeaqock/mc-design-system/pkgs/npm/design-system) — published, private · **Repo:** [`mc-design-system`](https://github.com/rachidpeaqock/mc-design-system) · **Tag:** `v0.1.0` · CI ✅ Publish ✅

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-101** | As a **developer**, I extract tokens into `@rachidpeaqock/design-system`, so all apps share one visual source of truth. | 5 | ✅ **Done** — `styles/tokens.scss` + `styles/ionic.scss`, shipped as source SCSS via a `./styles/*` export so consumers override at build time. |
| **MC-102** | As a **developer**, I move the four UI primitives into the package. | 5 | ✅ **Done** — all four ported as `OnPush` standalone components. `mc-reason-badge` **reworked to take `label` + `hue`** instead of a reason key (see note below). |
| **MC-103** | As a **developer**, I move `mc-top-bar` into the package **without assuming every consumer wants it**. | ~~3~~ **5** | ✅ **Done, re-pointed** — it could not be *moved*: it injected `StoreService`, imported `REASONS`, and used `RouterLink`. Rewritten as a presentational component (inputs/outputs only) in a `/shell` secondary entry point. |
| **MC-104** | As a **developer**, I move the display helpers into the package. | 2 | ✅ **Done** — `fmtDate`, `fmtShort`, `fmtVar`, `varClass`, `parseD`, `addDays`, `iso`. **`bizDays`/`ragOf` deliberately excluded** — they move server-side. |
| **MC-105** | As a **developer**, CI publishes to GitHub Packages on tag with semver. | 5 | ✅ **Done and verified green** — `ci.yml` (build + asserts the exports map and both entry points exist) and `publish.yml` (tag/version match gate). First run **failed**: `--provenance` only works for public packages. Fixed, re-tagged, published. |

**Verified:** both entry points build under ng-packagr; a scratch app installed the packed tarball and compiled all five components under `strictTemplates`; computed styles confirmed tokens resolve (`--neutral-bg` → `oklch(0.955 0.004 258)`, reason-badge background driven purely by the `hue` input).

### Decisions worth carrying forward

**The package carries no domain.** `mc-reason-badge` takes `label` + `hue`, not a `ReasonKey`. Reason categories are configurable API data — adding one must remain a database row, never a package release. Same reasoning as architecture §8e, one tier down.

**`bizDays()` and `ragOf()` stayed behind on purpose.** Both depend on a project's work calendar and thresholds and belong server-side (MC-311). A client copy would be a second source of truth for the numbers behind every RAG indicator on the platform, and the two would eventually disagree silently.

**Found by rendering, not by compiling:** the top bar's Ionicons are resolved *by name at runtime*, so a consumer that forgets `addIcons()` gets blank space with no error or warning. Now documented as a required integration step in the README — and a reminder that a green build is not a working UI.

**Found by running the pipeline, not by writing it:** the publish workflow failed on its first real tag — `npm publish --provenance` is rejected for private packages (`EUSAGE`), and no amount of review would have surfaced that. A workflow that has never run is a hypothesis.

### Carried out of Sprint 1

| Item | To | Why |
|---|---|---|
| MC-003 (repos) | **per sprint** | `gh` authenticated with `repo`, `workflow`, `write:packages`; repos now created as each sprint needs them rather than 15 empty ones up front. |

Nothing else carried. **Sprint 1 closed at 22 points** (MC-103 re-pointed 3 → 5).

## Sprint 2 — Dashboards and Templates repos 🔄 *(one manual step outstanding)*

**Goal:** two independently deployable web apps.
**Repos:** [`mc-dashboards`](https://github.com/rachidpeaqock/mc-dashboards) · [`mc-templates`](https://github.com/rachidpeaqock/mc-templates) · [`mc-platform-infra`](https://github.com/rachidpeaqock/mc-platform-infra)

**Carried in from Sprint 1:** nothing. Sprint 1 closed complete.

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-111** | As a **developer**, I scaffold `mc-dashboards` and migrate the 7 dashboard files. | 5 | ✅ **Done** — builds clean; rendered and verified: 32 PM rows, hue-driven badges, top bar wired, **zero console errors**. |
| **MC-112** | As a **developer**, I scaffold `mc-templates` and migrate its 2 files. | 3 | ✅ **Done** — builds clean. |
| **MC-113** | As a **developer**, each repo builds via GitHub Actions, with SWA deploy. | 5 | ✅ **Done** — the deploy job removed in Sprint 2 is reinstated and green on all three apps. The fix was `permissions: pull-requests: write` on the **caller**, exactly as the Sprint 4 root cause predicted. All three sites now serve the app; pushes to `main` publish, PRs get their own preview environment. |
| **MC-114** | As a **developer**, one reusable workflow in `mc-platform-infra` that both repos call. | 5 | ✅ **Done** — both repos call it; it resolves and runs. Also asserts the built CSS actually contains `--primary`, so a design-system regression can't ship a correctly-built, unstyled app. |

### Migration decisions

**Both apps now consume `@rachidpeaqock/design-system@0.1.0` as a real dependency.** `src/theme/variables.scss` is gone from both, and `global.scss` *imports* tokens rather than declaring them — the duplication the split was meant to eliminate is actually gone, not just relocated.

**`core/data.ts` shed its formatters.** `fmtDate`, `fmtShort`, `fmtVar`, `varClass`, `parseD`, `addDays` and `iso` were deleted and now come from the package. `bizDays` and `ragOf` deliberately stayed — they are business rules heading server-side in Sprint 7.

**The top-bar adapter is the seam that pays off later.** Because the shared top bar is presentational, `DashboardsComponent` maps store state onto its inputs (`activity()`, `pulseItem()`). When `StoreService` switches from `localStorage` to the API in Sprint 9, only the store changes — the chrome doesn't.

### Three CI failures, and what each taught

| Failure | Cause | Fix |
|---|---|---|
| `startup_failure`, 0s | A private repo's reusable workflow isn't callable from other repos by default | `actions/permissions/access` → `user`… which **still failed**, so it wasn't this |
| `startup_failure` persisted | Something in the reusable workflow's `deploy` job. Isolated by bisecting to a caller with no `uses:` (green), then a minimal callee (ran) | Removed the deploy block — deferred to Sprint 4 anyway. **The exact offending construct was not isolated**; re-introduce it carefully in Sprint 4 rather than assuming it works |
| `403 read_package` | **A repo's `GITHUB_TOKEN` cannot read a private package published from a different repo** | Package made public (below) |

✅ **Resolved — and the package stayed private.** Rather than making it public, the four consuming repos were granted **read** access via the package's *Manage Actions access* settings. Each repo's own `GITHUB_TOKEN` now resolves the package: **no PAT, no repository secret, nothing to rotate**, and access is per-repo and revocable.

Two notes for the next consumer added (`mc-field` in Sprint 10, and any new app):

- **The grant is UI-only.** GitHub's REST API exposes no endpoint for it on personal accounts, so this step cannot be scripted — it is a manual step per consuming repo, and the price of keeping the package private.
- **The picker does not save on selection.** The first attempt failed because the repos were chosen but the change was never committed; CI kept returning `403 permission_denied: read_package` with a token that correctly showed `Packages: read`. If a consumer 403s, verify the repo is actually *listed* with role **Read**, not merely selected.

**All six repos are now green**, including the reusable pipeline's assertion that the built CSS contains the design tokens.

## Sprint 3 — Shell, routing, and the mobile repo ✅ *(one item environment-blocked)*

**Goal:** four apps behind one origin; the mobile repo exists and builds to a device.
**Repos added:** [`mc-shell`](https://github.com/rachidpeaqock/mc-shell) · [`mc-field`](https://github.com/rachidpeaqock/mc-field)

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-121** | As **any user**, I land on the shell and pick my app. | 3 | ✅ **Done** — 3 cards; Dashboards and Templates link, **Field shows "iOS · Android" instead of a link** because it has no web build. Deliberately stateless (below). |
| **MC-122** | As a **developer**, Front Door path-routes `/dashboards`, `/templates` and `/` to the right app, keeping one origin. | 5 | 🔄 **Bicep written, not deployed** — `bicep/front-door.bicep` with an origin group per app and catch-all-last routing. ➡️ deploy in **Sprint 4** with the subscription. |
| **MC-123** | As a **developer**, I scaffold `mc-field` as **Ionic + Capacitor 8** and produce a debug build for a device. | 8 | 🔄 **Scaffolded and verified as a web build; APK blocked** — Capacitor 8 configured, Android platform added with 4 plugins. The APK build is **environment-blocked**, see below. ➡️ **Sprint 12**, where signing happens anyway. |
| **MC-124** | As a **developer**, I archive the prototype repo. | 1 | ✅ **Done** — `stones-angular` → **`milestone-command-prototype`**, archived and read-only. |

**Verified by rendering, not just building:** Field at a 390×844 phone viewport shows 3 cards, **no `mc-top-bar`**, and computed styles `max-width: none · border-radius: 0 · border: 0` — the simulated frame is genuinely gone and the app fills the device. Shell renders 3 cards with exactly 2 links. Zero console errors in both.

### Decisions

**The shell holds no data.** The prototype's launcher showed live project health, which required the seed data. Copying that here would have recreated the duplication the split exists to remove — in a *fourth* place. The shell only launches apps; a health strip can be added in Sprint 9 from `GET /projects/{id}/summary`.

**Field dropped the desktop chrome and the fake frame** — exactly what [architecture §4b](./platform-architecture.md#4b-the-field-app-is-a-native-mobile-app) predicted. It imports tokens and primitives but never `/shell`, which is precisely why that was a separate entry point.

---

## ⛔ Environment blocker — corporate TLS interception (JVM tooling)

**A Zscaler proxy performs TLS interception on this machine.** `services.gradle.org` presents a certificate issued by `Zscaler Intermediate Root CA`, not by Gradle's real CA. Windows trusts the Zscaler root (IT installed it), so browsers, `npm`, `git` and `gh` all work — but **the JDK keeps its own truststore**, which doesn't have it. Every JVM HTTPS download therefore fails with `PKIX path building failed`.

**What it blocks:**

| Blocked | Sprint |
|---|---|
| Android APK build (`gradlew assembleDebug`) — MC-123 | 3 → 12 |
| **All Maven dependency resolution** — the entire Spring Boot backend | 4 onward |

**What it does *not* block:** everything npm/Angular. Sprints 1–3 completed unaffected.

**✅ Resolved — by moving the build, not the machine.** No personal laptop materialised, so development moved to the cloud instead:

- **GitHub Actions is the compiler.** Runners are clean Ubuntu VMs with direct internet, so Maven Central resolves and every service is built, tested and verified there. Sprint 4 was completed this way.
- **Codespaces gives a real inner loop** when one is needed — `templates/devcontainer/devcontainer.json` pins JDK 21, Maven and Node, so a Codespace boots ready to build. Free tier is 120 core-hours/month (~60 real hours on 2-core). Needs `gh auth refresh -h github.com -s codespace`.

The work laptop is now used only for editing and pushing. Nothing JVM runs on it, and nothing needs to.

---

# Epic E2 — Platform foundations

*Nothing user-visible. This is the sprint pair that decides whether the architecture survives year two.*

## Sprint 4 — Gateway and registry 🔄 *(in progress)*

**Goal:** every future service registers and routes through infrastructure that already exists.
**Repos:** [`mc-discovery-server`](https://github.com/rachidpeaqock/mc-discovery-server) · [`mc-api-gateway`](https://github.com/rachidpeaqock/mc-api-gateway)

> **Development moved to the cloud.** No personal laptop was available, so the work machine's JVM blocker (below) was solved by moving the build off it entirely: **GitHub Actions runners are the compiler**, and a [devcontainer](https://github.com/rachidpeaqock/mc-platform-infra/blob/main/templates/devcontainer/devcontainer.json) gives Codespaces a real inner loop when needed. Runners have clean internet — no Zscaler, no corporate Nexus — so Maven Central resolves normally. **This unblocked the entire backend epic without new hardware.**

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-201** | As a **developer**, I stand up `mc-discovery-server` (Eureka), self-preservation on in prod, off in dev. | 5 | ✅ **Done** — Boot 4.0.5 + Spring Cloud 2025.1.1. **3 tests green**, 58 MB executable jar. Tests assert `/eureka/apps` and `/actuator/health` actually serve, not just that the context loads. *(2 peer replicas are a deployment concern — Sprint 23.)* |
| **MC-202** | As a **developer**, I stand up `mc-api-gateway` routing by `lb://` logical name. | 5 | ✅ **Done** — routes `/api/v1/*` to four services. **2 tests green**, 60 MB jar. Tests read the parsed route table back and assert **every route resolves via `lb://`**, never a hostname. |
| **MC-203** | As a **developer**, the gateway validates the Entra JWT once at the edge and mints a `traceparent` — **while every service still authorizes independently**. | 8 | ✅ **Done (validation)** — Entra registrations created, gateway rejects unauthenticated and malformed-token requests, 6 tests green. `traceparent` minting rides with MC-215's instrumentation in Sprint 17; per-service authorization is Sprint 8, where the write path arrives. |
| **MC-204** | As a **developer**, `docker compose up` gives registry + gateway + Postgres + Kafka locally. | 5 | ✅ **Done** — [`compose.yml`](https://github.com/rachidpeaqock/mc-platform-infra/blob/main/compose.yml). Services are **pulled from GHCR**, not built from sibling folders, because a Codespace has one repo checked out and not nine. `init/01-databases.sql` creates a database and login per service **with no cross-database grants**, so §6's hardest rule is enforced by the environment rather than only the document. |
| **MC-206** | *(new)* As a **developer**, every service publishes a container image on merge to main. | 3 | ✅ **Done** — multi-stage, non-root, container-aware heap (`MaxRAMPercentage`, so the JVM sees the container limit rather than the host's RAM). `ghcr.io/rachidpeaqock/mc-{discovery-server,api-gateway}:main` are live. |
| **MC-205** | *(new)* As a **developer**, one reusable Java pipeline builds, tests and verifies every service. | 3 | ✅ **Done** — [`java-service.yml`](https://github.com/rachidpeaqock/mc-platform-infra/blob/main/.github/workflows/java-service.yml). Asserts an **executable** jar (`BOOT-INF/` present), because a thin jar starts and dies in the cloud rather than failing the build. |

### Spring Boot 4 findings

**`TestRestTemplate` no longer lives at `org.springframework.boot.test.web.client`.** Boot 4's module split moved it, and the first CI run failed on exactly that. Fixed by using Spring Framework's `RestClient`, which needs no extra test dependency and doesn't depend on where Boot put things. **Every service test will hit this** — use `RestClient`.

**The gateway starter was renamed.** `spring-cloud-starter-gateway` no longer resolves in the 2025.x train; it is `spring-cloud-starter-gateway-server-webflux`. Route config also nests one level deeper: `spring.cloud.gateway.server.webflux.routes`.

### 🔎 The Sprint 2 `startup_failure` — root cause finally isolated

Adding the image-publish job reproduced the exact failure from Sprint 2: **`startup_failure` at 0–1s, no logs, no annotation, no check runs.** This time the change was small enough to bisect properly, and the cause is:

> **A called workflow can never hold more permission than its caller.** These repos default to `default_workflow_permissions: read`. The reusable workflow requested `permissions: packages: write`, which is an escalation — so GitHub refuses to start the run at all, before any job exists to attach an error to.

The Sprint 2 Angular `deploy` job failed for exactly the same reason: it asked for `pull-requests: write`. At the time I removed the block and noted the cause as unidentified — that was the right call to keep moving, but it was a workaround, not a diagnosis.

**The rule:** whenever a reusable workflow declares a `permissions:` block, **every caller must grant at least the same permissions.** The failure mode gives you nothing to work from, so it is worth knowing by heart.

Two hypotheses were tested and rejected on the way: hyphenated inputs in job-level expressions (`inputs.publish-image`), and third-party action resolution. Neither was the cause; the bisect — caller with no `uses:`, then a callee stripped to a single `echo` — is what found it.

✅ **Settled.** The Angular SWA deploy job was reinstated with `pull-requests: write` granted in each caller, and went green on all three apps first try — confirming the diagnosis rather than just working around it.

One correction worth recording: `java-service.yml` carried a comment claiming a hyphenated input in a job-level `if:` causes the same 0s failure. That was a bisecting hypothesis that turned out to be **wrong**, and it sat in the file for two sprints looking like a finding. `angular-app.yml` uses `app-name` in exactly that position and is fine. The comment has been corrected — a confidently-worded wrong note in shared infrastructure is worse than no note.

> **Pin the stack here:** Spring Boot **4.0.5** + Spring Cloud **2025.1.1**. Boot 4.1 has no compatible Spring Cloud release train ([backend §2](./backend-architecture.md#2-stack-and-versions)).

## Sprint 5 — Fitness functions and the contract pipeline

**Goal:** the architecture rules enforce themselves, before there is anything to violate.

➡️ **Deferred past Sprint 6 by choice.** The milestone service was built first, so `catalog`/`audit`/`schedule` now exist as conventions the build does not yet enforce. That is the debt this sprint was meant to prevent, and it grows with every module added — MC-211 and MC-212 should land before the second service, not after.

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-211** | As a **developer**, `ApplicationModules.verify()` and ArchUnit rules fail the build on a boundary violation. | 5 | ✅ **Done** — Modulith 2.0.7 + ArchUnit 1.5.0. Passed on the first CI round, which is the argument for doing it now rather than later. |
| **MC-212** | As a **developer**, an ArchUnit rule fails the build if `mc-platform-commons` ever contains an `@Entity` or a domain type. | 3 | ✅ **Done, rescoped** — `mc-platform-commons` does not exist, so the rule guards the shared kernel that does. Moves there unchanged when the library is created. |
| **MC-213** | As a **developer**, CI publishes the OpenAPI spec on every merge and **fails on an unversioned breaking change**. | 5 | ✅ **Done, split** — contract pinned against a committed `api/openapi.json`, spec published as a build artifact by every Java service. Breaking-vs-additive classification deferred to Sprint 9, see below. |
| **MC-214** | As a **developer**, a schema registry with backward-compatibility enforcement gates every event-schema change. | 5 | ➡️ **Sprint 13**, re-pointed from 10 at the Sprint 9 close — there are no events yet. Nothing produces to Kafka and no schema exists, so this would gate an empty set. The first event comes from `activity-service`, not from Field, so it belongs in the sprint that publishes one. |
| **MC-215** | As a **developer**, distributed tracing flows browser → gateway → service into App Insights. | 3 | 🔄 **Half done** — App Insights and Log Analytics exist, connection string stored. The instrumentation is not wired: tracing that cannot be observed cannot be verified, so it lands with the first deployment (Sprint 17). |

**This sprint has no demo and no user value, and skipping it is the single most expensive decision available in this plan.** Every rule here is trivial to add now and requires fixing violations *plus* writing tests later.

### Why two stories moved rather than shrank

A fitness function that guards nothing is worse than no fitness function: it passes, it looks like coverage, and it gives false confidence in a review. MC-214 would gate an empty set of schemas. MC-215 can send traces nowhere. Both are written down with a trigger — first published event, and the Azure subscription — rather than being quietly dropped or faked.

MC-213 split differently: **pinning the contract** and **classifying a change as breaking** are separate jobs, and only the first is useful before a consumer exists. `OpenApiContractTest` compares the generated spec to a committed `api/openapi.json`, so no controller edit can change the public shape of the service without a human committing the new spec — the diff *is* the review. Automated breaking-change detection (oasdiff) earns its keep once `mc-api-client` is generated from the spec in Sprint 9, and is scheduled there.

### Sprint 5 is complete — 13 of 21 points, and the rest deliberately parked

**27 tests green.** The three fitness-function stories cost four CI rounds; two of those were bootstrapping the API baseline, which is a one-time cost per service.

**MC-211 and MC-212 passed on the first attempt**, and that is the whole argument for this sprint. There were no violations to fix, because the rules arrived while the service was three modules old. The same rules added after four services would have meant a refactor *plus* the argument about whether it was worth it.

Three rules now hold the design in place:

| Rule | What it stops |
|---|---|
| `allowedDependencies` in each module's `package-info.java` | §3's dependency table drifting. Adding an import to an undeclared module breaks the build |
| `sharedKernelStaysPure` | The shared kernel acquiring an `@Entity` and becoming the lockstep-upgrade coupling point §8e warns about |
| `thereIsExactlyOneDefinitionOfTheNumbers` | A second implementation of variance or RAG in Java. A method named `calculateVariance` or `bizDays` fails the build |

That last one is blunt on purpose. Someone who writes `calculateVariance()` is not being careless — they are being helpful and have not read the migration that says the database owns it. The build tells them instead of a code review six months later.

⚠️ **One design flaw was caught by writing the test, not by reasoning.** The generated spec contained `"url": "http://localhost:34343"` — springdoc reports the live server address, which under `RANDOM_PORT` differs on every run. Committed as-is, the baseline would have failed the very next build for a reason unrelated to the contract, and a check that cries wolf is a check somebody deletes. Volatile fields are now stripped before comparison, and the bar for adding to that list is that a field genuinely cannot be made stable.

---

# Epic E3 — Milestone core service

*The heart. ~45 dev-days, four sprints. Everything else in the platform depends on this being right.*

## Sprint 6 — Schema and read path

**Goal:** real milestones out of a real database.

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-301** | As a **developer**, Flyway creates the full schema — project, phase, work package, milestone, dependency, log, rebaseline, reason codes, calendars. | 8 | ✅ **Done** — `V1`–`V4` in [`mc-milestone-service`](https://github.com/rachidpeaqock/mc-milestone-service). Three departures from the documented DDL, below. |
| **MC-302** | As a **developer**, the 32 seed milestones load as fixture data, so dev has realistic content. | 3 | ✅ **Done** — `V900__seed_meridian.sql`: 32 milestones, a 14-link dependency chain, 25 audit rows with real slip reasons. In `src/test/resources`, so it cannot reach production. |
| **MC-303** | As **P2 (PM)**, `GET /api/v1/projects/{id}/milestones` returns the hierarchy with server-computed `variance` and `rag`. | 5 | ✅ **Done** — assembled phase → work package → milestone tree, read from `milestone_view`. |
| **MC-304** | As a **developer**, migrations run as a discrete pipeline step, not on app startup, so a bad migration can't take the app down with it. | 3 | ✅ **Done** — `spring.flyway.enabled: false` plus `SchemaVersionGuard`, which fails startup loudly if the schema is missing. |

**Sprint 6 is complete.** 19 points, and the first service that does something a user would recognise.

### The one decision worth carrying forward

**Variance and RAG are computed by the database, and Java never recomputes them.** `biz_days(from, to, calendar)` and `milestone_view` are the single definition. There is deliberately no `ragOf()` method on the `Rag` enum to tempt anyone — the moment a second implementation exists the two disagree, and the disagreement surfaces as an executive dashboard that contradicts the field.

This also front-loads part of **MC-311**: `biz_days` already takes a calendar and honours holidays and non-Mon–Fri week patterns, rather than shipping the prototype's known bug and fixing it next sprint. Sprint 7 keeps the admin-facing calendar configuration, the exhaustive test suite (MC-312), and the sweeper.

### Three departures from the documented DDL

[`azure-deployment-plan.md` §4](./azure-deployment-plan.md#4-database-schema) was written when there was one shared database. Under database-per-service:

1. **Only this service's tables exist here.** Users, activity and templates went to their own services.
2. **`owner_id` and `actor_id` carry no foreign key.** They point into another service's database, and a FK across that line is precisely the coupling database-per-service prevents. `owner_id` is returned as an opaque id — resolving it to a name is API composition, not this service's job.
3. **`REVOKE UPDATE, DELETE` is replaced by triggers.** ⚠️ Worth internalising: Flyway connects as the table owner, and **a table owner keeps every privilege regardless of `REVOKE`**. The documented statement would have run without error and enforced nothing — a control you believe is protecting you and isn't.

### What Boot 4 cost, and it was not the language

Six CI rounds, none of them about the domain. This is the tax for being early on a major version, and it is worth writing down because the other three services will pay it once each otherwise:

| Failure | Cause |
|---|---|
| Non-parseable POM | An XML comment cannot contain `--`, and mine had a divider rule |
| `version is missing` | Boot 4 manages the Testcontainers *version property* but not the modules |
| Still missing | **Testcontainers 2.x renamed everything**: `org.testcontainers:postgresql` → `testcontainers-postgresql`, and the class moved to `org.testcontainers.postgresql`. The last 1.x release is the highest published under the old coordinates |
| Whole context failed, 19 tests | **Boot 4 ships Jackson 3** (`tools.jackson`), which has no `SerializationFeature.WRITE_DATES_AS_TIMESTAMPS`. Jackson 3 already defaults to ISO-8601, so the correct configuration was none at all |
| Schema missing, 19 tests | **Boot 4 split autoconfigure into a module per technology.** `flyway-core` gives you the library and none of the Boot integration — no migration, no `spring.flyway.*`, and *no error*. The dependency is `org.springframework.boot:spring-boot-flyway` |

⚠️ **Two of these five failed silently rather than loudly**, and that is the pattern to watch for. An obsolete Jackson property did not warn, it killed the entire application context. A missing autoconfiguration module did not warn either — the application started perfectly against an empty database.

**The second one was caught only by `SchemaVersionGuard`**, written for MC-304 to cover the risk of separating migration from startup. It earned its place before the sprint that added it was even finished: without it the service would have started clean, registered with Eureka, and returned 500s on the first request. That is the argument for asserting what you depend on rather than assuming the framework wired it.

## Sprint 7 — Working days and RAG (highest-value tests in the codebase)

**Goal:** the numbers are right, and provably so.

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-311** | As **P5 (admin)**, I configure a **work calendar with holidays and a site work pattern**, so variance reflects the actual site — not a hardcoded Mon–Fri. | 8 | ✅ **Done** — `schedule` module, six endpoints, writes restricted to `ADMIN`. Reads stay open to any authenticated user: the client needs the pattern to render a date picker that skips non-working days. |
| **MC-312** | As a **developer**, `biz_days(from, to, calendar)` is exhaustively unit tested — holidays, year boundaries, negative spans, 6-day weeks. | 5 | ✅ **Done** — 22 cases: holidays on weekends, consecutive holidays, cross-calendar isolation, Sun–Thu weeks, single-day weeks, year and leap boundaries, a full year, and null propagation. |
| **MC-313** | As **P1 (sponsor)**, RAG is derived server-side from variance, status and per-project thresholds, so client and server can never disagree. | 3 | ✅ **Done** — proven by changing thresholds and the calendar and watching the answer change with no milestone written, plus a structural assertion that neither is a column. |
| **MC-314** | As a **developer**, an hourly job flips past-due milestones to `missed` (ShedLock so one replica runs it). | 5 | ✅ **Done** — four SQL statements over `milestone_view`, so the sweep uses exactly the variance the API serves. |

**Sprint 7 complete. 21 points, 69 tests green.**

⚠️ **MC-311 fixed a correctness bug in the prototype:** `bizDays()` counted Mon–Fri only and knew nothing about holidays. That number drives variance, RAG, every threshold, and the exec slippage figure. The function was written calendar-aware in Sprint 6 rather than shipping the bug and fixing it later; this sprint added the administration and the proof.

### Three bugs found in my own work, two before they shipped

**1. A test that was wrong, not the code.** `biz_days(Monday → Saturday)` returns **−1**, and I had asserted 0 by sloppy symmetry with the Saturday→Sunday case. It is right: pulling a milestone from Monday back to Saturday gives Monday back, and Monday is a working day. Going backwards the boundaries mirror — the later date is included, not excluded. The test now states that instead of asserting a guessed number.

**2. `@Transactional` that did nothing.** It sat on `sweepStatuses`, which `sweep()` calls directly. Self-invocation does not pass through the Spring proxy, so the annotation was **dead** and each of the four statements would have committed separately — a sweep that half-applies. Moved to the scheduled entry point.

**3. Statement order in the sweep is load-bearing.** Un-missing must run *first*, so a milestone re-forecast into the future returns to `pending` and is re-evaluated as `atrisk` in the same pass. Written in the intuitive place — last, since it reads like a special case — it would leave a milestone green for an hour despite being ten working days late. There is now a test named for exactly that.

### Authorization arrived a sprint early, deliberately

MC-311 is the first story with a **write** endpoint, and `mc-milestone-service` was not a resource server — the gateway authenticated, the service checked nothing. That was tolerable while everything was read-only and not tolerable for an endpoint that changes every variance figure on a project.

So a slice of Sprint 8 came forward: the service validates tokens itself and `@PreAuthorize("hasRole('ADMIN')")` guards the writes. **This is not duplicating the gateway.** A gateway is a router, not a network boundary — every other service and every scheduled job reaches this one directly on port 8081. Protecting a write endpoint one hop upstream protects it from the internet and from nothing else.

Most of the new tests assert a **refusal**, because the usual way an authorization rule fails is not by wrongly blocking someone — that gets reported in a minute — but by never firing at all.

### The contract check earned its keep immediately

Adding six endpoints failed `OpenApiContractTest` on the first run, which is the design. Reviewing the diff before accepting it showed the change was **purely additive**: `MilestoneView`, `ProjectMilestones`, `Phase`, `WorkPackage` and the milestones endpoint all byte-identical, one path becoming six. No consumer breaks. That is a judgement a person made from a diff, rather than something nobody noticed.

## Sprint 8 — The write path and the audit trail

**Goal:** the product's core promise, enforced by the database.

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-321** | As **P2 (PM)**, I change a milestone's real date **with a mandatory reason**, and the change plus its reason commit atomically. | 8 | ✅ **Done** — `POST /api/v1/milestones/{id}/real-date`. Tested by asserting that a refused change leaves *nothing* behind: the date unmoved and no audit row. |
| **MC-322** | As **any user**, the audit trail is **append-only — enforced by database grants**, not application code. | 5 | ✅ **Done in Sprint 6, by trigger rather than grant.** See the note below — the grant approach silently enforces nothing here. |
| **MC-323** | As **P2 (PM)**, I re-baseline a scheduled date with a mandatory justification, role-gated to PM/planner, recorded separately from routine updates. | 5 | ✅ **Done** — own endpoint, own table, own role gate. A field user may move the forecast on a milestone they own and still cannot re-baseline it. |
| **MC-324** | As **any user**, the actor is taken **from the token, never the request body**, so the audit trail can't be forged. | 3 | ✅ **Done** — from the token's `oid` claim. |

**Sprint 8 complete. 21 points, 87 tests.**

⚠️ **MC-324 closed a real hole in the prototype**, which sent `by: 'You'` from the client. The fix is not validation — **there is nowhere in the request record to put an actor**. A test posts `actorId` and `by` in the body and asserts the audit row still carries the token's identity.

`oid` is used rather than `sub` deliberately: `sub` is pairwise, so the same person gets a different value per application and one human would appear in the trail as several.

### MC-322 was already done, and not the way the story says

The story asks for `REVOKE UPDATE, DELETE`. **That would have enforced nothing.** Flyway connects as the owner of these tables, and a table owner keeps every privilege regardless of `REVOKE` — the statement runs without error and does nothing. Triggers hold regardless of ownership, which is what V3 uses, proven by `AuditImmutabilityTest`. The `REVOKE` remains worth adding in production, where the app should connect as a non-owner role; it is defence in depth, not the control.

### The ordering choice that makes atomicity real

The audit row is inserted **before** the milestone is updated. It sounds backwards — write the thing, then log it — but the reason code is a foreign key into `reason_code`, so an unknown reason fails at the insert and the date never moves. The other order moves the date and *then* discovers the explanation is invalid, and while the transaction still rolls back, the failure arrives after the interesting work rather than before it.

### Authorization: two rules, because there are two acts

`hasRole` cannot express "this row is mine", so the row-level rule is a bean called from `@PreAuthorize`:

| Act | Who |
|---|---|
| Change a real date | PM, planner, admin — any milestone. **FIELD — only milestones they own** |
| Re-baseline | PM, planner only |

The Field app already filters its list to the signed-in user, so this *looked* enforced. It was not — that filtering is a convenience, and until now any field user could post an update for any milestone on the project.

### A test that was wrong, for the second sprint running

`statusIsReDerivedOnWrite` used fixed dates in March 2026 and asserted `atrisk`. By the time it ran, March was in the past and the correct answer was `missed`. **The code was right; the test had drifted with the calendar.**

The lesson is narrow and worth keeping: variance depends only on scheduled versus real, so fixed dates are fine for it. **Status depends on today**, so any test asserting a status must build its dates relative to `now()`. That distinction is now written into the test rather than left to be rediscovered.

## Sprint 9 — Concurrency, impact, and Dashboards on the API

**Goal:** the first end-to-end vertical slice. **This is the release that matters.**

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-331** | As **P2 (PM)**, if someone else moved a milestone while I was editing, I get "M. Castellano moved this to 24 Jul" instead of silently overwriting them (`@Version` + `If-Match` → 409). | 8 | ✅ **Done** — the version is inside the `UPDATE`'s `WHERE`, so check and write are one statement. The 409 carries the current date, version and last editor. |
| **MC-332** | As **P2 (PM)**, I see what a slip threatens, via a recursive CTE with cycle protection and a depth cap. | 5 | ✅ **Done** — a slip on m17 reaches first LNG five links away and the handover at seven. |
| **MC-333** | As **P1 (sponsor)**, the exec dashboard loads from **one aggregate query**, not by shipping every milestone to the browser. | 5 | ✅ **Done** — `GET /projects/{id}/summary`. Headline counts, lost days by reason, worst exposure. |
| **MC-334** | As **P2 (PM)**, `mc-dashboards` reads and writes through the API, with loading, error and 409-conflict states. | 8 | ✅ **Done.** The PM tree was the last screen holding a second copy of the project and it is off `localStorage` entirely — read, create, rename, delete, re-baseline and date change all through the gateway. Verified by driving a browser against a stub of the real contract, not by reading the diff. See below. |

### Found during Sprint 9, logged here rather than remembered

Nine gaps surfaced while putting the front end on the API — five of them only once the PM tree was
actually swapped and the dead prototype code came out behind it. None were in the plan; all are
real.

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-335** | As **P2 (PM)**, I create, rename and delete milestones through the API, so the PM view can leave localStorage entirely. | 8 | ✅ **Done** — `POST /milestones`, `PATCH /milestones/{id}`, `DELETE /milestones/{id}`. Edit carries **neither date**: moving the forecast needs a reason, moving the baseline needs a justification and a different role, so an edit endpoint that accepted a date would be a way around both. Delete is soft — the audit trail references the row and outlives it. |
| **MC-336** | As **P2 (PM)**, I see a milestone's slip history, so the reason badge shows what actually caused the delay. | 3 | ✅ **Done, the smaller way.** The last reason — code, label and hue — is carried on each exposure row rather than adding a history endpoint the exec screen would only reduce to its final entry. The hue travels with it, so adding a reason category server-side needs no client change. |
| **MC-338** | As a **planner**, I create and rename phases and work packages, so a new project can be structured without SQL. | 5 | ✅ **Done in Sprint 14**, and **not** with the templates service — `phase` and `work_package` are milestone-service tables; a template *instantiates* them. The deferral below was wrong for six sprints. *(original note follows)* Found while building MC-335. Creating a milestone needs a `workPackageId`, and the only way to get a work package that does not already exist is a manual `INSERT`. Deliberately not folded into MC-335: creating the containing structure implicitly from names would make "Piping" typed twice with different capitalisation into two work packages, and nobody would notice until a report split in half. |
| **MC-337** | As a **field user**, replaying a queued update after a lost response does **not** write a second audit entry. | 5 | ✅ **Done, ahead of Sprint 11 rather than during it.** `Idempotency-Key` header, keyed by `(actor, key)`, claimed with `INSERT … ON CONFLICT DO NOTHING` so check and claim are one statement. Keys expire after 30 days on the existing hourly sweep. |
| **MC-339** | As **P2 (PM)**, I read one milestone's **delay log and re-baseline history** in the detail drawer, so I can see what actually happened to it rather than only that it is late. | 5 | ➡️ **Sprint 11.** Found while swapping the PM tree. The drawer's largest panel had no data behind it. MC-336 solved the *exec* badge by carrying the last reason on each exposure row, which is one label; the drawer needs the sequence. The server holds the trail and no endpoint reads it per milestone. **The drawer now says so rather than falling back to the prototype's "No changes — real date still equals scheduled", which would have been a lie on every milestone that has slipped.** |
| **MC-340** | As **P2 (PM)**, I see a milestone's **predecessors**, so the dependency panel says what this milestone is waiting on. | 3 | ➡️ **Sprint 11.** Found while swapping the PM tree. Nothing the API returns points upstream. Successors were recoverable for free — `GET /impact` is the transitive closure with a depth on each row, so depth 1 *is* the direct successors, and the drawer renders them from the walk it already fetches. There is no equivalent walking the other way. |
| **MC-341** | As **P1 (sponsor)**, the S-curve is anchored to the **project's own start and finish dates**, so the x-axis is not a seed constant. | 2 | ➡️ **Sprint 11.** `PROJECT.scheduledStart` and a hardcoded `2027-04-15` still drive the chart's geometry — the only surviving use of the seed on the exec screen now that the project's *name* comes from the server. Needs two dates on `GET /projects/{id}`. |
| **MC-342** | As **any user**, the activity feed and the notification bell show **real events from the platform**, not an empty list. | 3 | ✅ **Done in Sprint 13**, from the audit trail — no activity-service, no Kafka. *(original note follows)* ➡️ ~~Sprint 13~~, and now **explicitly** empty. `StoreService` fed the bell from this app's own `localStorage` writes; nothing writes there any more, so the only thing the feed could still surface was **leftover prototype events from an old browser session, rendered as current activity**. The store and the adapter are deleted rather than left mapping a permanently empty array. A **visible regression from the prototype**, and it must not be discovered as a surprise in Sprint 13. |
| **MC-343** | As **P1 (sponsor)**, the exec numbers **reflect a change a PM just made**, without a reload. | 3 | ✅ **Done in Sprint 13**, a sprint early, because MC-342 settled the decision this was waiting on: the push channel is not being built, so the choice collapsed to refetch vs refresh-on-view and refetch won. *(original note follows)* ➡️ ~~Sprint 14, where the push channel is built and the choice is actually available.~~ Found while swapping the PM tree. `GET /summary` is fetched once per load and never refreshed, so every write leaves it stale: the project row and the whole exec screen keep the old counts until the page reloads. Deliberately *not* fixed by refetching the summary after each write — that is a design choice between refetch, refresh-on-view and the push channel Sprint 14 builds, and picking the first one silently would prejudge it. |
| **MC-344** | As **P5 (admin)**, a reason category I add server-side **appears in the capture modal**, so the picker is not a second catalogue. | ~~3~~ **5** | ✅ **Done, and it grew by one rule.** `GET /api/v1/reason-codes`, and `REASONS` is deleted from `core/data.ts` with **no fallback list**. Re-pointed because the story turned out to include a second hardcoded copy of reason semantics — see below. |

### The ordering that makes MC-337 work, and the one that makes it useless

**The idempotency check must run before the version check.** A replay carries the same `If-Match` the original did — but the original succeeded and incremented `row_version`, so that header is now stale. Check the version first and every successful-but-unacknowledged write returns 409, showing the user a conflict *with themselves*. The retry is not a competing edit; it is the same edit arriving twice, and only the key can tell them apart.

A test is named for exactly that case, because the obvious "same key twice" test passes against an implementation that still fails this way in production.

Two smaller decisions worth keeping:

- **Keys expire after 30 days**, not hours. Expiring early is worse than keeping too long — a late replay writes the duplicate the mechanism exists to prevent, and a phone left in a site hut over a shutdown is weeks.
- **The key is optional.** An interactive browser edit has a human watching; requiring one would make every client carry machinery for a problem only the offline replayer has.

⚠️ **MC-337 was the one that mattered most and looked least urgent.** Sprint 11 builds Field's offline outbox, and an outbox retries on any response it did not receive — including the ones that succeeded. Without a key, every such retry appends a duplicate entry to the audit trail. That trail is what a delay claim is argued from, so duplicating it is not a cosmetic bug; it is the product's core asset quietly becoming untrustworthy. Adding it now costs a header and a table. Adding it after Field ships means reconciling data already written.

**Backend: 105 tests green.** Front end builds clean. **Both dashboards read and write entirely
through the API** — and the sprint's demo runs: open Dashboards, change a real date with a reason,
watch variance and RAG recompute server-side, reload, and it is still there.

### Four prototype defects the API swap flushed out

Re-pointing components at a real server found bugs that had been sitting in the prototype the whole time. Each was invisible against seed data and would have mattered against a database — worth recording, because the pattern is the point:

| Defect | Why it was invisible |
|---|---|
| `confirm()` computed `atrisk` vs `pending` **client-side** from `bizDays()` and a hardcoded threshold | A second implementation of the server's number, ignoring site calendars entirely. The backend ArchUnit rule forbids exactly this and cannot reach into TypeScript |
| The completion date came from **`AS_OF`, the frozen clock** (2026-06-06) | Marking a milestone done would have written June 6th as the actual date, permanently, into a trail V3's triggers make un-editable |
| `overallSlip` read **`store.get('m28')`** | A hardcoded id that worked only because the seed happened to name the handover milestone that |
| `store.impact(id)` called **synchronously from templates**, in two places | Free against an in-memory graph; one HTTP request per row per change-detection cycle against an API |

The last one is the most instructive. `ProjectStore` deliberately exposes `loadImpact()` (a fetch a caller must invoke) and `impactCount()` (reads the cache) rather than a convenient synchronous `impact()`. Adding the convenient version would have made both compile errors disappear **and reintroduced the N+1 invisibly** — the compiler only caught them because the easy shim was refused.

### The PM tree swap — what changed, and the four defects it exposed

Both blockers are closed: MSAL landed as the one-line provider swap the `ACCESS_TOKEN` seam was
built for, and MC-335 gave the tree the endpoints it needed. **`localStorage` is gone from both
dashboards.** What remains on `StoreService` is the notification bell alone — MC-342.

**The tree is now the server's tree.** It was rebuilt by grouping a flat list by phase *name* and
ordering the result against a hardcoded `PHASE_ORDER` array; it now renders `phase → work package
→ milestone` as the API returns it, in the `sort` the API returns it in. Two things fall out of
that. A project whose phases are not the seed's no longer falls back to alphabetical accident. And
every work package carries its **id**, which is what `POST /milestones` needs — matching on a name
would target the wrong package the first time two phases both contain a "Piping".

Four defects surfaced. Each was invisible against seed data, and only one is a porting detail:

| Defect | Why it was invisible |
|---|---|
| **The search box never filtered anything.** `query` was a plain field read inside a `computed()`, which only re-runs when a *signal* it read changes | The box accepted text, so it looked like it worked. Nothing downstream ever recomputed. It is a signal now |
| The audit-trail panel fell back to **"No changes — real date still equals scheduled"** | True against a client-side log that started empty. Against the API it asserts "nothing happened" on every milestone that has slipped — MC-339 |
| The drawer called `store.impact(id)` **synchronously in three template bindings** | Free against an in-memory graph; three HTTP requests per change-detection cycle against an API. The same N+1 the exec screen had, in a second place |
| A failed write set the store's `LoadState` to `failed`, **replacing the milestone tree with a full-page error** | Only reachable when a write actually fails, which a store that cannot fail never does. The read path fails the screen; the write path now fails the dialog |

**The rollups needed a decision, not a port.** A phase row shows `done/total`, and under an active
search the prototype would have shown the *matching* rows. Filtering is a visibility concern —
hiding rows does not change how a work package is doing — so rollups are computed over the
unfiltered set and the project row takes its numbers from `GET /summary` directly. The project row
and the exec screen now cannot disagree, because they are reading the same response.

**Two capabilities were removed rather than faked.** The owner picker is gone: `ownerId` is an
identity-service id, that service does not exist until Sprint 17, and a list of names would have
had to send something. Rendering it is handled the same way — two characters of a GUID look
exactly like initials, which is worse than showing nothing, so an unresolved owner says
"Unresolved owner". The edit form no longer offers the scheduled date, because the `PATCH`
endpoint deliberately does not accept one.

### Verified by driving it, not by reading it

The front end has no test runner, and this repo's own record says a green build is not a working
UI. So the swap was checked by serving the app against a **stub of the real contract**, shaped from
`MilestoneWriteController` and the wire types, and driving a browser through it: **23 assertions,
all passing** — the tree renders in server order, search filters rows without moving a rollup, the
impact walk populates both the successors list and the what-if panel, a date change takes the
server's recomputed variance, create/rename/delete round-trip, and a **409 forced behind the
client's back renders the conflict banner naming who got there first, with the modal still open and
the user's input intact**.

Two of the first run's three failures were the *test* being wrong about what a rollup means — the
pattern this plan has now recorded in four consecutive sprints. The third was the search bug above,
and nothing but running it would have found it.

### The debt the swap left, paid the same day

`mc-dashboards` is **454 lines lighter**. `StoreService` was 258 lines of which five members were
still reachable, and `core/data.ts` was a 32-milestone seed hierarchy with no readers left. Both
are deleted.

**One of them was a hazard rather than clutter.** `StoreService` still exposed `commitReal`,
`createMilestone`, `editMilestone`, `deleteMilestone` and `rebaseline` — a complete second write
path, into `localStorage`, that anyone wiring a new screen could have injected and used without
noticing the data never reached the server.

Three defects came out with it, each invisible against a synchronous seed store:

| Defect | Why it was invisible |
|---|---|
| **The frozen clock**, `AS_OF = 2026-06-06`, read in three places | It labelled the chrome and the exec footer "As of" against a live database — and positioned the **TODAY line on the S-curve**, drawing three months of real progress as still in the future, on the one chart a sponsor reads to judge recovery |
| The exec curve divided by a **zero milestone count** on every load, emitting `<path d="M38.0 NaN …">` until the API answered | The seed store was never empty, so there was no frame in which the count was zero |
| The bell could still surface **prototype events from an old browser session as current activity** | Only reachable on a browser that had used the prototype — a developer's, before a user's |

**`Milestone` lost `depends`, `log` and `rebaselines`.** The API sends none of them, so the store
could only fill them with empty arrays — and a typed, always-empty `log` is exactly how the drawer
came to render "No changes" over milestones with a full audit trail. Removing the fields turns that
from a silent render into a **compile error**, which is what MC-339 and MC-340 should hit on
arrival. The compiler caught the store still filling them, which is the argument for doing it.

What survives client-side in `data.ts` is four things, each carrying a comment saying why: the seed
project (only `scheduledStart`, for the curve's x-axis — MC-341), fallback thresholds, the reason
picker's catalogue, and `bizDays`/`ragOf` for previewing a change **before it is submitted**. Every
stored number on every screen is read from the API.

⚠️ **The reason picker is the last place a client owns domain data** — MC-344 above.

### The contract check earned its keep, by catching me

I recorded that this change would be additive. **It was breaking**: both write endpoints now require `If-Match`, so a previously working client gets 428. The baseline diff showed it, and the API went to **2.0.0** rather than shipping a break as a minor bump.

The path stays `/api/v1` because this API has never had a consumer — MC-334 is the first, in this same sprint. That is a one-time licence and the reasoning is written into `OpenApiConfiguration` so nobody reads the precedent as permission.

### MC-344 — the picker, and the rule hiding behind it

**The story as written was "serve the catalogue".** Doing it surfaced that the catalogue was only
*half* the client-owned domain. The other half was one line:

| Where | The rule |
|---|---|
| `MilestoneService.java` | `if ("other".equalsIgnoreCase(reason))` → a note is required |
| `reason-modal.ts` | `if (reason() === 'other')` → a note is required |

Both were correct about today's data and both made the catalogue's extensibility a lie. An admin can
add "Under investigation" and **cannot say that it obliges the writer to explain themselves** — the
rule is a string literal in two compiled artifacts, in two languages. Serving an extensible
catalogue whose *behaviour* is still keyed off one hardcoded code would have looked finished and
been half done, so `V7` adds `reason_code.requires_note`, the service reads the flag, and the form
reads the same flag off the same response. `'other'` is seeded `true`, so **no request that
succeeded before fails now** — only the place the rule is written down changed.

Three decisions worth carrying:

**There is no fallback list, and that is the feature.** A built-in seven is exactly how an admin's
eighth category became unselectable in the first place: the picker was never empty, never errored,
and was quietly missing the right answer. When the catalogue cannot be read the modal says so and
refuses the write. A picker that admits it is broken beats one that looks healthy and is wrong.

**A reason code is a `string` now.** `ReasonKey` was a union of seven literals describing a database
table, so the *type system itself* prevented this app from selecting a category an administrator had
added. Deleting the type is part of the fix, not a consequence of it. `MilestoneStatus` and `Rag`
stay unions on purpose — those are closed sets defined by a Postgres enum and a `CASE` in
`milestone_view`, where adding a value is a migration, not a row.

**Retiring a category hides it from pickers and nothing else.** `active` gates
`GET /reason-codes`; the summary resolves label and hue by joining `reason_code` with no `active`
filter, so Meridian's 2025 weather losses keep rendering with the right label and the right colour
after the category is retired in 2026. Filtering there too would look like consistency and would
quietly blank a column of the executive dashboard. The **write** path also deliberately still
accepts a retired code — Sprint 11's Field outbox can replay an update queued three weeks ago, and
rejecting it because an admin retired the category since would lose a real day's work to a
housekeeping action.

### Verified by driving it, again — and the harness is still ad-hoc

**19 assertions against a stub of the real contract**, in a browser. The stub deliberately serves a
catalogue that is *not* the deleted client list: it contains "Marine access", which no build of this
app has ever known about, and it **inverts the old hardcoded rule** — `marine` requires a note and
`other` does not. Anything still testing `reason === 'other'` fails both ways round, which is the
only way to prove the literal is really gone rather than merely relocated.

Also asserted: the picker renders in the server's order, an unknown category is coloured from the
server's `hue`, the chosen code reaches the wire verbatim, the write takes the server's recomputed
variance over the client's copy, and a catalogue that 500s leaves the tree, the numbers and every
read-only view working while the modal alone refuses.

⚠️ **This is the second sprint running that this harness has been built from scratch and thrown
away** — MC-345 below.

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-345** | As a **developer**, the web apps have a **repeatable** way to be driven against a stub of the real contract, so "verified by rendering" is a command rather than an afternoon. | 5 | ⬜ **To do — logged rather than remembered.** Both Sprint 9 verifications found real defects nothing else could have (`query` was not a signal; the search box never filtered). Both harnesses were rebuilt from nothing and deleted after. The blocker is not the driver — it is that the app bootstraps MSAL in `main.ts`, so driving it needs a build with `provideDevAccessToken()`, which today means patching a file by hand. A second `main.*.ts` and an `angular.json` configuration makes it one command. |

### Arithmetic I got wrong for the third sprint running

`deepestLevel` was 7, not the 6 I hand-traced. Sprint 7 it was a working-day direction; Sprint 8 it was a status that depended on today's date. The pattern is consistent enough to name: **when a test's expected value comes from me counting something, it is the most likely thing in the commit to be wrong** — and every one of them was caught by running it rather than by re-reading it.

## Sprint 9 close · 2026-08-24

**Sprint 9 is complete at 47 of 73 points**, and it is the release the whole plan was pointed at:
open Dashboards, change a real date with a reason, watch variance and RAG recompute server-side,
reload, and it is still there. Both dashboards read and write entirely through the API, and
`localStorage` is gone from this platform.

**The sprint was planned at 26 points and finished at 73.** That is not an estimation failure worth
apologising for, it is the finding: MC-335 through MC-345 — **eleven stories, 47 points** — were all
discovered by putting a real client on a real API, and not one of them was visible from the plan.
Four were done here because they blocked the demo or the next sprint; seven are carried below with
somewhere to go. The number to carry into future estimates is that **wiring the first consumer of a
service costs roughly what building the service cost**, and no amount of up-front design finds those
stories, because they are all of the form "the client cannot do X and nobody noticed until a client
tried".

| Carried out of Sprint 9 | To | Why |
|---|---|---|
| **MC-338** phase / work-package creation | ~~Sprint 15~~ ✅ **done in 14** | ⚠️ **The reason given here was wrong.** *(original follows)* It is the templates service's job. Sprint 15 builds project structure from templates, and building a second structure editor in the PM screen first would mean two ways to create a work package before there is one good one. Nothing is blocked meanwhile — the tree endpoint returns work-package ids, so milestones can be created in any package that exists. |
| **MC-339** per-milestone history | **Sprint 11** | The drawer's largest panel says it has no data instead of inventing some, which is correct but not finished. Sprint 11 rather than 10 because Field's offline outbox makes "what happened to this milestone" a question a *second* client asks, and one endpoint should answer both. |
| **MC-340** predecessors | **Sprint 11** | Rides with MC-339: the same drawer, the same fetch-on-selection, and the dependency panel currently hardcodes `FS` as the link type, which is its own small lie to fix. |
| **MC-341** S-curve anchored to project dates | **Sprint 11** | Two dates on `GET /projects/{id}` and the last use of the seed constant on the exec screen goes. Small, and grouped with the other read-path gaps so the contract changes once. |
| **MC-343** exec numbers stale after a write | ~~Sprint 14~~ **done in 13** | The deferral was right and its premise expired. Three answers — refetch, refresh-on-view, push — and the third was never built, so the decision became free in a way nobody predicted: by one option being removed rather than by it arriving. |
| **MC-345** a repeatable browser harness | **Sprint 11** | Logged this sprint. Cheap, and it pays for itself the next time a rendering defect is invisible to the compiler — which has now happened in two consecutive sprints. |
| **MC-342** activity feed and bell | **Sprint 13** | Already carried, and already **explicitly empty** rather than mapping a permanently empty array. A visible regression from the prototype, and it must not be a surprise in Sprint 13. |
| **MC-214** event schema registry | **Sprint 13** | Moved from Sprint 5 and re-pointed from 10 to 13: it gates event schemas, and the first event is produced by `activity-service`, not by Field. Gating an empty set a sprint earlier gates nothing. |

**MC-344 was pulled forward into this sprint rather than carried**, and that decision is the reason
it exists as a finished story: Sprint 10 puts a **second** client on this API, and Field's capture
modal has the same reason picker. Shipping Sprint 10 first would have meant copying a client-owned
catalogue into a second app and then removing it from two places. The rule that fell out is worth
keeping — **when a story is "stop duplicating X", it has to land before the next duplicate is
created, not after.**

**Backend: 125 tests green**, MC-344's six included, verified on CI. Front end builds clean and was
driven in a browser for both of the sprint's two client changes.

*(The "105 tests" recorded against MC-334 above was accurate the day it was written and had drifted
by four commits. Counting from CI rather than from memory: 125.)*

⚠️ **Nothing JVM runs on this machine** (the Zscaler blocker above), so every backend change is
written locally and only *becomes true* when GitHub Actions answers. That is the standing
arrangement and it is worth stating plainly: between commit and green run, a backend claim in this
document is a hypothesis.

---

# Epic E4 — Field native app · Sprints 10–12

**Goal:** crews updating milestones from site, offline, on their own phones.

| Sprint | Focus | Key stories |
|---|---|---|
| **10** | API + auth | Field reads/writes the API · MSAL flow · **minimum-supported-version gate with a blocking upgrade screen** |
| **11** | Offline | IndexedDB/SQLite outbox · **idempotent replay** (a lost response must not double-write the audit log) · queued-state UI · conflict-on-replay handling |
| **12** | Native capabilities | **Camera — photo evidence on a slip** · GPS site verification · biometric unlock |
| **later** | Shipping | macOS CI + signing · Keychain/Keystore token storage · TestFlight / MDM distribution · device testing |

### 🔀 Re-sequenced: Apple enrolment moves to the end of all epics

**Decided 2026-08-24.** MC-004 is deferred past every epic rather than gating Sprint 12.

The reasoning holds up: enrolment is **pure external latency with no code behind it**. Nothing in Epics E4–E10 is blocked by *writing* Field — only by shipping it to a device. Paying weeks of waiting now, to sit on a certificate that goes unused until the end, buys nothing.

**What replaces it: a web CI build for `mc-field`.** The repo had no CI at all until now, which meant the Field app had never been compiled by anything.

| The web build covers | It does not cover |
|---|---|
| TypeScript and templates | Anything behind a Capacitor plugin |
| The design-system contract | Camera, GPS, biometrics |
| Every piece of app logic and state | Real device behaviour, gestures, performance |

⚠️ **So a green Field build means "this compiles and its logic holds", not "this works on a phone".** That distinction has to stay explicit or the CI badge becomes a false comfort — it is the reason the shipping row above was split out of Sprint 12 rather than left implied.

**Sprint 12 is no longer blocked.** Camera, GPS and biometrics can be *written* and unit-tested against Capacitor's web fallbacks; what waits for enrolment is running them on hardware and distributing the result. When enrolment happens, the remaining work is signing and distribution — not development.

The risk accepted, stated plainly: **native-only defects accumulate undetected until the first real device run.** That run will find more than it would have if devices had been in the loop throughout. That is a real cost, knowingly taken in exchange for not blocking on a queue.

## Sprint 10 — Field on the API 🔄 *(open)*

**Goal:** the second consumer. A crew lead's phone reads and writes the same API the dashboards do,
signed in as themselves.

**This sprint is the platform thesis's first real test.** Everything up to now has been one client
talking to one service — which is an application. If putting a second, differently-shaped client on
this API needs core changes, a seam is missing, and it is much cheaper to find that out now than at
MC-701 in Sprint 17.

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-401** | As **P3 (field crew lead)**, my milestone list comes from the API, so what I see on site is what the project actually says rather than what this phone last stored. | 8 | ✅ **Done** — `StoreService` deleted with the seed hierarchy, the dependency graph and the client reason list. |
| **MC-402** | As **P3**, I sign in with my own Entra account, so the audit trail records **me** and not a name the app made up. | 5 | ✅ **Done** — one provider, and nothing else changed. The `ACCESS_TOKEN` seam paid for itself a second time. |
| **MC-403** | As **P3**, I update a real date with a reason **through the API**, and I am told whether it saved. | 5 | ✅ **Done** — and it can fail, which is the part that did not exist before. |
| **MC-404** | As **P3**, my list is **the milestones I own**, decided by the server, so a phone on a site connection is not downloading an entire LNG train to filter it locally. | 5 | ✅ **Done** — `?owner=me`, resolved server-side from the token. Contract 2.2.0. |
| **MC-405** | As **P3**, a version of this app the platform no longer supports **stops and tells me to update**, rather than writing something the API will reject. | 5 | ✅ **Done** — `X-Client-Version` + `426` at the gateway, and **no new endpoint**. |

## Sprint 10 close — the platform thesis held ✅

**Five of five stories, 28 of 28 points.** The headline result is what the second consumer
*did not* need:

| It needed | It did not need |
|---|---|
| One new query parameter — `?owner=` | Any change to the write path |
| Its own store, its own wire types | Any change to authentication |
| A build-time API base URL | Any change to the reason catalogue, the audit trail, the calendar or the contract's shape |

**MSAL cost one line.** `provideMsalAccessToken()` replaced `provideDevAccessToken()` in `main.ts`
and nothing else in the app knew. That seam was built in Sprint 9 on the argument that scattering
`acquireTokenSilent()` through a data layer puts an auth library's API into every component that
wanted a milestone — and the payoff arrives here, in a *different app*, where the same swap was
again one line.

**MC-344 landing first was the right call, and it is now demonstrable.** Field's capture sheet reads
`GET /reason-codes`. Had Sprint 10 gone first, this app would have shipped a ninth copy of the seven
categories and the same `reason === 'other'` literal, and MC-344 would have had to be done twice.

### What Field being second exposed

**One seam was genuinely missing**, and the fact that it was exactly one is the sprint's actual
finding. `?owner=` had to be added: `GET /projects/{id}/milestones` served the dashboards perfectly
and served a phone badly, because it answers "what is the project doing" and Field asks "what am I
on the hook for". Adding a parameter rather than a Field-shaped endpoint keeps the risk register's
"screen-shaped endpoints in the core API" line honest — one resource, one extra filter, no
`/field/my-work`.

Two decisions worth carrying:

**`owner=me` is resolved on the server, from the token.** The alternative — each client decoding its
own token for an `oid` — spreads a claim name and Entra's pairwise-`sub` trap (MC-324) into every
consumer, and gets it wrong once per consumer. The server already knows who is asking.

**A filtered tree prunes empty phases and work packages; an unfiltered one does not.** The
`LEFT JOIN` exists so a planner sees a work package they just created. "Show me mine" is a different
question, and every empty phase of an LNG train is noise on a phone. Two behaviours from one
endpoint, and the parameter is what distinguishes them.

**`Idempotency-Key` goes out from Field's very first write**, not from Sprint 11 where the outbox
arrives. A crew lead retries by hand on a bad connection, and that is the same duplicate a queue
would cause. The key is **derived from the update** — milestone, date, done-or-not — rather than
random: a fresh random key per attempt is exactly as useful as sending none, and it would have
looked correct in review.

### Verified by driving it — 31 assertions at a phone viewport

Including the three states a store that cannot fail never had: a write that **never arrives** (the
stub drops the socket) leaves the sheet open, keeps what was typed and does not claim to have saved;
a **409 while the sheet sat in a pocket** renders as a conflict naming the new date; and
**signed in with nothing assigned** reads as "nothing assigned to you" rather than as a blank
screen.

⚠️ **Four consecutive sprints now, the wrong half of a test has been my own arithmetic.** Three
assertions failed on the first run and all three were the *test* being wrong about which tab a card
belongs to — the app was right every time. Sprint 7 a working-day direction, Sprint 8 a status that
depended on today, Sprint 9 a rollup and a hand-traced depth, Sprint 10 a card count. The rule has
earned promotion from an observation to a habit: **an expected value I computed myself is the least
trustworthy line in the change, and running it is the only thing that has ever caught it.**

### MC-405 — the rule this sprint deliberately broke, and why that was right

A native app does not update itself. An `mc-field` build on a crew's personal phone runs until
somebody chooses to replace it, which can be never — so the platform needs to refuse a version it
knows is wrong rather than accept its writes and repair the data afterwards.

**Enforced at the gateway**, which contradicts this plan's firmest rule — *a gateway is a router,
not a network boundary, so every service authorizes for itself* ([§8f](./platform-architecture.md),
MC-203, MC-311). The contradiction is real and the rule still holds, because the threat models are
opposite:

| | Authorization | Version gating |
|---|---|---|
| Defends against | A caller who wants in | A client that is outdated but **honest** |
| Can it bypass the gateway? | Yes — every service answers on its own port | No — the gateway URL is the only address it was ever given |
| So the check belongs | In every service | At the edge |

An attacker can send any version string they like. That is fine: they could send none. This gate is
not what stops them — it stops a phone in a pocket in the wrong year.

**No new endpoint.** The header rides on every request, so the first call the app makes is the one
that gets refused. A "fetch the minimum version" endpoint would have been skippable by exactly the
kind of old build the gate exists to catch.

The design is **deliberately permissive in four places**, each of which would otherwise turn a
safety feature into an outage:

| Passes | Because |
|---|---|
| No header | `mc-dashboards` sends none. Refusing an unidentified client turns a version gate into a breaking change for every existing consumer, shipped under a name that sounds like safety |
| An unknown client name | MC-701's entire claim is that a new consumer needs no core change. A gateway that blocked every app it had not been told about would make that false, and fail closed on the one path that must stay open |
| A garbled header | A typo is not evidence of an expired build |
| Anything outside `/api/` | ⬇️ see below |

⚠️ **That last one was found by writing the test, not the filter.** The gate as first written
answered `426` to `/actuator/health` — and Container Apps restarts a container whose probe fails, so
the first person to configure a floor would have put the gateway into a permanent crash loop whose
symptom looks like anything except a version gate.

**A second one nearly shipped the same way.** The filter answers the request itself and so never
reaches the gateway's own CORS handling, which means a browser would have blocked the `426` before
the app could read it — the client that most needs to render "update required" seeing an opaque
network error instead. The gate would have been working perfectly and looking broken. CORS headers
are now set by hand on the refusal. **This is the third time this codebase has hit the same shape of
bug**: `REVOKE` that ran without error and enforced nothing, Ionicons that resolved by name and
rendered blank, and now a gate whose answer never arrives.

**Version comparison is numeric, and there is a test named for why.** Lexically `"0.10.0" < "0.9.0"`,
so a `String::compareTo` gate locks out the *newest* build the day 0.10.0 ships — blocking precisely
the users who updated, on a day nobody would connect to a change made months earlier.

**The floors are configuration, not code** (`CLIENT_MINIMUM_MC-FIELD=0.3.0`). Raising one is the
reaction to a defect discovered in the field, at exactly the moment nobody wants to cut a gateway
release to do it.

⚠️ **One piece of debt, stated rather than hidden:** `APP_VERSION` in `mc-field` is kept in step with
`package.json` **by hand**. A build claiming a version it is not would pass a phone the gate exists
to stop, silently — the worst failure this feature has. Deriving it at build time is a small CI
change and is carried with MC-345.

**Verified by driving it: 38 assertions**, up from 31. Including the case that is easy to miss — a
phone already loaded when the floor is raised meets the gate **mid-update, with a reason typed in**,
not on startup. Both paths reach the same screen; without that, one of them shows "something went
wrong" for a condition the platform stated precisely.

### What the audit of `mc-field` found before a line was written

Field is where `mc-dashboards` was before Sprint 9 — a `StoreService` over `localStorage` and the
prototype seed — so most of the swap is known work. Five things it does are **worse than what the
dashboards did**, and they are the reason MC-403 is its own story rather than part of MC-401:

| In `field.component.ts` | Why it matters against a real API |
|---|---|
| `commit()` sends **`reason: this.reason() \|\| 'other'`** | An unpicked reason is silently recorded as "Other" — with no note. The one thing the audit trail exists for, defaulted. The server refuses this now (`reason.required`), so it becomes a visible failure rather than a quiet corruption |
| It computes `status` as **`bizDays(...) > THRESHOLDS.amber ? 'atrisk' : 'pending'`** | The same second implementation of the server's number that MC-334 removed from the exec screen, ignoring site calendars and holidays. Only `done` is the client's to send |
| **`by: ME`**, where `ME = 'M. Castellano'` | A hardcoded identity, and MC-324's hole exactly: the actor must come from the token. There is nowhere in the request record to put one |
| `AS_OF` — the frozen clock, **2026-06-06** — anchors "Today", every quick chip and every "overdue" calculation | On a phone this is the whole product. A crew lead marking a milestone done would write June 6th into a trail V3's triggers make un-editable |
| `commit()` is **fire-and-forget**, then shows "Update saved · Synced to project record" | A store that cannot fail never taught this screen to report failure. Against an API on a site connection, that success screen is a lie roughly as often as the signal drops |

The reason picker is *already* fixed by MC-344 landing first: Field will read `GET /reason-codes`
rather than shipping a ninth copy of the seven. That was the whole argument for pulling it forward.

### ⚠️ The one that needs a decision: what "my milestones" means

**MC-404 is blocked on something the platform does not have yet, and it is worth stating before it
is discovered mid-sprint.**

Field filters its list with `m.owner === 'M. Castellano'` — a *name*, matched client-side. The
server stores `owner_id`, an **identity-service id**, and identity-service does not exist until
Sprint 17. So:

- There is **no `GET /milestones?owner=me`**. The tree endpoint returns the whole project, which is
  what the dashboards want and precisely what a phone on a site connection does not.
- Even with such an endpoint, the seeded `owner_id`s are fixture UUIDs. A real Entra sign-in returns
  a real `oid`, which matches none of them — so "my milestones" against a real login returns **an
  empty list**, and the app looks broken while being entirely correct.

Three ways out, and the recommendation:

| Option | Cost | What it buys |
|---|---|---|
| Wait for identity-service | Blocks Sprint 10 until Sprint 17 | Nothing. Seven sprints of a stalled epic to avoid one fixture change |
| Filter client-side on `ownerId` | Free | A phone downloading 5,000 milestones to show nine. It is the bug MC-333 was written to prevent, in a worse place |
| **Add `?owner=` to the tree endpoint and seed one owner to the dev account's `oid`** | ~2 points | The server decides what is mine, the wire carries only that, and identity-service later changes *where the id comes from* — not what the endpoint means |

**Recommended: the third.** It is the same shape as every other decision in this plan — put the rule
on the server, and let the thing that does not exist yet change only the source of an id.

**Taken, and half done.** `?owner=` ships and `owner=me` resolves from the token. The **fixture half
is deliberately not done**, because it needs a value only the account holder has:

```sql
-- Run once against the dev database, with your own Entra object id.
-- Find it at portal.azure.com → Microsoft Entra ID → Users → your user →
-- Object ID, or in the `oid` claim of any token the app already holds.
UPDATE milestone
   SET owner_id = '<your-entra-oid>'
 WHERE owner_id = 'e0000000-0000-4000-8000-000000000005';
```

Until that runs, a real sign-in sees **"No milestones are assigned to you on this project yet"** —
which is correct, is tested, and is a state the app now says out loud rather than rendering as a
blank screen. ⚠️ **This belongs in the dev seed only.** A production database gets its owner ids
from identity-service in Sprint 17; a hardcoded personal `oid` reaching `V900` is the sort of
fixture fact that survives into an environment nobody meant it to.

## Sprint 11 — Offline ✅ **COMPLETE**

**Goal:** a crew lead records an update with no signal, walks back into coverage, and it is in the
project record — exactly once.

**This is the sprint MC-337 was built for.** The idempotency key landed in Sprint 9 and Field has
been sending one on every write since Sprint 10, so the contract that makes a replay safe already
exists and is already exercised. What is missing is the queue.

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-411** | As **P3 (field crew lead)**, an update I record with no signal is **queued on the phone** and sent when signal returns, so I do not have to remember to redo it. | 8 | ✅ **Done** — IndexedDB, and it survives the app being closed. |
| **MC-412** | As **P3**, I can see **what is still queued** and what has reached the project, so I know whether to say it is done on the radio. | 5 | ✅ **Done** — a header pill, a per-card marker, and a panel with "try sending now". |
| **MC-413** | As **P3**, a queued update the server **permanently refuses** tells me and stops retrying, rather than sitting in the queue forever. | 5 | ✅ **Done** — a refusal leaves the queue and is shown, with the note attached. |
| **MC-339** | As **P2 (PM)**, I read one milestone's **delay log and re-baseline history** in the detail drawer. | 5 | ✅ **Done** — `GET /milestones/{id}/history`, two lists, merged for display only. *(carried from 9)* |
| **MC-340** | As **P2 (PM)**, I see a milestone's **predecessors**, so the dependency panel says what it is waiting on. | 3 | ✅ **Done** — `GET /milestones/{id}/dependencies`, with the link type the drawer had hardcoded. *(carried from 9)* |
| **MC-341** | As **P1 (sponsor)**, the S-curve is anchored to the **project's own dates**, not a seed constant. | 2 | ✅ **Done** — and it took two goes; see below. *(carried from 9)* |
| **MC-345** | As a **developer**, driving a web app against a stub is **one command**, not an afternoon. | 5 | ✅ **Done** — `npm run verify`, and it runs in CI. *(carried from 9)* |

**33 points**, which is above the ~20 velocity assumption. The four carried stories are small and
three of them are one backend change; if the sprint has to shed something it sheds MC-413 to 12,
because an update that is permanently refused is rare and currently *visible* — it fails in the
sheet with the reason on screen. Nothing is silently lost by not having it.

### The three carried stories, closed — and the one that needed a second pass

**One contract change rather than three.** MC-339, MC-340 and MC-341 all wanted something from the
same service, so they moved together and the API went to **2.3.0** once. 146 tests green.

**MC-339 returns two lists, not one timeline.** A date change and a re-baseline are different acts
with different tables, roles and meaning, and the two-date model depends on nobody confusing them.
Merging them server-side would flatten a distinction the server exists to enforce so that a client
could render one list; the PM screen merges on `at` in three lines and keeps the badge that says
which is which. Capped at 100 with a `truncated` flag rather than paginated — a milestone with a
hundred recorded date changes is a data-quality question, not a paging problem.

**The audit join is `LEFT`, and that is not a detail.** A foreign key makes an orphan impossible
today, but an `INNER JOIN` would mean that if a reason code were ever removed, every audit entry
referencing it would **vanish from the trail** rather than lose a label. Losing a row's colour is
recoverable. Losing the row is the one thing that table exists to prevent.

**MC-340's real finding was the hardcoded `FS`.** Successors were already available for free from
the impact walk's depth-1 rows, so this looked like churn. What a transitive closure cannot carry is
the *link* — its type and its lag — and the drawer had been printing "FS" beside every successor.
Right for this fixture, wrong the first time anyone records a start-to-start dependency, and silent
in both cases. There is now a test that creates the row the fixture does not contain.

### ⚠️ MC-341 was "done" once before it was done

Anchoring the curve's **scale** to `scheduledStart` / `scheduledFinish` was the obvious half, and it
made the chart look completely correct. `yearMarks` was still a hardcoded
`[['2025', …], ['2026', …], ['2027', …]]` — and the fixture's years are exactly those three, so
nothing on screen looked wrong.

On any other project the curve would have been drawn to the right span and then **labelled with
Meridian's years**. That is worse than the bug it replaced: a chart that is obviously broken gets
fixed, and a chart that is subtly mislabelled gets read and believed.

**Nothing but running it would have found this.** It was caught by moving the project's dates on the
stub and watching the axis refuse to move — the assertion that survived three rewrites of my own
wrong expectations about it. The marks are derived now, and thin to every second or fifth year on a
long programme rather than overprinting eleven labels across five hundred pixels.

**There is no seed data left in `mc-dashboards`.** `PROJECT` and the `Project` interface are
deleted. What remains in `core/data.ts` is a preview calculation labelled as an estimate and the
threshold pair that colours it before a change is submitted.

### The count that keeps being wrong is still mine

**Five of the six browser assertions that failed on a first run this sprint were the test**, not the
app: a lookahead that matched the variance's `+` instead of a lag suffix, `innerText` on an SVG
element that has none, an expectation that the axis would show the project's start year when the
marks are Jan-1 boundaries, and a stub left in the wrong mode by the previous run. The sixth was
real, and it was `yearMarks`.

That ratio is the argument for the harness, not against it: **the only defect that mattered was
invisible to the compiler, invisible in review, and invisible on the fixture** — and five wrong
guesses of mine were the price of finding it. MC-345 is what makes that price a command rather than
an afternoon.

### MC-345 — the harness, and the debt it collected on the way

**`npm run verify`.** It checks the version, builds a stub entry point, starts a stub of the real
contract, drives the app in a browser and shuts everything down. **39 assertions in
`mc-dashboards`, 37 in `mc-field`**, and both now run on every push — verified by reading them out
of a GitHub runner's log rather than by trusting the workflow file.

**The blocker was never the driver.** It was that both apps bootstrap MSAL in `main.ts`, so driving
one meant hand-editing that file to swap a provider, building, and remembering to put it back —
done three times across Sprints 9 to 11, and every time it found something the compiler could not
see. `app.config.ts` now holds everything *except* where a token comes from, and `main.stub.ts` is
the same app with `provideDevAccessToken()`. **The seam that made this a five-line change was built
in Sprint 9 for exactly this reason**, which is the second time `ACCESS_TOKEN` has paid for itself
in a place it was not designed for.

Three decisions worth keeping:

**The stub is shaped from the contract, not from the client.** It serves a reason category no build
ever hardcoded, a start-to-start dependency with lag, and project dates that are not the fixture's.
Every one of those corresponds to something a client used to assume; a stub mirroring the client
would only prove the client agrees with itself.

**`harness.mjs` is duplicated, deliberately.** Sixty lines in two repos rather than
`@rachidpeaqock/verify` — a package means a release cycle and a version bump every time an
assertion helper changes, which is the lockstep coupling MC-212's fitness function exists to
prevent one tier down. The platform has now made this argument three times: for `bizDays`, for the
wire types, and here.

**No browser is downloaded.** `playwright-core` plus whatever Chromium the machine already has —
Edge on this laptop, Chrome on a runner. The full `playwright` package would pull ~150 MB per
install, per repo, for a check that runs in seconds.

### The debt MC-405 left, paid

`mc-field`'s `APP_VERSION` was kept in step with `package.json` **by hand**, and MC-405 recorded
that as the version gate's one silent failure mode: a build claiming a version it is not sails
through the check that exists to stop it — app working, CI green, and nothing anywhere saying so.

`verify/check-version.mjs` fails the build when they disagree. **It was tested by making it fail**,
not by assuming it would, which is the same discipline as MC-322's trigger and MC-203's denial
tests: the usual way a guard fails is by never firing.

---

### The distinction that decides this sprint's design

**A retry is not a queue, and this app already has the first one.** Today a failed write leaves the
sheet open with the reason on screen and the crew lead presses the button again — which is honest
and works while they are standing still. The outbox exists for the case that is not that: **the
phone leaves coverage entirely, the app is closed, the shift ends.** So the queue must survive a
process death, which is what makes it storage rather than a variable.

Three decisions to make before writing it, recorded here so they are decisions rather than
accidents:

| Question | Leaning |
|---|---|
| Where does the queue live? | **IndexedDB**, not `localStorage`. A queued write is structured, it is read back by key, and `localStorage` is synchronous — which on a phone means blocking the UI thread on every enqueue |
| What is queued — the request, or the intent? | **The intent** (milestone, new date, reason, note, done-or-not). A serialised HTTP request pins the API shape into the phone's storage, and a queued item can outlive a contract version. ~~`If-Match` in particular *must not* be frozen: it is stale by definition on replay~~ — **wrong, corrected below** |
| What happens when a replay 409s? | It is **not** an error to retry. The row moved while the phone was away, and the crew lead has to decide — so a conflicted item leaves the queue and becomes something to look at, with both dates shown |

## Sprint 11 close — the outbox ✅

**33 of 33 points. Sprint 11 is complete**, and the sprint's most valuable output was a correction
rather than a feature — see below.

**A retry is not a queue, and this app already had the first one.** A failed write left the sheet
open with the reason on screen and the crew lead pressed the button again, which is honest and works
while they are standing still. The outbox exists for the case that is not that: **the phone leaves
coverage, the app is closed, the shift ends.** That is why it is IndexedDB rather than a field, and
why the test that matters most is the one that reloads the page and asserts the queue is still
there.

### What does and does not get queued

The distinction the whole story rests on, and three of the four answers are "no":

| Outcome | Queued? | Why |
|---|---|---|
| No signal, 5xx, 408, 429 | **Yes** | The server never heard it. This is work the phone owes the project |
| A refusal (422, 403) | **No** | It will not become an acceptance. It stays on the form, where the person who can fix it is standing |
| A lost race (409) | **No** | Replaying it later applies a decision the crew lead never got to reconsider |
| Upgrade required (426) | **No** | Queueing against a build the platform has refused fills a queue that can never drain, on an app the user is being told to replace |

**Unknown failures are treated as permanent**, which is the uncomfortable direction and the right
one: a queue that retries forever hides the problem, while one that surfaces it too eagerly puts a
wrong answer in front of somebody who can act on it.

### One pending update per milestone, and that is correctness

A crew lead who moves a date to the 20th and then to the 27th while offline **never had a project in
which the 20th was true**. Replaying both would invent an intermediate slip that reached nobody and
write it into a trail the database will not let anyone edit — and the second would 409 against the
first anyway, since both were composed against the same row version. The later intent replaces the
earlier one.

### Two smaller things worth keeping

**The success screen now has two states.** "The project has it" and "this phone has it and the
project does not yet" are things a crew lead acts on differently — one of them means you can say it
on the radio. The old screen said the first for both, because a fire-and-forget write could not tell
them apart.

**The IndexedDB writes await the transaction, not the request.** `request.onsuccess` fires while the
transaction is still open, so resolving there tells the caller an update is durably queued a moment
before it is. If the tab closes in that window — on a phone, exactly when it happens — the write is
gone and the app has already said it was saved.

**55 browser assertions**, up from 37, first run green.

### ⚠️ The `If-Match` note above was wrong, and it would have caused a lost update

**Written at sprint open, corrected while building it.** The claim was that the row version "must be
re-read at send time rather than frozen at queue time". Writing the three replay cases out is what
showed it is exactly backwards:

| On replay | With the version **frozen** | With it **re-read** |
|---|---|---|
| **1. The write arrived; the response was lost.** Server has it, row is at V+1 | The key is already spent, the idempotency check runs first (MC-337), the original outcome comes back. The stale `If-Match` never matters | Same — the key short-circuits before the version is looked at |
| **2. The write never arrived, and somebody else moved the row.** | 409. The crew lead is told their update was composed against a project that has since changed — **which is the correct answer** | It **silently overwrites** the other person's change. A lost update, in the one case optimistic concurrency exists to prevent |
| **3. The write never arrived, and nothing moved.** | It applies | It applies |

So freezing is right in all three, and the note that said otherwise would have quietly turned the
only interesting case into the failure `If-Match` was added for in Sprint 9. **It is struck through
rather than deleted** — a confidently-worded wrong note in shared infrastructure is worse than no
note, and this document has said so before about a comment in `java-service.yml` that sat there for
two sprints looking like a finding.

What survives from it is the part that was right: **a replay of a lost-response write and a replay
of a never-received one look identical from the phone**, only the server can tell them apart, and
that is why the idempotency key ships with every attempt rather than only with retries.

---

## Sprint 12 — Native capabilities ✅ **COMPLETE**

**Goal:** the three things a phone can do that a browser cannot — evidence, place, and privacy —
written and proven as far as a runner can prove them.

**Carried in from Sprint 11:** nothing. Sprint 11 closed at 33 of 33.

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-123** | As a **developer**, `mc-field` produces an installable Android debug APK, so the app can be run on a real device. | 8 | ✅ **Done** — 4.3 MB, built on a runner, uploaded as an artifact. *(carried from Sprint 3)* |
| **MC-421** | As **P3 (field crew lead)**, I attach a **photo** to a slip I record, so the reason is evidenced rather than asserted — including with no signal. | 8 | ✅ **Done** — uploaded before the write, queued with it when there is no signal. 75 browser assertions. |
| **MC-424** | As a **developer**, evidence is **stored where it belongs**, so a photo outlives the phone that took it. | 8 | ✅ **Done** — blob storage, digest-checked, tested against Azurite. Contract 2.5.0. |
| **MC-422** | As **P3**, an update I record on site carries **where I was**, so "done" and "done from the car park" are distinguishable. | 5 | ✅ **Done** — contract 2.4.0, 58 browser assertions. Verification against a site boundary is MC-425. |
| **MC-423** | As **P3**, the app **hides the project when I put the phone down**, so a milestone schedule is not readable by whoever picks it up. | ~~5~~ **3** | ✅ **Done** — the content is replaced, not blurred. The biometric half is MC-426. *(re-scoped from "biometric unlock")* |

### MC-123 is closed, and it took two fixes and eight sprints of not looking

**A 4.3 MB installable debug APK**, built on a runner in 2m 28s, uploaded as a CI artifact and
retained for 14 days. The story was carried out of Sprint 3 and had sat at "environment-blocked"
ever since.

**Neither of the two things actually wrong with it was the thing the status described.**

| What broke | Why it was invisible |
|---|---|
| The Capacitor 8 CLI **refuses to run below Node 22**, and the shared Angular pipeline pins 20 | It fails *after* the Angular build succeeds, so the log reads as a green web build followed by a fatal — which scans as an Android problem and is not one |
| **`./gradlew` had no executable bit.** It was committed from a Windows checkout, where git does not track the mode, so every Linux clone got a 644 script | ⚠️ **The first blocker was hiding it.** Nobody could run `gradlew` locally to discover that they could not run `gradlew` |

The wrapper's mode is fixed **in the index** (`git update-index --chmod=+x`) rather than with a
`chmod` step in the workflow: the mode is a property of the file, and a workflow fix would leave the
next person cloning this on a Mac with the same broken wrapper.

**The lesson is about the words, not the tooling.** The status said "environment-blocked", which
scans as *blocked*. It meant *blocked on this laptop* — and the laptop stopped mattering in Sprint 4,
when the Java build moved to Actions for exactly the same TLS-interception reason. Eight sprints of
a story nobody re-read because its status sounded final. **"Blocked by TLS interception on the
development machine" would have been re-read the moment the development machine stopped being where
things were built.**

⚠️ **Still a debug APK, not a shippable one.** It carries the Android debug key; Play needs a real
upload key, iOS needs enrolment, and both are the Shipping row of this epic. What changed is that
the Android half of Field is now *installable on a device by hand*, which is the first time any of
this code can be run on a phone at all.

### 🔀 MC-423 was "biometric unlock", and that would have been a lie

The story as outlined was **biometric unlock**. Writing down what it would actually protect is what
killed it:

> The Entra access token lives in `sessionStorage` inside the webview. A biometric gate stops
> somebody **opening the app**. It does not stop anybody reading the token off the device, because
> secure token storage — Keychain and Keystore — is explicitly in Epic E4's **"later · Shipping"**
> row and does not exist.

So "biometric unlock" would be **a lock on a door in a glass wall**: it looks like a security
control, it would be described as one in a release note, and the thing it claims to protect is
sitting in the open beside it. This codebase has now hit that shape four times — `REVOKE` that
enforced nothing, Ionicons that resolved by name and rendered blank, a `426` whose CORS headers
never arrived, and now this.

**Re-scoped to what it can honestly be: a privacy screen.** It hides the schedule when the app is
backgrounded and asks for a biometric to reveal it again, and the UI says *that* rather than
implying the data is protected. It **becomes** a security control the day the token moves to
Keystore/Keychain, and that day is written into the Shipping row rather than assumed.

### The decision MC-421 needs: where evidence lives, and in what order

There is **no storage account** in `bicep/` — the only thing there is `front-door.bicep`. A photo
has nowhere server-side to go, which is why the story split:

| | |
|---|---|
| **MC-421** | Capture, compress, and **queue** — including the offline path, since a photo taken with no signal has to survive in the outbox beside the update it evidences |
| **MC-424** | The place it is stored, and the endpoint that puts it there |

**⚠️ The ordering is the interesting part, and it is the same argument as MC-321.** The audit row and
the photo live in different stores and cannot commit together, so one of them goes first:

- **Photo first, then the audit row that references it.** If the write then fails, there is an
  orphan blob — cheap, sweepable, invisible to a user.
- **Audit row first.** If the upload then fails, the trail contains an entry citing evidence that
  does not exist — in a table whose triggers make it un-editable.

The trail is what a delay claim is argued from, so an entry pointing at nothing is the expensive
failure and the blob is the cheap one. **Do the thing whose failure is cheapest to discover last** —
which is precisely why MC-321 inserts the audit row *before* moving the date.

### MC-422 — the server half, and the line it does not cross

`milestone_log` gains three nullable columns and the write path carries them. **156 tests green.**

**⚠️ Provenance on a deliberate act, not tracking.** A position arrives only with an update somebody
chose to record, and there is deliberately **nowhere else in this service to put a coordinate** —
no background fix, no periodic ping, nothing that answers "where was this person at 14:20". The
schema is the enforcement: a future story that wanted continuous location would have to add a table
and argue for it, rather than quietly reusing a column that was already there.

**A missing position is never an error**, and three separate cases produce one: a PM at a desk, a
crew lead who declines the permission, and an offline update replayed days later. An audit trail
that refused a reason because a phone could not see the sky would have its priorities inverted.

**The accuracy radius is kept, and a poor fix is stored rather than discarded.** A fix is a claim
with an error bar: ±8 m and ±2,400 m from a cell tower are the same two numbers meaning entirely
different things, and a reader shown only a coordinate believes it absolutely. A ±3 km fix is a bad
answer and still a true one — dropping it would leave the trail claiming no position was available
when one was.

⚠️ **`getObject`, not `getDouble`.** JDBC returns `0.0` for a null double, and (0, 0) is a real
place — so every milestone updated from a desk would appear 600 km off the coast of Ghana, and
appear certain about it. There is a test named for exactly that.

### Three CI rounds, and none of them was the domain

The tax for having no JVM on this machine, and worth recording because the shapes recur:

| Round | Cause |
|---|---|
| 1 | `position` inserted as the **third** record component instead of the last, colliding with `idempotencyKey`. Caught by the compiler in seconds |
| 2 | **`ADD CONSTRAINT`, not a bare `CONSTRAINT`**, inside `ALTER TABLE`. Inside `CREATE TABLE` the keyword is optional, which is where the habit comes from; Postgres answers `syntax error at or near "CONSTRAINT"` and never mentions the missing word |
| 3 | The hand-patched contract baseline was missing `minimum: 0`, which springdoc emits for `@Positive` |

⚠️ **Round 2 is the one worth knowing.** A failed migration takes the whole application context with
it, so **every test in the run errors and not one of them is the problem** — 60 red tests, one root
cause, and the cause is four lines from the top of the log rather than anywhere near the failures.

Round 3 ended by taking the **generated** spec wholesale rather than patching the baseline again.
The baseline had been hand-edited for three releases and springdoc lays the file out differently, so
99 lines of the diff were key ordering. Now that it byte-matches what CI produces, the next contract
diff is only the contract — which is the entire point of the check.

### MC-422's Field half — three decisions, and one new story

**Done. 58 browser assertions**, driven with Playwright granting a real fix at Pointe-Sable, so the
capture path is exercised rather than only its refusal.

**Asked once per update, never watched.** There is no `watchPosition`, and the absence is the
feature: this platform can answer *"where was this person when they said this was done"* and
deliberately cannot answer *"where were they at 14:20"*. The server's schema enforces the same limit
from the other end — there is nowhere else to put a coordinate — so the two halves agree without
either trusting the other.

**⚠️ It never blocks the write.** Denied, timed out, unavailable, switched off: every outcome
produces no coordinate and the update is recorded anyway. **A crew lead inside a cold box with no
sky is exactly who needs to close a milestone**, and an app that refused them because it could not
find a satellite would be broken in the one place it has to work.

**⚠️ The fix is frozen into the outbox beside `expectedVersion`, and for the same kind of reason.**
A queued update sent three days later from a site office must say where the person was **when they
recorded it**, not where the phone is when the signal returns. Re-reading it at flush time would
have looked like a freshness improvement and would quietly have turned evidence into fiction. That
is the second time this sprint pair that "refresh it at send time" was the wrong instinct.

Two smaller ones worth keeping:

**The switch is on the form, not in a settings screen.** Recording where somebody is standing is not
a neutral act, so the control sits where the act is, says what it does, and is remembered. Default
on — off-by-default means it is never there on the day a claim is argued.

**The success screen names which of four things happened.** A crew lead who believes their location
was attached, and finds out later that it was not, has lost the one piece of context the claim would
have leaned on. Silence is not an acceptable answer to "did that work".

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-425** | As **P5 (admin)**, a project carries its **site coordinates and a radius**, so an update recorded 40 km away can be told apart from one recorded at the gantry. | 5 | ✅ **Done in Sprint 14.** *(original note follows)* ⬜ Found while building MC-422. The story was outlined as "GPS site *verification*", and verification is not possible: `project.location` is free text (`'Pointe-Sable Terminal'`) and there is no coordinate anywhere to compare a fix against. What shipped is the half that is real — the position is *recorded*, and a human reading the trail can see it. Comparing it to a boundary needs the boundary, which is planner data nobody has entered and no endpoint accepts. |

### MC-423 — the privacy screen, and the story it refused to be

**Done, and it does less than the outline promised on purpose.**

When the app goes to the background, the OS screenshots it for the task switcher — and that
screenshot shows a client's whole delivery schedule to anybody thumbing through a borrowed phone.
The cover goes up before the app loses focus, so the switcher captures the cover instead. **That is
a real and complete win, and it needs no biometric.**

⚠️ **The content is replaced, not blurred.** A blur or an opacity on a parent is still composited
into the snapshot on some devices; swapping the rendered tree means there is nothing underneath to
capture. The test asserts no milestone name survives anywhere in the document, not that it looks
hidden.

**Two listeners, because the platforms disagree.** Capacitor's `appStateChange` is the native signal
and never fires in a browser; `visibilitychange` is the web one and fires in a webview too, but on
some Android versions only *after* the snapshot is taken. Listening to both means the cover is up in
time where it matters and still works in the web build CI drives.

**The cover sits ahead of the upgrade blocker**, which reads like an ordering detail and is not: a
refused build's schedule is exactly as confidential as a working one's.

### ⚠️ Two listeners for one concept, and the platform's own shim fought mine

The cover would not go up, and the reason is the most useful thing this story produced.

`PrivacyScreen` registers **two** listeners, because iOS and the browser signal "backgrounded"
differently: Capacitor's `appStateChange`, and the DOM's `visibilitychange`. In a browser **both
fire for one background** — Capacitor's web shim for the App plugin is itself listening to
`visibilitychange` — and they were reading *different properties* to decide what it meant:

| | reads |
|---|---|
| `PrivacyScreen` | `document.visibilityState === 'hidden'` |
| Capacitor's web shim | `document.hidden` |

On a real device those two always agree, so nothing about this is visible on hardware. In the
harness, which shadowed only `visibilityState`, **the shim fired second, read a `hidden` nobody had
changed, and set the cover straight back down.** The cover went up and came down within one tick.

The fix is to read the one property both paths agree on — `document.hidden` — which removes the
disagreement rather than ordering around it. The harness now shadows both, because a browser
reproducing a background has to reproduce all of it.

**Worth generalising:** two listeners writing one signal from two platform APIs is a race whenever
the APIs can disagree, and "they agree on a real device" is not a defence — it only means the
disagreement will surface somewhere nobody is looking. This was found by driving it, and would not
have been found by reading it.

| ID | Story | Pts | Status |
|---|---|---|---|
| **MC-426** | As **P3**, the app **asks for a biometric before revealing the schedule**, so somebody holding my unlocked phone still cannot read it. | 5 | ⬜ **To do — split out of MC-423, and deliberately parked with Shipping.** Two things make it premature. It needs a **third-party plugin** — there is no first-party Capacitor biometric — which is real supply-chain weight for a three-point story. And until the token is in Keychain/Keystore it protects the *screen* while the credential sits in webview storage beside it. It becomes worth doing on the day secure storage lands, and it should land in the same change. |

**What MC-423 does not do, stated so nobody assumes otherwise:** it does not stop somebody who picks
up an unlocked phone and switches back to Field. The cover lifts when the app returns to the
foreground, because a tap-to-dismiss gate is pure friction — anyone who can reach the cover can tap
it. Pretending otherwise would be the fifth instance of a control that looks like protection and is
not.

### MC-424 — evidence has somewhere to live

**Done. 168 tests green**, twelve of them against **Azurite**, Microsoft's own Blob Storage
emulator, over the real Blob API. That is the entire reason `EvidenceStore` is an interface: a
hand-written fake agrees with whatever the code does, and the failures worth catching are the ones
where this code and Azure's client disagree. It runs as a plain `GenericContainer` rather than a
Testcontainers module, because 2.x renamed every module and an image plus a port cannot break on a
rename.

**The bytes are not in Postgres.** Photographs there would put megabytes into every backup and every
restore of a database whose entire value is a few hundred kilobytes of dates and reasons — and the
restore drill (Sprint 23) is exactly the thing that would suffer, at the worst possible moment.

**The write order is the reverse of the intuitive one, and it is MC-321's argument again.** Bytes,
then metadata, then the audit entry, because each step's failure costs a different amount:

| If this succeeds and the next fails | What is left |
|---|---|
| Bytes, no row | An unreferenced blob. Costs storage, invisible, sweepable |
| Row, no bytes | A record pointing at nothing — a viewer renders a broken image, an auditor reads tampering |
| Audit entry citing evidence that does not exist | **The trail itself is wrong**, in a table whose triggers make it un-editable |

Do the irreversible, most-trusted thing last, when everything it depends on already exists.

**The digest is re-checked on every read**, not merely recorded. An evidence store whose contents can
change without anybody noticing is not evidence, and that read is the only place that would ever
find out.

**An SVG is refused by name**, and the database enforces the same list. The failure that prevents is
not a broken image: an SVG served back from the platform's own origin is **stored XSS dressed as a
site photograph**. The image response also carries `nosniff` and a content disposition, because it
is the one route on this API where a mistake is script execution rather than a rendering bug.

### ⚠️ Two things the first CI round found, and one of them was a forgery route

**The catch on the audit insert blamed the reason code for every integrity violation.** That was
true while `reason_code` was the only foreign key on `milestone_log`. Adding `evidence_id` made a
dangling id report *"Unknown reason code 'weather'"* — a message that sends somebody to look at
exactly the wrong thing. **A catch that names one cause is a guess in a confident voice, and it
stops being true the moment a second cause exists.**

**And the foreign key alone permitted the forging case.** Evidence uploaded against one milestone
could be cited by an entry on another: attach a genuine photograph of a genuinely flooded excavation
to a milestone that slipped for a reason nobody wants recorded. Only the service knows which
milestone an entry is for, so only a domain check can refuse it — the constraint cannot. It was
found by a test failing for the *wrong reason*, which is the second time this sprint a red test
pointed somewhere more interesting than where it was aimed.

### MC-421 — the photograph, and the ordering it inherits

**The client half of evidence.** A photograph is taken with the reason it supports, compressed on the
device, uploaded **before** the update that cites it, and — if there is no signal — queued *with*
the update rather than dropped.

**⚠️ 1600px at 70% quality, and that is not a nicety.** A modern phone produces 4–12 MB per frame:
a photo a crew lead cannot send on site wifi, cannot queue several of, and which the server refuses
over 8 MB anyway. The compression is what makes the feature work on the connection it was built for.
1600px still resolves a flooded excavation, a cracked weld or a delivery note; it does not resolve a
serial number, and if that turns out to matter the number goes up rather than the limit coming off.

**The camera, not the gallery.** Evidence for a delay claim should be a photograph taken now, and
offering the library invites a picture of something from last month.

**⚠️ The bytes are fetched into a `Blob` immediately.** Capacitor hands back a `webPath` pointing at
a temporary file the OS is free to clean up — which for a photo that may sit in an offline queue for
days is a guarantee of losing it. IndexedDB stores a `Blob` natively; base64 in `localStorage` would
be a third larger, synchronous, and capped low enough that one site photograph fills it.

**The evidence id is written back into the queue the moment an upload succeeds.** Without that, a
queued update whose photograph landed and whose write then failed would re-upload on every flush —
**one orphan blob per retry, accumulating fastest for exactly the phone with the worst connection.**

### What the harness can and cannot prove here

Capacitor's camera cannot open in a desktop browser, so `main.stub.ts` swaps **one call** for a
deterministic PNG. Everything downstream is the shipped code: the `Blob`, the preview, the upload,
the queue, the survival across a reload, and the upload-before-write ordering on both the first
attempt and the replay.

That seam is the same one the harness already used for authentication, and it sits in the stub entry
point which is never deployed. **What it cannot prove is that a phone's camera opens at all** —
which is Epic E4's standing limit rather than a gap in the harness, and the reason the APK now
matters: the code is at least installable on a device by hand.

### ⚠️ The harness was testing the wrong process

The camera assertions failed with `No stub for /api/v1/milestones/d1/evidence` — a route that
plainly existed in `verify/stub.mjs`. It existed in the *file*; it did not exist in the *process
answering*, which was a stub left running by an earlier debugging session.

Node's default made it invisible: the new stub emitted `EADDRINUSE`, died quietly, and the old one
carried on serving. The drive script connected, got sensible answers to everything the old stub knew
about, and failed only on the one route that was new.

`run.mjs` now refuses to start on a taken port and says why. **A test harness that silently tests
a different build than the one you just made is worse than one that does not start** — it produces
failures that point at the code you just wrote, which is the last place the problem is.

## Sprint 12 close — native capabilities ✅

**32 of 32 points**, and the sprint's shape was set by two stories refusing to be what their outlines
said. MC-423 was "biometric unlock" and became a privacy screen, because a biometric would have
guarded a screen while the token sat in webview storage beside it. MC-422 was "GPS site
verification" and became "record where the update was taken", because verification needs a site
boundary that nothing in this platform has.

**Neither was scope being cut.** In both cases the outline described something that could not
honestly be built yet, and the half that *could* be built is genuinely useful — a task-switcher that
no longer leaks a client's schedule, and a trail that can tell "done" from "done from the car park".
What was left out is written down as MC-425 and MC-426 with the reason, rather than quietly shipped
as a thinner version wearing the original name.

### The pattern this sprint kept hitting

Four separate times, a red test or a failed build pointed somewhere more interesting than where it
was aimed:

| Aimed at | Actually found |
|---|---|
| The APK not building | Two causes, neither the one the status had claimed for eight sprints — and one hidden *behind* the other |
| A dangling evidence id | An over-broad catch blaming the reason code for every integrity violation |
| Fixing that catch | **A forgery route**: evidence uploaded against one milestone could be cited by an entry on another |
| The privacy cover not staying up | Two listeners reading different properties for one concept, with the platform's own shim undoing the app |

⚠️ **And the harness made the same class of mistake I had just written up.** `run.mjs` announced
"is the port already in use?" when the stub had died of a syntax error — one cause out of several,
stated confidently, sending the search to exactly the wrong place. It reports the stub's exit code
now. **A diagnostic that guesses is a diagnostic that lies eventually**, and it does not matter
whether it is a catch block or an error message.

### Carried out of Sprint 12

| Item | To | Why |
|---|---|---|
| **MC-425** site coordinates and radius | ~~Sprint 15~~ ✅ **done in 14** | ⚠️ **Wrong for the same reason as MC-338**: `project` is a milestone-service table, so the boundary was never the templates service's to hold. *(original)* Verification needs a boundary, and a boundary is planner data |
| **MC-426** biometric reveal | **later · Shipping** | It needs a third-party plugin and it only becomes a security control once the token is in Keychain/Keystore. It should land in the same change as secure storage, not before it |
| **MC-215** tracing instrumentation | **Sprint 17** | Unchanged: tracing that cannot be observed cannot be verified |

**Backend: 168 tests green**, twelve of them against Azurite over the real Blob API. **Field: 75
browser assertions**, plus an installable APK for the first time in the project's life.

⚠️ **What none of it proves.** Camera, GPS and the privacy cover are all written against Capacitor's
web fallbacks and driven in a desktop Chromium. That exercises the logic, the queue, the ordering,
the permission-denied paths and the UI — **and nothing behind a plugin**. A camera that never opens
on a real phone, a GPS that returns a cached fix, a cover that arrives after the snapshot: none of
those are reachable from here. The APK narrows it for Android by making the code installable by
hand; it does not close it, and Epic E4's standing risk is unchanged.

### ⚠️ What this sprint cannot prove

Everything here is written against **Capacitor's web fallbacks** and driven by `npm run verify` in a
desktop Chromium. That exercises the logic, the queue, the permission-denied path and the UI — and
**nothing behind a plugin**. A camera that never opens on a real phone, a GPS that returns a
cached fix, a biometric prompt that behaves differently on a locked device: none of those are
reachable from here.

The APK job above narrows this for Android specifically — the code now at least *compiles into an
installable artifact* — but installing it on a device is still a thing a person does by hand. That
gap is the standing risk in Epic E4, and it is not closed by this sprint.

---

# Epic E5 — Activity and real-time · Sprints 13–14

**Goal:** a Field update on a phone appears live on a PM's laptop — something `BroadcastChannel` never could.

| Sprint | Focus | Key stories |
|---|---|---|
| **13** | Event feed | `activity-service` + own database · Kafka consumer · activity feed API · per-user notification read state (replacing `localStorage['mc.notif.seen']`) |
| **14** | Push | Transactional outbox → **Web PubSub** for web · **Notification Hubs → APNs/FCM** for mobile when backgrounded · at-least-once + client dedupe · toast and bell wired in all apps |

---

# Epic E6 — Templates service · Sprints 15–16

| Sprint | Focus | Key stories |
|---|---|---|
| **15** | Library | ✅ **Built in Sprint 14.** `template-service` + own database · list / read / create / save / copy · tree-grid persistence as a whole document with `If-Match` · **counts derived from the rows by the database**, so the prototype's bug (every card opened the same starter and claimed a different size) is impossible rather than fixed. Contract **1.0.0**, 28 tests. `mc-templates` rewired: 41 browser assertions against a stub of it |
| **16** | Instantiate | ⬜ "Create project from template" as **one idempotent bulk call** to `milestone-service` · offsets resolved against a work calendar · all-or-nothing semantics. The button is present in the editor and **disabled with the reason in its tooltip** — not a button that opens the editor again, which is what the prototype did |

---

# Epic E7 — Identity service · Sprint 17

✅ **Partly built in Sprint 13, ten sprints early** (MC-701/MC-702). Not opportunism: it was the
only thing standing between the platform and showing a person's name anywhere, and the audit
trail had carried actor ids with nothing able to resolve them since Sprint 6.

**Goal:** authorization becomes a platform concern, so a fourth consumer is possible.

| Story | |
|---|---|
| `identity-service` with its own database | ✅ **Built.** `app_user`, contract 1.0.0 pinned, 18 tests |
| JIT user provisioning from Entra | ✅ **Built.** On any authenticated request, not just `/me` |
| Batch id → name resolution | ✅ **Built**, and consumed by `mc-dashboards` in both the bell and the audit trail |
| **OAuth scopes alongside roles** | ⬜ Not built. Authorization still reads Entra app roles from the token |
| `client_credentials` for machine consumers | ⬜ Not built. No machine consumer exists |
| `user_project_role` | ⚠️ **Deliberately not built** — nothing consults a per-project role, so it would be a second source of truth nobody reads. The same reasoning that parked MC-214 |

⚠️ **What was built answers "who is this", never "may they".** The service validates its own
token despite the gateway having done so, because every service is reachable directly on its
own port and this is the one whose answers others will be tempted to trust. Making it an
authorization authority is the unbuilt half, and it is the half that needs the scopes above.

**MC-701 is the acceptance test for the whole platform thesis.** If onboarding a consumer needs a core change, a seam is missing.

**MC-701 is the acceptance test for the whole platform thesis.** If onboarding a consumer needs a core change, a seam is missing.

---

# Epic E8 — AI service · Sprints 18–20

⚠️ **Deliberately late.** The classifier learns from the audit trail, which only exists once real crews have been capturing reasons for months. Shipping this in Sprint 6 means training on 32 seeded rows.

| Sprint | Focus | Key stories |
|---|---|---|
| **18** | Foundations + eval | FastAPI service · Kafka consumer · Claude on Microsoft Foundry · **eval set built from the audit trail** (before any prompt tuning) · per-feature cost metrics |
| **19** | Suggest + narrate | Reason auto-suggest in the capture modal — **suggestion only, human confirms, human's choice is what's recorded** · weekly executive narrative |
| **20** | NL query + cost | Natural-language query via **tool use over existing endpoints** (no RAG, no vector store — the API is the retrieval layer) · prompt caching · effort tuning · budget alerts |

---

# Epic E9 — Integration · Sprints 21–22

| Sprint | Focus | Key stories |
|---|---|---|
| **21** | Inbound | Camel 4.20 service · SFTP poll of P6 exports · XER/XML parse and map · **idempotent consumer** (a re-applied export must not double-write the audit log) · dead-letter route |
| **22** | Outbound | Push changes to P6/ERP · weekly Excel export to the client's SFTP · Teams/email notifications · **webhooks with HMAC signatures** for third parties who can't consume Kafka |

---

# Epic E10 — Production hardening · Sprints 23–24

| Sprint | Focus | Key stories |
|---|---|---|
| **23** | Reliability | Prod environment via Bicep · backups + **a restore drill actually performed** · alerts on outbox lag, 5xx, cost · runbook |
| **24** | Scale + security | k6 load test at **5,000 milestones** (the PM tree renders unvirtualized — expect to add CDK virtual scroll) · security review · penetration test of the gateway · deprecation policy published |

---

## Cross-sprint risks

| Risk | Sprint it hits | Mitigation |
|---|---|---|
| ~~Apple enrolment not started~~ | ~~12~~ | **Retired 2026-08-24** — enrolment moved past all epics, Sprint 12 unblocked by splitting writing from shipping |
| **Native-only defects invisible until the first device run** | whenever shipping happens | Accepted, not mitigated. The `mc-field` web CI compiles the code and exercises its logic; nothing exercises Capacitor plugins until real hardware. Expect that run to find more than it otherwise would |
| Fitness functions skipped as "not user value" | 5 | They are the sprint goal — no demo, still non-negotiable |
| Shared domain library created "just for DTOs" | 6–8 | MC-212 fails the build |
| Screen-shaped endpoints in the core API | 9 | Aggregation goes in a BFF |
| **A client re-implements a rule the server owns** | 9–10, then every new client | Held four times, **missed once**. Held: `bizDays`/`ragOf` kept off the design system, the client status calculation deleted in MC-334, the reason catalogue served in MC-344, the note rule moved into `reason_code`. Missed: **MC-427**, for twelve sprints. ⚠️ **The audit looks for logic a client should not have, and MC-427 was logic a client legitimately has, fed the wrong number** — a preview `ragOf` is correct to exist and was correct in every line except where its tolerances came from. The audit question has to be "where does each input come from", not only "should this code be here". **The ArchUnit rule that forbids this cannot see TypeScript** |
| **A second consumer needs a core change to be onboarded** | 10, rehearsed for 17 | Sprint 10 is the dry run for MC-701. Anything Field needs that `mc-dashboards` did not is a seam that was missing; `?owner=` is the first one found |
| AI built before data exists | 18 | Epic ordering; needs ~6 months of real captures |
| Token spend unmonitored | 19–20 | Cost metrics ship *with* the first feature, not after |

---

## What to do first

*Written before Sprint 0. Kept for the record; see "Where things actually stand" below for the current position.*

~~**Sprint 0, today.** It's 8 points, most of it waiting on other people, and **MC-004 is the only item in this entire plan with a multi-week external lead time.** Start it before you write a line of code.~~

Then Sprint 1 — extracting the design system needs no backend, no Azure, and no decisions you haven't already made.

---

## Sprint 13 opens · 2026-09-07 — MC-427, and the documents reconciled

No sprint work. The four planning documents were checked line by line against what twelve
sprints actually built, and annotated rather than rewritten — ✅ where the code matches, ⚠️
where it does not, with the reason for each difference. The discarded option is usually the
more useful half of the record, so nothing was quietly corrected into looking right.

| Document | State |
|---|---|
| `platform-architecture.md` | Reconciled. New §0a as-built table, §0b **three** named gaps, §10a object storage, §9 version-gate reasoning, §4b corrected (the web build exists) |
| `backend-architecture.md` | Reconciled end to end — §1, §2, §5, §6, §8, §10, §11, §12, §15, §16, §20 |
| `azure-deployment-plan.md` | Reconciled — §2 delta table, §4 migrations, §10 resources, §11 cost, §13 roadmap scored, §16 decisions scored |
| `concept-v5.md`, `competitive-landscape.md` | Written 2026-09-06 |

**Four things the reconciliation found that the code alone did not say.**

**⚠️ A new defect: both front ends hardcode the RAG thresholds.** `THRESHOLDS = { amber: 3,
red: 10 }` is a module constant in `mc-field` and `mc-dashboards`, used to preview a date's
colour before the user commits. The server sends `amberThreshold` and `redThreshold` on every
project tree and **neither client reads them**. Any project not on 3/10 sees a preview that
disagrees with the server, on the one screen whose job is to show how bad a slip is. It
survived twelve sprints because **the verification fixture also uses 3 and 10** — the same
shape as the `yearMarks` defect in Sprint 11. A fixture that shares a constant with the code
cannot test that constant. **This is the fifth time a client re-implemented a rule the server
owns**, and the first one the cross-sprint risk register did not catch — because the audit
looks for *logic* a client should not have, and this is logic the client legitimately has,
fed the wrong number.

**⚠️ The endpoint catalogue was materially wrong.** It documented four paths that do not exist
(`POST /projects/{p}/milestones`, `/mark-done`, `/log`, `/rebaselines`) and omitted eight that
do, including all of evidence and the whole calendar. It also had the prefix wrong: `/api`,
not `/api/v1`. Anyone integrating from that document would have failed on their first call.

**✅ The impact query is better than its design, and the design was subtly wrong.** The plan
specified `UNION` plus a depth guard for cycle protection. `UNION` de-duplicates whole rows,
and the rows carry a depth — so a cycle produces distinct rows and walks until the depth
limit, doing exponential work first. The built version carries a path array and refuses to
re-enter a node. The document now says so, because the plausible-but-wrong version is the one
someone would otherwise reintroduce.

**⚠️ The cost estimate's stability was a coincidence.** Prod moved from ~€140 to ~€125–160
only because dropping the unbuilt Web PubSub (−€45) nearly cancelled the extra container apps
the service split requires (+€45–70). Build real-time in Sprint 13 as planned and it goes to
**€170–205**. That is the figure to quote when anyone asks whether decomposition paid.

One more thing worth stating plainly: **Phase 5 (real-time) was estimated at one week and has
sat untouched at the top of the backlog for twelve sprints without anyone needing it.** Clients
refetch and nobody has complained. That is the best evidence available that it is a feature to
sell rather than a feature to run on, and Sprint 13 should scope it in that light.

---

### MC-427 — the preview is coloured by the project, not by a constant · 3 pts · ✅ **Done**

| | | | |
|---|---|---|---|
| **MC-427** | As **any user**, the colour on a date I have not yet committed to uses **my project's** tolerances, so the preview and the server agree. | 3 | ✅ **Done** — fixed in both clients, and the fixtures moved so the harness can see it |

**What was wrong.** `THRESHOLDS = { amber: 3, red: 10 }` was a module constant in both
`mc-field` and `mc-dashboards`. The server sends `amberThreshold` and `redThreshold` on every
project tree read; neither client read them. `mc-dashboards` had even built the plumbing —
`ProjectStore.thresholds()` existed, with a doc comment two files away pointing at it — and
**had zero readers**. The constant was simply the shorter path.

**What was done.**

| Change | Where |
|---|---|
| Deleted `THRESHOLDS` | both `core/data.ts` |
| **Removed `ragOf`'s default parameter** so `t` is required | both `core/data.ts` |
| Added `thresholds` computed | `FieldStore` (it had none) |
| Pointed the preview at it | `field.component.ts`, `reason-modal.component.ts` |
| Replaced the store's own `{ amber: 3, red: 10 }` fallback | `ProjectStore` — the same constant, one layer down |

**Removing the default is the actual fix.** Deleting the constant would have left the next
call site free to invent another; a required argument means a new caller cannot compile
without deciding where its tolerances come from, and there is exactly one correct answer.
That is the same move as MC-344's refusal to keep a fallback reason list, applied to a value
that had escaped the same reasoning — the argument was already written forty lines above the
bug, in the same file.

**The fixtures were the reason this survived twelve sprints**, so they changed too:

| Harness | Was | Now | A 4/10-day slip |
|---|---|---|---|
| `mc-dashboards` | 3 / 10 | **8 / 12** — a tolerant project | was amber → now **green** |
| `mc-field` | 3 / 10 | **2 / 8** — a strict project | was amber → now **red** |

Deliberately in **opposite directions**. A client that merely swapped one hardcoded pair for
another would pass one harness and fail the other; only reading the project's own numbers
passes both.

✅ **Both assertions were confirmed to fail against the old code before being accepted** —
reverted to the constant, rebuilt, watched them go red (`var(--amber-bg)` in both), then
restored. A test that passes before and after the fix proves nothing, and this defect is the
second in three sprints to hide behind a fixture that agreed with it.

| | Before | After |
|---|---|---|
| `mc-field` browser assertions | 75 | **77** |
| `mc-dashboards` browser assertions | 39 | **41** |

Production builds clean in both apps.

---

### Sprint 13 — the activity feed · Epic E5 opens

| Story | | Pts | State |
|---|---|---|---|
| **MC-427** | The preview uses the project's thresholds | 3 | ✅ **Done** |
| **MC-342** | The activity feed and the notification bell show real platform events | 3 | ✅ **Done** — and **without `activity-service` or Kafka**; see below |
| **MC-343** | The exec numbers reflect a change a PM just made, without a reload | 3 | ✅ **Done** — pulled forward from Sprint 14 |
| **MC-214** | A schema registry with backward-compatibility enforcement gates every event-schema change | 5 | ⚠️ **Parked again — fourth time, and now against a trigger instead of a sprint** |
| **MC-501** | `activity-service` with its own database | — | ⚠️ **Re-open against a trigger, not a date** — the first event `milestone-service` does not already store |
| **MC-502** | Kafka as the event backbone; `milestone-service` produces | — | ⚠️ **Same** — nothing consumes an event across a service boundary yet |

### MC-342 — the bell, filled · 3 pts · ✅ **Done**

Empty since Sprint 9, and honestly so. It now reads
`GET /api/v1/projects/{id}/activity` — **contract 2.6.0**.

**⚠️ The story was delivered without the two things the epic said it needed.**
E5 called for `activity-service` with its own database and Kafka as the event backbone.
Neither was built, and the argument for not building them is the same one every other
decision in this codebase has made: **the activity feed *is* the audit trail.**
`milestone-service` already owns it, already writes it in the same transaction as the change,
and already guarantees it immutable. A second service holding a copy would be a second read
path over the same facts — and it would be *eventually consistent* with a trail whose entire
value is that it is not. Kafka is not needed to read a table.

**`activity-service` earns its existence when there is an event `milestone-service` does not
already store** — comments, assignments, document uploads. That is a real future, and it is
not this sprint. MC-501 and MC-502 are therefore **not deferred, they are unjustified as
written**, and should be re-opened against that trigger rather than a date.

| Decision | Why |
|---|---|
| Fetched on **open**, not pushed | §13 of the deployment plan: real-time was a one-week estimate that sat untouched for twelve sprints while clients refetched and nobody complained |
| … **and on load** | A badge that only becomes accurate once you have opened the bell is not a badge |
| Two lists from the server, merged in the client | The server keeps a date change and a re-baseline apart because they are different acts; the flattening belongs at the one consumer that wants a timeline |
| **No captured position in the response** | A feed row says what changed and who changed it. Sending coordinates to every reader of a project-wide feed would widen who can trace a person's movements far past the drawer built to show them |
| **No `actor` rendered** | The API sends an identity-service id and nothing resolves it until Sprint 17. A raw UUID beside "slipped 4 days" is worse than silence, and an invented name is worse still |
| A deleted milestone's activity leaves the feed | Its rows stay in the database — the trail outlives the milestone — but every other endpoint treats it as absent, and one that disagreed is how a client discovers deleted work exists |

**Two things caught before they shipped.**

⚠️ **A schema collision.** springdoc names a schema after a record's *simple* name, so
`ProjectActivity.Rebaselining` would have collided with `MilestoneHistory.Rebaselining` and
produced a contract in which one silently described the other. Renamed to `ActivityChange`
and `ActivityRebaseline`. **Nested-record names are API surface on this project**, which is
not obvious from the Java and is now written down in `OpenApiConfiguration`.

⚠️ **A stray separator in the design system.** The activity row rendered
`{{ source === 'field' ? 'Field' : actor }} · {{ ago }}`, and with no actor Angular renders
an empty string — so a PM-sourced row read "· 12m ago". Fixed in `mc-design-system`, which
**ships on that package's next release, not with this story**: it is consumed as a published
package, so the harness still runs against the old build. Recorded here so it is not
rediscovered as a defect.

| | Before | After |
|---|---|---|
| `mc-milestone-service` tests | 168 | **177** (read from the CI log, not carried forward) |
| `mc-dashboards` browser assertions | 41 | **52** |
| Contract | 2.5.0 | **2.6.0** — additive; a 2.5.0 client keeps working having never called it |

✅ CI green on the first push, **including `OpenApiContractTest`** — the hand-patched baseline
matched what springdoc generated, which is the half of a backend change that cannot be checked
on this laptop.

---

### MC-343 — the exec numbers move when a write lands · 3 pts · ✅ **Done**

`GET /summary` was fetched once per load and never again, so **every write left the executive
screen showing counts the server had already superseded** — done, missed, at risk, days lost
by reason, worst exposure, the headline slip. The segment control swaps components without
reloading, so a PM could record a slip, flip to the exec view, and read last hour's numbers
with nothing on screen suggesting they were old.

**This story was waiting on a decision, and MC-342 made it.** It was deferred to Sprint 14
"where the push channel is built and the choice is actually available", because refetch,
refresh-on-view and push were three answers and picking the cheapest early would prejudge it.
The push channel is not being built. So the choice collapsed to two, and refetch wins:
refresh-on-view still leaves a window where the screen is knowingly wrong, and the exec screen
is the one people quote numbers out of.

**Refreshed after every successful write, including a rename.** Being selective would mean the
client deciding which fields feed which aggregate — whether `critical` affects the exposure
list, say. That is the server's model, and a client holding a copy of it is exactly MC-427.
One small request on an action a human deliberately took is a cheap price for never having to
be right about that.

⚠️ **It is not a push channel and must not be read as one.** It refreshes after *your* write.
A sponsor watching the exec screen while somebody else records a slip still sees nothing. That
remains the only genuinely push-shaped case on this platform — far narrower than "live sync
across web and mobile" — and it is still unbuilt.

The stub had to change too: it now answers with different aggregates once a write has landed.
Without that it would return the same numbers before and after, and **the assertion would have
passed against the stale client the story exists to fix** — the same fixture-agrees-with-the-bug
trap as MC-427 and MC-341. ✅ Confirmed failing first: `+4` where `+41` was due.

| | Before | After |
|---|---|---|
| `mc-dashboards` browser assertions | 52 | **55** |

---

### MC-430 — the gateway was hiding three unreachable endpoints · ✅ **Done**

Found while starting B14, and it outranks everything else in this sprint.

The gateway's route predicate enumerates path prefixes. Three of the service's paths matched
none of them:

| Path | What it does | Consequence |
|---|---|---|
| `/api/v1/reason-codes` | The delay-reason catalogue | **The reason picker offers nothing.** MC-344 deliberately removed the local fallback list, so there is nothing behind it |
| `/api/v1/evidence/{id}` | Photograph metadata | Uploaded evidence unreadable |
| `/api/v1/evidence/{id}/image` | The bytes | Same |

The evidence asymmetry is the part worth remembering: **the upload sits under `/milestones`
and was routed, while the read has its own prefix and was not.** A crew lead could photograph
a slip, watch it upload successfully, and nobody could ever open it.

**Nothing had ever exercised these.** Nothing is deployed, and both browser harnesses drive a
stub directly rather than through the gateway — so the gap was invisible from both sides at
once. This is the third routing omission in the same list (calendars was the first, found by
hand), and the failure mode is the nastiest available: **the service works perfectly when
called directly and 404s at the edge.**

`GatewayRoutingTest` now applies each route's predicate to a mock exchange for every path in
contract 2.6.0. ⚠️ **Its limit is written into the test:** the path list is a *copy* of the
contract, so it catches a path that is known there and unrouted, and cannot catch one added to
the service that nobody added to the list. Closing that properly means the gateway build
reading the service's published contract, which is CI work across two repositories and is not
done.

---

### MC-701 — `identity-service`, built out of order · ✅ **Done**

E7 was Sprint 17. It was built on 2026-09-07 because it was the only thing standing between
this platform and showing a person's name anywhere at all, and because the two options I put
up were not equal: **`activity-service` had been asked for twice and had no job either time**,
while identity had a payoff nobody could work around.

**The fourth service, and the first built because something visible was missing** rather than
because a plan listed it.

| | |
|---|---|
| `GET /api/v1/me` | The caller's profile, provisioned on first sight |
| `GET /api/v1/users?ids=…` | **Resolve a batch of ids to names** — the endpoint the platform came for |
| `GET /api/v1/users/{id}` | One profile |
| | **No write surface at all** |

**The primary key is the Entra `oid`, and that is why nothing had to be migrated.**
`milestone-service` has been writing that exact value into `owner_id` and `actor_id` since
Sprint 6, so every existing audit row already points at this table. A surrogate key would have
needed a mapping table and would have left every historical row referring to something this
service could not resolve — **failing silently, as missing names rather than as an error**.

**No write surface is a decision, not an omission.** Every field is a copy of what a token
said and Entra is the system of record; an endpoint to override it would create exactly the
disagreement the service exists to avoid. The fix for a stale name is for its owner to sign in
again.

**Provisioning happens on any authenticated request, not inside `/me`.** Putting it in `/me`
is cheaper and fragile: it makes a user's existence depend on a client remembering one call,
and the consequence of forgetting is not an error but an **absence** — a name missing from an
audit trail six weeks later.

⚠️ **`user_project_role` is not built**, though §6 names it as this service's. Authorization
reads Entra app roles from the token, so a per-project role table would be a second source of
truth nothing consults — **the same ceremony MC-214 was parked for**, and it would have been
easy to build it here simply because the architecture diagram has a box for it.

#### MC-702 — and the names appear on screen · ✅ **Done**

`identity-service` was infrastructure until something consumed it. `mc-dashboards` now
resolves the actor ids in both places that carry them: **the notification bell** and **the
drawer's audit trail**, which has printed the literal words "unresolved user" since MC-339.

**One request per screen, not one per row.** `IdentityStore` batches every id out of the feed
or the trail into a single `GET /users?ids=`, caches what comes back, and caches *unknown*
ids as unresolved so a departed user is asked about once rather than on every render.
`actorName()` in the template stays a pure lookup for exactly that reason: making it fetch
would reintroduce, across a service boundary, the N+1 this screen has already acquired twice.

⚠️ **A missing name is never an error, and that is the whole design.** Nothing in the compose
file `depends_on` identity-service, and the client mirrors it: if identity is down, slow, or
has never heard of somebody, every screen renders exactly as it did before the service
existed. **A store that threw would turn an optional service into a required one by
accident** — which is how a platform acquires an outage it never designed for. The harness
asserts it directly: with identity returning 503, the feed still lists every entry, shows no
error, and simply names nobody.

**One existing assertion changed rather than being deleted.** "the actor is not dressed up as
a name" tested for the literal "unresolved user" — the right claim when nothing could resolve
anything. The claim it was *really* making survives: never a raw id dressed up as initials.
That is what it asserts now, and the unresolved case kept its own assertion. Worth noting as a
pattern: **a test that fails because a feature arrived is usually asserting the right thing in
an expired way.**

⚠️ **The stub crashed mid-suite and the symptom was a lie.** The dashboards stub keeps only the
path in `url`, unlike `mc-field`'s which destructures path and query; copying the shape rather
than reading it left an undefined `query` and took the process down. What the harness showed
was an *unrelated write test* hanging on a sheet that never closed. **A dead stub does not
announce itself — it makes the next assertion lie**, which is the same lesson as the stale
stub in Sprint 12, arriving by a different route.

| | Before | After |
|---|---|---|
| `mc-dashboards` browser assertions | 55 | **64** |

⚠️ **`mc-field` is not wired.** Its list shows only the signed-in user's own milestones, so
every actor on its screen is the person holding the phone — there is nothing to resolve. That
is a real reason rather than an omission, and it changes the day Field shows anyone else's
work.

---

#### Three CI rounds, and what each one was

CI is the only compiler this project has, so the sequence is the record:

| Round | Result |
|---|---|
| 1 | Compiled, ArchUnit 3/3, **5 HTTP tests failed** |
| 2 | **14 of 15**, one real defect |
| 3 | **15 of 15**, image build failed — no `Dockerfile` |
| 4 | ✅ Green |

**Round 1 was my mistake, and the evidence named it exactly.** Every failing test used a
fixture name containing a space; the two whose names were single words passed. A Bearer token
is `token68` (RFC 6750), grammar `[A-Za-z0-9-._~+/]` — a space means Spring extracts *no token
at all* and the request arrives anonymous, so the symptom is a 401 that reads as broken
authentication rather than as a malformed fixture. `mc-milestone-service` already records the
other half of this lesson, about `@` in the separator. **I read that comment, followed its
advice about the separator, and then put spaces in the very names it was warning about.**
`+` now stands for a space and the decoder puts it back.

**⚠️ Round 2 was a real design flaw, and the test earned its keep.** The provisioning cache
was a `Set<UUID>`, so once a user had been seen nothing about them was ever read again — a
person who changed their name in Entra would keep the old one on every screen until a
deployment happened to restart the process. I had written that weakness into the class javadoc
*as a feature*: "a restart re-provisions each active user once, which keeps the copy fresh".
It is only true if restarts are frequent, which is not something a correctness property may
depend on. The cache is now keyed on the whole claims record, so a rename is a miss and
propagates on the next request.

**Note what caught it: every test that provisioned a user once passed.** The failing test
provisioned the same user twice with different claims, which is the only shape that can see
it. **Second time on this project a defect survived because a fixture exercised a single
pass** — MC-427 was the first, and both were found by making the fixture vary rather than by
reading the code.

| | |
|---|---|
| `mc-identity-service` | **18 tests** · contract 1.0.0, pinned · image published |

✅ **Both caveats closed.** `mc-dashboards` consumes the names (MC-702, above), and the
contract is pinned (below).

#### The contract, pinned · ✅ **Done**

This service shipped without an `OpenApiContractTest`, which was the clearest inconsistency
on the platform: `mc-milestone-service` cannot change its published contract without somebody
committing the change, and this one could change it silently. **Size was the wrong reason to
skip it** — a service with three endpoints has three endpoints somebody is about to depend
on, and `mc-dashboards` already did by the time it was noticed.

**The baseline came out of CI, not off this laptop.** The test writes the generated spec to
`target/openapi.json` and fails when no baseline exists; `java-service.yml` uploads that file
as an artifact for exactly this purpose. So the sequence was deliberate: push a commit that
**is expected to fail**, `gh run download` the spec, commit it, push again. ⚠️ Hand-writing
the baseline is how `mc-milestone-service`'s went wrong repeatedly before this path existed —
springdoc emits details no human predicts.

Two assertions beyond the comparison, and both guard against a failure the baseline check
cannot see on its own:

| | |
|---|---|
| `/users` and `/me` are present | **A technically valid empty spec is exactly what a baseline check would happily pin forever**, and it would stay invisible until a consumer generated a client from it and found nothing |
| ⚠️ **No non-GET method exists anywhere** | This service is read-only by design. *"Add a small PATCH to fix a name"* is a reasonable-sounding request that quietly makes it a second source of truth about who somebody is — so the refusal is pinned rather than left to a code review |

Checked before committing rather than trusted: the `servers` block is stripped (it carries a
random test port and would fail the next run for a reason unrelated to the contract), and
`ids` is an array of uuids — the shape `mc-dashboards` actually sends.

---

### The prefix guard — closing MC-430's residual risk · ✅ **Done**

`GatewayRoutingTest` could not close this on its own, and saying why is the useful part: its
path list is a **copy** of the contract, so it catches a path known there and unrouted, and is
blind to a path added to the service that nobody added to the list. Reading the real contract
from the gateway's build needs cross-repository access that a default CI token does not grant
to two private repositories.

**So the check went where the change is made.** `GatewayPrefixContractTest` lives in
`mc-milestone-service`, reads the committed contract, and fails **in this repository, in the
commit that caused it**, if an endpoint introduces a path prefix the gateway has never heard
of — naming the prefix and the three places to add it. The duplication is five strings rather
than nineteen paths, and **a new prefix is precisely the event behind all three bugs**.

It asserts in both directions: a prefix nothing serves any more is flagged too, because a list
maintained in only one direction stops being trustworthy.

⚠️ **Neither test is sufficient alone.** This one cannot verify the gateway *actually* routes
anything — only that no new prefix appeared. Someone deleting a predicate over there is caught
by the gateway's test, not this one.

The matcher mirrors Spring's `PathPattern` rather than using `startsWith`, because
`<prefix>/**` matches the bare prefix too. **I made exactly that mistake while analysing the
original bug** and briefly believed five paths were broken instead of three.

---

### ⚠️ Priorities 2 and 3 are blocked by the same boundary — and it is a real decision

Working the risk list in order stopped at #1, and not for lack of time.

| # | Item | Status |
|---|---|---|
| 1 | **B14** | ✅ Done (bar caching, argued away) — plus MC-430 and the prefix guard |
| 2 | **JIT user provisioning** | 🚫 **Blocked by design** |
| 3 | **Server-side notification read state** | 🚫 **Blocked by the same thing** |

`V1__baseline.sql` opens by stating where these tables live, and it is unambiguous:

```
--  1. app_user, user_project_role       -> identity-service  (identity_db)
--     activity_event, notification_read -> activity-service (activity_db)
--     template, template_row            -> template-service (template_db)
--     None of them appear here.
```

**JIT provisioning writes `app_user`. Read state writes `notification_read`.** Neither table
exists in `milestone-service` and neither is supposed to. Building them here would not be a
shortcut — it would contradict the decomposition the entire schema is designed around, in the
one repository that has so far honoured it perfectly.

Note this is **not** the MC-342 situation. There, `activity-service` was unnecessary because
`milestone-service` already owned the facts. Here it is the opposite: **a user's identity and a
user's read state are genuinely not milestone data**, and no amount of looking will find them
already present.

So the trigger that parks MC-214, MC-501 and MC-502 has now caught two more items, and the
decision it defers is getting larger. Three options, and it is a product call rather than an
engineering one:

| Option | What it costs | What it buys |
|---|---|---|
| **Build `identity-service`** (E7, ~20 pts) | A fourth deployable, out of epic order | Names in the audit trail and the feed, JIT provisioning, ownership assignment, B2B guests |
| **Build `activity-service`** (E5) | A fifth deployable | Read state — and it would still have nothing else to do, since the feed does not need it |
| **Neither yet** | Names stay absent; the bell's watermark stays per browser | Nothing new to run, and both remain honestly documented as absent |

⚠️ **Worth weighing against §11's evidence.** Real-time was estimated at one week and went
thirteen sprints without being missed. Identity is not in that category — a platform where
nobody has a name has a ceiling on how far it can be demonstrated — but read state plausibly
is. **`identity-service` is the one with a real user-visible payoff; `activity-service` still
does not have a job.**

---

### B14 — the platform can now refuse, time out, and fail honestly · ✅ **Mostly done**

§20 of the backend architecture called B14 "the largest genuine risk in this document". Three
of its four parts are built; the fourth is argued away below.

| Part | State | |
|---|---|---|
| **Rate limiting** | ✅ Built | Write-only, at the gateway |
| **Timeouts** | ✅ Built | There were none at all |
| **Resilience** | ✅ Built | Circuit breaker + an honest fallback |
| **Caching** | ⚠️ **Deliberately not built** | See below |
| Observability | ⚠️ Actuator only | Tracing is MC-215, Sprint 17 |

**Rate limiting — the burst is sized for an offline replay, not for a click.** That single
constraint sizes the whole thing. `mc-field` queues writes with no signal and sends the lot
when coverage returns, so a crew lead out for a shift legitimately arrives with dozens at
once. A limiter tuned for a person clicking save would reject exactly the traffic the offline
story exists to protect — at the worst possible moment, after the work is done, when the phone
is finally handing it over. Default: burst 40, sustained 60/minute, writes only.

Two things that would have made the limiter the bug rather than the fix:

- **Actuator is excluded.** Container Apps restarts a container whose health probe fails, so a
  limiter able to answer 429 to `/actuator/health` turns a busy minute into a restart loop —
  and the symptom looks like anything but a limiter. The version gate learned this the same way.
- **The bucket map is swept.** One entry per caller, never removed, is unbounded growth driven
  by whoever is calling: **the limiter would itself be the denial of service.** Eviction drops
  only *full* buckets, which is safe because a full bucket and a bucket that never existed
  behave identically — so eviction can never wrongly grant capacity to someone being limited.

I wrote the bucket lock-free over a packed `long` first and **replaced it with a synchronized
one**. "Easier to be sure of by reading" was my stated argument for not taking a dependency,
and the packed version was not that.

**Timeouts — there were none.** A service that accepted a connection and then stopped
answering would hold gateway connections indefinitely: one slow dependency taking down the
single address every client has. ⚠️ Set to 30s rather than the 2–3s a JSON read deserves,
**because of the evidence upload** — a timeout tuned for reads would abort photograph uploads
from site links intermittently, and only for the users with the worst connections, which is
the hardest possible defect to reproduce. The test fails if anyone tightens it below 15s, so
the next person has to think about evidence first.

The timeout test asserts on the **bound bean, not the YAML**, and that is the point: a property
under the wrong prefix is not an error. Spring binds nothing, logs nothing, and the gateway
runs on library defaults while the file sits there looking configured. The prefix moved when
Spring Cloud 2025.x renamed the gateway artifact, so this is exactly the mistake that surfaces
as an incident where a timeout everyone believed was set had never been read.

**Resilience — ⚠️ the fallback is a 503, never an empty success.** The tempting fallback for a
read is a cheerful empty body: the client renders, nothing errors, the outage is invisible.
That is the worst thing this gateway could do. Every screen in this product exists to answer
"what is late", so an empty milestone list tells a PM their project is fine in precisely the
situation where the platform has no idea whether it is. **Looking healthy while being wrong is
the one failure this system must never have**, and a silent empty fallback is that failure
wearing a resilience pattern's name.

⚠️ **What resilience is not proven to do: open.** That needs a downstream that can be made to
fail, and nothing is deployed. The trip threshold, the half-open transition and the `forward:`
dispatch are configuration read carefully and never executed against a real outage.

**Caching — argued away rather than built.** The only cacheable thing on the platform is the
reason catalogue, and it is a handful of rows behind an index, fetched **once per session** as
part of `load()` — not per modal, as I first assumed. Caching that optimises nothing. Server
memory is not the cost; the round trip is, and a server-side object cache does not touch the
round trip. **If this is ever worth doing it is HTTP caching — `ETag` plus revalidation — so a
client can get a 304 instead of the body**, which also respects MC-344 (the server still owns
the list; the client just stops re-downloading an unchanged one). Not built, because a
platform with no load does not need it and a cache is a second copy of the truth.

| | Before | After |
|---|---|---|
| `mc-api-gateway` tests | 17 | **40** |

---

### MC-214 — parked for the fourth time, and this time properly

Moved Sprint 5 → 10 → 13, each time to the sprint that would produce the first event. Sprint 13
did not, because MC-342 showed the feed did not need one. Re-pointing it to Sprint 14 would be
the same mistake a fourth time.

**It is now parked against a trigger: the first event published across a service boundary.**
A schema registry with no schema to gate is ceremony, and three re-pointings are enough
evidence that a date is the wrong thing to attach it to. The same trigger governs MC-501 and
MC-502.

That trigger is worth stating plainly because it may never fire: if `milestone-service` keeps
turning out to already own what a new screen needs, the platform does not acquire a second
producer, and MC-214, MC-501 and MC-502 are all work that correctly never happens. **Sprint 13
is the first sprint on this project where the most valuable output was deciding not to build
three things.**

---

⚠️ **Scope this sprint against what §13 of the deployment plan just showed.** Real-time
fan-out was estimated at one week and sat untouched for twelve sprints while clients refetched
and nobody complained. The activity feed is worth building; **a live push channel is not
obviously worth building yet**, and the two are separable — a feed that is fetched when the
bell is opened needs no Web PubSub, no outbox and no client token endpoint, and it is the half
that has an actual consumer waiting. Decide that before provisioning anything.



---

## Sprint 14 opens · 2026-09-08 — MC-338, and structure without SQL

### MC-338 — a planner builds a project's structure · 5 pts · ✅ **Done**

⚠️ **The plan had this deferred to Sprint 15 as "the templates service's job", and that was
wrong.** `phase` and `work_package` are tables in **milestone-service's** database. A template is
a separate thing that *instantiates* them. Waiting for a service that does not exist, in order
to write rows this service already owns, is the same mistake MC-342 nearly made with
`activity-service` — and it had been blocking a real gap for six sprints: **a planner could not
start a project without a manual `INSERT`.**

`POST`/`PATCH` on `/api/v1/phases` and `/api/v1/work-packages`. Contract **2.7.0**.

**The story's rationale was one sentence, and the constraint that was supposed to enforce it
did not.**

> *"Piping" typed twice with different capitalisation would become two work packages, and
> nobody would notice until a report split in half.*

V1 declared `UNIQUE (phase_id, name)`. ⚠️ **It is case-sensitive**, so `Piping` and `piping`
both insert happily. **A constraint that guards something narrower than the story required is
worse than none — it reads like protection.** V10 replaces both with case-insensitive unique
indexes, and the service trims on the way in, because `"Piping "` and `"Piping"` render
identically on every screen.

The duplicate is caught **on the constraint**, not checked first with a `SELECT`. Check-then-insert
is a race: two planners adding "Piping" at the same moment both see nothing and both insert —
precisely what the story exists to prevent.

| Decision | Why |
|---|---|
| Roles are `PLANNER`/`ADMIN`, **not `PM`** | A PM moves dates and re-baselines *within* a structure. Renaming a phase changes every roll-up that mentions it |
| No sort given → goes **last** | What somebody adding a phase almost always means. Defaulting to 0 would silently reorder a plan on every addition |
| A `PATCH` with neither field is **refused** | Almost always a client bug — a form that lost its state. Answering 200 reports success for a change that did not happen |
| **No `DELETE` at all** | A phase holds packages holding milestones holding audit trails, and `ON DELETE CASCADE` answers "what happens to the work underneath" by destroying it. When somebody asks, it needs a name that says what it does to the contents |
| `StructureView`, not `Phase`/`WorkPackage` | `ProjectMilestones` already contributes both of those schema names from its nested records. **The 2.6.0 collision lesson was not a one-off** — verified in the regenerated spec: `Phase` and `WorkPackage` are still the originals |

#### The guard fired — in the right direction, twice

`GatewayPrefixContractTest` exists because three endpoints have shipped unroutable here. MC-338
introduced two new prefixes, which is exactly its trigger.

⚠️ **It did not go red, and the comment in the test now says so.** The check was run by hand
against its own list first, reported all four paths unrouted, and the gateway was updated before
pushing. **"The guard works" and "the guard fired" are different claims**, and only the first is
true here.

✅ **Its second direction did fire, unprompted.** `everyPrefixIsStillUsed` failed because
`/api/v1/phases` sat in the prefix list while the committed contract had no path using it. That
is the assertion nobody writes — a list maintained in only one direction stops being
trustworthy — doing its job on its first real opportunity.

#### The baseline came from CI again

Two expected failures on push (the contract diff, and the one above), then `gh run download`,
then green. **Hand-patching the baseline is how this file went wrong repeatedly**; the artifact
path that `identity-service` proved yesterday is now the normal way to change this contract.

| | Before | After |
|---|---|---|
| `mc-milestone-service` tests | 180 | **197** |
| Contract | 2.6.0 | **2.7.0** |

---

### MC-425 — a project's site, so a recorded position means something · 5 pts · ✅ **Done**

MC-422 shipped the honest half: the position is recorded and a human reading the trail can see
it. It could **not** say whether that position was on site, because `project.location` is free
text and no coordinate existed anywhere to compare against.

⚠️ **Deferred to Sprint 15 as "the templates service's job" — the same mistake MC-338 just
corrected.** `project` is a table in this service.

| Decision | Why |
|---|---|
| **`distance_m()` in SQL**, not Java | The V2 argument about variance: the moment two clients can each decide what "on site" means, they will disagree, and **the disagreement will be about somebody's honesty** |
| Haversine, not PostGIS | A heavy extension for one number. The question is "200 m or 40 km", not "1.02 m or 1.03 m" |
| ⚠️ **`SiteCheck` is a sibling of `Position`, not fields on it** | `Position` is what the phone reported and a client also *sends* it. A server-computed verdict living there raises the question of what happens when a client sends one — a question worth never having. Verified in the published spec: `Position` still carries exactly three fields |
| ⚠️ **Three states, never two** | `siteCheck` is null with no position *and* null with no boundary. Neither is "outside". Rendering an unconfigured project as outside would accuse every crew on it |
| The boundary is **inclusive**, rounded before comparing | A reader seeing "500 m" against a 500 m radius and a red flag would reasonably conclude the check was broken |
| A radius over **50 km is refused** | It would make every position count as on site — a green tick that means nothing, which is worse than no boundary, because green ticks that mean nothing stop being read |
| `PUT` is **ADMIN only** — tighter than MC-338's structure endpoints | Widening the radius makes every past entry compliant; moving the centre makes a crew look like they were never there. Not within reach of whoever is measured by it |

⚠️ **None of this makes a position proof.** It is self-reported by a device and trivially
spoofed, as MC-422 already recorded. A boundary turns *"here is a coordinate"* into *"here is a
coordinate, 41 km from site"* — **a question worth asking, never a verdict.**

#### ⚠️ The bug 210 passing tests did not catch

Three tests failed with `BadSqlGrammar` on `distance_m(?, ?, ?, ?)` — which reads like a syntax
error and is an **overload-resolution** one.

Postgres casts `numeric → float8` **implicitly**, but `float8 → numeric` only on **assignment**.
The columns are `numeric(9,6)`, so `numeric` looked like the obvious signature — and it works
perfectly for the production query, which passes those columns. It cannot work for *any* caller
binding a Java `Double`.

**So the function was unusable from anywhere except a numeric column, and 210 tests passed
while that was true.** The only callers that bind values directly are the arithmetic tests,
which is the argument for their existing at all: a distance function nobody checks against a
known figure will return a confident wrong answer, and every downstream verdict inherits it.
Checked against Paris–London, 343.5 km — verifiable against any external source.

⚠️ **V11 was edited in place rather than superseded.** Normally forbidden — Flyway records a
checksum and an edited migration breaks every database that already ran it. Correct here
because V11 was twenty minutes old, nothing is deployed, and the only database that had run it
was a throwaway CI container. A V12 would also have been *wrong*: `CREATE OR REPLACE` with a
different signature creates a **second overload** rather than replacing, so anyone who had run
V11 would end up with two functions and an ambiguous call.

✅ **No new gateway prefix.** Both paths nest under `/api/v1/projects/**`, unlike MC-338's flat
ones — whether an endpoint needs a gateway change depends entirely on whether it nests under
something already claimed.

| | Before | After |
|---|---|---|
| `mc-milestone-service` tests | 197 | **214** |
| Contract | 2.7.0 | **2.8.0** |

---

### The trail shows where an entry was recorded · ✅ **Done**

⚠️ **A finding first.** The dashboards client had **never modelled `position`**. MC-422 has
stored where a phone was standing since Sprint 12, and the plan said *"the position is recorded,
and a human reading the trail can see it"* — **nobody could.** The type did not carry it and the
drawer did not draw it. MC-425's `siteCheck` would have been invisible the same way. So what
looked like "render one new field" was rendering two, one of which had been dark for two sprints.

**Four states, one function.** Pre-rendered in `whereRecorded()` rather than branched in the
template, because four-way branching is exactly what a template gets wrong quietly:

| State | Rendered as |
|---|---|
| No position | *nothing* — a PM at a desk has no position and is not doing anything wrong |
| Position, no boundary | `position recorded` |
| On site | `on site · 340 m from centre` |
| Off site | `41 km from site` |

⚠️ **Off site is set apart by weight only, never by colour.** The harness reads the *computed*
colour and asserts it is not `--red-text`. Red would turn a self-reported, trivially spoofed
coordinate into an accusation on the way to the screen; the server records `siteCheck` as a
question and the trail must not upgrade it to a verdict. The wording follows the same rule — a
distance, stated plainly, no "flagged", no icon that means alarm.

⚠️ **No boundary is not "outside".** Asserted directly: the no-boundary case contains `position
recorded` and does not contain the word *site* at all, because rendering an unconfigured
project as off-site would accuse every crew on every project nobody has set up yet.

The stub drives the verdict off `historyMode` — `onsite`, `noboundary`, or the default off-site —
so four rendering states come from one fixture rather than four.

| | Before | After |
|---|---|---|
| `mc-dashboards` browser assertions | 64 | **69** |

---

### Tenancy — decided, guarded, and deliberately not built · ✅

I recommended taking `tenant_id` this sprint *"while the tables are near-empty, because it gets
harder with every row."* ⚠️ **That reasoning was imported from the option this platform should
not choose.** Full record in [`tenancy.md`](./tenancy.md); the shape of it:

| | |
|---|---|
| **What a tenant is** | A *contractor organisation*. The contractor's people and their client's engineers looking at the same project are one tenant, not two. A second tenant is a second contractor — a competitor who must never see the first one's delay reasons or claims file |
| **The key** | Entra `tid`. Already settled by a decision made elsewhere: §7 chose B2B guests in the contractor's tenant, so every user of a contractor carries that contractor's `tid`, guests included. **Signed, in every token, nothing to store** |
| **The model** | **A database per tenant**, not `tenant_id` + row-level security. The audit table is `REVOKE`d against `DELETE`; the isolation model must not be the one that asks that same table to police which rows a caller may see |
| **Why it can wait** | Under database-per-tenant, **no table and no query changes** — the retrofit cost does not grow with rows. It grows with the short list of code holding a `DataSource` outside a request: the sweeper, the startup guard, Flyway, ShedLock, compose. Five items, all additive, written down |
| **What enforces single tenancy today** | All three services pin `issuer-uri` to one tenant. A foreign token fails before any handler runs. **Enforced, not assumed** |
| **The one guard built now** | `TenantBoundaryTest` fails the build if anyone changes the issuer to `/common` or `/organizations` before the routing datasource exists — because that is exactly the one-word change that would put every tenant's users in the first tenant's database, and nothing else would fail |
| **Trigger** | The first customer outside the current Entra tenant. Not a sprint number — the same rule that parked MC-214 and `activity-service` |

**So the debt was the open decision, not the missing column.** Closed at the cost of one document
and one test, and the platform is no more expensive to make multi-tenant in a year than it is
today — which is the sentence the recommendation should have led with.

---

### ⚠️ Deferred to the manual test phase — not blockers, and not to be re-listed

Agreed 2026-09-08: **the human-dependent work happens together at the end**, as one manual
testing pass, and whatever it finds becomes bug tickets then. Until that pass, these are not
"next steps" and should stop appearing as though they were.

| | What | Why it needs a person |
|---|---|---|
| H1 | **Install the APK on a real phone** | Camera, GPS and the privacy cover have only ever run against browser fallbacks. Native-only defects have been accumulating since Sprint 3 by deliberate choice |
| H2 | **Dev-seed `oid` swap** | One `UPDATE`, needs a real Entra object id. Until it runs, a real Field sign-in correctly sees an empty list |
| H3 | **Design-system release** | The `attribution()` fix is committed and unpublished, so Field-sourced feed rows still read "Field" rather than the person's name |
| H4 | **Anything needing Azure** | B16, Phase 7, the restore drill, the load test. No subscription is in use |

⚠️ **H1 is the one with real risk attached.** Everything native is written against Capacitor's
web fallbacks; the first device run will find more than it would have if devices had been in the
loop throughout. That cost was knowingly taken to avoid blocking on an enrolment queue, and it
comes due in that pass.

---

## Where things actually stand · 2026-09-17 (Sprint 14 closed)

**Sprints 0–14 complete. Epic E4 finished bar shipping; E5 closed or parked; E6's library half
built; E7 built early.** A crew lead can record an update with no signal, photograph the reason,
walk back into coverage, and have all of it reach the project exactly once — with the position
they were standing in when they recorded it, and no duplicate however many times the phone
retries. A planner can now build the shape of the next project in a library that is actually
stored, and two planners editing the same template cannot silently overwrite each other.

| | |
|---|---|
| `mc-milestone-service` | **215 tests**, twelve against Azurite over the real Blob API. Contract **2.8.0** |
| `mc-api-gateway` | **46 tests** — version gate, routing (per built service), CORS policy, rate limiting, timeouts, fallback |
| `mc-identity-service` | **18 tests** — JIT provisioning, batch resolve, boundaries, contract. Pinned at **1.0.0** |
| `mc-template-service` | **28 tests** — the library over HTTP, the stale-version race, every draft rule, roles, prefix, tenant guard, contract. Pinned at **1.0.0** |
| `mc-dashboards` | **69 browser assertions**, in CI |
| `mc-field` | **77 browser assertions**, in CI, plus an installable Android APK |
| `mc-templates` | **41 browser assertions**, in CI |

**No client on this platform holds domain data any more — and this time it is true.** The
2026-09-13 version of this sentence overlooked `mc-templates`, which still carried four
hierarchies as constants in a component file. Those are `template-service`'s dev seed now, with
the prototype's seven people mapped to the roles they held, because a template's owner is a role
and the person is chosen when it becomes a project.

### Sprint 13 · closed

| Story | Pts | |
|---|---|---|
| **MC-427** preview uses the project's thresholds | 3 | ✅ Done |
| **MC-342** activity feed and notification bell | 3 | ✅ Done — **without** `activity-service` or Kafka |
| **MC-343** exec numbers refresh after a write | 3 | ✅ Done — pulled forward from Sprint 14 |
| **MC-702** identity-service, and names on screen | — | ✅ Done — E7 built ten sprints early |
| **MC-430** three endpoints the gateway could not reach | — | ✅ Found and fixed |
| **B14** rate limiting, timeouts, circuit breaker | — | ✅ Done bar caching, which was argued away |
| **MC-214** schema registry · **MC-501/502** activity-service, Kafka | 5+ | ⚠️ **Parked against a trigger**, not a date |

### Sprint 14 · closed 2026-09-17

| Story | Pts | |
|---|---|---|
| **MC-338** structure without SQL | 5 | ✅ Done |
| **MC-425** site boundary, and a position that means something | 5 | ✅ Done |
| Where an entry was recorded, in the drawer | — | ✅ Done — and it turned out to be **both** MC-422's position and MC-425's verdict; see below |
| Wire `mc-templates` to a real backend | — | ✅ **Done — by building `template-service`**, which is E6's Sprint 15 pulled forward. See below |
| `tenant_id` | — | ✅ **Decided, not built** — and the "cheapest now" reasoning was wrong; see below |

### The templates service, and three things the wiring found

**A template is stored as the document a planner edits** — a flat, ordered list of rows whose
hierarchy is implied by order — not as a phase/work-package/milestone tree with foreign keys.
Nothing ever addresses one template row on its own, and the flat list is exactly what Sprint 16
instantiates in one pass, so a normalised tree would have been three tables and two joins to
answer questions nobody asks. Rows are replaced whole on save, guarded by `If-Match`: the second
of two planners to save loses and is told who won and when, rather than silently overwriting
somebody's afternoon. The rules a draft must satisfy (a milestone needs a work package above it; a
predecessor is an *earlier milestone*, so the graph is acyclic by construction) are refused with
the row number at save time, because the day they matter is a bulk instantiate failing halfway
through a project.

Deliberately absent, and pinned by the contract test: `DELETE`, and "create project from
template". The second writes into another service and is Sprint 16.

⚠️ **Three things the wiring found, none of them in the templates code:**

1. **`PUT` was not in the gateway's CORS allow-list.** A browser preflights any `PUT`; a method
   missing from `allowedMethods` is refused at the preflight, the real request is never sent, and
   nothing server-side logs anything. The save would have failed with an opaque network error
   while working perfectly from curl. Added, with `CorsPolicyTest` asserting every verb in use.
2. **A refused request carried no CORS headers at all.** Found by that test's first version, which
   asserted `ETag` exposure on a request and got nothing — because the request was a 401, and
   Gateway's `globalcors` is applied when a route matches, which is *after* security has already
   refused. Every expired token has been going out as a 401 a browser hides from the app: the web
   apps saw "cannot reach the server" where they should have seen the 401 that sends a user back
   to sign in. The security chain now applies the same policy, built from the same properties.
   **This has been true since Sprint 4 and would have been the first bug reported by the first
   real user whose token expired.**
3. **The artifact storage quota is still full** and takes 6–12 hours to recalculate — which broke
   the one path a brand-new service has to its first contract baseline. `java-service.yml` now
   prints the spec into the job log between markers when the upload fails (the log is not subject
   to the quota), and `angular-app.yml` skips the deploy rather than failing the build when the
   `dist` upload fails. The template-service baseline came from that log.

**And a fourth, raised by the user the same day: every cross-app link was still a same-origin
path.** `platform-architecture.md` §5 designs one origin behind Front Door with `/dashboards`,
`/templates` and `/` path-routed, and the launcher and both app switchers were written for it.
Front Door does not exist; each app is on its own Static Web App host. So on the deployed apps the
switcher sent users to a 404 on the same host, and on a laptop — where every app defaulted to
port 4200 — it looped back to the same app's catch-all route. Fixed with one resolver per app
(`platform-apps.ts`, copied into shell, dashboards and templates) that answers by where the app is
served: the three SWA hosts when deployed, per-app ports on localhost (4200–4203, now set in each
`angular.json`), Codespaces port-swapping, and a path for anything else — which is the Front Door
case, so the day it lands the file shrinks to its last line. Field's web build also gained the
`.azurestaticapps.net` branch its `api-config` was missing; deployed, it would have called
`localhost:8080`. Two browser assertions per app now intercept the navigation and check the origin.

Also: the templates route was declared in Sprint 4 for a service that did not exist. `GatewayRoutingTest`
now has a block per built service — including the bare `/api/v1/templates` collection, the path a
`/**` suffix is most often assumed not to match. It does; that is no longer an assumption.

⚠️ **Two stories this sprint were both deferred to Sprint 15 for the same wrong reason** — "it
belongs with the templates service" — when `phase`, `work_package` and `project` are all
milestone-service tables. **That misassignment blocked a planner from starting a project without
SQL for six sprints.**

✅ **Checked, 2026-09-13: the rest of Sprint 15 and 16 is correctly placed.** `template` and
`template_row` are genuinely `template-service`'s own tables and no other service owns them, so
the library CRUD and the instantiate-from-template call belong exactly where they sit. MC-338
and MC-425 were the two misassigned items, not a pattern running through the epic.

⚠️ **The standing risk, unchanged and worth restating at the end of the epic that created it.**
Camera, GPS and the privacy cover are all exercised in a desktop Chromium against web fallbacks.
That proves the logic, the queue, the ordering and the refusal paths, and proves **nothing behind a
plugin**. Native-only defects have been accumulating undetected since Sprint 3 by deliberate choice,
and the first device run will find more than it would have if devices had been in the loop
throughout. That was a real cost, knowingly taken to avoid blocking on an enrolment queue — and it
comes due the day somebody installs that APK.
