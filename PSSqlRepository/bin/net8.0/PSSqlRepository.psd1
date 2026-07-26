@{
    RootModule             = 'PSSqlRepository.psm1'
    ModuleVersion          = '0.0.0'
    GUID                   = 'a4f5e3c1-9d6b-4d2a-8e7f-3b5c2a1d8e90'
    Author                 = 'Ondrej Kracmar'
    CompanyName            = 'Isystem'
    Copyright              = '(c) Isystem. All rights reserved.'
    Description            = 'PSSqlRepository: PowerShell + EF Core repository module with pluggable SQL providers and authentication strategies.'
    PowerShellVersion      = '7.4'
    CompatiblePSEditions   = @('Core')

    FormatsToProcess       = @()
    TypesToProcess         = @()
    RequiredAssemblies     = @()
    RequiredModules        = @()

    CmdletsToExport        = @(
        'Connect-PSSqlRepository',
        'Disconnect-PSSqlRepository',
        'Get-PSSqlRepositoryProvider',
        'Get-PSSqlRepositoryExtension',
        'Get-PSSqlRepositoryExtensionToken',
        'Install-PSSqlRepositoryExtension',
        'Uninstall-PSSqlRepositoryExtension',
        'Get-PSSqlRepositorySession',
        'Register-PSSqlRepositoryContext',
        'Unregister-PSSqlRepositoryContext',
        'Register-PSSqlRepositoryEntity',
        'Get-PSSqlRepositoryEntity',
        'Save-PSSqlRepositoryEntity',
        'Remove-PSSqlRepositoryEntity',
        'Start-PSSqlRepositoryTransaction',
        'Complete-PSSqlRepositoryTransaction',
        'Undo-PSSqlRepositoryTransaction'
    )

    FunctionsToExport      = @('Update-PSSqlRepositoryEntity')
    VariablesToExport      = @()
    # Item-style aliases mirror the PSDataRepository command surface
    # ($collection | Set-PSSqlRepositoryItem / Get-PSSqlRepositoryItem). They are
    # [Alias()] attributes on the Entity cmdlets, so both spellings share one
    # implementation; listing them here enables module auto-loading by alias.
    AliasesToExport        = @(
        'Get-PSSqlRepositoryItem',
        'Remove-PSSqlRepositoryItem',
        'Save-PSSqlRepositoryItem',
        'Set-PSSqlRepositoryItem'
    )

    PrivateData = @{
        PSData = @{
            Tags         = @('SQL', 'EFCore', 'Repository', 'PSSqlRepository', 'SqlServer', 'SQLite', 'Database', 'ORM')
            ProjectUri   = 'https://dev.azure.com/i-system/PSModules/_git/PSSqlRepository'
            LicenseUri   = 'https://dev.azure.com/i-system/PSModules/_git/PSSqlRepository?path=/LICENSE'
            ReleaseNotes = 'See CHANGELOG.md in the project repository.'
        }
    }
}
