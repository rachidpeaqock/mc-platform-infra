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
| `mc-platform-infra` | This repo |
| [`milestone-command-prototype`](https://github.com/rachidpeaqock/milestone-command-prototype) | Archived. The original single-workspace prototype everything was extracted from |

Not yet created: `mc-api-client`, `mc-discovery-server`, `mc-api-gateway`, `mc-milestone-service`, `mc-activity-service`, `mc-template-service`, `mc-identity-service`, `mc-ai-service`, `mc-integration-service`.

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

> This repo is **public** so its reusable workflows can be called from the other repos. It contains no secrets.

## Infrastructure

`bicep/front-door.bicep` — one origin for the three web apps (`/` → shell, `/dashboards/*`, `/templates/*`), with an origin group per app. Written, not yet deployed; needs the Azure subscription.

## Status

**Sprints 1–3 complete.** The front-end split is done: four deployable apps over one shared design system, no backend required.

**Two blockers** — both tracked in `docs/sprint-plan.md`:

1. The `design-system` package is private, so other repos' CI cannot install it. One visibility flip in the package settings fixes every repo at once.
2. **Sprint 4 onward cannot be built on the original development machine.** Maven there is pinned to a corporate Nexus mirror that is unreachable off that network, and a corporate TLS-inspection proxy breaks JVM certificate validation. The backend work moves to a personal machine.
