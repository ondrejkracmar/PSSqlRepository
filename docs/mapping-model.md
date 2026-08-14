# Mapping model

How an object arriving on the pipeline becomes a row. Two distinct steps are involved, and knowing
which one produced an error is most of the diagnosis:

1. **PowerShell object → entity instance** (`PSObjectEntityConverter`) — the loose PowerShell input
   is materialised into the CLR entity type you registered.
2. **Entity instance → columns** (EF Core) — the model built by
   `Register-PSSqlRepositoryEntity` or your own `DbContext` decides tables, columns, keys, and
   relationships.

Step 2 is plain EF Core with conventions; this document is mostly about step 1.

---

## Accepted input

`Save-PSSqlRepositoryEntity` and `Remove-PSSqlRepositoryEntity` accept:

| Input | Handling |
|---|---|
| An instance of the registered entity type | Used as-is, no conversion |
| `[pscustomobject]@{ … }` | Property-by-property into a new entity instance |
| `[hashtable]` / any `IDictionary` | Keys become property names |
| Any CLR object with public properties | Public readable properties are enumerated |
| Anonymous types | Same as any CLR object |

When the input is not already the entity type, pass `-EntityType` so the target is unambiguous:

```powershell
[pscustomobject]@{ Name = 'Acme'; Email = 'hi@acme.cz' } |
    Save-PSSqlRepositoryEntity -EntityType ([Customer])
```

The entity type is inferred automatically only when the pipeline object *is* a typed instance —
a `[pscustomobject]` or hashtable carries no type information to infer from.

## Property matching

- Matching is **by name, case-insensitively**.
- Only **writable** properties on the target are set.
- A source property with no matching target property is **ignored silently**. This is deliberate:
  PowerShell decorates objects with note properties (`PSComputerName`, `RunspaceId`, …) that would
  otherwise make every piped object fail.
- A target property with no matching source property keeps its default (`0`, `null`, …).

The consequence worth remembering: a typo in a property name does not raise an error, it produces a
row with a default value in that column. Prefer typed entity instances (`[Customer]@{ … }`) over
`[pscustomobject]` — PowerShell's own class binding catches the typo at construction time.

## Value conversion

| Target type | Conversion |
|---|---|
| Already the target type | Used as-is |
| `PSObject` wrapper | Unwrapped to `BaseObject` first |
| Primitive, `string`, `decimal`, `Guid`, `DateTime`, `DateTimeOffset`, `TimeSpan` | `Convert.ChangeType` under the **invariant** culture |
| `enum` | From a string by name (case-insensitive), or from its numeric value |
| `Guid` from `string` | `Guid.Parse` |
| `Nullable<T>` | `null` passes through; otherwise converted as `T` |
| Complex type | Recursively converted as a nested entity |
| `ICollection<T>` / `List<T>` / `T[]` / `HashSet<T>` | Each element converted recursively |

Invariant culture matters: `'9.9'` is nine-point-nine regardless of the machine locale, and
`'9,9'` is not a valid decimal even on a Czech system. Pass real typed values (`9.9`, not `'9,9'`)
and this never comes up.

A conversion that fails throws with both types named:

```
Cannot convert value of type 'System.String' to 'System.Int32'.
Provide a value compatible with the target property type. Original error: …
```

The raw .NET exception is preserved as the inner exception.

## Nested objects and collections

Nested objects are **not** flattened and **not** serialised to JSON. They are converted into nested
entity instances, which EF Core then treats as navigations — that is how a graph save works:

```powershell
$company = [Company]@{
    Name   = 'Acme'
    People = [System.Collections.Generic.List[Person]]@(
        [Person]@{ FirstName = 'Jana'; LastName = 'Novakova' }
    )
}

Save-PSSqlRepositoryEntity -InputObject $company -IncludeNavigations
```

Without `-IncludeNavigations` only the root entity is written; the nested objects are converted but
not persisted.

A collection navigation must use a type with a public `Add(T)` — `List<T>`, `HashSet<T>`, or an
array. Anything else fails loudly rather than silently dropping the children:

```
Cannot populate collection of type '<Type>': no public Add(T) method was found.
```

The entity type itself needs a **public parameterless constructor**; PowerShell classes have one by
default.

## Requirements on the entity type

- Implements `IEntity<TKey>`; `Register-PSSqlRepositoryEntity` rejects anything else.
- Public parameterless constructor.
- Writable public properties for everything that should map.
- **No property initializers, no custom constructors, no computed getters** in PowerShell classes.
  Those bodies are script blocks, and EF Core materialises entities on a thread with no PowerShell
  runspace attached, so any of them turns every query into
  `There is no Runspace available to run scripts in this thread`. See
  [entity-model.md](./entity-model.md#rules-for-powershell-entity-classes).

## Schema mapping (step 2)

Table, column, key, and relationship mapping is EF Core's, by convention:

| Model element | Convention |
|---|---|
| Entity type name | Table name |
| Public property | Column of the same name |
| `Id` (from `IEntity<TKey>`) | Primary key, database-generated |
| `<Nav>Id` alongside a `<Nav>` reference property | Foreign key |
| `Nullable<T>` FK | Optional relationship |
| Non-nullable FK | Required relationship |

For anything conventions cannot express — explicit table/column names, precision, indexes, composite
keys, alternate delete behaviours — register a hand-written `DbContext` with
`Register-PSSqlRepositoryContext` and configure it in `OnModelCreating` as usual. The dynamic
model built by `Register-PSSqlRepositoryEntity` is the convenience path, not the only one.

## Update semantics

`Save-PSSqlRepositoryEntity` defaults to `-Mode Upsert`: a default-valued key (`0`, `null`,
`Guid.Empty`) inserts, anything else updates. On update the incoming graph is merged into the loaded
one by `EntityGraphMerger`:

- Primary keys are immutable. A different non-default key on a loaded row raises
  `Primary key mismatch on '<Type>.<Property>'`.
- Children present in the loaded collection but absent from the incoming one are **orphaned**. What
  happens then follows the relationship's `DeleteBehavior`, overridable with `-OrphanBehavior`.
- Graph depth is bounded (64 levels) to catch cycles introduced by deserialisation.

Both are covered in [../TROUBLESHOOTING.md](../TROUBLESHOOTING.md#save--merge).
