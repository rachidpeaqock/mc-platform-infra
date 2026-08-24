# mc-platform-infra

Shared CI/CD workflows, infrastructure-as-code, and the architecture and planning documents for the **Milestone Command** platform.

## Repositories

| Repo | What it is |
|---|---|
| [`mc-design-system`](https://github.com/rachidpeaqock/mc-design-system) | Tokens, UI primitives, shell chrome. Published as `@rachidpeaqock/design-system` |
| [`mc-shell`](https://github.com/rachidpeaqock/mc-shell) | Launcher and app switcher |
| [`mc-dashboards`](https://github.com/rachidpeaqock/mc-dashboards) | Executive + Project Manager views |
| [`mc-templates`](https://github.com/rachidpeaqock/mc-templates) | Planner tooling |
| [`mc-field`](https://github.com/rachidpeaqock/mc-field) | **Native iOS/Android** app for site crews (Ionic + Capacitor 8) |
| [`mc-discovery-server`](https://github.com/rachidpeaqock/mc-discovery-server) | Eureka registry. Every service registers here so the gateway can route by name |
| [`mc-api-gateway`](https://github.com/rachidpeaqock/mc-api-gateway) | Single entry point. Routes `lb://` by service name, never by host and port |
| [`mc-milestone-service`](https://github.com/rachidpeaqock/mc-milestone-service) | **The heart.** Milestones, audit trail, working-day calendar, dependency graph |
| `mc-platform-infra` | This repo |
| [`mc-concept`](https://github.com/rachidpeaqock/mc-concept) | **Private.** The founding product documents (Concept v3 + v4) everything here descends from |
| [`milestone-command-prototype`](https://github.com/rachidpeaqock/milestone-command-prototype) | Archived. The Angular single-workspace prototype everything was extracted from |
| [`stones-react`](https://github.com/rachidpeaqock/stones-react) | Archived. The original React prototype, written straight from Concept v4 |

Not yet created: `mc-api-client`, `mc-activity-service`, `mc-template-service`, `mc-identity-service`, `mc-ai-service`, `mc-integration-service`.

## Working locally

The platform is many repos on purpose — each one versions, tests and deploys on its own cadence ([§5](docs/platform-architecture.md)). That is right for CI and inconvenient for a human reading code, so:

```
File > Open Workspace from File… > milestone-command.code-workspace
```

One VS Code window, all twelve folders, each still its own repo in the SCM view. The file also carries the watcher excludes that keep twelve `node_modules` trees from grinding the window to a halt, and disables the Java language server's dependency resolution — which cannot succeed on the original development machine and otherwise retries forever.

Then bring the topology up:

```bash
docker compose up -d                      # registry, gateway, Postgres, Kafka
docker compose --profile tools up -d      # adds kafka-ui on :8090
```

The Java services are **pulled from GHCR, not built** — a Codespace has one repo checked out, not nine. Working on one? Stop its container and run it from the IDE on the same port; everything else keeps working.

```bash
docker compose stop api-gateway
cd ../mc-api-gateway && mvn spring-boot:run
```

`init/01-databases.sql` gives each service its own database and login with **no cross-database grants**, so the boundary in [§6](docs/platform-architecture.md) is enforced by the environment rather than asserted in a document.

## Documents

| Document | What it answers |
|---|---|
| [`docs/platform-architecture.md`](docs/platform-architecture.md) | **Start here.** The platform stance, service boundaries, gateway and discovery, event backbone, AI service, cost, sequencing |
| [`docs/backend-architecture.md`](docs/backend-architecture.md) | Spring Boot internals applied per service: domain model, endpoints, security, testing, build |
| [`docs/azure-deployment-plan.md`](docs/azure-deployment-plan.md) | Database schema, endpoint contract, auth model, the working-day calendar problem, concurrency and offline |
| [`docs/sprint-plan.md`](docs/sprint-plan.md) | 10 epics, 24 sprints, per-story status. **The living tracker** |

## Shared workflows

`.github/workflows/angular-app.yml` is the build pipeline every Angular front end calls, so a change to the Node version or a new check lands everywhere at once:

```yaml
jobs:
  app:
    uses: rachidpeaqock/mc-platform-infra/.github/workflows/angular-app.yml@main
    with:
      app-name: mc-dashboards
    secrets: inherit
```

It also asserts the built CSS contains `--primary` — so a design-system regression that silently drops the shared tokens fails the build instead of shipping a correctly-built, unstyled app.

`.github/workflows/java-service.yml` does the same for every Spring Boot service: compile, test, package, and assert the jar actually contains `BOOT-INF/` — catching a thin jar here rather than in the cloud, where it would start and immediately die.

> ⚠️ **A caller of `java-service.yml` must declare `permissions: packages: write`.** A called workflow can never hold more permission than its caller, and these repos default to a read-only token. Omit it and the whole run fails with `startup_failure` at 0s — no logs, no annotation, nothing pointing at permissions. This cost two sprints to find; see the note at the top of the workflow.

> This repo is **public** so its reusable workflows can be called from the other repos. It contains no secrets.

## Infrastructure

`bicep/front-door.bicep` — one origin for the three web apps (`/` → shell, `/dashboards/*`, `/templates/*`), with an origin group per app. Written, not yet deployed.

### What exists in Azure

Subscription: **Free Trial with the spending limit ON** — Azure disables the subscription rather than billing when the credit runs out, so nothing here can produce a surprise invoice. Everything below is free or inside a free allowance.

| Resource | Name | Region |
|---|---|---|
| Resource group | `rg-milestone-command-dev` | westeurope |
| Log Analytics | `log-milestone-command-dev` | francecentral |
| Application Insights | `appi-milestone-command-dev` | francecentral |
| Static Web App ×3 | `stapp-mc-{shell,dashboards,templates}-dev` | eastus2 |

⚠️ **The regions are inconsistent because Azure forced it, not by choice.** This subscription is refused in `westeurope` with `RequestDisallowedByAzure: region not accepting new customers`, and Static Web Apps does not exist in `francecentral` at all. Each resource sits in the nearest region that would accept it. Worth re-checking before the production subscription is set up — this is a free-trial capacity restriction, not a permanent one.

### Identity (Entra)

| Registration | Purpose |
|---|---|
| **Milestone Command API** | `api://milestone-command`. Defines the six app roles — `VIEWER`, `EXECUTIVE`, `PM`, `FIELD`, `PLANNER`, `ADMIN` — that land in the token's `roles` claim, and the `access_as_user` scope |
| **Milestone Command Web** | The three Angular apps. SPA platform, so PKCE with no client secret |
| **Milestone Command GitHub Actions** | Deployment identity. **No secret** — GitHub OIDC federated credential, `Contributor` scoped to the resource group only |

⚠️ **`requestedAccessTokenVersion` is set to 2 on the API registration and must stay there.** The default of 1 makes Entra issue tokens whose issuer is `https://sts.windows.net/{tenant}/`, which fails validation against the `/v2.0` issuer URI the gateway is configured with — and the resulting error says nothing about token versions.

The Field app's registration is deliberately **not** created yet: its redirect URIs depend on the iOS bundle id and Android signature hash, which do not exist until Apple enrolment (MC-004). Creating it now would mean placeholder values that are certain to change.

### Secrets and how they are stored

Nothing that authenticates is stored where it can leak into a terminal or a chat log:

| Value | Where | Why |
|---|---|---|
| Azure client/tenant/subscription id | GitHub **variables** on `mc-platform-infra` | These are identifiers, not credentials — they appear in every token. Storing non-secrets as secrets makes the real ones harder to notice |
| App Insights connection string | GitHub **secret** on `mc-platform-infra` | Anyone holding it can write telemetry to the resource |
| SWA deployment tokens | GitHub **secret** on each app repo | Scoped to one static site each |
| Azure deploy credential | **Does not exist** | Federated OIDC: GitHub proves its identity per run, so there is nothing stored and nothing to rotate |

### Working with this subscription from a corporate machine

The development machine's Azure CLI is signed in to an **Air France** account. Personal work must never run under it, so the personal login lives in its own CLI state directory:

```powershell
$env:AZURE_CONFIG_DIR = "$HOME\.azure-personal"
az login --use-device-code      # device code, so the default browser's corporate SSO is bypassed
az account show                 # verify before doing anything
```

Set `AZURE_CONFIG_DIR` on **every** invocation. A shell without it points at `~/.azure`, which is the work session.

## Status

**Sprints 1–4 complete**, bar one story.

- The front-end split is done: four deployable apps over one shared design system, no backend required.
- The backend skeleton is up: registry and gateway build, test, and publish images to GHCR on every push to `main`, and `docker compose up` brings the whole topology up locally.

**Both earlier blockers are resolved**, neither the way first proposed:

1. ~~The `design-system` package is private, so other repos' CI cannot install it.~~ Resolved **without** making it public and without a PAT — each consuming repo was granted access under the package's *Manage Actions access*. The package stays private.
2. ~~Sprint 4 onward cannot be built on the original development machine.~~ Maven there is still pinned to an unreachable corporate mirror behind a TLS-inspecting proxy, and that has not changed — but the build moved to GitHub Actions, so the machine no longer needs to compile anything. **`java-service.yml` is the compiler.**

**Remaining:** `MC-203`, JWT validation at the gateway, blocked on the Entra app registration (`MC-002`). Anything needing a corporate certificate is deferred until the work moves to a personal machine; the sprint plan tracks which stories those are.
