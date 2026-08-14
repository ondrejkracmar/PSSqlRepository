# PSSqlRepository.Extensions.Sdk

The SDK is the external extension boundary. Reference the single NuGet package
**`PSSqlRepository.Extensions.Sdk`** to author:

- SQL providers
- authentication providers
- provider-specific connect parameter surfaces
- provider-specific session behaviour

Everything in this document lives in the namespace `PSSqlRepository.Extensions.Sdk`.

> A working, end-to-end reference implementation — build, sign, deploy, trust, CI — is the DuckDB
> provider repository, `PSSqlRepository.Providers.DuckDB`. It consumes the SDK as a real NuGet
> `<PackageReference>`, exactly as a third-party author does.

---

## What the package gives you

| Type | Purpose |
|---|---|
| `SqlProviderExtension` | Base for provider extensions. Implement one method to wire EF Core. |
| `SqlAuthenticationExtension` | Base for authentication extensions. Two hooks: resolve + apply. |
| `PSSqlRepositoryExtensionsSdk` | Entry point + metadata (`ContractVersion`, `Title`, `CreateExtension`). |
| `PSSqlRepositoryExtensionBuilder` | Fluent bundle of providers/auth with explicit registration. |
| `AddPSSqlRepositoryExtension(...)` | `IServiceCollection` registration for hosts and tests. |

The contracts — `ISqlProviderDefinition`, `ISqlAuthenticationProvider`,
`SqlProviderParameterDefinition`, `SqlAuthModes` / `SqlAuthKeys`, `ISqlConnectContext`, and the
`[assembly: PSSqlRepositoryExtension]` marker — flow in transitively through that one reference.

Referencing the **package** (not an in-repo `ProjectReference`) also imports the SDK's
`build/*.targets`, which is what supplies:

- `<ExtensionSubfolder>` validation, and stamping it onto the assembly
- the strong-name check
- the contract-version attribute, applied automatically — you never write it by hand
- the `DeployExtensionToModule` target

## Project setup

```xml
<PropertyGroup>
  <TargetFramework>net10.0</TargetFramework>
  <Nullable>enable</Nullable>

  <!-- Which module subfolder this extension deploys into: Providers or Auth. Validated by the SDK targets. -->
  <ExtensionSubfolder>Providers</ExtensionSubfolder>

  <!-- Required: the loader only trusts strong-named plugins. Use YOUR OWN key, never the module's. -->
  <SignAssembly>true</SignAssembly>
  <AssemblyOriginatorKeyFile>MyCompany.snk</AssemblyOriginatorKeyFile>
</PropertyGroup>

<ItemGroup>
  <PackageReference Include="PSSqlRepository.Extensions.Sdk" Version="1.0.0" />
</ItemGroup>
```

```csharp
// AssemblyInfo.cs — the discovery marker. Without it the loader skips the assembly
// even when it contains provider types.
using PSSqlRepository.Abstractions;

[assembly: PSSqlRepositoryExtension]
```

## Authoring a provider

Derive from `SqlProviderExtension` and implement the single EF Core wiring hook. `DbContext`
registration, the EF configurator, and session creation are derived for you:

```csharp
using Microsoft.EntityFrameworkCore;
using PSSqlRepository.Extensions.Sdk;

public sealed class DuckDbProviderDefinition : SqlProviderExtension
{
    public override string Name => "DuckDB";
    public override string DisplayName => "DuckDB Repository";

    protected override void ConfigureProvider(DbContextOptionsBuilder options, string connectionString)
        => options.UseDuckDB(connectionString);
}
```

That is a working provider. From there:

- **`GetConnectParameters()`** — declare the friendly parameters the user sees on
  `Connect-PSSqlRepository` (`-Path`, `-Server`, …), as `SqlProviderParameterDefinition` entries
  carrying position, aliases, default value, and help text.
- **`ResolveConnectionString(ISqlConnectContext)`** — compose the connection string from those
  parameters. Use a `DbConnectionStringBuilder`; never concatenate.
- **`SupportedAuthModes`** — advertise explicitly. A mode beyond `SqlAuthModes.None` /
  `SqlAuthModes.ConnectionString` with no installed auth extension to satisfy it produces a
  capability-mismatch warning at import.
- **`CreateSession(...)`** — override only for credential-aware connections, and call the
  `BuildSession(connectionString, ensureCreated)` helper from it.

```csharp
public override IReadOnlyList<SqlProviderParameterDefinition> GetConnectParameters() =>
[
    new("Path", typeof(string))
    {
        Mandatory   = false,
        Position    = 1,
        Aliases     = ["Database", "FilePath"],
        HelpMessage = "Path to the database file; created on demand."
    },
    new("Memory", typeof(bool)) { DefaultValue = false },
    new("ConnectionString", typeof(string)),
    new("EnsureCreated", typeof(bool)) { DefaultValue = false }
];

public override string ResolveConnectionString(ISqlConnectContext context)
{
    ArgumentNullException.ThrowIfNull(context);

    var raw = context.GetString("ConnectionString");
    if (!string.IsNullOrWhiteSpace(raw)) return raw;

    if (context.GetSwitch("Memory", defaultValue: false)) return "Data Source=:memory:";

    var path = context.GetString("Path")
        ?? throw new ArgumentException("Specify -Path, -Memory, or -ConnectionString.");

    return $"Data Source={Path.GetFullPath(path)}";
}
```

### Native dependencies

Extensions load through a custom `AssemblyLoadContext`, and the default P/Invoke probe does **not**
search `runtimes\<rid>\native\` for assemblies loaded that way. An engine shipped that way
(DuckDB, SQLite, …) must be resolved explicitly with `NativeLibrary.SetDllImportResolver`, anchored
on the assembly that declares the P/Invokes. Register it from a static constructor and swallow
`InvalidOperationException` — the resolver survives extension reloads while the static constructor
re-runs on every `Import-Module -Force`. `DuckDbProviderDefinition` in the DuckDB repository is the
worked example.

## Authoring an authentication extension

Derive from `SqlAuthenticationExtension`. The base validates inputs, seeds the auth bag with the
mode, and hands you a connection-string builder to mutate:

```csharp
using System.Data.Common;
using PSSqlRepository.Abstractions;
using PSSqlRepository.Authentications;
using PSSqlRepository.Extensions.Sdk;

public sealed class XyzAuth : SqlAuthenticationExtension
{
    public override string Name => "XyzAuth";
    public override string DisplayName => "Xyz Authentication";
    public override IReadOnlyCollection<string> SupportedSqlProviders => ["Xyz"];
    public override IReadOnlyCollection<string> SupportedModes => [SqlAuthModes.UserPassword];

    protected override void ResolveCore(ISqlConnectContext context, SqlAuthenticationInfo info)
    {
        var user = context.GetString(SqlAuthKeys.UserName);
        if (!string.IsNullOrEmpty(user)) info.Set(SqlAuthKeys.UserName, user);
    }

    protected override void ApplyCore(DbConnectionStringBuilder builder, ISqlAuthenticationInfo info)
    {
        ThrowIfModeUnsupported(info);
        builder["User"] = info.Get<string>(SqlAuthKeys.UserName) ?? string.Empty;
    }
}
```

Prefer `SqlAuthKeys.SecurePassword` or a native credential over a cleartext password, keep secrets
out of exceptions and diagnostics, and always go through the builder.

## Registering without the module

Folder discovery is the PowerShell path. For other hosts and for tests, register explicitly:

```csharp
using Microsoft.Extensions.DependencyInjection;
using PSSqlRepository.Extensions.Sdk;

// Into a DI container:
services.AddPSSqlRepositoryExtension("Xyz", extension => extension
    .AddProvider<XyzProviderDefinition>()
    .AddAuthentication<XyzAuth>());

// Or into the module registries directly:
PSSqlRepositoryExtensionsSdk.CreateExtension("Xyz")
    .AddProvider<XyzProviderDefinition>()
    .AddAuthentication<XyzAuth>()
    .RegisterInto(PSSqlRepositoryHost.Current);
```

## Shipping

The deployment payload layout the module expects:

```
<tfm>\<Subfolder>\Your.Extension.dll     Providers or Auth
<tfm>\*.dll                              your NuGet dependencies
<tfm>\runtimes\<rid>\native\*            native engines, if any
```

Do **not** include `PSSqlRepository.*` assemblies — the module ships them, and overwriting them
breaks contract type identity. Do **not** publish the extension as a plain NuGet library
(`lib/<tfm>/`): installing that shape copies your assembly without its dependencies, and the
provider then loads and fails on first call. `Install-PSSqlRepositoryExtension` warns when it
detects it.

Publish your public key token alongside the package so administrators can trust it deliberately:

```powershell
Get-PSSqlRepositoryExtensionToken -Path .\Your.Extension.dll
```

Installation, trust, and diagnostics are covered in [extensibility.md](./extensibility.md).

## The contract version

The SDK stamps every extension with the contract version it was compiled against, and the loader
refuses one whose **major** does not match the host's. You do not write that attribute.

The contract version is deliberately *not* the SDK package version and *not* the module version: it
moves only when the public API of the contract assemblies moves. See
[extensibility.md](./extensibility.md#how-discovery-works) for the compatibility table.

## Authoring checklist

**Provider**

- Derive from `SqlProviderExtension`; implement `ConfigureProvider(...)`
- Declare friendly connect parameters via `GetConnectParameters()`
- Build the connection string with a builder, not string concatenation
- Advertise `SupportedAuthModes` explicitly
- Resolve native dependencies explicitly if the engine has any

**Authentication**

- Derive from `SqlAuthenticationExtension`; implement `ResolveCore` + `ApplyCore`
- Restrict `SupportedSqlProviders` / `SupportedModes` to what you actually ship
- Use `SqlAuthKeys.SecurePassword` / native credentials where available
- Keep secrets out of diagnostics and exceptions

**Both**

- Sign with your own key and publish the token
- `[assembly: PSSqlRepositoryExtension]`
- Correct `<ExtensionSubfolder>`
- Ship a deployment payload, not a library package
