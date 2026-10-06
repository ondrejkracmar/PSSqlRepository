---
document type: cmdlet
external help file: PSSqlRepository.Commands.dll-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/06/2026
PlatyPS schema version: 2024-05-01
title: Import-PSSqlRepositorySchema
---

# Import-PSSqlRepositorySchema

## SYNOPSIS

Database-first: reads the schema of an existing database, emits one entity type per table and registers them as the provider's repository context.

## SYNTAX

### ConnectionString (Default)

```
Import-PSSqlRepositorySchema [-ProviderName] <string> [-AuthMode <string>] [-Schema <string[]>]
 [-Table <string[]>] [-ExcludeTable <string[]>] [-IncludeView] [-Namespace <string>] [-NoRegister]
 [-WhatIf] [-Confirm]
```

### IntegratedSecurity

```
Import-PSSqlRepositorySchema [-ProviderName] <string> [-AuthMode <string>] [-Schema <string[]>]
 [-Table <string[]>] [-ExcludeTable <string[]>] [-IncludeView] [-Namespace <string>] [-NoRegister]
 [-WhatIf] [-Confirm]
```

### Credential

```
Import-PSSqlRepositorySchema [-ProviderName] <string> -Credential <pscredential>
 [-AuthMode <string>] [-Schema <string[]>] [-Table <string[]>] [-ExcludeTable <string[]>]
 [-IncludeView] [-Namespace <string>] [-NoRegister] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The database-first counterpart of Register-PSSqlRepositoryEntity.
Instead of writing PowerShell classes, point the cmdlet at a database that already exists: it reads the catalogue through the EF Core provider's own reverse-engineering component, emits a public CLR class per table at run time (a property per column, named after the column; the primary key wired to the IEntity[TKey] contract the entity cmdlets require) and registers the set exactly as Register-PSSqlRepositoryEntity would.
A following Connect-PSSqlRepository with the same connection parameters then serves Get-, Save- and Remove-PSSqlRepositoryEntity against those tables.
Connect-PSSqlRepository -ImportSchema performs both steps at once.

Takes the same provider connect parameters as Connect-PSSqlRepository (-Path, -Server/-Database, -ConnectionString, ...) and the same authentication surface.
Tables with a composite primary key, tables without a primary key and views are reported as skipped with a reason; columns whose store type cannot be mapped are listed per table and left off the entity.
The registration replaces any context previously registered for the provider; -NoRegister reads and emits without registering.

## EXAMPLES

### EXAMPLE 1

$schema = Import-PSSqlRepositorySchema Sqlite -Path .\shop.db
$null = Connect-PSSqlRepository Sqlite -Path .\shop.db
Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Top 10
[Customer]@{ Name = 'Acme' } | Save-PSSqlRepositoryEntity -PassThru

Imports every table of an existing SQLite file, connects, then queries and inserts through the emitted [Customer] type.

### EXAMPLE 2

Import-PSSqlRepositorySchema SqlServer -Server '.\SQLEXPRESS' -Database Shop -Schema dbo, sales -Table Customer, 'sales.Order' -Namespace Shop

Imports two tables from two schemas of a SQL Server database as [Shop.Customer] and [Shop.Order].

### EXAMPLE 3

(Import-PSSqlRepositorySchema DuckDB -Path .\analytics.duckdb -NoRegister).Tables | Format-Table FullName, EntityType, PrimaryKey, SkipReason

Inspects a DuckDB database through the DuckDB extension without registering anything.

## PARAMETERS

### -AuthMode

Authentication mode, same values and semantics as Connect-PSSqlRepository (ConnectionString, IntegratedSecurity, UserPassword).

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ConnectionString
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: IntegratedSecurity
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Credential
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

Credential for UserPassword authentication.
Handled exactly as by Connect-PSSqlRepository; on SQL Server the password never enters the connection string.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Credential
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ExcludeTable

Tables to leave out, same syntax as -Table.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeView

Lists views in the result.
Views have no primary key, so they are reported as skipped; the switch exists so the report is complete.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Namespace

CLR namespace for the emitted types.
Default: none, so PowerShell can write [Customer].
Set it when two databases with overlapping table names are imported into one session and address the types as [Shop.Customer].

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -NoRegister

Reads the schema and emits the types but does not register them as the provider's context.
Use it to inspect a database or to keep an existing registration.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ProviderName

Provider to read through: Sqlite, SqlServer, or an installed extension such as DuckDB.
The provider's own connect parameters (-Path, -Server/-Database, -ConnectionString, ...) become available once it is named.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Schema

Database schemas to import (dbo, sales, ...).
Default: every schema.
Ignored by providers without schemas (SQLite).

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Table

Tables to import, as bare names (Customer) or schema-qualified names (sales.Order), matched case-insensitively.
Default: every table.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSSqlRepository.Core.Schema.SqlSchemaImportResult

One object describing every table the reader saw: Tables (with Columns, PrimaryKey, ForeignKeys, EntityType or SkipReason), Imported, Skipped, EntityTypes and FindEntityType(name).

## NOTES

Importing the same table again returns the same type, so [Customer] keeps resolving across re-runs; when a table's shape changed a new type is emitted and $result.FindEntityType('Customer') is the unambiguous handle.
Composite keys, keyless tables, views and navigation properties are not emitted in this version.


## RELATED LINKS

- [Connect-PSSqlRepository]()
- [Register-PSSqlRepositoryEntity]()
