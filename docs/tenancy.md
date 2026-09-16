# Tenancy — the decision, and why it is not a migration

**Status:** decided 2026-09-16 · **Trigger for implementation:** the first customer whose people
are not in the current Entra tenant · **Supersedes** the open item in
[`platform-architecture.md` §0b](./platform-architecture.md#0b-three-gaps-worth-naming-rather-than-discovering)

---

## 0. What was actually open

Every document in this repository assumed multi-tenant isolation, and the schema has no
`tenant_id`. §0b said it *"must be settled before customer two"* and left two options standing:
a `tenant_id` column on every table with row-level security, or a database per tenant.

I recommended taking it in Sprint 14 *"while the tables are near-empty, because it gets harder
with every row."* ⚠️ **That reasoning was right for one option and wrong for the other, and the
other is the one this platform should choose.** So this document settles the decision, records
what is already true, and defers the build to its trigger — the same test that parked MC-214
and `activity-service`.

---

## 1. What a tenant is here

Not what it usually means in SaaS. This platform is run by a **contractor** and used by that
contractor's people *and their client's* people — Meridian Energy's engineers looking at the
same project the contractor's crews are updating. Both sides see the same milestones on
purpose. **That is one tenant, not two.**

A second tenant appears only when the platform is sold to a **second contractor**, who must
never see the first one's projects — and, since contractors bid against each other, must never
see the first one's delay reasons, evidence photographs or claim history. That is the isolation
requirement, and it is a hard one: a cross-tenant leak here is not a privacy incident, it is
handing a competitor a claims file.

**Tenant = contractor organisation.**

## 2. How a request names its tenant — already decided, by a decision made elsewhere

[`azure-deployment-plan.md` §7](./azure-deployment-plan.md#7-auth--roles) settled that external
users come in as **Entra B2B guests in the contractor's tenant**, not through a second identity
system. That choice has a consequence nobody wrote down: **every user of a given contractor
carries that contractor's Entra tenant id in the `tid` claim** — employees natively, the
client's engineers as guests. A second contractor is a second Entra tenant, and their users
carry a different `tid`.

So the tenant key is **`tid`**, it is already in every token, it is signed, and no table needs to
store it to know it. ✅ Nothing to build.

## 3. The isolation model: database per tenant, not `tenant_id` + RLS

| | `tenant_id` column + row-level security | Database per tenant |
|---|---|---|
| Rows touched now | **Every table, every row, a backfill** | None |
| Queries touched now | **Every one** must carry the predicate, or RLS must be trusted to add it | None |
| One missed predicate | A cross-tenant read that looks like a normal result | Impossible — the connection cannot see the other database |
| Per-tenant export or deletion at contract end | A filtered dump, and a `DELETE` on the most protected table in the system | `pg_dump` and `DROP DATABASE` |
| Noisy neighbour | Shared everything | Shared server, separate everything else |
| Number of tenants it suits | Thousands of small ones | **A handful of large ones** — which is exactly this market |
| Retrofit cost later | **Grows with every row and every query written single-tenant** | ⚠️ **Does not grow with rows at all.** It grows with the number of places that hold a `DataSource` assumption outside a request |

**Database per tenant.** The audit table is `REVOKE`d against `DELETE` — the platform's whole
promise rests on nobody being able to remove a row — and the isolation model must not be the
one that asks that same table to police *which* rows a caller may see. The platform already runs
one database per service; one database per service *per tenant* is the same rule applied twice,
and the rule §6 of the platform architecture calls its hardest ("no service may query another
service's database — ever") extends to it without a new sentence.

## 4. Why the cost does not grow with rows

Under database-per-tenant, **no table changes and no query changes.** What changes is which
connection a request gets, decided from `tid` before the first query. The rows that exist today
are simply the first tenant's rows. Nothing about them needs a column, a backfill, or a
predicate.

So the argument *"do it now while the tables are empty"* was importing the cost model of the
option we are not choosing. ⚠️ **Under the chosen option, the thing that grows over time is not
data — it is code that assumes a single `DataSource` outside a request.** That list is short and
is worth writing down now so it is not discovered later:

| Place | Why it is not request-scoped | What it needs at implementation |
|---|---|---|
| `StatusSweeper` (`@Scheduled`, hourly) | Runs on a timer, no token, no `tid` | Iterate every configured tenant, set the routing key, sweep, clear it |
| `SchemaVersionGuard` (startup) | Checks the schema exists before serving | Check every tenant's database, refuse to start if any is behind |
| Flyway (`mvn flyway:migrate`, a pipeline step) | One URL per invocation | One invocation per tenant, and CI must know the list |
| ShedLock | One lock table per database | One lock per tenant per job, or the sweep serialises across tenants |
| `compose.yml` | One database per service | One `CREATE DATABASE` per tenant per service in `init/` |

Every item on that list is *additive* at implementation time and none of them is made harder by
a row being written today. **That is the whole reason this can wait.**

## 5. What is true today, and what already enforces it

✅ **The platform is single-tenant, and that single tenancy is enforced at three places, not
assumed.** All three services pin `issuer-uri` to one Entra tenant:

```yaml
issuer-uri: https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0
```

A token issued by any other Entra tenant fails issuer validation at the gateway, at
`milestone-service` and at `identity-service`, before any handler runs. **There is no code path
today by which a second contractor's user reaches a query.** That is a real boundary, and it is
why the absence of `tenant_id` has never been a defect — only a decision left open.

⚠️ **It is a boundary that a configuration change can quietly remove.** Flipping the app
registration to multi-tenant (`/organizations` or `/common` as issuer) so that a second
contractor's people *can* sign in is exactly the step that makes the routing datasource
necessary, and nothing would fail if somebody did the first without the second — every tenant's
users would land in the first tenant's database. That is the one thing worth guarding before
the trigger, and it is guarded below.

## 6. The trigger, and what happens when it fires

**Trigger: the first customer whose people are not in the current Entra tenant.** Not a
sprint number. The same rule that parked MC-214, MC-501 and MC-502, applied to the item that
looked most like it needed doing early.

When it fires, in order:

1. **A `TenantRoutingDataSource`** (`AbstractRoutingDataSource`) keyed on `tid`, with the
   configured tenants as a map and **an unknown `tid` failing closed** — 403 before the first
   query, never a fallthrough to a default. The current database becomes the entry for the
   current tenant; behaviour is byte-for-byte unchanged until a second entry exists.
2. The five items in §4, each of which is a loop over the tenant list.
3. The app registration goes multi-tenant, **last** — because until steps 1 and 2 exist, a
   foreign token that passes issuer validation is a foreign user in the wrong database.
4. A test with two tenants: write in A, prove it is invisible in B, prove an unknown `tid`
   is refused. The isolation claim is not made until that test exists.

Estimated at 5–8 days, and — the point of this document — **no more than that in a year's time
than it is today.**

## 7. ⚠️ What not to do in the meantime

- **Do not add `tenant_id` columns "to be ready".** Under the chosen model they are dead weight,
  and their presence would invite somebody to filter on them, which would make the schema look
  isolated while the isolation lived elsewhere.
- **Do not loosen `issuer-uri`** in any service without steps 1 and 2 of §6 in place. See §5.
- **Do not write scheduled or startup code that holds a `DataSource` directly** without adding
  it to the §4 table. That table is the retrofit cost, and it is the only thing here that grows.
