---
document type: cmdlet
external help file: PSSqlRepository.Commands.dll-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/02/2026
PlatyPS schema version: 2024-05-01
title: Register-PSSqlRepositoryContext
---

# Register-PSSqlRepositoryContext

## SYNOPSIS

Registers a provider-backed repository context type so subsequent Connect-PSSqlRepository sessions wire it plus the matching IRepository<T>/IUnitOfWork registrations into the session's DI scope.

## SYNTAX

### __AllParameterSets

```
Register-PSSqlRepositoryContext [-ContextType] <type> [-ProviderName] <string> [-PassThru]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

registers a provider-backed repository context type so subsequent Connect-PSSqlRepository sessions wire it plus the matching IRepository<T>/IUnitOfWork registrations into the session's DI scope.
The user's entities are then reachable via Save-PSSqlRepositoryEntity and through Get-PSSqlRepositorySession.

## EXAMPLES

### Example 1

Register-PSSqlRepositoryContext

## PARAMETERS

### -ContextType

The ContextType parameter.

```yaml
Type: System.Type
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

### -PassThru

Returns the processed object(s) to the pipeline.

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
  Position: 1
  IsRequired: true
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

### System.Void

See the cmdlet description.

## NOTES

Part of the PSSqlRepository module.
See about_PSSqlRepository and the docs/ folder of the repository.


## RELATED LINKS

- [Online Version]()
