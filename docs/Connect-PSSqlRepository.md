---
document type: cmdlet
external help file: PSSqlRepository.Commands.dll-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/02/2026
PlatyPS schema version: 2024-05-01
title: Connect-PSSqlRepository
---

# Connect-PSSqlRepository

## SYNOPSIS

Opens a session for the requested provider, applies the requested authentication mode (resolved through SqlAuthenticationRegistry), and stores the session in the ambient SqlSessionManager.

## SYNTAX

### ConnectionString (Default)

```
Connect-PSSqlRepository [-ProviderName] <string> [-AuthMode <string>] [-ImportSchema] [-Migrate]
 [-WhatIf] [-Confirm]
```

### IntegratedSecurity

```
Connect-PSSqlRepository [-ProviderName] <string> [-AuthMode <string>] [-ImportSchema] [-Migrate]
 [-WhatIf] [-Confirm]
```

### Credential

```
Connect-PSSqlRepository [-ProviderName] <string> -Credential <pscredential> [-AuthMode <string>]
 [-ImportSchema] [-Migrate] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

opens a session for the requested provider, applies the requested authentication mode (resolved through SqlAuthenticationRegistry), and stores the session in the ambient SqlSessionManager.
Returns a SqlRepositoryConnection handle.

## EXAMPLES

### Example 1

Connect-PSSqlRepository

## PARAMETERS

### -AuthMode

The AuthMode parameter.

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

The Credential parameter.

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

### -ImportSchema

Database-first: reads the target database's schema first, emits one entity type per table and registers them as this provider's repository context, then connects.
Equivalent to Import-PSSqlRepositorySchema (all tables) followed by Connect-PSSqlRepository with the same parameters.
Replaces any context registered for the provider.
See Import-PSSqlRepositorySchema for filtering and the schema report.

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

### -Migrate

Forward-migrates the database schema to the registered model right after connecting: creates the database or missing tables (as -EnsureCreated does) and additionally adds missing columns, indexes and foreign keys to existing tables.
Destructive differences (dropped columns, narrowed types) are reported as warnings and left alone; apply them with Update-PSSqlRepositorySchema -AllowDestructive.
Each run that changes the schema is recorded in the __PSSqlRepositoryMigrations table.
Cannot be combined with -ImportSchema.
Implies -EnsureCreated.

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

Name of a registered SQL provider, for example Sqlite or SqlServer (see Get-PSSqlRepositoryProvider).

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

### PSSqlRepository.Providers.SqlRepositoryConnection

See the cmdlet description.

## NOTES

Part of the PSSqlRepository module.
See about_PSSqlRepository and the docs/ folder of the repository.


## RELATED LINKS

- [Online Version]()
