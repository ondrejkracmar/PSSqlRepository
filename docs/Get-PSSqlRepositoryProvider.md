---
document type: cmdlet
external help file: PSSqlRepository.Commands.dll-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/02/2026
PlatyPS schema version: 2024-05-01
title: Get-PSSqlRepositoryProvider
---

# Get-PSSqlRepositoryProvider

## SYNOPSIS

Lists all registered SQL provider definitions.

## SYNTAX

### __AllParameterSets

```
Get-PSSqlRepositoryProvider [[-Name] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

lists all registered SQL provider definitions.

## EXAMPLES

### Example 1

Get-PSSqlRepositoryProvider

## PARAMETERS

### -Name

The Name parameter.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
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

### PSSqlRepository.Providers.ISqlProviderDefinition

See the cmdlet description.

## NOTES

Part of the PSSqlRepository module.
See about_PSSqlRepository and the docs/ folder of the repository.


## RELATED LINKS

- [Online Version]()
