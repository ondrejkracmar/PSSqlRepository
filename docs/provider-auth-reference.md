# Provider and authentication reference

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
