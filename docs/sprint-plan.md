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
| **MC-214** | As a **developer**, a schema registry with backward-compatibility enforcement gates every event-schema change. | 5 | ➡️ **Sprint 10** — there are no events yet. Nothing produces to Kafka and no schema exists, so this would gate an empty set. Belongs with the first published event. |
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
| **MC-338** | As a **planner**, I create and rename phases and work packages, so a new project can be structured without SQL. | 5 | ➡️ **Sprint 15**, with the templates service. Found while building MC-335. Creating a milestone needs a `workPackageId`, and the only way to get a work package that does not already exist is a manual `INSERT`. Deliberately not folded into MC-335: creating the containing structure implicitly from names would make "Piping" typed twice with different capitalisation into two work packages, and nobody would notice until a report split in half. |
| **MC-337** | As a **field user**, replaying a queued update after a lost response does **not** write a second audit entry. | 5 | ✅ **Done, ahead of Sprint 11 rather than during it.** `Idempotency-Key` header, keyed by `(actor, key)`, claimed with `INSERT … ON CONFLICT DO NOTHING` so check and claim are one statement. Keys expire after 30 days on the existing hourly sweep. |
| **MC-339** | As **P2 (PM)**, I read one milestone's **delay log and re-baseline history** in the detail drawer, so I can see what actually happened to it rather than only that it is late. | 5 | ➡️ **Sprint 11.** Found while swapping the PM tree. The drawer's largest panel had no data behind it. MC-336 solved the *exec* badge by carrying the last reason on each exposure row, which is one label; the drawer needs the sequence. The server holds the trail and no endpoint reads it per milestone. **The drawer now says so rather than falling back to the prototype's "No changes — real date still equals scheduled", which would have been a lie on every milestone that has slipped.** |
| **MC-340** | As **P2 (PM)**, I see a milestone's **predecessors**, so the dependency panel says what this milestone is waiting on. | 3 | ➡️ **Sprint 11.** Found while swapping the PM tree. Nothing the API returns points upstream. Successors were recoverable for free — `GET /impact` is the transitive closure with a depth on each row, so depth 1 *is* the direct successors, and the drawer renders them from the walk it already fetches. There is no equivalent walking the other way. |
| **MC-341** | As **P1 (sponsor)**, the S-curve is anchored to the **project's own start and finish dates**, so the x-axis is not a seed constant. | 2 | ➡️ **Sprint 11.** `PROJECT.scheduledStart` and a hardcoded `2027-04-15` still drive the chart's geometry — the only surviving use of the seed on the exec screen now that the project's *name* comes from the server. Needs two dates on `GET /projects/{id}`. |
| **MC-342** | As **any user**, the activity feed and the notification bell show **real events from the platform**, not an empty list. | 3 | ➡️ **Sprint 13**, and now **explicitly** empty. `StoreService` fed the bell from this app's own `localStorage` writes; nothing writes there any more, so the only thing the feed could still surface was **leftover prototype events from an old browser session, rendered as current activity**. The store and the adapter are deleted rather than left mapping a permanently empty array. A **visible regression from the prototype**, and it must not be discovered as a surprise in Sprint 13. |
| **MC-343** | As **P1 (sponsor)**, the exec numbers **reflect a change a PM just made**, without a reload. | 3 | ➡️ **Sprint 14**, where the push channel is built and the choice is actually available. Found while swapping the PM tree. `GET /summary` is fetched once per load and never refreshed, so every write leaves it stale: the project row and the whole exec screen keep the old counts until the page reloads. Deliberately *not* fixed by refetching the summary after each write — that is a design choice between refetch, refresh-on-view and the push channel Sprint 14 builds, and picking the first one silently would prejudge it. |
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
| **MC-338** phase / work-package creation | **Sprint 15** | It is the templates service's job. Sprint 15 builds project structure from templates, and building a second structure editor in the PM screen first would mean two ways to create a work package before there is one good one. Nothing is blocked meanwhile — the tree endpoint returns work-package ids, so milestones can be created in any package that exists. |
| **MC-339** per-milestone history | **Sprint 11** | The drawer's largest panel says it has no data instead of inventing some, which is correct but not finished. Sprint 11 rather than 10 because Field's offline outbox makes "what happened to this milestone" a question a *second* client asks, and one endpoint should answer both. |
| **MC-340** predecessors | **Sprint 11** | Rides with MC-339: the same drawer, the same fetch-on-selection, and the dependency panel currently hardcodes `FS` as the link type, which is its own small lie to fix. |
| **MC-341** S-curve anchored to project dates | **Sprint 11** | Two dates on `GET /projects/{id}` and the last use of the seed constant on the exec screen goes. Small, and grouped with the other read-path gaps so the contract changes once. |
| **MC-343** exec numbers stale after a write | **Sprint 14** | Deliberately not fixed by refetching the summary after every write. That is one of three answers — refetch, refresh-on-view, or the push channel — and Sprint 14 builds the third. Picking the cheapest one now would prejudge a decision that is about to become free. |
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
| **15** | Library | `template-service` + own database · CRUD · tree-grid persistence · **per-template seeds with derived counts** (the prototype bug where every card opened the same 4-milestone starter) |
| **16** | Instantiate | "Create project from template" as **one idempotent bulk call** to `milestone-service` · offsets resolved against a work calendar · all-or-nothing semantics |

---

# Epic E7 — Identity service · Sprint 17

**Goal:** authorization becomes a platform concern, so a fourth consumer is possible.

Stories: extract `identity-service` with its own database · JIT user provisioning from Entra · **OAuth scopes alongside roles** · `client_credentials` for machine consumers with a service-account identity in the audit trail · **P6 story: a new app is onboarded with only an app registration, generated client and topic subscription — no core service modified.**

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
| **A client re-implements a rule the server owns** | 9–10, then every new client | Held four times so far: `bizDays`/`ragOf` kept off the design system, the client status calculation deleted in MC-334, the reason catalogue served in MC-344, and the note rule moved into `reason_code`. **The ArchUnit rule that forbids this cannot see TypeScript**, so the only defence is that each new client is audited for it before it ships — which is what found all four |
| **A second consumer needs a core change to be onboarded** | 10, rehearsed for 17 | Sprint 10 is the dry run for MC-701. Anything Field needs that `mc-dashboards` did not is a seam that was missing; `?owner=` is the first one found |
| AI built before data exists | 18 | Epic ordering; needs ~6 months of real captures |
| Token spend unmonitored | 19–20 | Cost metrics ship *with* the first feature, not after |

---

## What to do first

*Written before Sprint 0. Kept for the record; see "Where things actually stand" below for the current position.*

~~**Sprint 0, today.** It's 8 points, most of it waiting on other people, and **MC-004 is the only item in this entire plan with a multi-week external lead time.** Start it before you write a line of code.~~

Then Sprint 1 — extracting the design system needs no backend, no Azure, and no decisions you haven't already made.

---

## Where things actually stand · 2026-08-24 (end of Sprint 10)

**Sprints 1–9 complete.** 125 tests on the milestone service, all green on CI. The three web apps
deploy on merge. **The demo runs**: sign in, change a real date with a reason, watch variance and
RAG recompute server-side, reload, and it is still there.

`localStorage` is gone from `mc-dashboards`, and with MC-344 there is **no domain data left on that
client at all** — what remains in `data.ts` is a preview calculation labelled as an estimate, a
fallback threshold pair, and one seed date the S-curve still needs (MC-341).

**Sprints 1–10 complete.** Field reads and writes the same API the dashboards do, signed in as a
real person, and it needed **one** new seam to get there — `?owner=`. 131 tests on the milestone
service, 17 on the gateway, all green.

| # | What | Why it is next |
|---|---|---|
| 1 | **Sprint 11 — the offline outbox** | The next sprint, and genuinely unblocked: `Idempotency-Key` already goes out on every Field write, so the replay contract exists before the queue that needs it |
| 2 | MC-339 / MC-340 / MC-341 | Carried into 11. Two read endpoints and two dates — the drawer's dead panels and the S-curve's last seed constant |
| 3 | MC-345 — the browser harness | Also in 11. Three sprints of ad-hoc harnesses is enough; it also removes the hand-kept `APP_VERSION` that MC-405 left behind |
| 4 | The dev-seed `oid` swap | One `UPDATE`, above. Needs your Entra object id. Until it runs, a real Field sign-in correctly sees an empty list |

⚠️ **Sprint 11's idempotent replay no longer reaches back into the API — MC-337 landed early.**
`Idempotency-Key` is on both write endpoints and keyed by `(actor, key)`, so Field's outbox has
somewhere to put a replay before the outbox exists. **Field must send one from its first write**,
not from the sprint that adds queuing: an update retried by hand on a bad connection is the same
duplicate a queue would have caused.
