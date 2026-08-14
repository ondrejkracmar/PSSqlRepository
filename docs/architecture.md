# PSSqlRepository architecture

## Goals

PSSqlRepository is designed to make SQL persistence feel native in PowerShell while keeping the internal implementation layered, testable, and extension-friendly.

## Solution layers

- `PSSqlRepository` - PowerShell module loader, manifest, and runtime selection
- `PSSqlRepository.Commands` - binary cmdlets and PowerShell pipeline behavior
- `PSSqlRepository.Core` - session lifecycle, EF Core wiring, diagnostics, and runtime helpers
- `PSSqlRepository.Providers` - provider contracts, registry, and shared provider infrastructure
- `PSSqlRepository.Authentications` - authentication contracts and registry
- `PSSqlRepository.Abstractions` - shared public contracts
- `PSSqlRepository.SDK` - extension-facing SDK for third-party provider/auth packages
- `PSSqlRepository.Providers.SqlServer` / `PSSqlRepository.Providers.Sqlite` - built-in provider plugins
- `PSSqlRepository.Authentications.SqlServer` / `PSSqlRepository.Authentications.Sqlite` - built-in authentication plugins

## Runtime flow

```text
PowerShell command
  -> module loader
  -> binary cmdlet
  -> session manager
  -> provider definition
  -> authentication provider (if needed)
  -> EF Core DbContext
  -> SQL database
```

## Query flow

`Get-PSSqlRepositoryEntity` has two distinct query modes:

- `-Where` - client-side PowerShell filtering after materialization
- `-Filter`, `-OrderBy`, `-Property` - translated to SQL via EF Core expression trees

This split keeps PowerShell ergonomics available while still allowing efficient SQL-side query composition.

## Session model

A session owns the scoped service provider, DbContext, unit of work, and transaction handling. The `SqlSessionManager` exposes the current active session to cmdlets.

## Extensibility model

The SDK assembly is the published extension boundary for external provider authors. Third-party packages should depend on the SDK and implement provider/auth contracts there instead of referencing internal module projects directly.

## Diagnostics model

All user-facing warnings and exceptions are routed through shared resource-backed messages and the diagnostics broadcaster. This keeps secrets from leaking into logs and makes output consistent across cmdlets and providers.

## Practical outcome

The architecture is intentionally split so that:

- PowerShell users get a simple cmdlet surface
- EF Core handles persistence semantics
- provider authors can extend the system independently
- auth providers can remain isolated per provider family
