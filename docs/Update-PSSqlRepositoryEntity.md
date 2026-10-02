---
document type: cmdlet
external help file: PSSqlRepository-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/02/2026
PlatyPS schema version: 2024-05-01
title: Update-PSSqlRepositoryEntity
---

# Update-PSSqlRepositoryEntity

## SYNOPSIS

Updates existing entities: a discoverable proxy for Save-PSSqlRepositoryEntity -Mode Update.

## SYNTAX

### __AllParameterSets

```
Update-PSSqlRepositoryEntity [-InputObject] <psobject> [[-EntityType] <type>] [-IncludeNavigations]
 [-OrphanBehavior <OrphanBehavior>] [-PassThru] [-SkipEnumeration] [-CommandTimeout <int>] [-WhatIf]
 [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Forwards every parameter to Save-PSSqlRepositoryEntity with -Mode Update, so an entity whose key does not exist yet fails instead of being inserted.
Pipeline input, batching (-BatchSize), -IncludeNavigations, -OrphanBehavior and -PassThru behave exactly as on Save-PSSqlRepositoryEntity; see its help for details.

## EXAMPLES

### Example 1

$customer = Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Id 5
$customer.Name = 'Renamed'
$customer | Update-PSSqlRepositoryEntity -PassThru

## PARAMETERS

### -CommandTimeout

Per-invocation override (in seconds) of the command timeout used for the update; restored when the command ends.

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

### -EntityType

Entity type to update when it cannot be inferred from the input object (a hashtable or PSCustomObject).

```yaml
Type: System.Type
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeNavigations

Also merge navigation properties (child collections and references) instead of updating scalar columns only.

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

### -InputObject

The entity (or hashtable / PSCustomObject carrying its key) to update; accepts pipeline input.

```yaml
Type: System.Management.Automation.PSObject
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OrphanBehavior

What happens to child rows a merged collection no longer contains: Detach, Delete or Fail (see Save-PSSqlRepositoryEntity).

```yaml
Type: PSSqlRepository.Core.OrphanBehavior
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

### -PassThru

Returns the updated entity to the pipeline.

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

### -SkipEnumeration

Treat an input object that implements IEnumerable as one entity instead of unrolling it.

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

### System.Management.Automation.PSObject

Forwards every parameter to Save-PSSqlRepositoryEntity with -Mode Update, so an entity whose key does not exist yet fails instead of being inserted.
Pipeline input, batching (-BatchSize), -IncludeNavigations, -OrphanBehavior and -PassThru behave exactly as on Save-PSSqlRepositoryEntity; see its help for details.

## OUTPUTS

### System.Object

Forwards every parameter to Save-PSSqlRepositoryEntity with -Mode Update, so an entity whose key does not exist yet fails instead of being inserted.
Pipeline input, batching (-BatchSize), -IncludeNavigations, -OrphanBehavior and -PassThru behave exactly as on Save-PSSqlRepositoryEntity; see its help for details.

## NOTES

Proxy function defined in PSSqlRepository.psm1; the implementation is Save-PSSqlRepositoryEntity.


## RELATED LINKS

- [Online Version]()
