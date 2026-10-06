---
document type: cmdlet
external help file: PSSqlRepository.Commands.dll-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSSqlRepository
ms.date: 10/06/2026
PlatyPS schema version: 2024-05-01
title: Install-PSSqlRepositoryExtension
---

# Install-PSSqlRepositoryExtension

## SYNOPSIS

Installs a PSSqlRepository extension into the installed module from a local artifact.

## SYNTAX

### Path (Default)

```
Install-PSSqlRepositoryExtension [-Path] <string> [-ModuleRoot <string>] [-Subfolder <string>]
 [-Trust] [-Force] [-WhatIf] [-Confirm]
```

### Feed

```
Install-PSSqlRepositoryExtension -Name <string> -Repository <string> [-Version <string>]
 [-ModuleRoot <string>] [-Subfolder <string>] [-Trust] [-Force] [-WhatIf] [-Confirm]
```

### InstalledModule

```
Install-PSSqlRepositoryExtension -FromModule <string> [-Version <string>] [-ModuleRoot <string>]
 [-Subfolder <string>] [-Trust] [-Force] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Installs a PSSqlRepository extension into the installed module from a local artifact.

Places an extension's assemblies into the module's bin\{TFM}\{Subfolder}\ layout — the only location the loader scans — and copies its dependencies alongside the host assemblies where the plugin load context can resolve them.
The source may be a .zip from publish-extension.ps1, a .nupkg, a folder, or a single .dll.

Before anything is written, every candidate assembly is inspected the same way the loader inspects it: it must be strong-named, and its declared contract version must be one this module can satisfy.
Catching an incompatible extension here turns what would otherwise be a silently missing provider after the next restart into an error at install time.

Trust is deliberately NOT granted automatically.
An extension signed with a key the module does not already trust is installed but will not load until its public key token is added to extensions.trust.json; pass -Trust to do that as part of the install, which is an explicit decision to let that publisher's code run.
-Trust also pins the SHA-256 of every file it installs under trustedFileHashes: a third-party extension loads only while its content matches the pin, so a DLL replaced by hand must be installed with -Trust again.

## EXAMPLES

### Example 1

Install-PSSqlRepositoryExtension -Path .\PSSqlRepository.Providers.DuckDB-1.0.0.zip -Trust

## PARAMETERS

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

Overwrite an already installed extension, including a downgrade.

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

### -FromModule

Name of an installed PowerShell module carrying the extension payload.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: InstalledModule
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ModuleRoot

Module root to install into.
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

### -Name

Package id to install from a registered PSResource repository.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Feed
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Path

Path to a .zip artifact, .nupkg, folder, or a single extension .dll.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Path
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Repository

Name of a repository registered with Register-PSResourceRepository.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Feed
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Subfolder

Plugin subfolder.
Only needed when the assembly carries no SDK metadata.

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

### -Trust

Also trust the extension: add its signing key's token to extensions.trust.json and pin the SHA-256 of the installed files.

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

### -Version

Version to install; latest when omitted.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Feed
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InstalledModule
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

### System.Management.Automation.PSObject

See the cmdlet description.

## NOTES

Part of the PSSqlRepository module.
See about_PSSqlRepository and the docs/ folder of the repository.


## RELATED LINKS

- [Online Version]()
