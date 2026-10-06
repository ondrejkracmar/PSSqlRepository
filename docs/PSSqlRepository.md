---
document type: module
Help Version: 1.0.0.0
HelpInfoUri: 
Locale: en-US
Module Guid: a4f5e3c1-9d6b-4d2a-8e7f-3b5c2a1d8e90
Module Name: PSSqlRepository
ms.date: 10/06/2026
PlatyPS schema version: 2024-05-01
title: PSSqlRepository Module
---

# PSSqlRepository Module

## Description

PSSqlRepository: PowerShell + EF Core repository module with pluggable SQL providers and authentication strategies.

## PSSqlRepository

### [Compare-PSSqlRepositorySchema](Compare-PSSqlRepositorySchema.md)

Reports how the connected database differs from the registered entity model, without changing anything.

### [Complete-PSSqlRepositoryTransaction](Complete-PSSqlRepositoryTransaction.md)

Commits the ambient explicit transaction and clears it from the session manager.

### [Connect-PSSqlRepository](Connect-PSSqlRepository.md)

Opens a session for the requested provider, applies the requested authentication mode (resolved through SqlAuthenticationRegistry), and stores the session in the ambient SqlSessionManager.

### [Disconnect-PSSqlRepository](Disconnect-PSSqlRepository.md)

Disposes the ambient session held by SqlSessionManager and rolls back any active explicit transaction.

### [Get-PSSqlRepositoryEntity](Get-PSSqlRepositoryEntity.md)

Streams entities from the active session's database to the pipeline.

### [Get-PSSqlRepositoryExtension](Get-PSSqlRepositoryExtension.md)

Lists the extensions the module discovered at import time, including the ones it refused to load and why.

### [Get-PSSqlRepositoryExtensionToken](Get-PSSqlRepositoryExtensionToken.md)

Reads the strong-name public key token from a .NET assembly in the format used by extensions.trust.json.

### [Get-PSSqlRepositoryProvider](Get-PSSqlRepositoryProvider.md)

Lists all registered SQL provider definitions.

### [Get-PSSqlRepositorySession](Get-PSSqlRepositorySession.md)

Returns a handle for the active session held by SqlSessionManager, or $null when no session is connected.

### [Import-PSSqlRepositorySchema](Import-PSSqlRepositorySchema.md)

Database-first: reads the schema of an existing database, emits one entity type per table and registers them as the provider's repository context.

### [Install-PSSqlRepositoryExtension](Install-PSSqlRepositoryExtension.md)

Installs a PSSqlRepository extension into the installed module from a local artifact.

### [Register-PSSqlRepositoryContext](Register-PSSqlRepositoryContext.md)

Registers a provider-backed repository context type so subsequent Connect-PSSqlRepository sessions wire it plus the matching IRepository<T>/IUnitOfWork registrations into the session's DI scope.

### [Register-PSSqlRepositoryEntity](Register-PSSqlRepositoryEntity.md)

Registers a dynamic Microsoft.EntityFrameworkCore.DbContext built at runtime from the supplied entity types, so PowerShell users can persist plain PowerShell class definitions (or any CLR type implementing IEntity<TKey>) without writing or compiling a custom Microsoft.EntityFrameworkCore.DbContext in C#.

### [Remove-PSSqlRepositoryEntity](Remove-PSSqlRepositoryEntity.md)

Deletes one or more entities through the active session.

### [Save-PSSqlRepositoryEntity](Save-PSSqlRepositoryEntity.md)

Persists an entity through the active session's IRepository<T> + IUnitOfWork.

### [Start-PSSqlRepositoryTransaction](Start-PSSqlRepositoryTransaction.md)

Opens an explicit transaction on the active session and stores it in the ambient SqlSessionManager so subsequent Save-PSSqlRepositoryEntity calls enlist automatically.

### [Undo-PSSqlRepositoryTransaction](Undo-PSSqlRepositoryTransaction.md)

Rolls back the ambient explicit transaction and clears it from the session manager.

### [Uninstall-PSSqlRepositoryExtension](Uninstall-PSSqlRepositoryExtension.md)

Removes an installed PSSqlRepository extension from the module.

### [Unregister-PSSqlRepositoryContext](Unregister-PSSqlRepositoryContext.md)

Removes a previously registered repository context for the given provider.

### [Update-PSSqlRepositorySchema](Update-PSSqlRepositorySchema.md)

Forward-migrates the connected database to the registered entity model, the way EF Core migrations would, without a migrations project.

### [Update-PSSqlRepositoryEntity](Update-PSSqlRepositoryEntity.md)

Updates existing entities: a discoverable proxy for Save-PSSqlRepositoryEntity -Mode Update.

