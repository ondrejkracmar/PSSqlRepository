---
document type: cmdlet
external help file: PSSqlRepository.Commands.dll-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/02/2026
PlatyPS schema version: 2024-05-01
title: Compare-PSSqlRepositorySchema
---

# Compare-PSSqlRepositorySchema

## SYNOPSIS

Reports how the connected database differs from the registered entity model, without changing anything.

## SYNTAX

### __AllParameterSets

```
Compare-PSSqlRepositorySchema [-AllowDestructive] [-HistoryCount <int>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Reads the live catalogue of the connected database through the provider's own reverse-engineering component, rebuilds it as a model and compares it with the registered entity model using EF Core's model differ.
The result lists every operation Update-PSSqlRepositorySchema would run (Status Planned) or hold back (SkippedDestructive, SkippedDependent), formatting-only differences it ignores (Suppressed), the SQL script for the applicable operations, the tables the model does not map (UnmanagedTables, never touched) and the newest rows of the __PSSqlRepositoryMigrations history table.

Requires an open session (Connect-PSSqlRepository) and a provider that advertises the SchemaManagement capability.
Refuses to run while an explicit transaction (Start-PSSqlRepositoryTransaction) is open.

## EXAMPLES

### Inspect the differences

$plan = Compare-PSSqlRepositorySchema
$plan.HasChanges
$plan.Operations | Format-Table Status, Kind, Table, Column, Description

Lists what Update-PSSqlRepositorySchema would do.
Nothing is changed.

### Review the SQL including destructive changes

(Compare-PSSqlRepositorySchema -AllowDestructive).Script

The script in the provider's dialect, with drops and narrowing changes included.

## PARAMETERS

### -AllowDestructive

Plan destructive operations (drop table / column / index / constraint, narrowing column changes, NULL to NOT NULL) as applicable too, so Script and Applicable show what Update-PSSqlRepositorySchema -AllowDestructive would run.

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

### -HistoryCount

How many rows of the __PSSqlRepositoryMigrations table (newest first) to include in History.
Default 10; 0 skips reading the table.

```yaml
Type: System.Int32
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSSqlRepository.Core.Schema.SchemaMigrationPlan

The classified plan: Operations, Applicable, SkippedDestructive, Suppressed, UnmanagedTables, HasChanges, Script, History, HistoryTableExists.

## NOTES

See docs/schema-migration.md for the full guide: additive versus destructive operations, the history table, scripts for a DBA, transactions and limitations.


## RELATED LINKS

- [Update-PSSqlRepositorySchema]()
- [Connect-PSSqlRepository]()
- [Import-PSSqlRepositorySchema]()
