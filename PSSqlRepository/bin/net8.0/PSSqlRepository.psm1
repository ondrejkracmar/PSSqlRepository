# PSSqlRepository module loader
# Selects the correct binary for the running .NET runtime version.
# PowerShell 7.4 runs on .NET 8, PowerShell 7.6+ runs on .NET 10.

$dotnetMajor = [System.Environment]::Version.Major
$framework = if ($dotnetMajor -ge 10) { 'net10.0' } else { 'net8.0' }

$binRoot = [System.IO.Path]::Combine($PSScriptRoot, 'bin', $framework)
if (-not (Test-Path -LiteralPath $binRoot)) {
    throw "PSSqlRepository: build output for runtime '$framework' not found at '$binRoot'. " +
          "Detected .NET $($dotnetMajor).x; supported targets are net8.0 (PowerShell 7.4/7.5) " +
          "and net10.0 (PowerShell 7.6+). The module installation may be corrupted."
}

foreach ($required in 'PSSqlRepository.Loader.dll', 'PSSqlRepository.Commands.dll') {
    if (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($binRoot, $required)))) {
        throw "PSSqlRepository: could not find $required in '$binRoot'. " +
              "The module installation may be corrupted."
    }
}

# The engine — the cmdlets, EF Core, Microsoft.Extensions.*, the SQL client libraries — runs in an
# AssemblyLoadContext of its own (see PSSqlRepository.Loader). Loading it into the process-wide
# default context, as Import-Module of the binary path would, decides for every other module in the
# session which version of those libraries exists; Az.Resources, for one, then fails to import.
# Only the dependency-free loader and the types scripts compile against
# (Isystem.Shared.Infrastructure.Core/.Services) go into the default context.
#
# A loader already loaded by an earlier import is reused: a second file with the same assembly name
# cannot be loaded into the default context. Each module directory still gets its own engine.
$loaderAssembly = [System.AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GetName().Name -eq 'PSSqlRepository.Loader' -and
                   [System.Runtime.Loader.AssemblyLoadContext]::GetLoadContext($_) -eq [System.Runtime.Loader.AssemblyLoadContext]::Default } |
    Select-Object -First 1
if (-not $loaderAssembly) {
    $loaderAssembly = [System.Reflection.Assembly]::LoadFrom([System.IO.Path]::Combine($binRoot, 'PSSqlRepository.Loader.dll'))
}
$commandsAssembly = $loaderAssembly.GetType('PSSqlRepository.Loader.ModuleEngine', $true)::LoadCommands($binRoot)

# Initialization (extension loading, type accelerators) and cleanup are handled inside the binary by
# PSSqlRepositoryModuleInitializer (IModuleAssemblyInitializer) and PSSqlRepositoryModuleCleanup
# (IModuleAssemblyCleanup). The accelerators make the engine's types nameable from scripts
# (class Customer : IEntity[int], class ShopContext : Microsoft.EntityFrameworkCore.DbContext).
#
# The engine (and with it this assembly) outlives Remove-Module, and so does the binary module an
# earlier import created from it: PowerShell keeps it loaded and a second Import-Module -Assembly
# from this psm1 then imports none of its cmdlets into the new module. Removing that leftover
# first (its IModuleAssemblyCleanup resets the module state) makes every import start clean.
Get-Module -All |
    Where-Object { $_.ModuleType -eq 'Binary' -and $_.ImplementingAssembly -eq $commandsAssembly } |
    Remove-Module -Force
Import-Module -Assembly $commandsAssembly

# Update-PSSqlRepositoryEntity: discoverability proxy for Save-PSSqlRepositoryEntity -Mode Update.
# Kept as a thin function (not a separate binary cmdlet) so there is exactly one
# implementation of the persistence pipeline. The proxy forwards every parameter
# (including pipeline input and PassThru) to Save-PSSqlRepositoryEntity but locks
# Mode to Update — matching `Get-Command -Verb Update` discoverability without
# duplicating the cmdlet surface.
function Update-PSSqlRepositoryEntity {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNull()]
        [psobject] $InputObject,

        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [type] $EntityType,

        [Parameter()]
        [switch] $IncludeNavigations,

        [Parameter()]
        [PSSqlRepository.Core.OrphanBehavior] $OrphanBehavior = [PSSqlRepository.Core.OrphanBehavior]::FromModel,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [switch] $SkipEnumeration,

        [Parameter()]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $CommandTimeout
    )
    process {
        $forward = @{ InputObject = $InputObject; Mode = 'Update' }
        if ($PSBoundParameters.ContainsKey('EntityType'))        { $forward['EntityType']        = $EntityType }
        if ($PSBoundParameters.ContainsKey('IncludeNavigations')){ $forward['IncludeNavigations']= $IncludeNavigations }
        if ($PSBoundParameters.ContainsKey('OrphanBehavior'))    { $forward['OrphanBehavior']    = $OrphanBehavior }
        if ($PSBoundParameters.ContainsKey('PassThru'))          { $forward['PassThru']          = $PassThru }
        if ($PSBoundParameters.ContainsKey('SkipEnumeration'))   { $forward['SkipEnumeration']   = $SkipEnumeration }
        if ($PSBoundParameters.ContainsKey('CommandTimeout'))    { $forward['CommandTimeout']    = $CommandTimeout }
        Save-PSSqlRepositoryEntity @forward
    }
}

# NOTE: do NOT call Export-ModuleMember here.
#
# Calling Export-ModuleMember from a script module replaces the default export set
# for THIS module, which by default also exposes cmdlets imported from nested
# modules (the binary PSSqlRepository.Commands.dll loaded above). Listing only the
# proxy function would silently hide every binary cmdlet from the outer module.
#
# Exports are controlled exclusively by the manifest:
#   FunctionsToExport = @('Update-PSSqlRepositoryEntity')
#   CmdletsToExport   = @('Connect-PSSqlRepository', 'Save-PSSqlRepositoryEntity', ...)
