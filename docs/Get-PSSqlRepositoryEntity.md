---
document type: cmdlet
external help file: PSSqlRepository.Commands.dll-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/02/2026
PlatyPS schema version: 2024-05-01
title: Get-PSSqlRepositoryEntity
---

# Get-PSSqlRepositoryEntity

## SYNOPSIS

Streams entities from the active session's database to the pipeline.

## SYNTAX

### List (Default)

```
Get-PSSqlRepositoryEntity [-EntityType] <type> [-Skip <int>] [-Top <int>] [-Where <scriptblock>]
 [-Filter <string>] [-OrderBy <string[]>] [-Property <string[]>] [-AsNoTracking]
 [-Include <string[]>] [-IncludeAll] [-SuppressUnboundedWarning] [-CommandTimeout <int>]
```

### ById

```
Get-PSSqlRepositoryEntity [-EntityType] <type> [-Id] <Object> [-AsNoTracking] [-Include <string[]>]
 [-IncludeAll] [-SuppressUnboundedWarning] [-CommandTimeout <int>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

streams entities from the active session's database to the pipeline.
Supports lookup by Id, paging (-Top/-Skip), server-side filtering (-Filter), sorting (-OrderBy) and column projection (-Property) — all three translate to SQL WHERE / ORDER BY / SELECT — plus client-side filtering via a System.Management.Automation.ScriptBlock (-Where) and read-only execution (-AsNoTracking).

Also exposed as Get-PSSqlRepositoryItem for command-surface parity with the PSDataRepository module.
The alias shares this single implementation so query behaviour cannot drift between the Entity and Item spellings.

## EXAMPLES

### Example 1

Get-PSSqlRepositoryEntity -EntityType ([Customer])

### Example 2

Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Id 5

### Example 3

Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Top 100 -AsNoTracking

### Example 4

Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Filter "Name -like 'A*'" -OrderBy 'Name DESC' -Top 10

### Example 5

Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Filter "RowVersion -gt 3" -Property Id, Name

### Example 6

Get-PSSqlRepositoryEntity -EntityType ([Customer]) -Where { $_.Name -like 'A*' }

## PARAMETERS

### -AsNoTracking

Retained for compatibility.
Reads are now ALWAYS no-tracking (the cmdlet returns disconnected snapshots that are safe to mutate and re-Save), so this switch no longer changes behaviour.

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

### -CommandTimeout

Per-invocation override (in seconds) for DbContext.Database.CommandTimeout.
Use for one-off long-running queries (large scans, expensive includes) without bumping the provider-level default.
0 disables the timeout entirely; set only when you have a sustained workload that justifies waiting indefinitely.

```yaml
Type: System.Nullable`1[System.Int32]
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

### -EntityType

The EntityType parameter.

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

### -Filter

Server-side filter using PowerShell comparison syntax, translated to a SQL WHERE clause via an EF Core expression tree.
Supports -eq -ne -gt -ge -lt -le -like -notlike -in -notin -and -or -not, parentheses, dotted property paths ("Customer.Name") and literals ('text', numbers, $true, $false, $null).
Unlike -Where, the filter runs in the database, so it composes correctly with -Top/-Skip paging.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: List
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Id

The Id parameter.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ById
  Position: 1
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Include

Names of navigation properties to eagerly load.
Each entry is passed verbatim to EF.Functions.Include (string overload), so dotted paths like "Orders.Items" work for nested loads.
Use this when piping the result into Save-PSSqlRepositoryEntity -IncludeNavigations so the merger has the full existing graph to diff against.

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

### -IncludeAll

Eagerly loads every navigation declared on the entity in the EF Core model (collections and references, one level deep).
Convenient for ad-hoc inspection and for round-tripping into Save-PSSqlRepositoryEntity -IncludeNavigations.
Combine with explicit -Include 'Lines.Foo' when you need deeper-than-one-level paths.

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

### -OrderBy

Sort specification translated to a SQL ORDER BY.
Each entry is a property path optionally followed by a direction: 'Name', 'Name DESC' or 'Name:desc'.
Multiple entries become ThenBy chains.
Dotted paths order by related columns.
Applied before -Skip/-Top, so paging is stable.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: List
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Property

Projects only the named properties (SQL SELECT col1, col2) instead of loading full entities.
Output objects are System.Management.Automation.PSObjects with one note property per requested path (dotted paths use the full path as the name).
Mutually exclusive with -Include/-IncludeAll and tracking — the projected rows are detached values, not entities.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: List
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Skip

The Skip parameter.

```yaml
Type: System.Nullable`1[System.Int32]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: List
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SuppressUnboundedWarning

Suppresses the unbounded-query warning that Get-PSSqlRepositoryEntity emits when neither -Top nor -Skip is supplied.
Use this for intentionally unbounded scans (small lookup tables, ad-hoc one-shots) to keep pipelines quiet in production.

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

### -Top

The Top parameter.

```yaml
Type: System.Nullable`1[System.Int32]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: List
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Where

Client-side filter evaluated after the database Skip/Top page has been fetched.
With -Top N -Where { … } you may receive fewer than N results because filtering happens on the materialised page, not in the database.
Push predicates that affect the returned count down to the database via a custom repository method.

```yaml
Type: System.Management.Automation.ScriptBlock
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: List
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

### System.Object

See the cmdlet description.

## OUTPUTS

### System.Object

See the cmdlet description.

## NOTES

Part of the PSSqlRepository module.
See about_PSSqlRepository and the docs/ folder of the repository.


## RELATED LINKS

- [Online Version]()
