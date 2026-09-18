# Every link, in one place

**Written 2026-09-13**, because the URLs were lost once. This file is committed, so as long as
one repository survives, the rest can be found from it.

---

## 1. ⚠️ Deployed apps — these are live right now

Verified 2026-09-13: all three answer **HTTP 200**.

| App | URL | Last deployed |
|---|---|---|
| **Dashboards** | https://yellow-sand-06533ac0f.7.azurestaticapps.net | 2026-09-06 |
| **Templates** | https://orange-moss-08f7c2d0f.7.azurestaticapps.net | 2026-08-24 |
| **Shell** | https://gentle-moss-010767c0f.7.azurestaticapps.net | 2026-08-24 |

Azure Static Web Apps, deployed by `angular-app.yml` on every push to `main`. ⚠️ **These three hosts are hard-coded in each app's `src/app/core/platform-apps.ts`** (shell, dashboards, templates) — that is how the switcher and the launcher find the other apps until Front Door gives them one origin. Recreating a Static Web App means updating all three copies. ⚠️ The `deploy`
input **defaults to `true`**, so a front end is published unless it opts out — which is why
these exist without anyone deciding to publish them recently.

**`mc-field` is not here, deliberately**: it passes `deploy: false`. It is a native app, and a
web build of it on a public URL would be a second way to reach the platform that nobody
designed, tested or version-gated.

### ⚠️ What "deployed" does and does not mean here

| | |
|---|---|
| ✅ The front ends are live and public | Anyone with the URL loads the app |
| ⚠️ **There is no backend behind them** | No Azure Container App, no database, no gateway. Every API call from these pages fails |
| ⚠️ **They are old** | Dashboards predates MC-427, MC-342, MC-343 and MC-702. Templates and Shell are from August |
| ⚠️ **Public, and not access-controlled** | Static Web Apps serves them to anyone. There is no data behind them, so nothing leaks — but a stakeholder handed one of these URLs sees a broken app, not a demo |

**So these are not demo links.** They prove the pipeline works end to end. Sending one to a
partner would show an app that renders its shell and then fails every request.

The statement *"nothing is deployed"* appears in several documents. It is **correct about the
backend and about Azure resources**, and it was wrong as a blanket claim — corrected where it
was too broad.

---

## 2. Repositories

All under [`github.com/rachidpeaqock`](https://github.com/rachidpeaqock), all **private**.

### The platform

| Repo | What it is |
|---|---|
| [mc-platform-infra](https://github.com/rachidpeaqock/mc-platform-infra) | **Start here.** Docs, `compose.yml`, the reusable CI workflows, database init |
| [mc-discovery-server](https://github.com/rachidpeaqock/mc-discovery-server) | Eureka registry |
| [mc-api-gateway](https://github.com/rachidpeaqock/mc-api-gateway) | Spring Cloud Gateway — routing, version gate, rate limit, circuit breaker |
| [mc-milestone-service](https://github.com/rachidpeaqock/mc-milestone-service) | The transactional core. Milestones, audit trail, calendar, impact, evidence |
| [mc-identity-service](https://github.com/rachidpeaqock/mc-identity-service) | Who people are. JIT provisioning, batch name resolution |

### The front ends

| Repo | What it is |
|---|---|
| [mc-dashboards](https://github.com/rachidpeaqock/mc-dashboards) | Executive + PM screens |
| [mc-field](https://github.com/rachidpeaqock/mc-field) | The native app (Ionic/Capacitor) |
| [mc-templates](https://github.com/rachidpeaqock/mc-templates) | Planner templates — on `template-service` since Sprint 14 |
| [mc-template-service](https://github.com/rachidpeaqock/mc-template-service) | The planner's library: `template`, `template_row`. Contract 1.0.0 |
| [mc-integration-service](https://github.com/rachidpeaqock/mc-integration-service) | P6 XER → the platform's project structure, previewed. No database. Contract 1.0.0 |
| [mc-shell](https://github.com/rachidpeaqock/mc-shell) | The landing shell |
| [mc-design-system](https://github.com/rachidpeaqock/mc-design-system) | Tokens, primitives, the top bar |

### Concept and history

| Repo | What it is |
|---|---|
| [mc-concept](https://github.com/rachidpeaqock/mc-concept) | Product concept (v4, v5) and the competitive landscape |
| [stones-angular](https://github.com/rachidpeaqock/stones-angular) | ⚠️ The original prototype. Local checkout is `milestone-command-ng` — **the folder name and the repo name differ**, which is worth knowing before hunting for a repo called `milestone-command-ng` |
| [stones](https://github.com/rachidpeaqock/stones) | Earlier still |

---

## 3. The documents that matter

All in [`mc-platform-infra/docs`](https://github.com/rachidpeaqock/mc-platform-infra/tree/main/docs):

| | |
|---|---|
| [sprint-plan.md](https://github.com/rachidpeaqock/mc-platform-infra/blob/main/docs/sprint-plan.md) | **The system of record.** Every sprint, every decision, every defect and why |
| [platform-architecture.md](https://github.com/rachidpeaqock/mc-platform-infra/blob/main/docs/platform-architecture.md) | Service decomposition, communication, infrastructure |
| [backend-architecture.md](https://github.com/rachidpeaqock/mc-platform-infra/blob/main/docs/backend-architecture.md) | Per-service internals, the endpoint catalogue |
| [azure-deployment-plan.md](https://github.com/rachidpeaqock/mc-platform-infra/blob/main/docs/azure-deployment-plan.md) | Schema, resources, cost. ⚠️ No Azure *backend* resource in it exists — see §1 for what does |

And in [`mc-concept/docs`](https://github.com/rachidpeaqock/mc-concept/tree/main/docs):

| | |
|---|---|
| [concept-v5.md](https://github.com/rachidpeaqock/mc-concept/blob/main/docs/concept-v5.md) | The product, reconciled against what was built |
| [competitive-landscape.md](https://github.com/rachidpeaqock/mc-concept/blob/main/docs/competitive-landscape.md) | SAP, Salesforce, the real incumbents — **§10 is the battlecard** |

---

## 4. ⚠️ Published artifact pages — most are stale

These were published to `claude.ai` and **are not updated when the repo changes.** Dates are when
each was last published; the documents behind them have moved a long way since.

| Page | Published | State |
|---|---|---|
| [Milestone Command Build Board](https://claude.ai/code/artifact/7521ec34-68b7-4bef-aff0-17b47ecfc63c) | 2026-09-06 | Most recent. Predates Sprints 13–14, identity-service, MC-338 |
| [What landed while you were away](https://claude.ai/code/artifact/c1ffe1e6-ccba-4386-a966-13d2416bb8f9) | 2026-09-01 | A catch-up snapshot |
| [Milestone Command Status](https://claude.ai/code/artifact/b6095704-9ba0-4cc1-9374-32809c0e30e2) | 2026-08-24 | ⚠️ Stale |
| [sprint-plan.md](https://claude.ai/code/artifact/bedfc1d0-2aa5-4db8-b7b4-95b1fb851347) | 2026-08-24 | ⚠️ **Badly stale** — the real plan has roughly doubled since |
| [sprint-plan.md (older)](https://claude.ai/code/artifact/93a02d9e-f927-43f8-8bea-dcd1704f27c1) | 2026-08-17 | ⚠️ Superseded |
| [platform-architecture.md](https://claude.ai/code/artifact/e92f5bf2-2d24-4a87-b416-811323e5b4fc) | 2026-08-15 | ⚠️ Predates the whole 2026-09-07 reconciliation |
| [azure-deployment-plan.md](https://claude.ai/code/artifact/2dc19316-5701-4ea8-bc38-e44352f35a15) | 2026-08-15 | ⚠️ Same |

**Treat the repo as truth and these as photographs.** ⚠️ The three document pages are the risky
ones: they carry a document's name and old content, so anyone sent one reads a version whose
central claims — "no identity service", "no rate limiting", "SAP does not do this" — have since
been corrected.

*(Artifacts from unrelated work are in the same gallery: Studio Noor, Salon Ma Belle, Centre Zen,
Prospection Salons/Beauté, Turnaround Search Popup, AF 1182 Shooting Script. Listed only so they
are not mistaken for this project.)*

---

## 5. CI

Each repo's runs are at `…/actions`, e.g.
[mc-milestone-service/actions](https://github.com/rachidpeaqock/mc-milestone-service/actions).

⚠️ **CI is the only compiler this project has** — nothing JVM builds on the development laptop.
A backend change is a hypothesis until Actions answers.

| | |
|---|---|
| [java-service.yml](https://github.com/rachidpeaqock/mc-platform-infra/blob/main/.github/workflows/java-service.yml) | The shared backend workflow. Also **uploads the generated OpenAPI spec**, which is how a contract baseline gets off this machine |
| [angular-app.yml](https://github.com/rachidpeaqock/mc-platform-infra/blob/main/.github/workflows/angular-app.yml) | The shared front-end workflow |
| [design-system package](https://github.com/rachidpeaqock/mc-design-system/pkgs/npm/design-system) | Published to GitHub Packages; the front ends consume it from there |

**Fetching a contract baseline:**
```bash
gh run download <run-id> -n mc-<service>-openapi -D /tmp/spec
```

---

## 6. Running it locally

```bash
cd mc-platform-infra && docker compose up -d
```

| Service | URL |
|---|---|
| API gateway | http://localhost:8080 |
| Eureka | http://localhost:8761 |
| milestone-service | http://localhost:8081 |
| identity-service | http://localhost:8083 |
| template-service | http://localhost:8084 |
| integration-service | http://localhost:8085 |
| PostgreSQL | `localhost:5432` |
| Kafka | `localhost:9092` |
| Kafka UI (`--profile tools`) | http://localhost:8090 |
| Shell (`ng serve`) | http://localhost:4200 |
| Dashboards (`ng serve`) | http://localhost:4201 |
| Templates (`ng serve`) | http://localhost:4202 |
| Field web (`ng serve`) | http://localhost:4203 |
| Dashboards (verify harness) | http://localhost:4300 |
| Field (verify harness) | http://localhost:4301 |
| Templates (verify harness) | http://localhost:4302 |

⚠️ **Migrations do not run on startup, by design.** First run:
```bash
cd mc-milestone-service && mvn flyway:migrate
cd mc-identity-service  && mvn flyway:migrate
```

Published contracts: [milestone 2.7.0](https://github.com/rachidpeaqock/mc-milestone-service/blob/main/api/openapi.json)
· [identity 1.0.0](https://github.com/rachidpeaqock/mc-identity-service/blob/main/api/openapi.json)

---

## 7. Azure / Entra identifiers

Not secrets — every one of these appears in an issued token or a public discovery document.

| | |
|---|---|
| Tenant id | `5b6fa978-e0da-4f01-bb84-37309bc3fe60` |
| API client id (the `aud` that matches) | `92b0c16e-738b-4410-8ebd-a7dc49850d84` |
| Identifier URI | `api://milestone-command` |
| Issuer | `https://login.microsoftonline.com/{tenant}/v2.0` |

⚠️ The `/v2.0` suffix is load-bearing — it must match the app registration's
`requestedAccessTokenVersion: 2`, or Entra issues `sts.windows.net` tokens that fail validation
with an error mentioning nothing about token versions.

---

## 8. External sources

### ✅ Verified — opened and confirmed to say what is claimed

| | |
|---|---|
| [Using Milestones in Networks (SAP Learning)](https://learning.sap.com/learning-journeys/carrying-out-the-basic-configuration-of-sap-s-4hana-project-system/using-milestones-in-networks) | PS milestone functions, incl. *"Start a workflow task"* |
| [Progress Tracking PS-PRG-TRC (SAP Help)](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/4dd8cb7b1c484b4b93af84d00f60fdb8/8092c95360267214e10000000a174cb4.html) | Progress tracking on WBS and network activities |
| [Milestone Billing in S/4HANA (SAP Community)](https://community.sap.com/t5/supply-chain-management-blog-posts-by-members/milestone-billing-in-sap-s-4hana/ba-p/13980780) | Milestone-based billing |
| [ERP Research — S/4HANA project management](https://www.erpresearch.com/erp/sap-s4-hana-public-cloud/project-management) | ⚠️ Real page, but **does not mention milestones** — it was cited under milestone claims and did not support them |

### ⚠️ Cited but not verified

Collected before the sourcing discipline tightened. **Open before quoting.**

- [SAP: triggering a workflow from milestones](https://community.sap.com/t5/enterprise-resource-planning-q-a/triggering-a-workflow-from-milestones-in-project-systems/qaq-p/5092408) · [linking activities and milestones](https://community.sap.com/t5/enterprise-resource-planning-q-a/linking-of-activities-and-milestones-in-project-system-on-sap-s-4hana/qaq-p/13944407) *(403 on fetch)* · [EPPM what's new](https://community.sap.com/t5/enterprise-resource-planning-blog-posts-by-sap/what-s-new-in-enterprise-portfolio-and-project-management-in-sap-s-4hana/ba-p/14439146) · [PS ready reference](https://community.sap.com/t5/additional-blog-posts-by-members/sap-project-system-a-ready-reference-part-1/ba-p/12862174)
- [SAP Field Service Management](https://www.sap.com/assetdetail/2023/03/2ce961a2-677e-0010-bca6-c68f7e60039b.html) · [S/4HANA for EPC](https://emerging-alliance.net/sap-s-4hana-for-engineering-procurement-constructionepc-industry/) · [SAP S/4HANA Handbook for EPC Projects](https://link.springer.com/book/10.1007/979-8-8688-1466-2)
- Salesforce: [E&C industry page](https://www.salesforce.com/eu/engineering-construction-real-estate/construction-software/) · [AppExchange listing](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N30000009uYYMEA2) · [does Salesforce have PM (Aprika)](https://aprika.com/fundamental_library/does-salesforce-have-a-project-management-tool/)
- Delay claims: [construction delay claims guide](https://projul.com/blog/construction-delay-claims-guide/) · [CPM delay analysis methods](https://smartpm.com/blog/cpm-schedule-delay-analysis-methods-and-types) · [delay analysis (Planera)](https://www.planera.io/post/delay-analysis-in-construction)
- Market: [InEight forecasting](https://ineight.com/the-best-software-for-forecasting-in-capital-construction/) · [project controls software](https://gitnux.org/best/project-controls-software/) · [capital project tools 2026](https://optimalitypro.com/resources/10-best-capital-project-management-software-tools-2026-guide) · [Procore pricing](https://checkthat.ai/brands/procore/pricing) · [Autodesk ACC pricing](https://contractorsandbuilders.com/pricing/autodesk-acc/)

### Stack references

[Spring Boot 4.0.5](https://spring.io/blog/2026/03/26/spring-boot-4-0-5-available-now/) ·
[Boot EOL dates](https://endoflife.date/spring-boot) ·
[Spring Framework 7.0 GA](https://spring.io/blog/2025/11/13/spring-framework-7-0-general-availability/) ·
[Framework 7.0 release notes](https://github.com/spring-projects/spring-framework/wiki/Spring-Framework-7.0-Release-Notes) ·
[Modulith 2.0 GA](https://spring.io/blog/2025/11/21/spring-modulith-2-0-ga-1-4-5-and-1-3-11-released/) ·
[Modulith reference](https://docs.spring.io/spring-modulith/reference/index.html)
