# Provider and authentication reference

## Switches common to every provider

`Connect-PSSqlRepository` adds these to the provider's own parameters, built-in or extension:

| Switch | Effect |
|---|---|
| `-EnsureCreated` | Create the database from the registered model if it does not exist, and add tables the model has that the database lacks. Never alters an existing table. |
| `-Migrate` | `-EnsureCreated`, then reconcile existing tables with the model additively (new columns, indexes, foreign keys, widened columns). Destructive differences are warnings. Implies `-EnsureCreated`; cannot be combined with `-ImportSchema`. See [schema-migration.md](./schema-migration.md). |
| `-ImportSchema` | Database-first: read the catalogue and register one entity type per table before connecting. See [database-first.md](./database-first.md). |

A provider parameter with one of these names is skipped in favour of the switch; a verbose message on `Connect-PSSqlRepository` says so.

## Built-in providers

### SQL Server

Friendly connect parameters:

- `-Server`
- `-Database`
- `-TrustServerCertificate`
- `-ConnectionString`
- `-EnsureCreated`

Supported auth modes:

- `ConnectionString`
- `IntegratedSecurity`
- `UserPassword`

### SQLite

Friendly connect parameters:

- `-Path`
- `-Memory`
- `-ConnectionString`
- `-EnsureCreated`

Supported auth modes:

- `ConnectionString`
- `UserPassword`

## Built-in authentication surfaces

### SQL Server authentication

- `UserName`
- `Password`
- `SecurePassword`

Behavior notes:

- `SecurePassword` is preferred when you want to avoid materializing cleartext in managed memory.
- If a native credential is available, the provider path will bypass the cleartext connection-string route.

### SQLite authentication

- `Password`

Behavior notes:

- The SQLite auth provider currently supports password-based connection-string rewriting.
- Connection-string validation is performed through the standard SQLite connection-string builder.

## Extension guidance

If you add a new provider, document:

- friendly connect parameters
- supported auth modes
- required connection string rules
- any provider-specific security notes

If you add a new auth provider, document:

- required parameter names
- supported provider names
- whether secure credentials are supported
- any limitations around cleartext or native credentials
