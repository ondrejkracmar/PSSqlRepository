---
document type: cmdlet
external help file: PSSqlRepository.Commands.dll-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/02/2026
PlatyPS schema version: 2024-05-01
title: Get-PSSqlRepositoryExtensionToken
---

# Get-PSSqlRepositoryExtensionToken

## SYNOPSIS

Reads the strong-name public key token from a .NET assembly in the format used by extensions.trust.json.

## SYNTAX

### __AllParameterSets

```
Get-PSSqlRepositoryExtensionToken [-Path] <string[]>
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Reads the strong-name public key token from a .NET assembly in the format used by extensions.trust.json.

Helper for administrators who need to trust a 3rd-party PSSqlRepository extension.
It reads the assembly metadata WITHOUT loading it for execution and returns the lowercase 16-character hex public key token, suitable for pasting into extensions.trust.json under trustedPublicKeyTokens (the token the loader gates every plugin on — see ExtensionTrustPolicy).

## EXAMPLES

### Example 1

Get-PSSqlRepositoryExtensionToken -Path .\PSSqlRepository.Providers.DuckDB.dll

### Example 2

Get-ChildItem .\Providers\*.dll | Get-PSSqlRepositoryExtensionToken

## PARAMETERS

### -Path

Path to the .NET assembly to read the public key token from.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- FullName
- PSPath
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
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

### System.String[]

See the cmdlet description.

## OUTPUTS

### System.Management.Automation.PSObject

See the cmdlet description.

## NOTES

Part of the PSSqlRepository module.
See about_PSSqlRepository and the docs/ folder of the repository.


## RELATED LINKS

- [Online Version]()
