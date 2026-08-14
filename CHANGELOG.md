# Changelog

All notable changes to **PSSqlRepository** will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-08-14

### Added
- **Batched existence resolution for `Save-PSSqlRepositoryEntity` in Upsert/Update mode**
  (`-BatchSize`, default 500). Entities are buffered per entity type and their keys resolved with
  ONE keyed `IN` query per batch instead of one `GetByIdAsync` round-trip per entity. On providers
  with a high fixed cost per query the per-row lookup dominates the whole save — measured on
  DuckDB: ~9 rows/s per-row vs. hundreds on the batched path; on SQLite roughly 2× — while `Add`
  mode (no existence check) is unaffected and keeps the streaming path.
  - Duplicate keys are merged, not double-inserted — both within a batch and **across batches of
    one invocation**: an entity added in an earlier batch is not yet in the database, so a carried
    key → tracked-entity map (the batched equivalent of `FindAsync`'s change-tracker probe) is
    what routes a repeated key to a merge instead of a second `INSERT` that would fail at
    `SaveChanges`.
  - Semantics preserved: `SaveChanges` still runs exactly once at end of pipeline; `-PassThru`
    output keeps its order and content (it now surfaces at batch boundaries rather than per
    record); `Update` mode still throws `ItemNotFoundException` for a missing key and rejects a
    default key; `ShouldProcess`/`-WhatIf` still applies per record. `-BatchSize 1` restores
    strictly per-record behaviour, bit for bit.
  - The batch key predicate is built against a parameter-bound list (not an embedded constant),
    so EF caches one query plan per shape instead of recompiling per key list.

## [0.3.0] - 2026-08-14

### Changed
- `Isystem.Shared.Infrastructure.*` is consumed from the private Artifacts feed as a
  `PackageReference` instead of being built from a sibling source checkout. The published SDK
  packages previously declared a dependency on `1.0.0-localfeed` — a version that exists only
  inside a vendored feed — which is why extension repositories had to vendor the whole package
  set to build at all. They now declare `1.0.1` and resolve from the feed.
- **Publication is gated on a git tag.** Pushing to `main` builds and tests but no longer publishes
  to the Artifacts feed or the PowerShell Gallery. Releasing is `git tag v<x.y.z> && git push origin
  v<x.y.z>`. Previously `main` published a bare `MajorMinorPatch` and created no tag, so every build
  after a release proposed the version that had just been published.
- Resource strings format their arguments with `CurrentCulture` instead of `CurrentUICulture`;
  `ResourceManager.GetString` still uses `CurrentUICulture`. Numbers and dates inside diagnostics
  now follow regional settings rather than the display language.

### Fixed
- `Install-PSSqlRepositoryExtension` no longer tries to overwrite host assemblies with copies
  travelling in an extension payload. `Isystem.Shared.Infrastructure.*` is skipped alongside
  `PSSqlRepository.*`; the copy could never succeed (the session running the cmdlet has them
  loaded) and succeeding would have broken contract type identity.
- A locked or read-only dependency is reported as a warning naming the cause instead of an
  `IOException` that aborted the install half-way through.
- The SDK's `DeployExtensionToModule` target filters `Isystem.Shared.Infrastructure.*` out of
  extension payloads, so newly built extensions no longer carry host assemblies.
- `Testcontainers.MsSql` upgraded to 4.14.0. 3.10.0 pinned `SSH.NET` 2023.0.0, whose advisory
  (GHSA-q939-rpr3-3284) failed CI restore once it reached the NuGet audit database.

### Documentation
- New `docs/entity-model.md`: a worked model of Company / Person / Customer joined by foreign keys,
  graph saves, eager loading and transactions, every snippet executed before being written down.
- `docs/sdk.md` and `docs/extensibility.md` corrected — they named types that do not exist
  (`SqlProviderPlugin`, `SqlAuthenticationPlugin`, `[assembly: PSSqlRepositoryPlugin]`) and, along
  with the SDK README, described a trust model based on environment variables that was replaced by
  the strong-name gate long ago.
- Install instructions lead with the PowerShell Gallery route rather than a `.zip`.
- `docs/mapping-model.md` rewritten against the actual converter; it was unrenderable and described
  intent rather than behaviour.
- Maintainer material moved to `docs/internal/`, which is excluded from the public GitHub mirror.

## [0.2.1] and earlier

> These notes accumulated under *Unreleased* across the 0.2.x line and were never split per
> release. They are recorded here as one block rather than attributed to a version after the fact.

### Added
- `Get-PSSqlRepositoryEntity -IncludeAll` switch: eagerly loads every
  navigation declared on the entity in the EF Core model (collections and
  references, one level deep). Combine with `-Include 'Lines.Foo'` for deeper
  paths. Documented in `README.md` together with the existing `-Include`
  parameter and the explicit note that `Get-*` never auto-loads navigations \u2014
  callers must opt in, otherwise collections come back empty / references
  come back `$null`. Round-tripping into
  `Save-PSSqlRepositoryEntity -IncludeNavigations` requires fetching with the
  same navigations to avoid the merger dropping existing children.
- `Connect-PSSqlRepository -EnsureCreated` now works as a bare PowerShell switch
  (`-EnsureCreated` instead of `-EnsureCreated $true`). Bool-typed provider
  parameters are promoted to `SwitchParameter` by the dynamic-parameter builder;
  `PowerShellSqlConnectContext` unwraps the value back to `bool` so the provider
  surface stays PowerShell-agnostic. Legacy `-EnsureCreated $true` keeps working.
- **Additive schema creation on existing databases.** When `-EnsureCreated` is
  supplied and the database file already exists, `SqlProviderSession` runs EF
  Core's `IMigrationsModelDiffer` against an empty source model, filters the
  resulting operations down to tables that don't yet exist, and executes the
  generated SQL via the provider's `IMigrationsSqlGenerator` /
  `IMigrationCommandExecutor`. Existing tables, columns and indexes are left
  untouched (column drift inside an already-present table remains a migration
  concern). Works for SQLite and SQL Server with no migrations project required.
- **Connect-time schema validation.** Plain `Connect-PSSqlRepository` (without
  `-EnsureCreated`) now verifies that every registered entity has a matching
  table in the existing database and throws a precise, actionable error listing
  the missing tables, instead of letting the first `Save-PSSqlRepositoryEntity`
  call fail with a raw provider error such as
  `SQLite Error 1: 'no such table: Order'` or
  `Invalid object name 'Order'`.
- **Cumulative entity registration.** `Register-PSSqlRepositoryEntity` now
  accumulates entity types per provider across calls. Registering `Order`
  followed by `OrderLine` no longer drops `Order` from the dynamic model;
  passing them in a single call (`-EntityType ([Order],[OrderLine])`) still
  works and remains the recommended form.
- **Structured logging via PowerShell streams.** New
  `PSSqlRepository.Core.Diagnostics.PSSqlRepositoryDiagnostics` broadcaster
  publishes `Verbose` / `Debug` / `Warning` events from core, provider, and
  extension-loader code. `PSSqlRepositoryCmdletBase` subscribes for the lifetime of
  each cmdlet and forwards messages to `WriteVerbose` / `WriteDebug` /
  `WriteWarning`, with backlog replay for messages emitted before the first cmdlet
  runs. Off-thread publications are buffered and flushed on the pipeline thread
  after every `RunSync` and in `EndProcessing`.
- `Register-PSSqlRepositoryEntity` cmdlet: register CLR entity types (including
  PowerShell `class` definitions) and have a `DbContext` built at runtime via a new
  `DynamicEntityDbContext` + `DynamicEntityModelExtension`. No precompiled C#
  `DbContext` required.
- `Update-PSSqlRepositoryEntity` proxy function (forwards to `Save-PSSqlRepositoryEntity -Mode Update`)
  for `Get-Command -Verb Update` discoverability.
- Friendly error translation in `Save-PSSqlRepositoryEntity` for
  `DbUpdateConcurrencyException`, unique-constraint, foreign-key, and NOT NULL
  violations (original exception preserved as `InnerException`).
- `EntityPersistenceCoordinator`: shared persistence pipeline used by both Save and
  Update paths, eliminating duplicated `Add` / `Update` / `Upsert` logic.
- Auto-unrolling of collections passed as a single `-InputObject` so
  `Save-PSSqlRepositoryEntity -InputObject $collection` and
  `$collection | Save-PSSqlRepositoryEntity` behave identically.
- `about_PSSqlRepository` help topic, top-level `README.md`, and this `CHANGELOG.md`.
- README sections covering nested-collection / FK graph persistence, the
  diagnostics surface, and the existing CI/CD pipeline.

### Changed
- `PSSqlRepositoryModuleInitializer` no longer writes diagnostic lines to disk
  directly; the legacy `PSSQLREPOSITORY_LOG` environment variable is now mapped to
  `PSSqlRepositoryDiagnostics.FileLogPath` (file tee remains backward compatible).
- `SqlExtensionLoader` plug-in load / SHA-256 audit / ALC resolver messages flow
  through `PSSqlRepositoryDiagnostics.Verbose` and therefore appear in
  `Import-Module -Verbose` and any subsequent cmdlet's `-Verbose` output.
- `PSSqlRepositoryCmdletBase` now overrides `BeginProcessing` and `EndProcessing`
  to manage the diagnostics subscription. Derived cmdlets (`Save` / `Get` /
  `Remove`) call `base.BeginProcessing()` / `base.EndProcessing()` so the flush
  semantics are honored.
- Module manifest metadata populated: `ProjectUri`, `LicenseUri`, expanded `Tags`,
  `ReleaseNotes` pointer.
- `SqlProviderDefinitionBase.BuildEfRegistrationDelegate` gains an overload that
  accepts an extra `Action<DbContextOptionsBuilder>` so callers (notably
  `Register-PSSqlRepositoryEntity`) can attach options extensions without
  re-registering the `DbContext`.
- Sqlite/SqlServer provider plugins expose `GetEfProviderConfigurator()` so the
  dynamic registration path can compose the provider's `UseXxx` call with extra
  options.

### Fixed
- Pester test suite re-targeted at `PSSqlRepository` and runs clean (103/103).
- `PSSqlRepository.psm1` re-saved with UTF-8 BOM to satisfy file-integrity tests.
