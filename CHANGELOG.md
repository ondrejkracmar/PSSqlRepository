# Changelog

All notable changes to **PSSqlRepository** will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Extension trust pins file hashes.** `extensions.trust.json` gained `trustedFileHashes`
  (path relative to the trust file → SHA-256) and `developmentMode`. A third-party extension
  (any strong-name token other than the module's own) now loads only when its content matches
  the pinned hash; `Install-PSSqlRepositoryExtension -Trust` pins every file it installs and
  `Uninstall-PSSqlRepositoryExtension` removes the pin. A trust file written before this
  release has no section and is baselined on first load, so already-trusted extensions keep
  working unchanged; a DLL replaced by hand is refused with *"its content changed since it was
  trusted"* until it is re-trusted. `"developmentMode": true` restores token-only trust for
  developer machines. The loader keeps the candidate file open share-read from hashing through
  loading, so the bytes it verified are the bytes it loads. Public API:
  `ExtensionTrustStore.ReadTrustList`, `PinFileHash`, `UnpinFileHash`, `RelativeKey`,
  `ComputeSha256`. The extension contract is unchanged.
- **The pin covers the extension's dependencies.** `-Trust` also pins every file the extension
  installed (its private folder, the shared dependencies it claimed, the native assets staged
  under `runtimes/`, which `extensions.deps.json` now records so uninstall can remove them), the
  loader verifies that closure before the extension loads and refuses it naming the file that is
  unpinned or changed, and the extension's load context re-checks each file it actually loads.
  A trust file from before pinning baselines the closure on first load.
- **CI: the Microsoft Security DevOps step blocks on findings** once enabled (`enableMSDO`); it
  stays opt-in until the Marketplace extension is installed at the organisation.
- **Forward schema migration — `Update-PSSqlRepositorySchema`, `Compare-PSSqlRepositorySchema`,
  `Connect-PSSqlRepository -Migrate`.** The connected database is compared with the registered
  model the way EF Core migrations do, without a migrations project: the live catalogue is read
  through the provider's `IDatabaseModelFactory`, rebuilt as a snapshot-style model
  (`Schema/CatalogueModelBuilder`) and diffed with EF Core's own `IMigrationsModelDiffer`.
  Additive operations (new tables, columns, indexes, foreign keys, widened columns, index renames)
  apply in one batch through the provider's migrations SQL generator and executor; destructive
  ones (drops, narrowing, nullability changes in either direction, identity changes) are reported
  as warnings and only run with `-AllowDestructive` (prompting unless `-Force`). The differ's
  column-rename guesses are never applied: they become an add plus a held-back drop. Tables the model does not map are listed
  as unmanaged and never touched. `-Script` returns the SQL instead of running it. Each applied
  run is recorded in a `__PSSqlRepositoryMigrations` history table (`-NoHistory` opts out;
  `Compare` returns the newest rows). `Connect -Migrate` implies `-EnsureCreated` and reaches the
  provider through the connect context by name, so third-party providers need no rebuild; every
  surface honours `SqlProviderCapabilities.SchemaManagement`. Both cmdlets refuse to run inside an
  explicit transaction. New guide: `docs/schema-migration.md`. Public API in
  `PSSqlRepository.Core.Schema`: `SchemaMigrator`, `SchemaMigrationPlan`, `SchemaMigrationResult`,
  `SchemaMigrationOptions`, `SchemaMigrationHistory`; `DatabaseSchemaReader.Read(DbContext, …)`
  overload; `SqlProviderDefinitionBase.MigrateParameterName` and the virtual
  `MigrateAfterConnect`. The extension contract (Abstractions / Providers / Authentications) is
  unchanged.
- **Schema import reports unique constraints and indexes.** `SqlSchemaTable.UniqueConstraints`
  and `SqlSchemaTable.Indexes` (name, columns, `IsUnique`, filter) carry what the provider's
  catalogue reader already sees, so a consumer building its own schema model from the import
  no longer needs a separate catalogue query for them.
- **Unmapped columns stay visible.** A column whose store type neither the provider nor the ANSI
  fallback can map is still listed in `SqlSchemaTable.Columns` (`IsMappedToProperty = false`,
  `ClrType = object`) instead of vanishing from the table description; it is just not emitted as
  an entity property. `UnmappedColumns` keeps naming them for the warning.

### Changed
- `Connect -EnsureCreated`'s table-creation and table-existence checks moved from
  `SqlProviderSession` into `Schema/SchemaMigrator` (`CreateMissingTables`, `EnsureSchemaMatchesModel`)
  with identical behaviour and messages; `SqlProviderSession` delegates to them.
- `Import-PSSqlRepositorySchema` skips `__PSSqlRepositoryMigrations` and `__EFMigrationsHistory`
  (reported with a `SkipReason`) instead of emitting an entity for them.
- A provider connect parameter with no `HelpMessage` no longer throws while the dynamic
  parameters are built; it simply gets no help text.
- A provider connect parameter named like a static `Connect-`/`Import-` parameter
  (`Migrate`, `ImportSchema`, …) is skipped with a verbose note instead of making PowerShell fail
  at bind time with a duplicate parameter.

### Fixed
- **`Connect-PSSqlRepository -EnsureCreated` creates a missing schema before a new table.** The
  additive path kept only the `CreateTable` operations of the fresh-database diff and dropped
  the `EnsureSchema` that precedes a schema-qualified table, so a new entity mapped to a schema
  the database did not yet have failed with *"The specified schema name … does not exist"*.
  The schema is now created for the tables being added.

Findings of the October 2026 deep-dive review (`docs/internal/code-review-deep-dive.md`), each
with a regression test in `ReviewFixesTests`:
- **A failed or aborted `Save-`/`Remove-PSSqlRepositoryEntity` no longer poisons the session.**
  Entities staged on the shared change tracker but never committed (terminating error, failed
  `SaveChanges`) were persisted by the next unrelated Save/Remove, or kept failing it; they are
  now detached when the cmdlet ends without a commit, with a warning.
- **A streamed `Get-PSSqlRepositoryEntity` no longer hangs the session** when the consumer
  leaves early (a throwing `-Where`, a downstream error, `Select-Object -First`): the producer is
  cancelled instead of blocking on a full buffer forever.
- **`-CommandTimeout` is scoped to the invocation** instead of staying on the session's context
  for every later cmdlet.
- **Guid and enum keys given as strings** (`-Id '0f8f…'`, batched upserts) are converted like
  property values instead of failing with `InvalidCastException`.
- **`-Filter` values and `-Id` are SQL parameters, not literals** (one compiled query and one
  plan per filter shape instead of one per distinct value).
- **Input properties with no writable counterpart on the entity are reported** (once per entity
  type and name) instead of being dropped silently.
- **`Unregister-PSSqlRepositoryContext` really forgets the entity types**: the accumulated list
  behind `Register-PSSqlRepositoryEntity` lives on the registration now, so a later `Register`
  (or a database-first import, or a pre-compiled context) starts afresh; module unload clears the
  registry.
- **Constraint violations are classified by provider error code** (SQL Server `Number`, SQLite
  extended code) before falling back to message text, and `Remove-PSSqlRepositoryEntity`
  translates its commit errors like `Save` does.
- **`Install-PSSqlRepositoryExtension -Name/-Repository`** found no payload: the downloaded
  `.nupkg` is now extracted like a `-Path .nupkg`.
- **The credential-bearing `SqlConnection` is owned by EF** (`contextOwnsConnection: true`) and
  disposed with the context; **`SqlServerAuthProvider` no longer freezes the caller's
  `PSCredential.Password`** read-only (works on a copy).
- **Both MCP hosts refuse to start with authentication disabled** outside the Development
  environment unless `Authentication:AllowAnonymous=true` is set explicitly; the Runspace host
  **keeps the session between tool calls** (every cmdlet now runs on one dedicated thread, where
  the module's `AsyncLocal` session persists); provider error text returned to MCP clients is
  sanitised; a session is disposed when publishing it fails.
- Provider connect-parameter help texts for `ConnectionString` / `EnsureCreated` no longer show
  unrelated error strings.
- **`Get-Help` now shows real help for every cmdlet.** The shipped MAML sat one folder too deep
  (`en-US/PSSqlRepository/`), where PowerShell never looks, so every cmdlet fell back to
  auto-generated syntax; the files now live directly in `en-US/`, the 17 cmdlets whose help was
  PlatyPS placeholders got synopsis, description, parameter and example text generated from
  their C# XML documentation, and `tests/pester.ps1` now fails the run when a test file's
  discovery fails instead of reporting zero tests.
- `Remove-Module PSSqlRepository` no longer removes the `IEntity` / `OrphanBehavior` type
  accelerators when another module registered them first.

### Removed
- **BREAKING — the `Sql` prefix is gone from three loader types.**
  `SqlExtensionLoader`, `SqlExtensionTrustStore` and `SqlExtensionLoadContext` are now
  `ExtensionLoader`, `ExtensionTrustStore` and `ExtensionLoadContext`, matching
  PSDataRepository. Everything else in `Core/Extensions` was already unprefixed, so these
  three were the odd ones out and the prefix said nothing the namespace did not.

  A script calling `[PSSqlRepository.Core.Extensions.SqlExtensionLoader]::Inspect(...)`
  needs the new name. **Extensions are not affected** and do not need rebuilding: they
  reference `Abstractions`, `Extensions.Sdk` and `Providers` and never touch `Core` — verified
  against the published DuckDB, MySQL and PostgreSQL providers, none of which mentions either
  type. The extension contract version stays at 1.0.0.

### Added
- **Database-first: `Import-PSSqlRepositorySchema` and `Connect-PSSqlRepository -ImportSchema`.**
  Point the module at a database that already exists and it emits one entity class per table
  at run time (Reflection.Emit, no compilation step) and registers them the way
  `Register-PSSqlRepositoryEntity` registers hand-written classes. `Get-/Save-/Remove-
  PSSqlRepositoryEntity`, `-Filter`, `-Include`, transactions and the PSObject converter then
  work on those tables unchanged: `Import-PSSqlRepositorySchema Sqlite -Path .\shop.db`, then
  `Get-PSSqlRepositoryEntity -EntityType ([Customer])`.

  The emitted class mirrors the table: a public property per column with the column's name
  (`CustomerId` stays `CustomerId`; names that are not identifiers become `Order_Line` /
  `Unit_Price`, mapped back to the real names), nullable value types for nullable columns, and
  the `IEntity[TKey]` contract implemented explicitly against the primary-key column so the
  cmdlets' key handling (`-Id`, insert-vs-update, batched lookups) needs no change. Table and
  column names, store types, required-ness, identity / default / computed columns are configured
  on the EF model from the catalogue, so writes go back exactly.

  The catalogue is read through the EF Core provider's own `IDatabaseModelFactory` (the piece
  behind `dotnet ef dbcontext scaffold`, shipped in `Microsoft.EntityFrameworkCore.Relational`
  and the provider assemblies — no design-time package). SQL Server and SQLite name theirs;
  for an **extension** the factory is discovered in the provider's EF assembly, so the
  published DuckDB provider gets database-first **without a rebuild** (verified end to end).
  Providers that resolve store types only by CLR type fall back to a built-in ANSI table
  (`INTEGER`, `BIGINT`, `DOUBLE`, `DECIMAL(p,s)`, `BOOLEAN`, `VARCHAR`, `TIMESTAMP`, `UUID`, …).

  Filters: `-Schema`, `-Table` (bare or `schema.table`), `-ExcludeTable`, `-IncludeView`;
  `-Namespace` prefixes the types (`[Shop.Customer]`) when two databases overlap; `-NoRegister`
  reads and emits without touching the provider registration. The result object lists every
  table with its columns, keys, foreign keys, the emitted `EntityType` or a `SkipReason`.
  Tables with a composite primary key, tables without a key and views are reported as skipped
  (the entity cmdlets need one key value per entity); columns without a CLR mapping are listed
  in `UnmappedColumns` and warned about, never dropped silently.

  Core additions are purely additive and virtual (`SqlProviderDefinitionBase.DatabaseModelFactoryType`,
  `GetEfProviderConfigurator(ISqlConnectContext)`, the `PSSqlRepository.Core.Schema` namespace,
  an optional `SchemaModelConfigurationExtension` that `DynamicEntityDbContext` applies only
  when present). No contract assembly changed; the extension contract version stays at 1.0.0.
  See `docs/database-first.md`.
- **The plugin load context now follows the .NET plugin model.** It builds an
  `AssemblyDependencyResolver` from the extension's own `.deps.json`, so an extension resolves
  the exact versions its build resolved; it gets one context **per extension** rather than per
  subfolder, which is what makes a resolver usable at all and isolates two plugins in the same
  folder from each other; and it implements `LoadUnmanagedDll`, so native libraries declared in
  `deps.json` resolve with the right runtime identifier instead of by directory guesswork.
- Test coverage levelled against PSDataRepository (182 → 200): `ExtensionDependencyStoreTests`,
  `ExtensionLoaderIntegrationTests` exercising the real loader against a fixture, and
  `ManifestDriftTests`, which derives the manifest and the compiled cmdlets independently so a
  cmdlet added without a manifest entry now fails the build. Approved verbs are read out of the
  `Verbs*` classes rather than a hand-copied list.

### Fixed
- **An extension could shadow a library the module ships.** The load context probed the
  extension's own folder *before* the module root for non-host assemblies, so an extension
  carrying its own copy of, say, EF Core would bind to that copy — and a value handed from one
  extension to another would be typed against two different copies of the same assembly, which
  the JIT answers with `MissingMethodException`. The module root now wins, which also means an
  extension can only ever hold a private copy of something the host does *not* ship: exactly the
  subset where isolation is safe, with no list to maintain.

  Nothing published is affected: the three provider extensions install only their own assembly
  into the plugin folder, with dependencies arbitrated into the module root, so there was never
  anything there to shadow. Verified against the installed module.
- **Extensions with private dependencies installed but never loaded.**
  `Install-PSSqlRepositoryExtension` has always understood the private-dependency shape —
  `{Subfolder}/Contoso.Provider/` holding the assembly together with its own libraries,
  copied wholesale so nothing lands in the shared module root — but the loader scanned only
  the top level of each plugin folder. Such an extension reported a successful install and
  then silently never loaded: no error, just an absent provider. The scan now discovers both
  shapes, and each private extension gets its own load context probing its own folder, so its
  libraries resolve without reaching the module root. Everything *beside* the assembly in a
  private folder stays out of the candidate list, otherwise every library would be inspected
  and reported as an untrusted rejection.

  This is a host capability, not a contract change: no interface moved and the extension
  contract version stays at 1.0.0. It does mean an extension published in the private shape
  will not load on PSSqlRepository 0.4.1 or earlier — it installs and is simply ignored there.

### Changed
- **Operator-facing messages moved into `Resources/Strings.resx`.** The extension cmdlets and
  the transaction/session/entity cmdlets built their text inline while the rest of the fleet
  used resources; 68 keys added. `ErrorRecord` IDs stay inline — they are identifiers callers
  match on, not prose.
- `Get-PSSqlRepositoryExtension -MissingAfterUpgrade` told the operator to reinstall each
  extension by hand; it now points at `-FromModule PSSqlRepository -Version <older> -Trust`,
  which 0.4.1 introduced.

## [0.4.1] - 2026-08-14

### Added
- **Extension migration between module versions**:
  `Install-PSSqlRepositoryExtension -FromModule PSSqlRepository -Version <old>` now recognises an
  installed PSSqlRepository module as a MIGRATION source (`-Version` is new on that parameter set).
  Its third-party extensions are discovered by strong-name token — in-box plugins ship with every
  version and are never migrated — and their dependencies come from the source's
  `extensions.deps.json` record, or, for extensions deployed before the record existed, from a
  transitive referenced-assembly closure over the files actually present in the source framework
  root. Verified end to end against a live 0.3.1 install: DuckDB, PostgreSQL and MySQL providers
  moved with their dependency chains, trust and dependency records written, and the migrated module
  loads them. Upgrading the module previously meant copying the DLL, its dependencies and the trust
  file by hand.

### Fixed
- **`Install-PSSqlRepositoryExtension` no longer crashes mid-install on a locked file.** The
  extension copy and the `runtimes/` native mirror called `File.Copy` unguarded, so a file loaded by
  any running session — near-certain, since the cmdlet runs from a session that imported the module —
  escaped as an unhandled exception (`IOException`, surfaced in the field as
  `NullReferenceException`) after part of the payload was already written. Both paths now degrade to
  an actionable error/warning per file, like dependency copies always did.
- **Installing a single `.dll` from another module's `Providers` folder no longer clobbers the
  target's native tree.** The `runtimes/` mirror copied the WHOLE source tree — for a source inside a
  full module install, that is every provider's natives, overwriting the target module's own (e.g.
  its `e_sqlite3.dll`) with another version's copies. The merge is now per-file: missing files are
  copied, identical ones skipped, and a differing file is only overwritten when the source is a
  publish artifact (whose runtimes belong to the extension); when the source is another module's
  shared tree, the target's copy wins and the decision is reported.

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
- `ExtensionLoader` plug-in load / SHA-256 audit / ALC resolver messages flow
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
