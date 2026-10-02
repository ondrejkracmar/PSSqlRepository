---
document type: cmdlet
external help file: PSSqlRepository.Commands.dll-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/02/2026
PlatyPS schema version: 2024-05-01
title: Get-PSSqlRepositoryExtension
---

# Get-PSSqlRepositoryExtension

## SYNOPSIS

Lists the extensions the module discovered at import time, including the ones it refused to load and why.

## SYNTAX

### __AllParameterSets

```
Get-PSSqlRepositoryExtension [-Rejected] [-Subfolder <string>] [-VersionSkew] [-MissingAfterUpgrade]
 [-ModuleRoot <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Lists the extensions the module discovered at import time, including the ones it refused to load and why.

Extensions are plugin assemblies dropped into the module's Auth\ and Providers\ folders.
Loading one can fail for reasons that are invisible from the outside — the assembly is unsigned, its public key token is not trusted, or it was built against an incompatible contract version — and the only symptom is a provider that does not exist.

This cmdlet reports every candidate assembly the loader saw, whether it loaded, and the reason for each rejection.
The scan happens once when the module is imported, so results reflect that scan; restart PowerShell after adding or replacing an extension.

## EXAMPLES

### Example 1

Get-PSSqlRepositoryExtension

### Example 2

Get-PSSqlRepositoryExtension -Rejected | Format-List Name, Reason

### Example 3

Get-PSSqlRepositoryExtension -Subfolder Providers

## PARAMETERS

### -MissingAfterUpgrade

Report extensions an earlier installed module version had that this one does not.

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

### -ModuleRoot

Module root to compare for -MissingAfterUpgrade.
Defaults to the running module.

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

### -Rejected

Return only the extensions that were rejected, with the reason.

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

### -Subfolder

Limit the report to one plugin subfolder.

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

### -VersionSkew

Report assembly versions that differ from what each extension was built against.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject

See the cmdlet description.

## NOTES

Part of the PSSqlRepository module.
See about_PSSqlRepository and the docs/ folder of the repository.


## RELATED LINKS

- [Online Version]()
