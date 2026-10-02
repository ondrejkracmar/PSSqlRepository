---
document type: cmdlet
external help file: PSSqlRepository.Commands.dll-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/02/2026
PlatyPS schema version: 2024-05-01
title: Register-PSSqlRepositoryEntity
---

# Register-PSSqlRepositoryEntity

## SYNOPSIS

Registers a dynamic Microsoft.EntityFrameworkCore.DbContext built at runtime from the supplied entity types, so PowerShell users can persist plain PowerShell class definitions (or any CLR type implementing IEntity<TKey>) without writing or compiling a custom Microsoft.EntityFrameworkCore.DbContext in C#.

## SYNTAX

### __AllParameterSets

```
Register-PSSqlRepositoryEntity [-ProviderName] <string> [-EntityType] <type[]> [-PassThru]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

registers a dynamic Microsoft.EntityFrameworkCore.DbContext built at runtime from the supplied entity types, so PowerShell users can persist plain PowerShell class definitions (or any CLR type implementing IEntity<TKey>) without writing or compiling a custom Microsoft.EntityFrameworkCore.DbContext in C#.

Internally registers DynamicEntityDbContext for the requested provider and attaches a DynamicEntityModelExtension so EF Core's model cache produces a distinct model per distinct type set.
Subsequent Connect-PSSqlRepository calls will resolve the dynamic context exactly like a hand-written one.

## EXAMPLES

### Example 1

class Customer : IEntity[int] {
    [int]  $Id
    [string] $Name
}
Register-PSSqlRepositoryEntity -ProviderName Sqlite -EntityType ([Customer])
Connect-PSSqlRepository -ProviderName Sqlite -ConnectionString $cs -EnsureCreated
[Customer]@{ Name = 'Acme' } | Save-PSSqlRepositoryEntity

## PARAMETERS

### -EntityType

The EntityType parameter.

```yaml
Type: System.Type[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: true
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
  Position: 0
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

### System.Type[]

See the cmdlet description.

## OUTPUTS

### System.Type

See the cmdlet description.

## NOTES

Part of the PSSqlRepository module.
See about_PSSqlRepository and the docs/ folder of the repository.


## RELATED LINKS

- [Online Version]()
