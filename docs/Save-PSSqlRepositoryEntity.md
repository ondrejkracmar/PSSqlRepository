---
document type: cmdlet
external help file: PSSqlRepository.Commands.dll-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/06/2026
PlatyPS schema version: 2024-05-01
title: Save-PSSqlRepositoryEntity
---

# Save-PSSqlRepositoryEntity

## SYNOPSIS

Persists an entity through the active session's IRepository<T> + IUnitOfWork.

## SYNTAX

### __AllParameterSets

```
Save-PSSqlRepositoryEntity [-InputObject] <psobject> [[-EntityType] <type>]
 [-Mode <SqlEntitySaveMode>] [-IncludeNavigations] [-OrphanBehavior <OrphanBehavior>] [-PassThru]
 [-SkipEnumeration] [-CommandTimeout <int>] [-BatchSize <int>] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

persists an entity through the active session's IRepository<T> + IUnitOfWork.
Pipeline batched twice over: N entities pushed through the pipeline result in a single SaveChanges call, and in Upsert/Update mode the existence check runs once per BatchSize entities (one keyed IN query) instead of one lookup per entity — see PersistManyAsync(PSSqlRepository.Providers.ISqlProviderSession,Microsoft.EntityFrameworkCore.DbContext,PSSqlRepository.Commands.SqlEntitySaveMode,System.Collections.Generic.IReadOnlyList{System.Object},System.Type,System.Boolean,PSSqlRepository.Core.OrphanBehavior,System.Collections.Generic.IDictionary{System.Object,System.Object},System.Threading.CancellationToken).

Accepts strongly-typed instances, System.Management.Automation.PSObject, [pscustomobject], hashtables, and anonymous types.
Nested navigation collections are converted recursively.

Also exposed as Set-PSSqlRepositoryItem / Save-PSSqlRepositoryItem for command-surface parity with the PSDataRepository module ($collection | Set-PSSqlRepositoryItem).
Aliases share this single implementation so the persistence pipeline cannot drift between the Entity and Item spellings.

Add vs.
Upsert for graphs with existing relations.
-Mode Add tracks the whole incoming graph as new, so if it references an already-persisted related entity (e.g.
a category that already has a key) the provider tries to INSERT that row too and fails on the primary key.
To attach to existing related rows, use the default Upsert (or Update) with -IncludeNavigations, which matches children by key and only inserts the genuinely new ones.

Single session, single thread.
The whole pipeline shares one session-scoped DbContext, which — like EF Core itself — is not thread-safe.
The active session is held in an AsyncLocal, so it does NOT flow into ForEach-Object -Parallel branches: each branch starts with no session and fails fast on "Call Connect-PSSqlRepository first".
Give every parallel branch its own Connect-PSSqlRepository.
If you instead capture a session outside the block and drive it from several branches, the session's own guard throws a clear error rather than corrupting state.
On a single thread the batched single-SaveChanges commit is the fast path.

## EXAMPLES

### Example 1

Save-PSSqlRepositoryEntity

## PARAMETERS

### -BatchSize

{{ Fill BatchSize Description }}

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

### -CommandTimeout

Per-invocation override (in seconds) for DbContext.Database.CommandTimeout.
Apply to bulk pipeline writes that exceed the provider default (30 s on SQL Server).
0 disables the timeout entirely.

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

The EntityType parameter.

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

When set, navigation collections on the incoming graph are diffed against the stored graph: new children are inserted, matching children are updated, and children present in the database but absent from the incoming graph are deleted (or detached, per OrphanBehavior).

Conventions:

- A null navigation on the incoming entity means "do not touch this navigation".
- An empty collection means "remove all children".
- Children are matched by primary key.
- Many-to-many: orphaning drops only the join row, never the target entity.
- Owned references are merged in place; owned collections are replaced.

When unset (default), only mapped scalar properties are updated and navigation collections are ignored — preserving the legacy aggregate-root scalar-only behaviour.

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

The InputObject parameter.

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

### -Mode

The Mode parameter.

```yaml
Type: PSSqlRepository.Commands.SqlEntitySaveMode
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

### -OrphanBehavior

Per-call override for orphan handling.
Only meaningful in combination with IncludeNavigations.

- (default) honor each relationship's OnDelete behavior.
- always DELETE orphaned children.
- always NULL the FK and preserve the row.
- fail when an orphan would be produced.

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

### -SkipEnumeration

When set, suppresses the auto-unrolling of an System.Collections.IEnumerable passed as a single -InputObject.
Use when the entity itself implements System.Collections.IEnumerable (e.g.
an entity wrapping a custom collection) and must be persisted as a scalar input rather than expanded.

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

See the cmdlet description.

## OUTPUTS

### System.Object

See the cmdlet description.

## NOTES

Part of the PSSqlRepository module.
See about_PSSqlRepository and the docs/ folder of the repository.


## RELATED LINKS

- [Online Version]()
