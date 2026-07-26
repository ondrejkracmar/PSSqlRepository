# PSSqlRepository

PSSqlRepository is a PowerShell binary module for EF Core-backed SQL repositories. It provides a clean session model, typed CRUD operations, transaction control, server-side querying, and pluggable SQL provider/authentication extensions.

## What it does

- Connects PowerShell to SQL backends through friendly provider parameters
- Supports SQL Server and SQLite out of the box
- Lets you register EF Core entity types dynamically from PowerShell or through a custom DbContext
- Provides server-side filtering, sorting, and projection on queries
- Supports Add / Update / Upsert persistence flows with graph handling
- Keeps secrets out of warnings, errors, and diagnostics
- Exposes an SDK surface for external provider authors

## Quick start

```powershell
Import-Module .\src\PSSqlRepository\PSSqlRepository.psd1

Connect-PSSqlRepository Sqlite -Path .\app.db -EnsureCreated
Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Top 10 -AsNoTracking
Disconnect-PSSqlRepository
```

## Main commands

| Command | Purpose |
|---|---|
| `Connect-PSSqlRepository` | Open a provider session |
| `Disconnect-PSSqlRepository` | Close the current session |
| `Get-PSSqlRepositoryProvider` | List loaded providers |
| `Get-PSSqlRepositorySession` | Inspect the current session |
| `Register-PSSqlRepositoryContext` | Register a custom DbContext |
| `Register-PSSqlRepositoryEntity` | Build a DbContext dynamically from PowerShell entity types |
| `Get-PSSqlRepositoryEntity` | Query entities |
| `Save-PSSqlRepositoryEntity` | Persist changes |
| `Remove-PSSqlRepositoryEntity` | Delete entities |
| `Start-PSSqlRepositoryTransaction` | Start a transaction |
| `Complete-PSSqlRepositoryTransaction` | Commit a transaction |
| `Undo-PSSqlRepositoryTransaction` | Roll back a transaction |

## Query features

`Get-PSSqlRepositoryEntity` supports:

- `-Where` for client-side PowerShell filtering
- `-Filter` for SQL-translated filtering
- `-OrderBy` for SQL-translated sorting
- `-Property` for SQL-translated projection

Example:

```powershell
Get-PSSqlRepositoryEntity `
  -EntityType ([Customer]) `
  -Filter "Name -like 'A*' -and RowVersion -gt 3" `
  -OrderBy 'Name DESC' `
  -Property Id, Name `
  -Top 10
```

## Providers and authentication

Built-in providers:

- SQL Server
- SQLite

Built-in authentication surfaces:

- SQL Server: `UserName`, `Password`, `SecurePassword`
- SQLite: `Password`

## Extensibility

The repository now includes `PSSqlRepository.SDK`, which is intended for external SQL provider and authentication authors.

Use it when you want to build independent extensions for providers like DuckDB, MySQL, Progress, or other internal SQL systems.

See:

- `docs/getting-started.md`
- `docs/architecture.md`
- `docs/extensibility.md`
- `docs/provider-auth-reference.md`
- `docs/sdk.md`
- `docs/release-and-ci.md`
- `CONTRIBUTING.md`

## Development

```powershell
dotnet build .\src\PSSqlRepository.slnx
dotnet test .\src\PSSqlRepository.slnx
```

## Notes

- PowerShell 7.4 / 7.5 use the `net8.0` build
- PowerShell 7.6+ use the `net10.0` build
- The module loader selects the right runtime automatically
- Secrets are scrubbed from diagnostics before they are emitted

