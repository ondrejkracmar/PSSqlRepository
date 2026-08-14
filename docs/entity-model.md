# Entity model walkthrough — Company, Person, Customer

This is the end-to-end example: three entities joined by foreign keys, defined as plain PowerShell
classes, persisted as a graph, and queried across the relationships. Every snippet here was run
against a real database before it was written down.

The example uses the **DuckDB** provider, which is an external extension — that makes it a
walkthrough of extension installation as well. Change the provider name and the connect parameters
and the same model works on SQLite or SQL Server unmodified; see [Using another provider](#using-another-provider).

- [1. Install the module](#1-install-the-module)
- [2. Install the DuckDB provider](#2-install-the-duckdb-provider)
- [3. Define the model](#3-define-the-model)
- [4. The two-file pattern](#4-the-two-file-pattern-and-why-it-is-needed)
- [5. Register, connect, save](#5-register-connect-save)
- [6. Query across relationships](#6-query-across-relationships)
- [7. Transactions](#7-transactions)
- [Rules for PowerShell entity classes](#rules-for-powershell-entity-classes)
- [Using another provider](#using-another-provider)

---

## 1. Install the module

```powershell
Install-PSResource PSSqlRepository -Repository PSGallery   # or: Install-Module PSSqlRepository
Import-Module PSSqlRepository
Get-PSSqlRepositoryProvider
```

`Get-PSSqlRepositoryProvider` lists what you can connect to. A stock install shows `SqlServer` and
`Sqlite`.

## 2. Install the DuckDB provider

DuckDB ships as a separate extension, so it has to be installed into the module and its signing key
has to be trusted. Trust is a deliberate, separate step: it grants code execution to every assembly
signed with that key, so the module never grants it implicitly.

```powershell
Install-PSResource PSSqlRepository.Providers.DuckDB -Repository PSGallery
Install-PSSqlRepositoryExtension -FromModule PSSqlRepository.Providers.DuckDB -Trust
```

The first line downloads the payload; the second moves it into PSSqlRepository and trusts the
signing key. Offline, replace the second line with
`Install-PSSqlRepositoryExtension -Path .\PSSqlRepository.Providers.DuckDB-<version>.zip -Trust`.

Restart PowerShell, then verify:

```powershell
Get-PSSqlRepositoryExtension | Format-Table Name, Status, Reason
Get-PSSqlRepositoryProvider  | Format-Table Name, DisplayName
```

`DuckDB` must appear in both. If `Get-PSSqlRepositoryExtension` shows `Rejected` with a reason about
an untrusted public key token, you installed without `-Trust` — see
[extensibility.md](./extensibility.md#installing-an-extension).

> DuckDB is `net10.0`-only, so it appears on PowerShell 7.6+ and not on 7.4/7.5.

## 3. Define the model

Three entities, two foreign keys:

```
Company 1 ──< N Person 1 ──1 Customer
```

Every persisted type must implement `IEntity[TKey]`. The module registers `IEntity` as a type
accelerator at import, so no `using namespace` is needed.

```powershell
# model.ps1
class Company : IEntity[int] {
    [int]    $Id
    [string] $Name
    [string] $RegistrationNumber

    # Collection navigation to the dependent side.
    # NOTE: no '= [List[Person]]::new()' initializer here — see the rules below.
    [System.Collections.Generic.List[Person]] $People
}

class Person : IEntity[int] {
    [int]     $Id
    [string]  $FirstName
    [string]  $LastName
    [string]  $Email

    [int]     $CompanyId   # FK -> Company.Id
    [Company] $Company     # reference navigation

    [Customer] $Customer   # inverse of Customer.Person
}

class Customer : IEntity[int] {
    [int]     $Id
    [string]  $CustomerNumber
    [decimal] $CreditLimit

    [int]     $PersonId    # FK -> Person.Id
    [Person]  $Person
}
```

No mapping attributes and no Fluent API are required. EF Core's conventions do the work:

| What you write | What EF Core infers |
|---|---|
| `[int] $Id` (from `IEntity[int]`) | primary key, database-generated |
| `[int] $CompanyId` + `[Company] $Company` | required FK to `Company.Id` |
| `[List[Person]] $People` on `Company` | the inverse collection of `Person.Company` |
| `[Person] $Person` on `Customer` with `[Customer] $Customer` on `Person` | one-to-one |
| `[string]`, `[decimal]`, `[int]` | nullable / precision-typed columns per provider |

Make an FK **nullable** (`[Nullable[int]] $CompanyId`) when the relationship is optional. A
non-nullable FK is required, and detaching a child from it fails — that is what the
`-OrphanBehavior Detach … has a required (non-nullable) foreign key` error in
[TROUBLESHOOTING.md](../TROUBLESHOOTING.md) is about.

## 4. The two-file pattern (and why it is needed)

PowerShell compiles an **entire script file before executing any of it**. A
`class Company : IEntity[int]` declaration is resolved at that compile step, so if the file also
contains the `Import-Module` that makes `IEntity` resolvable, parsing fails first:

```
ParserError: Unable to find type [IEntity].
```

`using module` does not fix it either — the accelerator is registered by the module's script body,
which runs too late for the parser.

So keep the model in its own file and import before invoking it:

```powershell
# run.ps1
Import-Module PSSqlRepository
& "$PSScriptRoot\model.ps1"
```

Interactively there is no problem: `Import-Module PSSqlRepository` and then pasting the class at the
prompt works, because each prompt entry is compiled separately.

## 5. Register, connect, save

`Register-PSSqlRepositoryEntity` builds a `DbContext` at runtime from the types you name. Call it
**before** `Connect-PSSqlRepository`. Successive calls for the same provider accumulate, so you can
register one type at a time or all at once.

```powershell
# ...continuing model.ps1
Register-PSSqlRepositoryEntity -ProviderName DuckDB -EntityType ([Company]), ([Person]), ([Customer])

# Connect returns the session object. Assign it away in a script: PowerShell's formatter takes the
# column layout from the FIRST object in the output stream, so a stray session object makes every
# later entity print as blank rows.
$null = Connect-PSSqlRepository DuckDB -Path .\demo.duckdb -EnsureCreated
```

`-EnsureCreated` creates the schema from the model if it is not there. It is a development
convenience, not a migration system: it will not alter an existing table when the model changes.

### Saving a whole graph in one call

`-IncludeNavigations` walks the object graph and persists the children too, filling in their FKs:

```powershell
$acme = [Company]@{
    Name               = 'Acme s.r.o.'
    RegistrationNumber = '12345678'
    People             = [System.Collections.Generic.List[Person]]@(
        [Person]@{ FirstName = 'Jana'; LastName = 'Novakova'; Email = 'jana@acme.cz' }
        [Person]@{ FirstName = 'Petr'; LastName = 'Svoboda';  Email = 'petr@acme.cz' }
    )
}

$acme = Save-PSSqlRepositoryEntity -InputObject $acme -IncludeNavigations -PassThru
"Company Id=$($acme.Id), People=$($acme.People.Count)"    # -> Company Id=1, People=2
```

Without `-IncludeNavigations` only the root is written and the `People` collection is ignored.

### Saving a child against an existing parent

Set the FK yourself when the parent is already in the database:

```powershell
$jana = Get-PSSqlRepositoryEntity -EntityType ([Person]) -Filter "Email -eq 'jana@acme.cz'" -Top 1 -AsNoTracking

$cust = [Customer]@{ CustomerNumber = 'C-0001'; CreditLimit = 50000; PersonId = $jana.Id }
$cust = Save-PSSqlRepositoryEntity -InputObject $cust -PassThru
"Customer Id=$($cust.Id) PersonId=$($cust.PersonId)"      # -> Customer Id=1 PersonId=1
```

`Save-PSSqlRepositoryEntity` defaults to `-Mode Upsert`: a default-valued key (`0`, `null`,
`Guid.Empty`) inserts, anything else updates. Force one or the other with `-Mode Add` / `-Mode
Update`, or use the `Update-PSSqlRepositoryEntity` proxy.

## 6. Query across relationships

Navigations are **not** loaded by default. Ask for them by path with `-Include`:

```powershell
Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Include 'Person.Company' -Top 10 -AsNoTracking |
    ForEach-Object { "{0} -> {1} {2} @ {3}" -f $_.CustomerNumber, $_.Person.FirstName, $_.Person.LastName, $_.Person.Company.Name }

# C-0001 -> Jana Novakova @ Acme s.r.o.
```

`-IncludeAll` pulls every navigation one level deep — convenient at a prompt, wasteful in a script.

Filter, sort, and project run **in SQL**, not in PowerShell:

```powershell
Get-PSSqlRepositoryEntity -EntityType ([Person]) `
    -Filter "CompanyId -eq $($acme.Id)" `
    -OrderBy 'LastName' `
    -Property Id, LastName, Email `
    -Top 10

# 1  Novakova  jana@acme.cz
# 2  Svoboda   petr@acme.cz
```

| Parameter | Runs where | Use it for |
|---|---|---|
| `-Filter` | SQL | the real predicate — keeps rows on the server |
| `-Where` (ScriptBlock) | PowerShell | anything SQL cannot express; every row is fetched first |
| `-OrderBy` | SQL | `'LastName'`, `'Name DESC'` |
| `-Property` | SQL | projection — fetch only the columns you need |
| `-Top` / `-Skip` | SQL | paging |
| `-Id` | SQL | single-row lookup by primary key |
| `-AsNoTracking` | — | read-only queries; skips change-tracking overhead |

Querying without `-Top`/`-Skip` emits a one-time warning per entity type. Silence it with
`-SuppressUnboundedWarning` when the full scan is intentional.

## 7. Transactions

```powershell
Start-PSSqlRepositoryTransaction
$null = Save-PSSqlRepositoryEntity -InputObject ([Company]@{ Name = 'Rollback Ltd' }) -PassThru
Undo-PSSqlRepositoryTransaction

(Get-PSSqlRepositoryEntity -EntityType ([Company]) -Top 100 -AsNoTracking | Measure-Object).Count
# -> 1   (the rolled-back insert is gone)
```

Use `Complete-PSSqlRepositoryTransaction` to commit. Close the session when done:

```powershell
Disconnect-PSSqlRepository
```

---

## Rules for PowerShell entity classes

These are the ones that actually bite.

### Never give a property a default initializer

```powershell
# WRONG — every query fails
[System.Collections.Generic.List[Person]] $People = [System.Collections.Generic.List[Person]]::new()

# RIGHT
[System.Collections.Generic.List[Person]] $People
```

A PowerShell class property initializer is a script block, and EF Core materialises entities on a
worker thread that has no PowerShell runspace attached. Running the initializer there throws:

```
There is no Runspace available to run scripts in this thread.
```

The error surfaces on `Get-PSSqlRepositoryEntity`, far from the class that caused it, and it applies
to **any** initializer expression — not just collections. Leave the property null and assign the
collection when you construct the object:

```powershell
$c = [Company]@{ Name = 'Acme'; People = [System.Collections.Generic.List[Person]]@( $p1, $p2 ) }
```

The same reasoning rules out custom constructors, default-value expressions, and property getters
with logic. Keep entity classes to plain typed fields.

### Implement `IEntity[TKey]`

`Register-PSSqlRepositoryEntity` rejects anything else:

```
Type 'Foo' must implement Isystem.Shared.Infrastructure.Services.Repository.IEntity<TKey>.
```

`TKey` is whatever the key type is — `[int]`, `[guid]`, `[string]`. The `Id` property must match it.

### Use a collection type with a public `Add(T)`

`List<T>`, `HashSet<T>`, or an array. A collection navigation without `Add(T)` fails with
`Cannot populate collection of type '<Type>': no public Add(T) method was found.`

### Order matters

`Register-PSSqlRepositoryEntity` → `Connect-PSSqlRepository` → everything else. Registering after
connecting does not retroactively change the session's model.

---

## Using another provider

The model is provider-agnostic. Only the two lines that name the provider change:

```powershell
# SQLite
Register-PSSqlRepositoryEntity -ProviderName Sqlite -EntityType ([Company]), ([Person]), ([Customer])
$null = Connect-PSSqlRepository Sqlite -Path .\demo.db -EnsureCreated

# SQL Server
Register-PSSqlRepositoryEntity -ProviderName SqlServer -EntityType ([Company]), ([Person]), ([Customer])
$null = Connect-PSSqlRepository SqlServer -Server '.\SQLEXPRESS' -Database 'Demo' -EnsureCreated
```

Provider-specific connect parameters are listed in
[provider-auth-reference.md](./provider-auth-reference.md), and at runtime by
`(Get-PSSqlRepositoryProvider <name>).GetConnectParameters()`.
