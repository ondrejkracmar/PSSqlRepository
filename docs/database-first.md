# Database-first: working with an existing database

`Register-PSSqlRepositoryEntity` is code-first: you write the classes, the module creates the
tables. `Import-PSSqlRepositorySchema` is the opposite direction. Point it at a database that
already exists and it emits one entity class per table — at run time, in memory, no compilation
step — and registers them exactly as if you had written them. Every other command
(`Connect-`, `Get-`, `Save-`, `Remove-PSSqlRepositoryEntity`, transactions, `-Filter`,
`-Include`) then works on those tables unchanged.

```powershell
Import-Module PSSqlRepository

# 1. Read the schema and register the entity types (same connect parameters as Connect-)
$schema = Import-PSSqlRepositorySchema Sqlite -Path .\shop.db

# 2. Connect the way you always do
$null = Connect-PSSqlRepository Sqlite -Path .\shop.db

# 3. The tables are types now
Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Filter "Name -like 'A*'" -Top 10
[Customer]@{ Name = 'Acme'; Email = 'hello@acme.example' } | Save-PSSqlRepositoryEntity -PassThru
Remove-PSSqlRepositoryEntity -EntityType ([Customer]) -Id 42

Disconnect-PSSqlRepository
```

One-step form, when you do not need the schema report:

```powershell
$null = Connect-PSSqlRepository SqlServer -Server '.\SQLEXPRESS' -Database Shop -ImportSchema
Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Top 5
```

## What gets emitted

For each table with a **single-column primary key** the import emits a public class:

| Catalogue | Entity type |
|---|---|
| table `Customer` | class `Customer` |
| table `Order Line` (space) | class `Order_Line` — invalid characters become `_`, a leading digit gets a `_` prefix |
| the same table name in two schemas | `Sales_Order` and `Archive_Order` (schema-prefixed) |
| column `CustomerId INTEGER` | `[int] CustomerId` (SQLite: `[long]`) |
| column `Email VARCHAR NULL` | `[string] Email` |
| column `Credit DOUBLE NULL` | `[Nullable[double]] Credit` |
| column `"Unit Price"` | `Unit_Price`, mapped to the real column name |
| primary key `CustomerId` | the key the cmdlets use (`-Id`, insert-vs-update); also visible as `Id` |

Property names follow the column names; the mapping back to the catalogue (real table and
column names, store types, required-ness, identity / default / computed columns) is configured
on the EF model, so the type looks like the table and writes go back to the table exactly.

The entity classes implement the same `IEntity[TKey]` contract hand-written classes do, but
through an explicit interface implementation: the public surface shows the real key column
(`CustomerId`), while the cmdlets keep reading the key through the interface. PowerShell also
surfaces that interface property as `Id`, so `-Id 42`, `$row.Id` and `$row.CustomerId` all
refer to the same value.

Everything the import saw is in the result object:

```powershell
$schema.Tables | Format-Table FullName, EntityType, PrimaryKey, SkipReason
$schema.Imported          # tables that became types
$schema.Skipped           # tables that did not, with the reason
$schema.EntityTypes       # [Type[]] — hand these to the cmdlets if you prefer not to use type literals
$schema.FindEntityType('sales.Order')
($schema.Tables | Where-Object Name -eq 'Customer').Columns | Format-Table Name, PropertyName, StoreType, ClrType, IsNullable, IsGeneratedOnAdd
```

## What is skipped, and why

The entity cmdlets are built around one key value per entity (`IEntity[TKey]`), so the import
reports these as skipped instead of emitting a type that would fail later:

- tables with a **composite primary key** (junction tables),
- tables with **no primary key**,
- **views** (`-IncludeView` lists them in the report),
- columns whose store type neither the provider nor the built-in ANSI fallback can map are left
  off the entity and reported per table (`UnmappedColumns`), never dropped silently.

Every skip is a warning on the PowerShell warning stream and a `SkipReason` on the result.

## Filtering and naming

```powershell
# Only what you need
Import-PSSqlRepositorySchema SqlServer -Server . -Database Shop -Schema dbo, sales -Table Customer, 'sales.Order'
Import-PSSqlRepositorySchema Sqlite -Path .\shop.db -ExcludeTable __EFMigrationsHistory, AuditLog

# Two databases with overlapping table names in one session: give each its own namespace
Import-PSSqlRepositorySchema Sqlite -Path .\shop.db      -Namespace Shop
Import-PSSqlRepositorySchema Sqlite -Path .\warehouse.db -Namespace Warehouse -NoRegister
[Shop.Customer]; [Warehouse.Customer]

# Inspect without touching the registration
Import-PSSqlRepositorySchema DuckDB -Path .\analytics.duckdb -NoRegister | Select-Object -ExpandProperty Tables
```

`-Table` accepts bare names and `schema.table`; matching is case-insensitive. `-Schema` is
ignored by providers without schemas (SQLite).

## Re-importing and type identity

A PowerShell type literal (`[Customer]`) resolves by name across every loaded assembly.
Importing the same table again — same columns, same types — returns the **same** `Type`, so
scripts that re-run `Import-PSSqlRepositorySchema` keep working. When a table's shape changed
(a column added, a type altered) a new type is emitted; `[Customer]` may then resolve to the
older one. In that case use `$schema.FindEntityType('Customer')` or a `-Namespace` to address
the new type unambiguously.

## Registration semantics

`Import-PSSqlRepositorySchema` registers a `DynamicEntityDbContext` for the provider, the same
registration `Register-PSSqlRepositoryEntity` makes. It **replaces** whatever was registered for
that provider before (a warning tells you when that happens). `-NoRegister` reads and emits
without registering, and `Register-PSSqlRepositoryEntity -EntityType $schema.EntityTypes` is
not needed — the import already did that with the catalogue-derived configuration attached.

Views, composite keys and navigation properties (foreign keys as object references) are not
emitted in this version; foreign keys are reported on `SqlSchemaTable.ForeignKeys` and the FK
columns are ordinary scalar properties you filter and set directly.

## Providers and extensions

The import reads the catalogue through the EF Core provider's own reverse-engineering component
(`IDatabaseModelFactory`, the piece behind `dotnet ef dbcontext scaffold`), so it sees what the
provider sees: tables, columns, store types, primary keys, foreign keys, identity and default
values. SQL Server and SQLite name their factory explicitly; for an **extension** the module
discovers the factory in the provider's EF assembly, which every mainstream EF provider ships
(DuckDB, PostgreSQL, MySQL, …). An extension needs no rebuild to gain database-first; an
extension author can pin the factory type by overriding
`SqlProviderDefinitionBase.DatabaseModelFactoryType`.

Where a provider cannot resolve a store type by name (some third-party providers only map by
CLR type), a built-in ANSI table (`INTEGER`, `BIGINT`, `DOUBLE`, `DECIMAL(p,s)`, `BOOLEAN`,
`VARCHAR`, `TIMESTAMP`, `UUID`, `BLOB`, …) supplies the CLR type. The result reports which
columns were mapped by the provider (`IsStoreTypeMapped`) and which came from the fallback.
