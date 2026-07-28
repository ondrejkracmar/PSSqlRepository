# PSSqlRepository Extensions SDK (0.2.1)

This folder contains a **self-contained, restorable NuGet package set** for building
your own PSSqlRepository extensions (SQL providers and authentication resolvers). The
SDK meta-package depends on the other packages here, so they ship together and restore
offline from this single folder — no extra feed required.

## Packages

- `PSSqlRepository.Abstractions.0.2.1.nupkg`
- `PSSqlRepository.Authentications.0.2.1.nupkg`
- `PSSqlRepository.Core.0.2.1.nupkg`
- `PSSqlRepository.Extensions.Sdk.0.2.1.nupkg`
- `PSSqlRepository.Providers.0.2.1.nupkg`

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
   dotnet add package PSSqlRepository.Extensions.Sdk --version 0.2.1
   ```

The SDK brings in the contract assemblies and the MSBuild targets that validate and
deploy your extension automatically. Set `<ExtensionSubfolder>` (`Providers` or
`Auth`) and `<PSSqlRepositoryModuleDir>` in your project to auto-deploy on build.

## Trust model

PSSqlRepository loads extensions with an **opt-in, environment-variable** trust policy
(there is no trust.json file):

- `PSSQLREPOSITORY_EXTENSION_REQUIRE_SIGNATURE=1` requires a valid Authenticode signature.
- `PSSQLREPOSITORY_EXTENSION_ALLOWLIST=<sha256>[;<sha256>…]` restricts loading to listed hashes.

With neither variable set, your extension loads as-is, so strong-naming is optional.
See the `docs/` folder and the project `README.md` for the full authoring guide.
