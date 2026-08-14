# PSSqlRepository Extensions SDK (0.3.1)

This folder contains a **self-contained, restorable NuGet package set** for building
your own PSSqlRepository extensions (SQL providers and authentication resolvers). The
SDK meta-package depends on the other packages here, so they ship together and restore
offline from this single folder — no extra feed required.

## Packages

- `PSSqlRepository.Abstractions.0.3.1.nupkg`
- `PSSqlRepository.Authentications.0.3.1.nupkg`
- `PSSqlRepository.Core.0.3.1.nupkg`
- `PSSqlRepository.Extensions.Sdk.0.3.1.nupkg`
- `PSSqlRepository.Providers.0.3.1.nupkg`

## Use it in your extension project

1. Download (or clone) this repository so you have a local copy of the `sdk/` folder.

2. Add a `nuget.config` next to your extension's `.csproj` (or solution) that
   points NuGet at this folder:

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <configuration>
     <packageSources>
       <add key="PSSqlRepository-SDK" value="path/to/sdk" />
     </packageSources>
   </configuration>
   ```

3. Reference the SDK from your extension project:

   ```sh
   dotnet add package PSSqlRepository.Extensions.Sdk --version 0.3.1
   ```

The SDK brings in the contract assemblies and the MSBuild targets that validate and
deploy your extension automatically. Set `<ExtensionSubfolder>` (`Providers` or
`Auth`) and `<PSSqlRepositoryModuleDir>` in your project to auto-deploy on build.

## Trust model

**Strong-naming is mandatory and the loader fails closed.** A candidate's strong-name
public key token is read from PE metadata — before any of its code runs — and the
extension is instantiated only when that token is the module's own or is listed under
`trustedPublicKeyTokens` in `extensions.trust.json` in the module root. Anything
unsigned, or signed with an unknown key, is rejected.

Sign with your own key (never the module's, which is the trust anchor):

```xml
<SignAssembly>true</SignAssembly>
<AssemblyOriginatorKeyFile>MyCompany.snk</AssemblyOriginatorKeyFile>
```

Publish your token with `Get-PSSqlRepositoryExtensionToken -Path <dll>` so an
administrator can grant trust deliberately:

```powershell
Install-PSSqlRepositoryExtension -Path .\Your.Extension-1.0.0.zip -Trust
# restart pwsh, then verify
Get-PSSqlRepositoryExtension | Format-Table Name, Status, Reason
```

Until trust is granted the extension installs but reports as `Rejected`.
See the `docs/` folder and the project `README.md` for the full authoring guide.
