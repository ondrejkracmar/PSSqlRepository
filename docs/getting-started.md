# Getting started

## Prerequisites

- PowerShell **7.4 or later**
- A SQL target: a SQL Server instance, or nothing at all for SQLite (a file is created on demand)
- For local development only: the .NET 8 and .NET 10 SDKs

## Install the module

```powershell
Install-PSResource PSSqlRepository -Repository PSGallery   # or: Install-Module PSSqlRepository
Import-Module PSSqlRepository
```

The module ships two builds and the loader picks the one matching the running runtime:

| PowerShell | .NET | Build used |
|---|---|---|
| 7.4 / 7.5 | 8 | `bin\net8.0` |
| 7.6+ | 10 | `bin\net10.0` |

Verify the import:

```powershell
Get-PSSqlRepositoryProvider | Format-Table Name, DisplayName
```

### From a source checkout

Only from the Azure DevOps repository — the GitHub mirror is a published artifact and ships no
`src/`.

```powershell
dotnet build .\src\PSSqlRepository.slnx
Import-Module .\src\PSSqlRepository\PSSqlRepository.psd1
```

`Import-Module` on the manifest under `src\` only works **after** a build — the manifest points at
`bin\<tfm>\PSSqlRepository.Commands.dll`, which does not exist in a fresh clone.

### Adding a provider that is not built in

Providers such as DuckDB ship separately as signed extensions, published to the PowerShell Gallery
as thin wrapper modules whose only content is the payload. Installing one is two steps — get the
payload, then move it into PSSqlRepository:

```powershell
Install-PSResource PSSqlRepository.Providers.DuckDB -Repository PSGallery
Install-PSSqlRepositoryExtension -FromModule PSSqlRepository.Providers.DuckDB -Trust

# restart PowerShell, then:
Get-PSSqlRepositoryExtension | Format-Table Name, Status, Reason
```

The wrapper module is a delivery vehicle, not something you import — `Install-PSSqlRepositoryExtension`
takes the payload out of it and into the module's `bin\<tfm>\Providers\` folder.

Offline, the same cmdlet takes a `.zip` from the extension's build artifact instead:

```powershell
Install-PSSqlRepositoryExtension -Path .\PSSqlRepository.Providers.DuckDB-1.0.0.zip -Trust
```

`-Trust` is required unless the extension is signed with the module's own key: the loader refuses to
instantiate plugins whose signing key it does not trust, and reports them as `Rejected` rather than
failing the import. See [extensibility.md](./extensibility.md).

---

## Define an entity type

Everything persisted through PSSqlRepository implements `IEntity[TKey]`. The module registers
`IEntity` as a type accelerator on import, so no `using namespace` is needed.

```powershell
class Customer : IEntity[int] {
    [int]    $Id
    [string] $Name
    [string] $Email
}
```

> **Put the class in its own file.** PowerShell compiles a whole script file before executing any of
> it, so a `class … : IEntity[int]` in the same file as its `Import-Module` fails to parse with
> `Unable to find type [IEntity]`. Use a two-file pattern (`run.ps1` imports, then invokes
> `model.ps1`), or paste the class at an interactive prompt after importing. `using module` does not
> help. Full explanation in [entity-model.md](./entity-model.md#4-the-two-file-pattern-and-why-it-is-needed).

> **No property initializers.** `[string] $Name = 'x'` makes every query fail with
> `There is no Runspace available to run scripts in this thread` — EF Core materialises entities on
> a thread with no PowerShell runspace. Plain typed properties only.

Register the types, then connect. Order matters: registration builds the model the session uses.

```powershell
Register-PSSqlRepositoryEntity -ProviderName Sqlite -EntityType ([Customer])
```

## Connect

```powershell
# SQLite — file created on demand
$null = Connect-PSSqlRepository Sqlite -Path .\app.db -EnsureCreated

# SQLite — in-memory, discarded on disconnect
$null = Connect-PSSqlRepository Sqlite -Memory -EnsureCreated

# SQL Server
$null = Connect-PSSqlRepository SqlServer -Server '.\SQLEXPRESS' -Database 'MyDb' -EnsureCreated
```

`-EnsureCreated` creates the schema from the registered model when it is absent. It is a development
convenience — it will not alter an existing table after the model changes.

Assign the result away (`$null = …`) in scripts. `Connect-PSSqlRepository` emits the session object,
and PowerShell's formatter derives its column layout from the first object in the output stream — a
stray session object makes every entity printed afterwards render as blank rows.

Inspect the session at any time:

```powershell
Get-PSSqlRepositorySession
```

## Write

```powershell
$c = Save-PSSqlRepositoryEntity -InputObject ([Customer]@{ Name = 'Acme'; Email = 'hi@acme.cz' }) -PassThru
"Id=$($c.Id)"
```

`Save-PSSqlRepositoryEntity` defaults to `-Mode Upsert`: a default-valued key (`0`, `null`,
`Guid.Empty`) inserts, anything else updates. Force the behaviour with `-Mode Add` / `-Mode Update`
— or use the `Update-PSSqlRepositoryEntity` proxy, which is the same pipeline with `Mode` locked.

Pipeline input works, and so do object graphs:

```powershell
$people | Save-PSSqlRepositoryEntity -EntityType ([Customer])
Save-PSSqlRepositoryEntity -InputObject $companyWithChildren -IncludeNavigations
```

## Query

```powershell
Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Top 10 -AsNoTracking
Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Id 42
```

Filter, sort, and project run in SQL:

```powershell
Get-PSSqlRepositoryEntity `
  -EntityType ([Customer]) `
  -Filter "Name -like 'A*'" `
  -OrderBy 'Name DESC' `
  -Property Id, Name `
  -Top 10
```

| Parameter | Runs where | Notes |
|---|---|---|
| `-Filter` | SQL | PowerShell-style operators (`-eq`, `-like`, `-gt`, `-and`, …), translated |
| `-Where` | PowerShell | ScriptBlock; fetches rows first — use only for what SQL cannot express |
| `-OrderBy` | SQL | `'Name'`, `'Name DESC'`, multiple columns |
| `-Property` | SQL | projection |
| `-Top` / `-Skip` | SQL | paging |
| `-Include` / `-IncludeAll` | SQL | eager-load navigations (`-Include 'Person.Company'`) |
| `-AsNoTracking` | — | read-only; skips change tracking |

A query with neither `-Top` nor `-Skip` warns once per entity type. Pass
`-SuppressUnboundedWarning` when a full scan is intended.

## Delete

```powershell
Remove-PSSqlRepositoryEntity -EntityType ([Customer]) -Id 42
Remove-PSSqlRepositoryEntity -InputObject $customer
```

## Transactions

```powershell
Start-PSSqlRepositoryTransaction
Save-PSSqlRepositoryEntity -InputObject $a
Save-PSSqlRepositoryEntity -InputObject $b
Complete-PSSqlRepositoryTransaction     # commit
```

```powershell
Undo-PSSqlRepositoryTransaction         # roll back
```

## Close the session

```powershell
Disconnect-PSSqlRepository
```

---

## Next

- [entity-model.md](./entity-model.md) — a complete model with foreign keys, graph saves, and
  joined queries
- [provider-auth-reference.md](./provider-auth-reference.md) — per-provider connect parameters
- [extensibility.md](./extensibility.md) — installing and trusting extensions
- [../TROUBLESHOOTING.md](../TROUBLESHOOTING.md) — error messages and fixes

## Tips

- Use `-AsNoTracking` for read-only queries.
- Use `-Filter` when the predicate should run in SQL; reserve `-Where` for the rest.
- Set `$env:PSSQLREPOSITORY_LOG = '<path>.log'` **before** `Import-Module` to tee structured
  diagnostics — including every extension load decision — to a file.
