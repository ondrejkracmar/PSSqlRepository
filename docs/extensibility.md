# Extending PSSqlRepository

Providers and authentication surfaces beyond the built-in ones are **extensions**: strong-named
assemblies that the module discovers at import time and loads into a dedicated
`AssemblyLoadContext`.

- [How discovery works](#how-discovery-works)
- [The trust model](#the-trust-model)
- [Installing an extension](#installing-an-extension)
- [Diagnosing a missing provider](#diagnosing-a-missing-provider)
- [Uninstalling](#uninstalling)
- [Authoring an extension](#authoring-an-extension)

---

## How discovery works

At import the module scans exactly two folders next to its own binaries:

```
<module>\bin\<tfm>\Auth\         authentication extensions
<module>\bin\<tfm>\Providers\    provider extensions
<module>\bin\<tfm>\              their shared dependencies
<module>\bin\<tfm>\runtimes\     native engines, per RID
```

`<tfm>` is the build matching the running host — `net8.0` for PowerShell 7.4/7.5, `net10.0` for
7.6+. An extension deployed only for `net10.0` simply does not exist on a `net8.0` host.

Every `*.dll` in those two folders is a candidate. Before anything is loaded, three facts are read
straight from PE metadata — so **no code in the candidate runs before the decision is made**:

1. its strong-name public key token,
2. the extension contract version the SDK stamped on it,
3. the subfolder the SDK stamped on it.

A candidate is loaded only if it is trusted (below) and its contract **major** matches the host's.
Once loaded it must also carry `[assembly: PSSqlRepositoryExtension]`; without that marker the
assembly is skipped even if it contains provider types. Every exported non-abstract type
implementing `ISqlProviderDefinition` or `ISqlAuthenticationProvider` is then instantiated and
registered.

The contract assemblies (`PSSqlRepository.Abstractions`, `.Providers`, `.Authentications`, `.Core`)
are always resolved from the **module root**, never from the extension's own folder. The versions an
extension was compiled against are discarded, which is why the stamped contract version exists: it
turns an otherwise invisible breaking change into one actionable message.

| Host contract change | Effect on an already-built extension |
|---|---|
| Patch bump | None |
| Minor bump | Keeps loading — additions are non-breaking |
| Major bump | **Rejected**; rebuild against the new SDK |

An extension carrying no contract attribute at all is treated as `1.0` and still loads.

## The trust model

The loader **fails closed** and checks two things before any code from a plugin runs.

**Identity.** The plugin must be strong-named, and its public key token must be one of:

- the module's own token (implicitly trusted — the trust anchor, and what the in-box providers are
  signed with), or
- a token listed under `trustedPublicKeyTokens` in `extensions.trust.json`.

**Content.** A third-party plugin (any token other than the module's own) must also match the
SHA-256 pinned for its file under `trustedFileHashes`. `Install-PSSqlRepositoryExtension -Trust`
writes that pin. The token alone is not authentication: the runtime does not verify strong-name
signatures, and a public key is public, so any file can be built to carry a trusted token. The
pin ties trust to the bytes you actually installed.

```jsonc
// <module>\extensions.trust.json
{
  "_comment": "trustedPublicKeyTokens: lowercase hex public key tokens (16 hex chars) of SNKs trusted to author plugins. trustedFileHashes: SHA-256 of each installed third-party extension, keyed by path relative to this file; written by Install-PSSqlRepositoryExtension -Trust. developmentMode: true disables hash pinning.",
  "trustedPublicKeyTokens": [
    "7c0a159ccacb5b48"
  ],
  "trustedFileHashes": {
    "bin/net8.0/Providers/PSSqlRepository.Providers.DuckDB.dll": "9f2c…e1",
    "bin/net10.0/Providers/PSSqlRepository.Providers.DuckDB.dll": "4a71…c8"
  }
}
```

The file lives in the module root, next to `PSSqlRepository.psd1`. A module installed under
`C:\Program Files` needs an elevated shell to write it. Restart PowerShell after editing — the scan
happens once per process.

Consequences worth internalising:

- **Unsigned extensions never load.** Not a warning; a rejection.
- **A token authorises a publisher; a pin authorises a file.** Adding a token lets every present
  and future assembly signed with that key *pass the identity check*; only files whose hash is
  pinned actually load. That is why neither is granted implicitly.
- **An updated extension must be re-trusted.** Replacing a DLL changes its hash, so the loader
  refuses it with *"its content changed since it was trusted"* until you re-run
  `Install-PSSqlRepositoryExtension -Trust` (which overwrites the pin). Overwriting a trusted DLL
  by hand is exactly what the pin exists to catch.
- **The pin covers everything the extension brings.** `-Trust` pins the extension assembly and
  every file it installed: the libraries in its private folder, the shared dependencies it put in
  `bin\<tfm>\`, the native engines it staged under `runtimes\`. The loader verifies that whole
  set before the extension is loaded and refuses the extension if any file is missing a pin or
  has changed, naming the file (*"its dependency 'X' changed since it was trusted"*). The
  extension's load context repeats the check for every file it actually loads, so a swap after
  import is caught too. The host's own files are not pinned; they are protected the way the
  module itself is (file ACLs, Authenticode of the published package).
- **Pins travel with the module folder.** Keys are paths relative to `extensions.trust.json`, so a
  copied or relocated module keeps its trust. A new module version has a fresh folder and a fresh
  trust file: re-install the extensions into it.
- **Trust files from before hash pinning keep working.** A file with no `trustedFileHashes`
  section is treated as token-only once: on the first load the loader pins every third-party
  extension it finds trusted by token and adds the section. From then on content is verified.
  (If the module folder is read-only the pin cannot be written; the extension stays trusted by
  token and the diagnostic log says so — run `Install-PSSqlRepositoryExtension -Trust` from an
  elevated shell to pin it.)
- **`"developmentMode": true`** switches pinning off for that module (token-only trust, as
  before). Use it on a developer machine where the extension is rebuilt all day; never in
  production. The diagnostic log notes it on every load.
- **If the module's own Core assembly is not strong-named, nothing loads at all** — there is no
  anchor, so trusting anything would be a blind decision. In-box plugins carry that token and are
  never pinned.
- A malformed `extensions.trust.json` contributes no tokens and no pins and is reported in the
  diagnostic log, rather than silently widening or narrowing trust.

Read a candidate's token without installing it:

```powershell
Get-PSSqlRepositoryExtensionToken -Path .\MyProvider.dll
```

## Installing an extension

### From the PowerShell Gallery — the normal route

The Gallery accepts PowerShell modules, never plain .NET packages, so an extension ships there as a
thin **manifest-only wrapper module** whose entire content is the payload. It is not meant to be
imported; installing it just puts the payload on disk, and a second step moves it into
PSSqlRepository:

```powershell
Install-PSResource PSSqlRepository.Providers.DuckDB -Repository PSGallery
Install-PSSqlRepositoryExtension -FromModule PSSqlRepository.Providers.DuckDB -Trust
```

The wrapper declares `RequiredModules = PSSqlRepository`, so installing it also pulls in the host —
without which the cmdlet needed for the second step would not exist.

### Other sources

The same cmdlet accepts a `.zip` deployment payload, a `.nupkg`, a folder, a single `.dll`, or a
package from any registered PSResource repository:

```powershell
Install-PSSqlRepositoryExtension -Path .\PSSqlRepository.Providers.DuckDB-1.0.0.zip -Trust
Install-PSSqlRepositoryExtension -Name My.Provider -Repository MyFeed -Trust
```

It applies the loader's own gates *before* copying anything — strong name, contract compatibility,
target subfolder — so an incompatible build fails at install time instead of turning into a silently
missing provider after the next restart. It also stages the extension's dependencies into
`bin\<tfm>\` and its native `runtimes\` tree, records what it claimed so uninstall can clean up, and
refuses to overwrite a shared dependency with a different **major** version unless you pass
`-Force`.

`-Trust` does two things: it adds the publisher's token to `trustedPublicKeyTokens` and pins the
SHA-256 of every file it just installed under `trustedFileHashes`. Without `-Trust` the extension
is installed and a warning says it will not load. Restart PowerShell, then confirm:

```powershell
Get-PSSqlRepositoryExtension | Format-Table Name, Subfolder, Status, Registered, Reason
Get-PSSqlRepositoryProvider  | Format-Table Name, DisplayName
```

## Diagnosing a missing provider

`Get-PSSqlRepositoryExtension` reports one row per DLL found — loaded or rejected — with the reason.
Start there; the import itself succeeds even when every extension is rejected.

| `Reason` | Meaning | Fix |
|---|---|---|
| `its public key token '…' is not trusted` | Installed, signed, but the key is not authorised | Reinstall with `-Trust`, or add the token to `extensions.trust.json`, then restart |
| `its content changed since it was trusted (pinned SHA-256 …, actual …)` | The file is not the one that was trusted: updated by hand, or tampered with | If the update is intended, `Install-PSSqlRepositoryExtension … -Trust` again; otherwise investigate before trusting |
| `its SHA-256 is not pinned in 'extensions.trust.json'` | The key is trusted but this file was copied in without `Install-PSSqlRepositoryExtension -Trust` | Reinstall with `-Trust`, or set `"developmentMode": true` on a developer machine |
| `its dependency 'X' changed since it was trusted` / `its dependency 'X' is not pinned` | A library or native asset the extension loads is not the one `-Trust` pinned, or was copied in by hand | Reinstall with `-Trust` if the change is intended; otherwise investigate the file |
| `it is not strong-named` | Built without a signing key | Rebuild with `<SignAssembly>true</SignAssembly>` |
| `contract incompatible: it was built against contract …` | Contract major moved | Rebuild against the current SDK |
| `missing [assembly: PSSqlRepositoryExtension]` | No discovery marker | Add the assembly attribute |
| `unable to read assembly metadata` | Not a managed assembly, or corrupt | Re-copy the file |
| *no row at all* | The DLL is not in `bin\<tfm>\Providers\` or `bin\<tfm>\Auth\`, or `<tfm>` does not match the running host | Check the path and `[System.Environment]::Version.Major` |

The full load trace — trust anchor, per-candidate SHA-256, each accept/reject — goes to the
diagnostic log. It runs inside the module initializer where no cmdlet owns the verbose stream, so
`Import-Module -Verbose` does **not** show it; tee it to a file, setting the variable before import:

```powershell
pwsh -NoProfile -Command '$env:PSSQLREPOSITORY_LOG = "$PWD\pssql.log"; Import-Module PSSqlRepository'
Get-Content .\pssql.log
```

Two further diagnostics are emitted after the scan, as warnings rather than failures, because a
deployment may legitimately ship one half of a pair:

- an auth extension advertising support for a provider that is not registered;
- a provider advertising a credential-bearing auth mode that no installed auth extension can supply.

## Uninstalling

```powershell
Uninstall-PSSqlRepositoryExtension -Name PSSqlRepository.Providers.DuckDB
```

The pinned hashes of the removed files (the extension, its private folder, the dependencies and
native assets only it introduced) are dropped from `extensions.trust.json`; the publisher's
token stays unless you pass `-RemoveTrust`, which affects every extension signed with that key.

Remove extensions **before** removing PSSqlRepository itself. `Uninstall-PSSqlRepositoryExtension`
is a cmdlet of the host module; once the module is gone there is nothing left to clean up with, and
the extension's assemblies stay behind in the orphaned module folder. PowerShell's
`RequiredModules` only guarantees install order, never uninstall order.

---

## Authoring an extension

Full walkthrough with code in [sdk.md](./sdk.md). In short:

- Reference the **`PSSqlRepository.Extensions.Sdk`** NuGet package. It brings the contracts
  transitively *and* imports the build targets that validate and deploy the extension.
- Set `<ExtensionSubfolder>Providers</ExtensionSubfolder>` (or `Auth`) — the targets validate it and
  stamp it onto the assembly.
- Sign the assembly: `<SignAssembly>true</SignAssembly>` plus an `<AssemblyOriginatorKeyFile>`. Use
  **your own** key, not the module's — the module's key is the trust anchor and must not be copied
  around. Publish your public key token so administrators can trust it deliberately.
- Mark the assembly: `[assembly: PSSqlRepositoryExtension]`.
- Derive from `SqlProviderExtension` (providers) or `SqlAuthenticationExtension` (authentication).
- Ship a deployment payload, not a library package: the layout must be
  `<tfm>\<Subfolder>\Your.dll` plus dependencies in `<tfm>\` and native assets under
  `<tfm>\runtimes\`. A plain NuGet `lib/<tfm>/` package installs without its dependencies and fails
  at first use — `Install-PSSqlRepositoryExtension` warns when it detects that shape.
- Never ship `PSSqlRepository.*` assemblies in the payload. The module supplies them; overwriting
  them breaks contract type identity.

### Recommended package split

- `YourCompany.PSSqlRepository.Provider.Xyz`
- `YourCompany.PSSqlRepository.Auth.Xyz` (optional)

### Provider checklist

- Derive from `SqlProviderExtension` and implement `ConfigureProvider(...)`
- Expose friendly connect parameters through `GetConnectParameters()`
- Compose the connection string in `ResolveConnectionString(...)` with a
  `DbConnectionStringBuilder`, never by concatenation
- Advertise supported auth modes explicitly via `SupportedAuthModes`
- If the engine has a native component, resolve it explicitly — extensions load through a custom
  `AssemblyLoadContext`, and the default P/Invoke probe does not search `runtimes\<rid>\native\`

### Authentication checklist

- Derive from `SqlAuthenticationExtension` and implement `ResolveCore` + `ApplyCore`
- Support only the providers and modes you intend, via `SupportedSqlProviders` / `SupportedModes`
- Prefer `SqlAuthKeys.SecurePassword` or a native credential over a cleartext password
- Keep secrets out of exceptions and diagnostics

### Registering without the module

For non-PowerShell hosts and tests, register explicitly instead of relying on folder discovery:

```csharp
services.AddPSSqlRepositoryExtension("Xyz", extension => extension
    .AddProvider<XyzProvider>()
    .AddAuthentication<XyzAuth>());
```

## Built-in auth parameter surfaces

| Provider | Parameters |
|---|---|
| SQL Server | `UserName`, `Password`, `SecurePassword` |
| SQLite | `Password` |
