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
| **MC-002** | As a **developer**, I create the Azure subscription, resource groups, and a `dev` Container Apps environment. | 3 | ➡️ **Sprint 4** — nothing to deploy until the gateway exists. |
| **MC-003** | As a **developer**, I create the GitHub repos so structure exists before code does. | 2 | ✅ **Done**, rescoped — `gh` 2.97.0 installed and authenticated as `rachidpeaqock` (`repo`, `workflow`, `write:packages`). Repos created **per sprint** rather than 15 empty ones up front; `mc-design-system` is live. |
| **MC-004** | As a **developer**, I start **Apple Developer Program enrolment** and decide **App Store vs MDM distribution**. | 2 | ⬜ **To do — yours, and urgent.** |

⚠️ **MC-004 is the one that bites if deferred.** Enrolment and certificates take weeks and block Sprint 12. Start it now, when it costs nothing.

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
| **MC-113** | As a **developer**, each repo builds via GitHub Actions, with SWA deploy. | 5 | 🔄 **Build wired; deploy deferred** — the SWA deploy job needs `AZURE_SWA_TOKEN`, which needs the Azure subscription. ➡️ **Sprint 4** with MC-002. |
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

⬜ **Outstanding manual step:** make the `design-system` package public via the package settings UI. **GitHub's REST API has no visibility endpoint for user-scoped packages** — this genuinely cannot be automated. Making the *repo* public does not propagate to the package.

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
| **MC-203** | As a **developer**, the gateway validates the Entra JWT once at the edge and mints a `traceparent` — **while every service still authorizes independently**. | 8 | ⬜ **To do** — needs an Entra app registration (MC-002). |
| **MC-204** | As a **developer**, `docker compose up` gives registry + gateway + Postgres + Kafka locally. | 5 | ⬜ **To do** — the devcontainer already includes docker-in-docker for this. |
| **MC-205** | *(new)* As a **developer**, one reusable Java pipeline builds, tests and verifies every service. | 3 | ✅ **Done** — [`java-service.yml`](https://github.com/rachidpeaqock/mc-platform-infra/blob/main/.github/workflows/java-service.yml). Asserts an **executable** jar (`BOOT-INF/` present), because a thin jar starts and dies in the cloud rather than failing the build. |

### Spring Boot 4 findings

**`TestRestTemplate` no longer lives at `org.springframework.boot.test.web.client`.** Boot 4's module split moved it, and the first CI run failed on exactly that. Fixed by using Spring Framework's `RestClient`, which needs no extra test dependency and doesn't depend on where Boot put things. **Every service test will hit this** — use `RestClient`.

**The gateway starter was renamed.** `spring-cloud-starter-gateway` no longer resolves in the 2025.x train; it is `spring-cloud-starter-gateway-server-webflux`. Route config also nests one level deeper: `spring.cloud.gateway.server.webflux.routes`.

**The earlier `startup_failure` did not recur.** The reusable-workflow call resolved cleanly for both services, so whatever broke it was in the removed `deploy` block — still worth re-introducing carefully in the deployment sprint rather than assuming.

> **Pin the stack here:** Spring Boot **4.0.5** + Spring Cloud **2025.1.1**. Boot 4.1 has no compatible Spring Cloud release train ([backend §2](./backend-architecture.md#2-stack-and-versions)).

## Sprint 5 — Fitness functions and the contract pipeline

**Goal:** the architecture rules enforce themselves, before there is anything to violate.

| ID | Story | Pts |
|---|---|---|
| **MC-211** | As a **developer**, `ApplicationModules.verify()` and ArchUnit rules fail the build on a boundary violation. | 5 |
| **MC-212** | As a **developer**, an ArchUnit rule fails the build if `mc-platform-commons` ever contains an `@Entity` or a domain type. | 3 |
| **MC-213** | As a **developer**, CI publishes the OpenAPI spec on every merge and **fails on an unversioned breaking change**. | 5 |
| **MC-214** | As a **developer**, a schema registry with backward-compatibility enforcement gates every event-schema change. | 5 |
| **MC-215** | As a **developer**, distributed tracing flows browser → gateway → service into App Insights. | 3 |

**This sprint has no demo and no user value, and skipping it is the single most expensive decision available in this plan.** Every rule here is trivial to add now and requires fixing violations *plus* writing tests later.

---

# Epic E3 — Milestone core service

*The heart. ~45 dev-days, four sprints. Everything else in the platform depends on this being right.*

## Sprint 6 — Schema and read path

**Goal:** real milestones out of a real database.

| ID | Story | Pts |
|---|---|---|
| **MC-301** | As a **developer**, Flyway creates the full schema — project, phase, work package, milestone, dependency, log, rebaseline, reason codes, calendars. | 8 |
| **MC-302** | As a **developer**, the 32 seed milestones load as fixture data, so dev has realistic content. | 3 |
| **MC-303** | As **P2 (PM)**, `GET /api/v1/projects/{id}/milestones` returns the hierarchy with server-computed `variance` and `rag`. | 5 |
| **MC-304** | As a **developer**, migrations run as a discrete pipeline step, not on app startup, so a bad migration can't take the app down with it. | 3 |

## Sprint 7 — Working days and RAG (highest-value tests in the codebase)

**Goal:** the numbers are right, and provably so.

| ID | Story | Pts |
|---|---|---|
| **MC-311** | As **P5 (admin)**, I configure a **work calendar with holidays and a site work pattern**, so variance reflects the actual site — not a hardcoded Mon–Fri. | 8 |
| **MC-312** | As a **developer**, `biz_days(from, to, calendar)` is exhaustively unit tested — holidays, year boundaries, negative spans, 6-day weeks. | 5 |
| **MC-313** | As **P1 (sponsor)**, RAG is derived server-side from variance, status and per-project thresholds, so client and server can never disagree. | 3 |
| **MC-314** | As a **developer**, an hourly job flips past-due milestones to `missed` (ShedLock so one replica runs it). | 5 |

⚠️ **MC-311 fixes a correctness bug in the prototype:** `bizDays()` counts Mon–Fri only and knows nothing about holidays. That number drives variance, RAG, every threshold, and the exec slippage figure.

## Sprint 8 — The write path and the audit trail

**Goal:** the product's core promise, enforced by the database.

| ID | Story | Pts |
|---|---|---|
| **MC-321** | As **P2 (PM)**, I change a milestone's real date **with a mandatory reason**, and the change plus its reason commit atomically. | 8 |
| **MC-322** | As **any user**, the audit trail is **append-only — enforced by database grants**, not application code. | 5 |
| **MC-323** | As **P2 (PM)**, I re-baseline a scheduled date with a mandatory justification, role-gated to PM/planner, recorded separately from routine updates. | 5 |
| **MC-324** | As **any user**, the actor is taken **from the token, never the request body**, so the audit trail can't be forged. | 3 |

⚠️ **MC-324 closes a real hole in the prototype**, which sends `by: 'You'` from the client.

## Sprint 9 — Concurrency, impact, and Dashboards on the API

**Goal:** the first end-to-end vertical slice. **This is the release that matters.**

| ID | Story | Pts |
|---|---|---|
| **MC-331** | As **P2 (PM)**, if someone else moved a milestone while I was editing, I get "M. Castellano moved this to 24 Jul" instead of silently overwriting them (`@Version` + `If-Match` → 409). | 8 |
| **MC-332** | As **P2 (PM)**, I see what a slip threatens, via a recursive CTE with cycle protection and a depth cap. | 5 |
| **MC-333** | As **P1 (sponsor)**, the exec dashboard loads from **one aggregate query**, not by shipping every milestone to the browser. | 5 |
| **MC-334** | As **P2 (PM)**, `mc-dashboards` reads and writes through the API, with loading, error and 409-conflict states. | 8 |

**Demo:** open Dashboards, change a real date with a reason, watch variance and RAG recompute server-side, see it in the audit trail, reload and it's still there. **The product is real from here.**

---

# Epic E4 — Field native app · Sprints 10–12

**Goal:** crews updating milestones from site, offline, on their own phones.

| Sprint | Focus | Key stories |
|---|---|---|
| **10** | API + native auth | Field reads/writes the API · MSAL native flow · tokens in Keychain/Keystore · **minimum-supported-version gate with a blocking upgrade screen** |
| **11** | Offline | IndexedDB/SQLite outbox · **idempotent replay** (a lost response must not double-write the audit log) · queued-state UI · conflict-on-replay handling |
| **12** | Native capabilities + shipping | **Camera — photo evidence on a slip** · GPS site verification · biometric unlock · macOS CI + signing · TestFlight / MDM distribution · device testing |

⚠️ **Sprint 12 depends on MC-004 from Sprint 0.** If enrolment hasn't happened, this sprint stalls entirely.

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
| Apple enrolment not started | 12 | **MC-004 in Sprint 0** |
| Fitness functions skipped as "not user value" | 5 | They are the sprint goal — no demo, still non-negotiable |
| Shared domain library created "just for DTOs" | 6–8 | MC-212 fails the build |
| Screen-shaped endpoints in the core API | 9 | Aggregation goes in a BFF |
| AI built before data exists | 18 | Epic ordering; needs ~6 months of real captures |
| Token spend unmonitored | 19–20 | Cost metrics ship *with* the first feature, not after |

---

## What to do first

**Sprint 0, today.** It's 8 points, most of it waiting on other people, and **MC-004 is the only item in this entire plan with a multi-week external lead time.** Start it before you write a line of code.

Then Sprint 1 — extracting the design system needs no backend, no Azure, and no decisions you haven't already made.
