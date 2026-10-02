# Schema migration — evolving an existing database with the model

`Connect-PSSqlRepository -EnsureCreated` creates a database from the registered model, and adds
tables the model gained since. It never changes a table that already exists. The three surfaces
on this page close that gap the way EF Core migrations do, without a migrations project:

| Surface | What it does |
|---|---|
| `Compare-PSSqlRepositorySchema` | Reports how the connected database differs from the model. Changes nothing. |
| `Update-PSSqlRepositorySchema` | Applies the additive differences in one batch and records the run. `-Script` prints the SQL instead; `-WhatIf` previews. |
| `Connect-PSSqlRepository -Migrate` | `-EnsureCreated` plus the additive differences, every time you connect. |

- [How it works](#how-it-works)
- [Additive versus destructive](#additive-versus-destructive)
- [Walkthrough](#walkthrough)
- [The history table](#the-history-table)
- [Scripts for a DBA](#scripts-for-a-dba)
- [What is never touched](#what-is-never-touched)
- [Transactions](#transactions)
- [Limitations](#limitations)
- [Providers and extensions](#providers-and-extensions)

---

## How it works

There is no model snapshot to keep in sync. The migrator reads the live catalogue of the
connected database through the provider's own reverse-engineering component (the one
`dotnet ef dbcontext scaffold` and `Import-PSSqlRepositorySchema` use), rebuilds it as a model
of the same shape EF Core's `ModelSnapshot` has, and hands both sides to EF Core's own model
differ. The resulting operations are classified (see below), rendered by the provider's
migrations SQL generator and executed by its migration command executor — the same components
that run `dotnet ef database update`.

Only tables the model maps take part. Formatting differences the catalogue introduces
(`((0))` for a default of `0`, `([Email] IS NOT NULL)` for an index filter, `NO ACTION` for a
`Restrict` foreign key on SQL Server) are normalised away, and a database created from the
model compares as *no changes*.

## Additive versus destructive

The migrator is forward-only and, by default, additive. Each operation in a plan is one of:

| Status | Meaning | Applied by default |
|---|---|---|
| `Planned` | Additive: create table, add column, create index, add foreign key / unique / check constraint, widen a column (`nvarchar(50)` → `nvarchar(100)`, `int` → `bigint`), rename an index | yes |
| `SkippedDestructive` | Can lose data, drop an object or loosen a constraint for good: drop table / column / index / constraint, narrow a column, NULL → NOT NULL, NOT NULL → NULL, change identity | only with `-AllowDestructive` |
| `SkippedDependent` | Additive, but it re-creates an object whose drop was held back (an index or constraint defined differently in the database) | only with `-AllowDestructive` |
| `SkippedSeedData` | `HasData` seed rows of a compiled context | never |
| `SkippedUnsupported` | Raw SQL or operation kinds the migrator does not run | never |
| `Suppressed` | Reported by the differ but identical once formatting is ignored | never (nothing to do) |

Held-back operations are written to the warning stream every time, so a model that dropped a
property keeps reminding you until you either apply the drop with `-AllowDestructive` or put the
property back.

Removing a `NOT NULL` is held back on purpose. A PowerShell class cannot say that a string is
required, so every string property is nullable in the model; applying that by default would strip
the constraints a DBA put on the database the first time you ran `Update-PSSqlRepositorySchema`.

`-AllowDestructive` prompts before running (ShouldContinue); add `-Force` in scripts.

## Walkthrough

```powershell
Import-Module PSSqlRepository

class Customer : IEntity[int] {
    [int]    $Id
    [string] $Name
    [string] $Email        # new since the database was created
}

Register-PSSqlRepositoryEntity -ProviderName Sqlite -EntityType ([Customer])
$null = Connect-PSSqlRepository Sqlite -Path .\app.db

# What would change?
$plan = Compare-PSSqlRepositorySchema
$plan.HasChanges                                          # True
$plan.Operations | Format-Table Status, Kind, Table, Column, Description
#   Planned  AddColumn  Customer  Email  AddColumn Customer.Email TEXT NULL

# Apply it. Returns a result object; the SQL that ran is on $result.Plan.Script.
$result = Update-PSSqlRepositorySchema
$result.Applied, $result.MigrationId                      # True, 20261001120000123

# Nothing left to do.
(Compare-PSSqlRepositorySchema).HasChanges                # False
```

The same in one step, as part of connecting:

```powershell
$null = Connect-PSSqlRepository Sqlite -Path .\app.db -Migrate
```

`-Migrate` implies `-EnsureCreated`: a missing database is created from the model (no history
row, there was nothing to migrate), missing tables are added, and then columns, indexes and
foreign keys are reconciled additively. Destructive differences are warnings. It cannot be
combined with `-ImportSchema`, whose model is by definition the database.

## The history table

Every `Update-PSSqlRepositorySchema` or `-Migrate` run that changes something writes one row to
`__PSSqlRepositoryMigrations`, created on first use, in the same batch (and transaction) as the
schema change it records:

| Column | Content |
|---|---|
| `MigrationId` | UTC timestamp `yyyyMMddHHmmssfff`; primary key |
| `ProductVersion` | PSSqlRepository.Core version that applied it |
| `ProviderName` | `Sqlite`, `SqlServer`, … |
| `AppliedOnUtc` | When |
| `Operations` | JSON array of every classified operation of the plan, held-back ones included |
| `Script` | The SQL that was executed |

`Compare-PSSqlRepositorySchema` returns the newest rows in `History` (`-HistoryCount`, default
10). `Update-PSSqlRepositorySchema -NoHistory` applies without recording. The table is skipped by
`Import-PSSqlRepositorySchema` and is never reported as unmanaged.

## Scripts for a DBA

```powershell
Update-PSSqlRepositorySchema -Script | Set-Content .\migration-$(Get-Date -Format yyyyMMdd).sql
Update-PSSqlRepositorySchema -Script -AllowDestructive         # include the drops
```

The script is in the provider's dialect (batches separated by `GO` on SQL Server) and includes
the history table DDL and the history row, so applying it by hand leaves the same audit trail
as applying it through the module. `-Script` executes nothing.

## What is never touched

- **Tables the model does not map.** They are listed on `Compare-PSSqlRepositorySchema` as
  `UnmanagedTables` and left alone — no drop, no alter, not even their foreign keys.
- **Defaults, collations and comments the model does not declare.** A default a DBA put on a
  column stays unless the model declares a different one.
- **Seed data and raw SQL.**
- **`__PSSqlRepositoryMigrations`, `__EFMigrationsHistory`, `sqlite_sequence`.**

## Transactions

Schema changes run in their own transaction, owned by EF Core's migration command executor:

- **SQL Server**: one transaction for the whole plan, history row included; a failure rolls
  everything back.
- **SQLite**: adding tables, columns and indexes runs in one transaction. Altering or dropping a
  column, or changing a constraint, makes EF Core rebuild the table, and the `PRAGMA foreign_keys`
  toggles around a rebuild cannot run inside a transaction — such a plan commits in more than one
  step. The history row is always the last statement, so a failure never leaves a row for a plan
  that did not finish. Because a rebuild recreates the table from the model, it would also carry
  out every held-back drop on that table; on SQLite the migrator therefore holds back the
  rebuilding operations (column alterations, foreign key / primary key / unique / check constraint
  changes) on any table that has held-back changes, and reports them as `SkippedDependent` until
  you run with `-AllowDestructive`.

`Compare-` and `Update-PSSqlRepositorySchema` refuse to run while an explicit
`Start-PSSqlRepositoryTransaction` is open: complete or undo it first.

## Limitations

- **Columns are never renamed.** EF Core's differ guesses a rename whenever one column vanished
  and another of the same shape appeared; acting on that guess would silently move unrelated data
  (an obsolete `TEXT` column into a new one). The migrator turns every such guess into an
  `AddColumn` (applied) plus a `DropColumn` (held back). To keep the data of a renamed property,
  rename the column yourself first, or add the new column, copy the data and apply the drop
  afterwards. Index renames *are* applied.
- **Identity cannot be altered.** Making an existing integer key an identity column (or the
  reverse) is reported as destructive; SQL Server has no in-place `ALTER` for it either.
- **Store types the provider cannot parse** (user-defined types, unusual aliases) are compared by
  name only; a difference is reported as destructive rather than guessed at.
- **Composite keys, views and keyless tables** follow the entity cmdlets' rules: a compiled
  context may map them and they migrate like any other table, but `Register-PSSqlRepositoryEntity`
  still requires `IEntity<TKey>`.
- The migrator uses the connected session's connection and credential; it needs the right to
  read the catalogue and to run DDL.

## Providers and extensions

Every surface honours `SqlProviderCapabilities.SchemaManagement`, which the built-in providers
and every `SqlProviderExtension`-based extension advertise by default. An extension whose EF
Core provider has no usable migrations SQL generator can clear the flag from `Capabilities` to
opt out; `-Migrate` and the two cmdlets then fail with a clear message instead of running.

`-Migrate` reaches the provider through the connect context by name, so extensions built
against the current SDK get it without a rebuild. `-EnsureCreated` is unchanged.
