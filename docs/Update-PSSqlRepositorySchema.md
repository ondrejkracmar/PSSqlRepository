---
document type: cmdlet
external help file: PSSqlRepository.Commands.dll-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/06/2026
PlatyPS schema version: 2024-05-01
title: Update-PSSqlRepositorySchema
---

# Update-PSSqlRepositorySchema

## SYNOPSIS

Forward-migrates the connected database to the registered entity model, the way EF Core migrations would, without a migrations project.

## SYNTAX

### __AllParameterSets

```
Update-PSSqlRepositorySchema [-AllowDestructive] [-NoHistory] [-Script] [-Force] [-WhatIf]
 [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Compares the live catalogue with the registered model (see Compare-PSSqlRepositorySchema) and applies the additive differences in one batch: new tables, columns, indexes, foreign keys, unique and check constraints, widened columns and index renames.
Destructive differences (dropped tables or columns, narrowed types, NULL to NOT NULL, identity changes) are reported as warnings and only applied with -AllowDestructive, which prompts unless -Force is given.
Tables the model does not map are never touched.

Every run that changes the schema is recorded as a row in the __PSSqlRepositoryMigrations table (created on first use) in the same batch as the schema change; -NoHistory skips that.
-Script returns the SQL in the provider's dialect instead of running it; -WhatIf reports what would run.
Schema changes run in their own transaction, so the cmdlet refuses to run while an explicit transaction is open.

Returns a SchemaMigrationResult (Applied, MigrationId, AppliedOnUtc, AppliedOperationCount, Plan), or the SQL string with -Script.

## EXAMPLES

### Preview, then apply

Update-PSSqlRepositorySchema -WhatIf
Update-PSSqlRepositorySchema

The first call reports what would run; the second applies the additive changes and records them.

### Hand the SQL to a DBA

Update-PSSqlRepositorySchema -Script | Set-Content .\migration.sql

Nothing is executed.
The script includes the history table and row, so applying it by hand leaves the same audit trail.

### Apply destructive changes in a script

Update-PSSqlRepositorySchema -AllowDestructive -Force

Drops and narrowing changes run too; -Force suppresses the confirmation prompt.

## PARAMETERS

### -AllowDestructive

Also apply destructive operations: drop tables, columns, indexes and constraints the model no longer has, narrow column types, make columns NOT NULL.
Prompts before running them unless -Force is given.

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

### -Force

Skip the confirmation prompt for destructive operations (-AllowDestructive).

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

### -NoHistory

Do not record this run in the __PSSqlRepositoryMigrations table (and do not create it).

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

### -Script

Return the SQL script that would run, in the provider's dialect, instead of executing it.
Honours -AllowDestructive and -NoHistory.

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

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

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

### PSSqlRepository.Core.Schema.SchemaMigrationResult

Whether the plan was applied, the migration id recorded in the history table, and the plan itself.
With -Script: the SQL as a string.

### System.String

{{ Fill in the Description }}

## NOTES

See docs/schema-migration.md for the full guide: additive versus destructive operations, the history table, scripts for a DBA, transactions and limitations.


## RELATED LINKS

- [Compare-PSSqlRepositorySchema]()
- [Connect-PSSqlRepository]()
- [Import-PSSqlRepositorySchema]()
