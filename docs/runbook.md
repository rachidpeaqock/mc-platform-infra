# Milestone Command — Runbook

**Written:** 2026-09-18 (Sprint 23) · **Against:** `bicep/` at the same commit · **Environment:** `dev` in `rg-milestone-command-dev`

This is what a person does to the running estate, in the order they will need it. Every command is
real and every name is the one Bicep produces. **§1 was run for the first time on 2026-09-19**, and
what it found is folded back in below rather than left as a war story: five things the templates or
this document had wrong, each marked ⚠️ *found 2026-09-19* where it lives.

> ⚠️ **The development machine reaches ARM and nothing else.** Key Vault's data plane, the
> registry, the Log Analytics query endpoint, the container-apps log stream and the Postgres port
> all fail behind its TLS-intercepting proxy. Everything below that is not ARM — reading a log,
> writing a secret, checking a table — is therefore done either as an ARM resource
> (`vault-bootstrap.bicep`), as a Container Apps job (`job-bootstrap-db`), or from a GitHub runner
> (`.github/workflows/ops-logs.yml`, read-only: `gh workflow run ops-logs.yml -f target=<app|job> -f kind=<app|job>`).

> ⚠️ **Two rules before any command.** (1) `$env:AZURE_CONFIG_DIR = "$HOME\.azure-personal"` on
> every invocation — the default profile on the development machine is a corporate session (README,
> "Working with this subscription from a corporate machine"). (2) `az account show` before anything
> that creates or deletes. The subscription must read `Azure subscription 1` /
> `rachidouahmanetdi@gmail.com`. Nothing in this document is ever run against any other subscription.

---

## 0. What exists, and how to see it

```powershell
$env:AZURE_CONFIG_DIR = "$HOME\.azure-personal"
az login --use-device-code                       # if `az account show` fails
az account show -o table
az resource list -g rg-milestone-command-dev -o table
```

**Inventoried 2026-09-19** (the README's "What exists in Azure" table is that inventory). The short
version: the environment is `cae-milestone-command-dev` — the template's default, so
`MC_CONTAINER_ENV_NAME` need not be set — and it already holds `ca-api-gateway`,
`ca-milestone-service` (on the `dev` profile, connecting as the administrator), `ca-discovery-server`
and a `caj-migrate` job, in front of `psql-milestone-command-dev` with one database. All of it is
**adopted** by the templates under its existing name; nothing is recreated.

```powershell
az containerapp env list -g rg-milestone-command-dev --query "[].{name:name, domain:properties.defaultDomain}" -o table
```

⚠️ Three consequences for §1, each handled where it lands: the Postgres administrator password
already exists (1.3 stores *that* one, it does not mint one); `milestone_db`'s tables are owned by
`mcadmin` (the bootstrap job hands them to `milestone_svc`); and rolling `ca-milestone-service`
from `dev` to `azure` profile ends its use of Eureka, after which `ca-discovery-server` can go (1.7).

---

## 1. First deployment — foundation, secrets, platform

Two templates and a step between them, because the second reads a secret the first creates the
place for (`bicep/foundation.bicep` explains the split).

### 1.0 Sign in

The tenant enforces MFA; a cached token is refused as "blocked by security defaults". Device-code
codes expire unused if the browser is not open. What works, in one go:

```powershell
$env:AZURE_CONFIG_DIR = "$HOME\.azure-personal"
az config set core.enable_broker_on_windows=false     # or the Windows account picker offers the corporate account
$env:BROWSER = "$env:LOCALAPPDATA\Programs\Opera\opera.exe"   # not the default browser's corporate SSO
az login --tenant 5b6fa978-e0da-4f01-bb84-37309bc3fe60
```

### 1.1 Identify yourself to the templates

```powershell
$me = az ad signed-in-user show --query "{id:id, upn:userPrincipalName}" -o json | ConvertFrom-Json
$env:MC_DEPLOYER_OBJECT_ID = $me.id
$env:MC_DEPLOYER_UPN       = $me.upn
```

The parameter files read these. Your object id becomes Key Vault Secrets Officer (to write the
passwords in 1.3) and, optionally, the Postgres Entra administrator (to `psql` in without a password).

### 1.2 Foundation

```powershell
cd mc-platform-infra
az deployment group what-if -g rg-milestone-command-dev -f bicep/foundation.bicep -p bicep/foundation.dev.bicepparam
az deployment group create  -g rg-milestone-command-dev -f bicep/foundation.bicep -p bicep/foundation.dev.bicepparam
```

Creates `id-mc-apps-dev` (the identity every app runs as), `kv-mc-milestone-dev`, `ag-mc-dev-ops`,
and adopts the registry, the workspace and App Insights. Role assignments need Owner or *User
Access Administrator* on the group — you have it as subscription owner; the GitHub identity does
not (see `infra.yml`), which is why a person runs this stage. ⚠️ *found 2026-09-19:* the what-if
reported App Insights retention 90 → 30; the template now pins 90 (the free allowance). Ran in ~1 min.

### 1.3 The passwords — into the vault, never seen

The administrator password **already exists**: `psql-milestone-command-dev` was created by hand and
`ca-milestone-service` held it as the container-app secret `dbpw`. `platform.bicep` sets
`administratorLoginPassword` from the vault on every deploy, so the vault must hold the *current*
value or the first deploy rotates it under the running app.

⚠️ *found 2026-09-19:* `az keyvault secret set` is the vault's data plane and fails from this
machine. The secrets are written as ARM resources instead — `vault-bootstrap.bicep`, **run once**
(its three minted passwords default to fresh GUIDs; a second run would rotate them):

```powershell
$pw = az containerapp secret show -n ca-milestone-service -g rg-milestone-command-dev --secret-name dbpw --query value -o tsv
az deployment group create -g rg-milestone-command-dev -n vault-bootstrap -f bicep/vault-bootstrap.bicep -p existingAdminPassword=$pw -o none
Remove-Variable pw
az rest --method get --url "https://management.azure.com/subscriptions/f5dd2845-c223-47a4-9539-724ad720e327/resourceGroups/rg-milestone-command-dev/providers/Microsoft.KeyVault/vaults/kv-mc-milestone-dev/secrets?api-version=2023-07-01" --query "value[].name" -o tsv
```

Four names (the list pages at three — follow `nextLink` or fetch the fourth by name), no values on
screen. `evidence-connection-string` is the fifth; Bicep writes it in 1.5 because it created the
storage account. Once the old `dbpw` secret is gone from the app (1.5 replaces it), the vault is the
only place the administrator password exists.

RBAC on a new vault takes a minute to propagate; a `Forbidden` on the first `secret set` is that, not
a mistake — wait and retry.

### 1.4 Images into ACR

Set the GitHub variables that make `java-service.yml` push to ACR and deploy, on **each service
repo** (or as organisation variables):

| Variable | Value | Effect |
|---|---|---|
| `ACR_NAME` | `acrmilestonecommanddev` | pushes `<svc>:main`, `<svc>:<sha>` and `<svc>-migrate:*` to ACR next to GHCR |
| `CONTAINER_APPS_RG` | `rg-milestone-command-dev` | after the push: run `job-migrate-<svc>`, then `az containerapp update` |
| `AZURE_CLIENT_ID` / `AZURE_TENANT_ID` / `AZURE_SUBSCRIPTION_ID` | already on `mc-platform-infra` | needed on the callers too — a called workflow reads the caller's `vars` |

`acrmilestonecommanddev` **already exists** and `mc-api-gateway`, `mc-milestone-service` and
`mc-discovery-server` already carry `ACR_NAME` + the three Azure ids (set 2026-08-24) — the
milestone-service run of 2026-09-18 pushed `mc-milestone-service:main` *and*
`mc-milestone-service-migrate:main` to it, which is the new steps proven once. What is missing:

```powershell
foreach ($r in 'mc-identity-service','mc-template-service','mc-integration-service') {
  gh variable set ACR_NAME              -R rachidpeaqock/$r -b acrmilestonecommanddev
  gh variable set AZURE_CLIENT_ID       -R rachidpeaqock/$r -b (gh variable get AZURE_CLIENT_ID       -R rachidpeaqock/mc-platform-infra)
  gh variable set AZURE_TENANT_ID       -R rachidpeaqock/$r -b (gh variable get AZURE_TENANT_ID       -R rachidpeaqock/mc-platform-infra)
  gh variable set AZURE_SUBSCRIPTION_ID -R rachidpeaqock/$r -b (gh variable get AZURE_SUBSCRIPTION_ID -R rachidpeaqock/mc-platform-infra)
}
```

Then push to `main` (or `gh workflow run` the CI) on those three, and on `mc-identity-service` /
`mc-template-service` the run also builds the `-migrate` image. Each run publishes to ACR and stops
at "Not deployed" — the container apps do not exist yet. `CONTAINER_APPS_RG` goes on all five
**after** 1.5, when there is something to deploy to. Images first, because a
container app whose image cannot be pulled fails to provision, and the deployment in 1.5 with it.

```powershell
az acr repository list -n acrmilestonecommanddev -o tsv     # five services + three -migrate
```

The GitHub identity needs **AcrPush** on the registry (Contributor on the group covers it) and
Contributor on the group for `az containerapp update` (it has it). ⚠️ *found 2026-09-19:* it also
needs a **federated credential per repository** — the three new repos failed `azure/login` with
`AADSTS700213` until they had one. GitHub now presents the *immutable* subject form
(`repo:owner@id/repo@id:ref:…`), so both forms are added:

```powershell
$app = "86be49e1-6fd7-451f-b7bb-f94316cee4df"          # Milestone Command GitHub Actions
$ownerId = gh api users/rachidpeaqock --jq .id
foreach ($r in 'mc-identity-service','mc-template-service','mc-integration-service') {
  $repoId = gh api repos/rachidpeaqock/$r --jq .id
  @{ name="gh-$r-main"; issuer="https://token.actions.githubusercontent.com"; subject="repo:rachidpeaqock/$r:ref:refs/heads/main"; audiences=@("api://AzureADTokenExchange") } | ConvertTo-Json | Set-Content fc.json
  az ad app federated-credential create --id $app --parameters fc.json -o none
  @{ name="gh-$r-main-immutable"; issuer="https://token.actions.githubusercontent.com"; subject="repo:rachidpeaqock@$ownerId/$r@${repoId}:ref:refs/heads/main"; audiences=@("api://AzureADTokenExchange") } | ConvertTo-Json | Set-Content fc.json
  az ad app federated-credential create --id $app --parameters fc.json -o none
}
```

And a manual run of `main` must publish: `java-service.yml` now does so on `workflow_dispatch`, and
each service's `ci.yml` has the trigger.

### 1.5 Platform

```powershell
az deployment group what-if -g rg-milestone-command-dev -f bicep/platform.bicep -p bicep/platform.dev.bicepparam
az deployment group create  -g rg-milestone-command-dev -f bicep/platform.bicep -p bicep/platform.dev.bicepparam
```

Read the what-if. Expected, given the 2026-09-19 inventory: **Create** for the vault-side pieces
(storage, `identity_db`, `template_db`, `ca-identity-service`, `ca-template-service`,
`ca-integration-service`, the four jobs, `stapp-mc-field-dev`, six alerts); **Modify** for
`psql-milestone-command-dev` (a firewall rule named ours beside theirs; nothing on the server
itself if 1.3 was done), `ca-api-gateway` (identity type system → user-assigned, probes, the four
service URIs and `CORS_ALLOWED_ORIGINS` it now has by hand), **`ca-milestone-service`** (profile
`dev` → `azure`, `DB_USER` `mcadmin` → `milestone_svc`, the vault secret in place of `dbpw`, 1 vCPU →
0.5, and `EUREKA_URI` gone — this is the one to read line by line), the workspace (a 1 GB/day cap)
and the three static sites (no-op). **NoChange** for the environment and the registry. A **Delete**
anywhere is a stop.

⚠️ `ca-milestone-service` comes up on the new login only after 1.6's bootstrap job has created it —
so between this deploy and 1.6 the app restarts on a failed connection. Run 1.6 straight after; it
takes a minute.

⚠️ *found 2026-09-19, three times:* the first `create` failed at parameter resolution with
`KeyVaultParameterReferenceSecretRetrieveFailed … Access denied to first party service` — the
vault needs `enabledForTemplateDeployment: true` for `getSecret()`; `keyvault.bicep` sets it now,
and it took a foundation re-run. The what-if also showed the three hand-made static sites losing
`provider`/`repositoryUrl`/`branch` — the module now states them, so they are a no-op. And the
Postgres Entra-administrator child cannot be *predicted* while the server still has Entra auth
disabled (`BadRequest` in what-if); run the first deploy without `MC_DEPLOYER_OBJECT_ID`, then a
second with it once the server reports `activeDirectoryAuth: Enabled`. Ran in ~9 min.

Postgres takes ~10 minutes. The gateway and integration-service come up; the three database
services come up *failing* — their databases have no roles and no schema yet (1.6). That is the
designed order, not a fault: `SchemaVersionGuard` refuses to serve against an un-migrated database
and Container Apps restarts it until the schema exists.

### 1.6 Bootstrap the database, migrate, watch them come up

```powershell
$rg = "rg-milestone-command-dev"
az containerapp job start -n job-bootstrap-db -g $rg          # roles + grants, from the vault's passwords
az containerapp job execution list -n job-bootstrap-db -g $rg -o table
az containerapp job logs show -n job-bootstrap-db -g $rg --container job-bootstrap-db --format text
# expect: ok milestone_svc -> milestone_db … bootstrap complete

foreach ($s in 'milestone','identity','template') { az containerapp job start -n "job-migrate-$s" -g $rg -o none }
az containerapp job execution list -n job-migrate-milestone -g $rg -o table   # Succeeded

az containerapp list -g $rg --query "[].{app:name, running:properties.runningStatus, fqdn:properties.configuration.ingress.fqdn}" -o table
```

CI does 1.6's migrate step on every later push; the bootstrap job runs once, and again only for §4.

⚠️ *found 2026-09-19, twice:* the bootstrap's first run died with `permission denied for schema
public` — a table's new owner must already hold `CREATE` on the schema before `REASSIGN OWNED` can
hand it over, so the schema grant now comes first. And `job-migrate-milestone` refused with
*"resolved migration not applied"* for V7–V12: the hand-built `caj-migrate` had applied a `V900` dev
seed, so everything below it is out of order to Flyway. `FLYWAY_OUT_OF_ORDER=true` on the jobs; the
migrations were genuinely pending and applied cleanly. Identity and template migrated first time.

**Proof through the gateway**, with a user token the CLI can mint for the API:

```powershell
$tok = az account get-access-token --resource api://milestone-command --query accessToken -o tsv
curl -s -H "Authorization: Bearer $tok" $gw/api/v1/projects          # milestone-service, as milestone_svc
curl -s -H "Authorization: Bearer $tok" $gw/api/v1/me                # identity-service — JIT-provisions you
curl -s -H "Authorization: Bearer $tok" $gw/api/v1/templates         # template-service — [] on a fresh library
curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $tok" -X POST $gw/api/v1/imports/p6/preview -F file=@…/meridian-t4.xml
#   403 with a PM-only account: the endpoint wants PLANNER or ADMIN. The service is reached and authorizing.
```

A service at `minReplicas: 0` takes 40–60 s to answer its first request; the gateway's response
timeout is 30 s, so **the first call to a cold service is a 504 and the second succeeds**. Either
raise `minReplicas` to 1 for the services a planner uses interactively, or accept one cold 504 a day.

### 1.7 Retire what the templates replaced

Once `ca-milestone-service` runs the `azure` profile (1.5) nothing registers with Eureka, and once
`job-migrate-milestone` has run (1.6) the old job has no caller:

```powershell
az containerapp delete -n ca-discovery-server -g $rg --yes
az containerapp job delete -n caj-migrate -g $rg --yes
az identity delete -n id-milestone-pull -g $rg          # AcrPull, attached to nothing
```

Not before: a `dev`-profile milestone-service with no registry to reach logs a retry every thirty
seconds and keeps serving, but the noise hides real errors.

### 1.8 Prove it

```powershell
$gw = az deployment group show -g $rg -n platform --query properties.outputs.gatewayUrl.value -o tsv
curl "$gw/actuator/health"                       # {"status":"UP"}
curl -i "$gw/api/v1/projects"                    # 401 with www-authenticate: Bearer — security before routing
```

Then the real test: open <https://yellow-sand-06533ac0f.7.azurestaticapps.net>, sign in, and the
exec dashboard loads from the API. If the gateway's FQDN changed (0. was skipped), the apps call the
old one and fail with a network error — fix `api-config.ts` in the three web repos and `mc-field`.

### 1.9 Field's static web app

`platform.bicep` created `stapp-mc-field-dev`. Its deployment token is the last H4 item
`angular-app.yml` waits on:

```powershell
az staticwebapp secrets list -n stapp-mc-field-dev -g $rg --query properties.apiKey -o tsv | gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN -R rachidpeaqock/mc-field
az staticwebapp show -n stapp-mc-field-dev -g $rg --query defaultHostname -o tsv
```

Put that hostname in `platform-apps.ts` (`field: null` today) in shell, dashboards and templates.

⚠️ *found 2026-09-19:* **a new site is also a new Entra redirect URI.** The web apps sign in with the
*Milestone Command Web* registration (`5281cccd-756a-4353-8ef5-908eac2d543b`), and a host it does
not list fails with `AADSTS50011` at sign-in. Add it as an **SPA** redirect (not Web — an SPA's
token redemption is cross-origin, and a Web-type URI fails with `AADSTS9002326`):

```powershell
$app = az ad app show --id 5281cccd-756a-4353-8ef5-908eac2d543b --query id -o tsv
$uris = az ad app show --id 5281cccd-756a-4353-8ef5-908eac2d543b --query spa.redirectUris -o json | ConvertFrom-Json
$uris += "https://<new host>"
@{ spa = @{ redirectUris = $uris } } | ConvertTo-Json -Depth 3 | Set-Content spa.json
az rest --method patch --url "https://graph.microsoft.com/v1.0/applications/$app" --headers "Content-Type=application/json" --body "@spa.json"
```

Entra replicates registration changes to its token endpoints in a few minutes; a sign-in in that
window can pass the authorize step and still fail the token step with `9002326`. Wait, reload, retry.

### 1.10 Budget

```powershell
az deployment sub create -l francecentral -f bicep/budget.bicep -p env=dev opsEmail=rachidouahmanetdi@gmail.com startDate=(Get-Date -Format yyyy-MM-01)
```

---

## 2. Deploy a service

**Normal path: push to `main`.** `java-service.yml` builds, tests, pushes the image and the
migration image, runs `job-migrate-<svc>` against the live database, waits for `Succeeded`, then
`az containerapp update --image …:<sha>` and waits for the new revision to report `Healthy`. The
step summary shows the revision name. A failed migration stops before the update; the running
revision is untouched.

**By hand, same order:**

```powershell
$svc = "mc-milestone-service"; $app = "ca-milestone-service"; $job = "job-migrate-milestone"; $tag = "<sha or main>"
az containerapp job update -n $job -g $rg --image "acrmilestonecommanddev.azurecr.io/$svc-migrate:$tag" -o none
az containerapp job start  -n $job -g $rg
az containerapp update -n $app -g $rg --image "acrmilestonecommanddev.azurecr.io/${svc}:$tag"
az containerapp revision list -n $app -g $rg --query "[].{rev:name, active:properties.active, health:properties.healthState, traffic:properties.trafficWeight}" -o table
```

**Redeploy the whole estate** (a Bicep change): §1.4's two commands. `imageTag` defaults to `main`,
so a platform redeploy moves every app back to `:main` — which is whatever last passed CI, i.e. the
same image, and creates no new revision unless the template changed.

---

## 3. Roll back

Container Apps keeps the previous revisions. Single-revision mode means the old one is deactivated,
not deleted:

```powershell
az containerapp revision list -n ca-milestone-service -g $rg --query "[].{rev:name, created:properties.createdTime, image:properties.template.containers[0].image, health:properties.healthState}" -o table
az containerapp revision activate -n ca-milestone-service -g $rg --revision <previous>
az containerapp ingress traffic set -n ca-milestone-service -g $rg --revision-weight <previous>=100
```

One caveat, and it is the important one: **a migration is not rolled back by rolling back the
image.** Flyway migrations here are forward-only by design (the audit table is `REVOKE`d against
`DELETE`; nothing here writes a down script). A migration that added a column is harmless to the
previous image; one that renamed or dropped is not — and the rule since MC-304 is that such a
migration ships in two releases (add, deploy, then remove), so that the previous image always runs
against the current schema. Check the migration that shipped before activating the old revision.

The gateway rolls back the same way. Rolling back a **front end** is a redeploy of the previous
commit (`gh workflow run` on that SHA) — Static Web Apps keeps no revisions.

---

## 4. Rotate a secret

**A service's database password** — the vault is the source of truth, the bootstrap job syncs
Postgres to it, the app picks it up on restart:

```powershell
$bytes = New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
az keyvault secret set --vault-name kv-mc-milestone-dev --name pg-milestone-svc-password --value ([Convert]::ToBase64String($bytes) -replace '[^A-Za-z0-9]','x') -o none
az containerapp job start -n job-bootstrap-db -g $rg          # ALTER ROLE … PASSWORD from the vault
az containerapp revision restart -n ca-milestone-service -g $rg --revision (az containerapp show -n ca-milestone-service -g $rg --query properties.latestRevisionName -o tsv)
```

Between the job and the restart the running replicas hold pooled connections opened with the old
password; they keep working (Postgres authenticates at connect, not per query). New connections
fail for that window — seconds, if the restart follows the job.

**The evidence storage key:** `az storage account keys renew -n <account> -g $rg --key primary`,
then redeploy `platform.bicep` — `storage.bicep` rewrites `evidence-connection-string` from
`listKeys()` — then restart `ca-milestone-service`. Rotate `secondary` first if you want zero
downtime: the app holds key 1; renewing key 2 costs nothing, and the module always writes key 1.

**The Postgres admin password:** `az keyvault secret set … pg-admin-password`, then redeploy
`platform.bicep` (the parameter file reads it with `getSecret()`, and the server resource applies
it). Nothing running uses this password — only the bootstrap job and you.

**The automation's client secret** (§11) — mint in Entra, write to the vault, and nothing restarts:
the only reader is `load.yml`, which fetches it per run. From this machine the vault's data plane is
unreachable, so the write goes through ARM with a secure parameter, the same way §1.3 wrote the
passwords. The value never appears in a terminal:

```powershell
$app = 'fad7865a-cb9a-4655-8b69-e9ec57211f95'
$new = az ad app credential reset --id $app --append --display-name "load-$(Get-Date -f yyyy-MM)" --years 1 --query password -o tsv
az deployment group create -g $rg -n automation-secret -f bicep/vault-secret.bicep -p name=automation-client-secret value=$new -o none
Remove-Variable new
az ad app credential list --id $app -o table            # then delete the previous keyId
az ad app credential delete --id $app --key-id <old>
```

---

## 5. Restore drill

The plan's Phase 7 calls for "a restore drill actually performed". This is the drill. Do it once
against dev, and write the date and the time-to-restore at the bottom of this section.

```powershell
# 1. Pick a point in time within the retention window (7 days in dev).
$when = (Get-Date).AddMinutes(-30).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# 2. Restore to a NEW server. Never over the live one.
az postgres flexible-server restore -g $rg -n psql-milestone-command-dev-drill --source-server psql-milestone-command-dev --restore-time $when
# ~10–15 minutes. The restored server has the same admin login and password, all databases, all roles.

# 3. Prove the data is there. ⚠️ found 2026-09-19: the restored server has NO firewall rules —
#    nothing can connect until one exists. From a machine that can reach 5432:
az postgres flexible-server firewall-rule create -g $rg -n psql-milestone-command-dev-drill -r me --start-ip-address <your ip> --end-ip-address <your ip>
#    From the development machine (which cannot): AllowAzureServices + a one-off job, then read it with ops-logs.yml —
az postgres flexible-server firewall-rule create -g $rg -n psql-milestone-command-dev-drill -r AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
#    az containerapp job create -n job-drill-check -g $rg --yaml drill-job.yaml   (postgres:17-alpine, PGHOST=<drill fqdn>, PGPASSWORD=keyvaultref pg-admin-password, psql -c "select count(*) from milestone" …)
$env:PGPASSWORD = az keyvault secret show --vault-name kv-mc-milestone-dev -n pg-admin-password --query value -o tsv
psql "host=psql-milestone-command-dev-drill.postgres.database.azure.com dbname=milestone_db user=mcadmin sslmode=require" -c "select count(*) from milestone; select max(created_at) from milestone_log;"
Remove-Item Env:PGPASSWORD

# 4. Point ONE service at it and read through the API (optional, and the real proof):
az containerapp update -n ca-milestone-service -g $rg --set-env-vars "DB_URL=jdbc:postgresql://psql-milestone-command-dev-drill.postgres.database.azure.com:5432/milestone_db?sslmode=require"
#    … open Dashboards, see the data as of $when …
az containerapp update -n ca-milestone-service -g $rg --set-env-vars "DB_URL=jdbc:postgresql://psql-milestone-command-dev.postgres.database.azure.com:5432/milestone_db?sslmode=require"

# 5. Delete the drill server. It bills like the real one.
az postgres flexible-server delete -g $rg -n psql-milestone-command-dev-drill --yes
```

If the real server is lost, step 4 is the recovery: restore, repoint the three `DB_URL`s (or
redeploy `platform.bicep` after renaming), and the evidence blobs are untouched in storage — the
audit rows reference them by digest.

| Drill | Date | Restore point → usable | Notes |
|---|---|---|---|
| 1 | 2026-09-19 | restore 7 min; **usable 12 min** — 5 of them finding that a restored server has **no firewall rules** (PITR does not copy them; step 3 below now adds one) | 32 milestones, 25 audit rows, Flyway history 900/6/5 at the 11:11 UTC point (the 11:19 migration correctly absent), owner `milestone_svc`. Verified with a one-off job inside the environment (`docker.io/library/postgres:17-alpine`, admin password by vault reference), because port 5432 is unreachable from the development machine. Drill server deleted 11:58 |

---

## 6. When an alert fires

All alerts email `ag-mc-dev-ops`. Each says what it is; this is what to do first.

| Alert | Means | First command |
|---|---|---|
| `…-gateway-5xx` | users are seeing errors | `az containerapp logs show -n ca-api-gateway -g $rg --type console --tail 100` — a 503 with `__unavailable` in the path is the circuit breaker: the service behind it is down, look there |
| `…-<app>-restarts` | crash loop | `az containerapp logs show -n <app> -g $rg --type system --tail 50` then `--type console`. "Database is not migrated" → run `job-migrate-<svc>`. "Failed to fetch secret" → the vault role or the secret name. OOM → the memory in `container-app.bicep` |
| `…-postgres-down` | everything is down | Azure status page first, then `az postgres flexible-server show -n psql-milestone-command-dev -g $rg --query state`. If `Stopped`: `az postgres flexible-server start`. The free-trial spending limit stops servers without warning — check `az account show --query state` |
| `…-postgres-storage` | 80 % of 32 GB | autoGrow will handle it; the alert exists so the cost is not a surprise. `select pg_size_pretty(pg_database_size('milestone_db'))` |
| `…-postgres-cpu` | burst credits draining | which query: `select query, calls, mean_exec_time from pg_stat_statements order by total_exec_time desc limit 10` (extension needs enabling once) |
| `…-webpubsub-connections` | the Free tier's 20 connections are nearly used (16) | `webpubsub.bicep` → `sku: Standard_S1`, redeploy `platform`; ~€45/month. Until then the 21st board falls back to polling — it still works |
| budget 80 % / forecast 100 % | money | `az consumption usage list` or the portal's Cost analysis by resource. The usual suspect is a container app that stopped scaling to zero |

---

### 6.1 Is the live channel late?

Measure it from the database, not from a laptop: on 2026-09-19 the development machine's clock
was **+58 s** against Azure, and frames stamped with the server's `at` looked a minute late when
they had arrived in one second. The truth is one query, run as a one-off job (the shape of
`job-bootstrap-db`, `postgres:17-alpine`, admin password by vault reference):

```sql
select id, kind, created_at, sent_at, sent_at - created_at as delay from outbox order by id desc limit 20;
select name, lock_until, locked_at, timezone('utc', now()) as db_now from shedlock;   -- outbox-relay should cycle every ~1 s
```

`delay` of a few seconds is the relay's tick. A row with `sent_at` null for minutes means the
relay is not sending: `ops-logs.yml` on `ca-milestone-service` for `Relay paused` (Web PubSub
refused) or nothing at all (no `REALTIME_ENDPOINT` — the module is off and the row will wait
forever; prune or set the endpoint).

## 7. Reading the logs

Console output of every container goes to `log-milestone-command-dev`. The gateway logs a line per
request with the route id; the services log at INFO with the caller's `oid` on writes.

```kusto
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "ca-milestone-service"
| where Log_s has "ERROR"
| project TimeGenerated, Log_s
| order by TimeGenerated desc
| take 50
```

```kusto
// Restarts and probe failures — the platform's view, not the app's
ContainerAppSystemLogs_CL
| where ContainerAppName_s == "ca-api-gateway"
| where Reason_s in ("ContainerCrashing", "ProbeFailed", "ContainerTerminated")
| project TimeGenerated, Reason_s, Log_s
| order by TimeGenerated desc
```

```powershell
az monitor log-analytics query -w (az monitor log-analytics workspace show -g $rg -n log-milestone-command-dev --query customerId -o tsv) --analytics-query "ContainerAppConsoleLogs_CL | where TimeGenerated > ago(1h) | summarize count() by ContainerAppName_s"
```

---

## 8. Cost, and the free trial

Fixed monthly, dev, roughly: Postgres B1ms ~€13 · two always-on replicas (gateway, milestone) ~€20 ·
ACR Basic ~€5 · storage, vault, logs under the daily cap ~€2 · the three scale-to-zero services and
the jobs ~€0 when idle. **~€40.** The budget is 60.

The trial's **spending limit** disables the subscription when credit runs out — every container
stops, the database stops, the static sites stay up (Free tier). Nothing is deleted. Removing the
limit converts to pay-as-you-go; that is a decision, not a step in this runbook.

### 8.1 What that looks like when it happens (2026-09-25)

It happened, and it does not announce itself. Nothing in the estate says "the subscription has a
billing problem"; what you get is a set of unrelated-looking failures:

| Symptom | What it looks like |
|---|---|
| CI cannot publish | `az acr login` → "Looks like you don't have access to registry …". With `--debug`: `GET https://<acr>.azurecr.io/v2/ → 403`, empty body — refused at the door, before any token exchange, while ARM reports the registry `Succeeded`, public, well inside its quota, with AcrPush correctly assigned |
| Nothing answers | every app's FQDN times out, and `az containerapp show` has `"deploymentErrors": "ContainerAppNotFoundInCluster"` with `configuration.ingress: null` — the ARM record survives, the app is gone from the cluster |
| Postgres looks fine | `state: Ready`. ARM reads are not the data plane |
| ⚠️ The CLI says everything is fine | `az account show` reports `"state": "Enabled"` — it answers from the cached profile |

The one place that tells the truth:

```powershell
az rest --method get --url "https://management.azure.com/subscriptions/$sub?api-version=2022-12-01" --query "{state:state, policies:subscriptionPolicies}"
# state: Warned | Enabled | PastDue | Disabled   ·   quotaId: FreeTrial_… · spendingLimit: On
```

**`Warned`** is the state this subscription reached: credit exhausted or the trial ended, compute
deallocated, data planes refused, ARM records kept for a grace period and then deleted with the
backups. The fix is billing — a payment method and pay-as-you-go — and it is nobody's but the
owner's. Afterwards: `az deployment group create` both stages (the templates are the estate, so this
is not a rebuild by hand), `job-bootstrap-db`, the migrate jobs, then the CI dispatch on each service
repo. §5's drill is what proves the database came back.

⚠️ **Before the grace period ends, anything in that database that is not in a repo is gone** — the
projects and templates made by hand during a walkthrough, not the schema or the seed. A `pg_dump`
is the only copy; from a GitHub runner, because this network cannot reach 5432.

Untagged ACR manifests accumulate one per push:

```powershell
az acr manifest list-metadata -r acrmilestonecommanddev -n mc-milestone-service --query "[?tags==null].digest" -o tsv | % { az acr repository delete -n acrmilestonecommanddev --image "mc-milestone-service@$_" --yes }
```

---

## 9. Not hardened yet — the list, so it is not a surprise

In the order they would matter for a first paying customer:

| | Today | Hardening |
|---|---|---|
| Network | Postgres, vault and storage on public endpoints with Azure-services firewall rules | VNet-integrated Container Apps environment (a new environment — the gateway FQDN changes), private endpoints, `publicNetworkAccess: Disabled` |
| Evidence access | connection string in the vault | `DefaultAzureCredential` in milestone-service + *Storage Blob Data Contributor* on `id-mc-apps` — a service change, small |
| Edge | gateway FQDN called directly by the apps; CORS exact in the cloud (`CORS_ALLOWED_ORIGINS` from Bicep) since Sprint 24 | `front-door.bicep` in front of the four sites and `/api` — one origin, WAF, custom domain; then `api-config.ts` → `''` |
| Vault | soft delete, no purge protection | `env == 'prod'` turns it on (already in `keyvault.bicep`) |
| Backups | 7-day PITR, LRS storage | 14-day + geo-redundant and GRS storage under `env == 'prod'` (already in the templates); a *performed* drill (§5) |
| Identity | Contributor-on-group for the GitHub identity | split: a deploy identity per repo with AcrPush + Container Apps Contributor only |
| Load | measured once, from a runner (`load/README.md`, Sprint 24) — `load.yml` seeds, mints the machine identity's token and runs k6 | a run per release, and the results table kept |
| Machine identity | one registration, one secret in the vault, a year's expiry, the `SERVICE` role — every read plus the real date (§11) | a certificate credential instead of a secret; workload identity federation if the caller is ever a GitHub workflow rather than k6 |
| Security review / pen test | none | Sprint 24; the gateway is the surface |
| Field app registration | not created | needs the iOS bundle id (MC-004) |

---

## 10. Tear down (dev only)

Everything in the group, keeping the group, the Entra registrations and the GitHub identity:

```powershell
az account show -o table        # Azure subscription 1 — read it
az deployment group create -g rg-milestone-command-dev --mode Complete --template-uri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/empty-template/azuredeploy.json" --what-if
```

Complete mode with an empty template deletes what is not in the template — i.e. everything. Read the
what-if; it lists every resource by name. Then the same without `--what-if`. The vault is
soft-deleted for 30 days (`az keyvault purge` to free the name sooner); Postgres is gone with its
backups, which is why §5 is done *before* anyone relies on this.

---

## 11. The machine identity

**Milestone Command Automation** (`appId fad7865a-…`, service principal `6ef0a031-…`) — Sprint 24,
the first path on the platform no person signs in for. It holds one thing: the API's `SERVICE` app
role, which is *application-only* (`allowedMemberTypes: Application`), so Entra will never put it in
a user's token. Its secret lives in the vault as `automation-client-secret` and nowhere else;
`AUTOMATION_CLIENT_ID` on `mc-platform-infra` is the identifier, not a secret.

**What the services let it do** — pinned by `ServiceRoleTest` (milestone), `TemplateLibraryTest`,
`ImportEndpointTest`: every read, the real-date change (and the evidence upload that rides on the
same check), a project's live-channel group. Not a re-baseline, not a structure edit, not a template
write, not a P6 preview, not a new project, not a calendar. identity-service names it
**"Automation (fad7865a)"** on every activity row it writes (`CurrentActor`, from the role — a
client-credentials token carries no `name`), and milestone-service's audit trail records its
service-principal oid as the actor: a specific, revocable identity, never "the system".

**Who uses it:** `load.yml`, from a GitHub runner — reads the secret (Key Vault Secrets User for the
CI identity, `foundation.bicep` `ciPrincipalId`), mints a token at
`login.microsoftonline.com/<tenant>/oauth2/v2.0/token` with `scope=api://milestone-command/.default`,
masks both, runs k6. A token from here, for a probe:

```powershell
# a throwaway secret, used once and deleted — never the vault's
$probe = az ad app credential reset --id fad7865a-cb9a-4655-8b69-e9ec57211f95 --append --display-name probe --years 1 --query password -o tsv
$tok = (Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/5b6fa978-e0da-4f01-bb84-37309bc3fe60/oauth2/v2.0/token" -Body @{ client_id='fad7865a-cb9a-4655-8b69-e9ec57211f95'; client_secret=$probe; grant_type='client_credentials'; scope='api://milestone-command/.default' }).access_token
Remove-Variable probe
az ad app credential delete --id fad7865a-cb9a-4655-8b69-e9ec57211f95 --key-id (az ad app credential list --id fad7865a-cb9a-4655-8b69-e9ec57211f95 --query "[?displayName=='probe'].keyId | [0]" -o tsv)
```

**Rotate:** §4. **Revoke, now:** `az ad sp update --id 6ef0a031-3bc4-44a2-9faa-1c1fc1cf2491 --set accountEnabled=false`
— tokens already issued live out their hour; the gateway validates signature and audience, not
revocation, and an hour is the ceiling by design. Deleting the role assignment on the API's service
principal (`az rest … /servicePrincipals/941936a5-…/appRoleAssignedTo`) is the slower, permanent form.

⚠️ **The gateway's write limiter counts it as one caller.** 60 writes a minute, burst 40 (B14). That is
why `load/pm-tree.js` writes at 48/min from this identity and reports 429s as a threshold — a run
that raised the limit for itself would prove nothing about the platform a crew lead meets.
