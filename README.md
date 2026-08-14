# PSSqlRepository

PSSqlRepository is a PowerShell binary module for EF Core-backed SQL repositories. It provides a
clean session model, typed CRUD operations, transaction control, server-side querying, and pluggable
SQL provider/authentication extensions.

## What it does

- Connects PowerShell to SQL backends through friendly provider parameters
- Supports SQL Server and SQLite out of the box; other providers install as signed extensions
- Lets you register EF Core entity types dynamically from PowerShell — including relationships — or
  bring your own `DbContext`
- Provides server-side filtering, sorting, projection, paging, and eager loading
- Supports Add / Update / Upsert persistence flows with object-graph handling
- Keeps secrets out of warnings, errors, and diagnostics

## Install

```powershell
Install-PSResource PSSqlRepository -Repository PSGallery   # or: Install-Module PSSqlRepository
Import-Module PSSqlRepository
```

Requires PowerShell 7.4+. The module ships both a `net8.0` and a `net10.0` build and the loader
picks the one matching the running runtime — `net8.0` for PowerShell 7.4/7.5, `net10.0` for 7.6+.

> **Reading this on GitHub?** This repository is a published mirror: it carries the compiled
> module, its documentation and the Extensions SDK packages, but no source and no build. Source
> and issues live in Azure DevOps (`i-system/PSModules/PSSqlRepository`). Install from the
> PowerShell Gallery as above.

## Quick start

Entities are ordinary PowerShell classes implementing `IEntity[TKey]`. Because PowerShell compiles a
whole script before running it, the class must be parsed **after** the module is imported — so keep
the model in its own file, or paste it at an interactive prompt after `Import-Module`.

```powershell
# model.ps1
class Customer : IEntity[int] {
    [int]    $Id
    [string] $Name
}

Register-PSSqlRepositoryEntity -ProviderName Sqlite -EntityType ([Customer])
$null = Connect-PSSqlRepository Sqlite -Path .\app.db -EnsureCreated

Save-PSSqlRepositoryEntity -InputObject ([Customer]@{ Name = 'Acme' }) -PassThru
Get-PSSqlRepositoryEntity  -EntityType ([Customer]) -Top 10 -AsNoTracking

Disconnect-PSSqlRepository
```

```powershell
# run.ps1 — import first, then run the model script
Import-Module PSSqlRepository
& "$PSScriptRoot\model.ps1"
```

A full model with foreign keys, graph saves, and joined queries is in
[`docs/entity-model.md`](docs/entity-model.md).

## Main commands

| Command | Purpose |
|---|---|
| `Connect-PSSqlRepository` | Open a provider session |
| `Disconnect-PSSqlRepository` | Close the current session |
| `Get-PSSqlRepositoryProvider` | List loaded providers |
| `Get-PSSqlRepositorySession` | Inspect the current session |
| `Register-PSSqlRepositoryEntity` | Build a DbContext dynamically from PowerShell entity types |
| `Register-PSSqlRepositoryContext` | Register a custom DbContext instead |
| `Get-PSSqlRepositoryEntity` | Query entities |
| `Save-PSSqlRepositoryEntity` | Persist changes (Add / Update / Upsert) |
| `Update-PSSqlRepositoryEntity` | `Save … -Mode Update` under a discoverable verb |
| `Remove-PSSqlRepositoryEntity` | Delete entities |
| `Start-PSSqlRepositoryTransaction` | Start a transaction |
| `Complete-PSSqlRepositoryTransaction` | Commit a transaction |
| `Undo-PSSqlRepositoryTransaction` | Roll back a transaction |
| `Get-PSSqlRepositoryExtension` | Report every extension DLL found, loaded or rejected, with the reason |
| `Get-PSSqlRepositoryExtensionToken` | Read an extension's strong-name public key token |
| `Install-PSSqlRepositoryExtension` | Install an extension from a `.zip`, `.nupkg`, folder, feed, or module |
| `Uninstall-PSSqlRepositoryExtension` | Remove an installed extension and its dependencies |

## Query features

`Get-PSSqlRepositoryEntity` translates `-Filter`, `-OrderBy`, `-Property`, `-Top`, `-Skip`, and
`-Include` into SQL; `-Where` is a PowerShell-side escape hatch that fetches rows first.

```powershell
Get-PSSqlRepositoryEntity `
  -EntityType ([Customer]) `
  -Filter "Name -like 'A*' -and RowVersion -gt 3" `
  -OrderBy 'Name DESC' `
  -Property Id, Name `
  -Top 10 `
  -AsNoTracking
```

## Providers and authentication

Built-in providers:

| Provider | Connect parameters | Auth modes |
|---|---|---|
| `SqlServer` | `-Server`, `-Database`, `-TrustServerCertificate`, `-ConnectionString`, `-EnsureCreated` | `ConnectionString`, `IntegratedSecurity`, `UserPassword` |
| `Sqlite` | `-Path`, `-Memory`, `-ConnectionString`, `-EnsureCreated` | `ConnectionString`, `UserPassword` |

Details in [`docs/provider-auth-reference.md`](docs/provider-auth-reference.md).

## Extensions

Additional providers (DuckDB, MySQL, …) and authentication surfaces are separate, strong-named
packages dropped into the module's `bin\<tfm>\Providers\` or `bin\<tfm>\Auth\` folder.

They are published to the PowerShell Gallery as thin wrapper modules whose only content is the
payload. Installing one is two steps — get the payload, then move it into PSSqlRepository:

```powershell
Install-PSResource PSSqlRepository.Providers.DuckDB -Repository PSGallery
Install-PSSqlRepositoryExtension -FromModule PSSqlRepository.Providers.DuckDB -Trust

# restart PowerShell, then confirm
Get-PSSqlRepositoryExtension | Format-Table Name, Status, Reason
Get-PSSqlRepositoryProvider  | Format-Table Name, DisplayName
```

Offline, or from a build artifact, the same cmdlet takes a `.zip`, `.nupkg`, folder or private feed:

```powershell
Install-PSSqlRepositoryExtension -Path .\MyProvider-1.0.0.zip -Trust
Install-PSSqlRepositoryExtension -Name My.Provider -Repository MyFeed -Trust
```

The loader **fails closed**: it only instantiates strong-named assemblies whose public key token is
either the module's own or listed in `extensions.trust.json`. An untrusted extension is installed
but reported as `Rejected` rather than silently missing — `-Trust` is the explicit decision to let
that publisher's code run. See [`docs/extensibility.md`](docs/extensibility.md).

To author one, reference the `PSSqlRepository.Extensions.Sdk` package — see
[`docs/sdk.md`](docs/sdk.md).

## Documentation

| Document | Contents |
|---|---|
| [`docs/getting-started.md`](docs/getting-started.md) | Install, first session, CRUD, transactions |
| [`docs/entity-model.md`](docs/entity-model.md) | Full worked model: Company / Person / Customer with foreign keys |
| [`docs/architecture.md`](docs/architecture.md) | Layering and component responsibilities |
| [`docs/extensibility.md`](docs/extensibility.md) | How extensions are discovered, trusted, installed |
| [`docs/sdk.md`](docs/sdk.md) | Authoring a provider or authentication extension |
| [`docs/provider-auth-reference.md`](docs/provider-auth-reference.md) | Per-provider parameters and auth modes |
| [`docs/mapping-model.md`](docs/mapping-model.md) | How PowerShell objects map to columns |
| [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) | Error messages and what to do about them |

Maintainer documentation — the release runbook, the SNK threat model and the code-review
findings — lives under `docs/internal/` and is not part of the published mirror.

## Development

From a source checkout of the Azure DevOps repository — **not** from the GitHub mirror, which
ships no `src/`:

```powershell
dotnet build .\src\PSSqlRepository.slnx
dotnet test  .\src\PSSqlRepository.slnx
```

## Notes

- PowerShell 7.4 / 7.5 use the `net8.0` build; PowerShell 7.6+ use `net10.0`. The loader selects
  automatically.
- Secrets are scrubbed from diagnostics before they are emitted.
- Set `$env:PSSQLREPOSITORY_LOG` **before** importing to tee structured diagnostics — including
  every extension load decision — to a file.
