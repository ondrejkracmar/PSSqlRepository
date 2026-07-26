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

$binaryPath = [System.IO.Path]::Combine($binRoot, 'PSSqlRepository.Commands.dll')
if (-not (Test-Path -LiteralPath $binaryPath)) {
    throw "PSSqlRepository: could not find PSSqlRepository.Commands.dll at '$binaryPath'. " +
          "The module installation may be corrupted."
}

# Cleanup is handled by PSSqlRepositoryModuleCleanup (IModuleAssemblyCleanup) inside the binary.
Import-Module -Name $binaryPath

# Proactively load the supporting assemblies that ship side-by-side with the
# binary cmdlets so PowerShell's type resolver can see types like
# [Isystem.Shared.Infrastructure.Services.Repository.IEntity`1] *before* a
# `class Foo : IEntity[int]` declaration is parsed at the prompt. Import-Module
# alone only forces the load of PSSqlRepository.Commands.dll; transitive
# references stay lazy and are invisible to `[type]::GetType` until first use.
$preloadAssemblies = @(
    'Isystem.Shared.Infrastructure.Core.dll',
    'Isystem.Shared.Infrastructure.Services.dll',
    'Isystem.Shared.Infrastructure.EFCore.dll',
    'PSSqlRepository.Abstractions.dll',
    'PSSqlRepository.Authentications.dll',
    'PSSqlRepository.Providers.dll',
    'PSSqlRepository.Core.dll'
)
foreach ($asm in $preloadAssemblies) {
    $asmPath = [System.IO.Path]::Combine($binRoot, $asm)
    if (Test-Path -LiteralPath $asmPath) {
        try { [void][System.Reflection.Assembly]::LoadFrom($asmPath) }
        catch {
            # Preload failures usually indicate a corrupted installation or a missing
            # transitive dependency. Surface them as a warning (not just verbose) so
            # users see a hint *before* a downstream `class Foo : IEntity[int]` fails
            # with a cryptic 'unable to find type' error.
            Write-Warning "PSSqlRepository: failed to preload '$asm': $($_.Exception.Message). The module may not function correctly; reinstall to repair."
        }
    }
}

# Register short type accelerators so PowerShell users can write
#   class Customer : IEntity[int] { ... }
# without a leading `using namespace Isystem.Shared.Infrastructure.Services.Repository`.
# Accelerators registered here are process-wide; PSSqlRepositoryModuleCleanup removes
# them on Remove-Module so subsequent re-imports stay idempotent.
$typeAcceleratorsClass = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
if ($typeAcceleratorsClass) {
    $existing = $typeAcceleratorsClass::Get
    # NB: PowerShell's `Type[T]` syntax (e.g. `IEntity[int]`) requires the accelerator
    # to point at the *open generic* definition (`IEntity`1`), not at the non-generic
    # convenience interface. Without the backtick-1 the parser would resolve `IEntity`
    # to the non-generic interface and then fail to apply the type argument.
    $accelerators = @{
        'IEntity'        = 'Isystem.Shared.Infrastructure.Services.Repository.IEntity`1, Isystem.Shared.Infrastructure.Services'
        'OrphanBehavior' = 'PSSqlRepository.Core.OrphanBehavior, PSSqlRepository.Core'
    }
    foreach ($name in $accelerators.Keys) {
        $resolved = [type]::GetType($accelerators[$name], $false)
        if ($null -ne $resolved -and -not $existing.ContainsKey($name)) {
            try { $typeAcceleratorsClass::Add($name, $resolved) }
            catch { Write-Verbose "PSSqlRepository: could not register type accelerator '$name': $($_.Exception.Message)" }
        }
    }
}

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
