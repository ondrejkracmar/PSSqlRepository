# Troubleshooting

Common errors when using `PSSqlRepository` and how to resolve them.

## Connect / session

### `No active PSSqlRepository session. Call Connect-PSSqlRepository first.`

A cmdlet that requires an active session (`Save-/Get-/Remove-PSSqlRepositoryEntity`,
`Start-PSSqlRepositoryTransaction`, …) was invoked before `Connect-PSSqlRepository`
ran in the current session. Open a session first.

### `Provider '<name>' is not registered.`

The provider plugin assembly was not loaded. Re-import the module and verify the
plugin DLL is present in `bin/<framework>/`. Use `Get-PSSqlRepositoryProvider` to
list discovered providers.

### `Authentication mode '<mode>' is not supported by provider '<name>'.`

The selected `-AuthMode` is not advertised by the provider's
`SupportedAuthModes`. List the supported modes with
`(Get-PSSqlRepositoryProvider <name>).SupportedAuthModes`.

## Save / merge

### `Primary key mismatch on '<Type>.<Property>' …`

`EntityGraphMerger` detected that the incoming entity carries a different primary
key value than the loaded row. Primary keys are immutable. Either reload the
correct row, or remove the old row and add a new one explicitly. Default-valued
keys (e.g. `0` for `int`, `null`, `Guid.Empty`) are tolerated to support
PowerShell-built objects that omit the PK.

### `EntityGraphMerger exceeded the maximum recursion depth …`

The incoming graph is deeper than `EntityGraphMerger.MaxMergeDepth` (currently
**64**) or contains a cycle that the reference-based detector cannot see — usually
because the same logical entity has been materialised as multiple distinct CLR
instances (typical after deserialisation). Inspect the graph for unexpected
nesting and break the cycle before calling `Save`.

### `unique constraint violated` / `foreign key constraint violated` / `required column was NULL`

These are friendly messages emitted by `SaveErrorTranslator` for typical EF Core
`DbUpdateException` causes. The original provider message is preserved on
`$Error[0].Exception.InnerException`.

### `Cannot orphan child of type '<Type>' from navigation '<Nav>': DeleteBehavior is Restrict.`

You omitted a child from the incoming collection but the relationship is
configured with `DeleteBehavior.Restrict` / `NoAction`. Either remove the child
explicitly before saving, change the relationship's `OnDelete` behavior, or pass
`-OrphanBehavior Delete` to override.

### `-OrphanBehavior Detach was requested but navigation '<Nav>' has a required (non-nullable) foreign key …`

`SetNull` requires a nullable FK. Make the FK nullable in your model, or use
`-OrphanBehavior Delete` instead.

## Mapping / conversion

### `Cannot convert value of type '<Source>' to '<Target>'.`

A scalar property could not be converted by `PSObjectEntityConverter`. Check the
incoming object: the source value's type is not compatible with the target CLR
type. The original .NET conversion error is preserved as the inner exception.

### `Cannot populate collection of type '<Type>': no public Add(T) method was found.`

A navigation collection on the entity uses a CLR type that does not expose a
public `Add(T)`. Use `List<T>`, `HashSet<T>`, an array, or expose a writable
backing collection.

## Schema migration

### `An explicit transaction is active. Complete-PSSqlRepositoryTransaction or Undo-PSSqlRepositoryTransaction first …`

`Compare-` and `Update-PSSqlRepositorySchema` read the catalogue and run DDL outside the session's
transaction, so they refuse to start while `Start-PSSqlRepositoryTransaction` is open. Complete or
undo it first.

### `Held back: DropColumn … (destructive)` / `Skipped: … (dependent)`

The plan contains a change that can lose data or an object (a drop, a narrowed column, a
nullability change) and the default run is additive. Review it, then apply with
`Update-PSSqlRepositorySchema -AllowDestructive` (add `-Force` in scripts to skip the prompt), or
put the property back in the model. `Update-PSSqlRepositorySchema -Script -AllowDestructive`
shows the SQL that would run. See [docs/schema-migration.md](docs/schema-migration.md).

### `Provider '<name>' does not advertise the SchemaManagement capability …`

The provider opted out of schema management (its EF Core provider has no migrations pipeline), or
the session exposes no `DbContext`. There is nothing to migrate through the module; manage the
schema with the provider's own tooling.

### `-ImportSchema and -Migrate cannot be combined`

An imported model is a copy of the database, so there is nothing to migrate. Use one or the other.

### `Compare-PSSqlRepositorySchema` keeps reporting a change that `Update` never clears

The database has an object the model describes differently in a way that is not applied by
default — typically a column rename (reported as an add plus a held-back drop; columns are never
renamed) or a constraint a DBA defined differently (a held-back drop plus a dependent create).
Apply it once with `-AllowDestructive`, or change the model to match the database.

## Get

### `There is no Runspace available to run scripts in this thread.`

Your PowerShell entity class contains a **property initializer**, a custom constructor, or a
property getter with a body:

```powershell
# every query against this type fails
class Company : IEntity[int] {
    [System.Collections.Generic.List[Person]] $People = [System.Collections.Generic.List[Person]]::new()
}
```

Those bodies are script blocks. EF Core materialises entities on a worker thread with no PowerShell
runspace attached, so running one throws. The error surfaces on `Get-PSSqlRepositoryEntity`, far from
the class that caused it, and applies to *any* initializer expression — not just collections.

Declare the property bare and assign the value when you construct the object:

```powershell
class Company : IEntity[int] {
    [System.Collections.Generic.List[Person]] $People
}

$c = [Company]@{ People = [System.Collections.Generic.List[Person]]@( $p1, $p2 ) }
```

### `Get-PSSqlRepositoryEntity is enumerating '<Type>' without -Top/-Skip. …`

Defensive warning against accidental full-table scans. The query is still
streamed (memory-bounded), but consider adding `-Top` / `-Skip` for large tables.
Pass `-SuppressUnboundedWarning` to silence the warning when the scan is
intentional.

## Module load

### `ParserError: Unable to find type [IEntity].`

The `class … : IEntity[int]` declaration lives in the same script file as its `Import-Module`.
PowerShell compiles a whole file before executing any of it, so the type is resolved before the
import has run. `using module` does not help — the accelerator is registered by the module's script
body, which runs too late for the parser.

Split the file: one script imports and then invokes the other.

```powershell
# run.ps1
Import-Module PSSqlRepository
& "$PSScriptRoot\model.ps1"
```

Interactively there is no problem — each prompt entry is compiled separately, so
`Import-Module PSSqlRepository` followed by the class definition works.

### A provider is missing / `Provider '<name>' is not registered` after installing an extension

The import succeeds even when every extension is rejected. Ask for the report:

```powershell
Get-PSSqlRepositoryExtension | Format-Table Name, Status, Reason
```

`Status: Rejected` with *"its public key token '…' is not trusted"* is the usual answer — the
extension was installed without `-Trust`. Re-run
`Install-PSSqlRepositoryExtension -Path … -Trust` (or add the token to `extensions.trust.json` in
the module root) and restart PowerShell.

*"its content changed since it was trusted"* means the DLL on disk is not the one `-Trust` pinned
(it was updated by hand, or tampered with); re-run the install with `-Trust` if the update is
intended. *"its SHA-256 is not pinned"* means the file was copied in without the install cmdlet.
Other reasons are tabulated in
[docs/extensibility.md](docs/extensibility.md#diagnosing-a-missing-provider).

### `PSSqlRepository: could not find PSSqlRepository.Loader.dll …` / `… is not signed with the PSSqlRepository key`

The module loads its engine through `PSSqlRepository.Loader.dll`, which checks that
`PSSqlRepository.Commands.dll` carries the module's strong-name key before loading it. A missing
file or a different signature means the installation was modified or is incomplete; reinstall the
module.

### `Could not load file or assembly '…' … Assembly with same name is already loaded` (Az, other modules)

Since the engine runs in its own `AssemblyLoadContext` (`PSSqlRepository.Engine`), the module puts
nothing but `PSSqlRepository.Loader` and `Isystem.Shared.Infrastructure.Core`/`.Services` into the
process-wide default context, so it no longer collides with Az.Accounts, Az.Resources or other
modules in either import order. If the error persists, check which module loaded the named
assembly first:

```powershell
[System.Runtime.Loader.AssemblyLoadContext]::Default.Assemblies |
    Where-Object { $_.GetName().Name -like 'Microsoft.Extensions*' } |
    ForEach-Object { '{0} {1} {2}' -f $_.GetName().Name, $_.GetName().Version, $_.Location }
```

### `Unable to find type [Microsoft.EntityFrameworkCore.…]` in a script

Engine types are made nameable through type accelerators registered on import. Import the module
before the script that names them is parsed (a `class` declaration is resolved when its script is
parsed, not when it runs). A name another module registered first keeps pointing at that module's
type.

### `PSSqlRepository: build output for runtime '<framework>' not found …`

The detected .NET runtime version does not match any of the binaries shipped
with the module. Supported targets are `net8.0` (PowerShell 7.4 / 7.5) and
`net10.0` (PowerShell 7.6+).

## Diagnostics

Set `$env:PSSQLREPOSITORY_LOG = '<path>.log'` (then re-import the module) to
tee structured diagnostic messages to a file. The same scrubbing applied to the
PowerShell streams is applied to the file log.

## Performance / timeouts

### Long-running query is killed by the default 30 s command timeout

The SQL Server provider applies a 30 s `CommandTimeout` by default and an EF
Core retry policy (6 retries, 30 s ceiling) on transient network/SQL errors.
Override per invocation:

```powershell
Get-PSSqlRepositoryEntity  -EntityType ([Order]) -CommandTimeout 600
Save-PSSqlRepositoryEntity -InputObject $bulk   -CommandTimeout 0   # disable
```

`-CommandTimeout 0` disables the timeout entirely; reserve for sustained bulk
operations that genuinely need it.

### Transient `SqlException` (network blip, SQL Azure throttling)

The provider re-tries automatically up to six times. If you still hit the error,
the issue is non-transient — increase `MaxRetryCount` by registering a custom
DbContext, or fix the underlying connectivity / quota problem.
