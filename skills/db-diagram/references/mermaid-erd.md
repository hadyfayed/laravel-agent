# Mermaid ERD Syntax

## Relationship Cardinalities

| Cardinality | Syntax | Meaning |
|-------------|--------|---------|
| One-to-one | `\|\|--\|\|` | One entity relates to exactly one |
| One-to-many | `\|\|--o{` | One entity relates to many |
| Many-to-one | `}o--\|\|` | Many entities relate to one |
| Many-to-many | `}o--o{` | Many relate to many |

## Basic Syntax

```mermaid
erDiagram
    ENTITY-NAME ||--o{ OTHER-ENTITY : RELATIONSHIP-LABEL

    ENTITY-NAME {
        column_type column_name PK
        column_type column_name
    }
```

## Key Indicators

- `PK` — Primary key
- `FK` — Foreign key
- `UK` — Unique key

## Full Example

```mermaid
erDiagram
    users ||--o{ orders : places
    users ||--o{ addresses : has
    orders ||--|{ order_items : contains
    products ||--o{ order_items : "included in"
    users ||--o{ reviews : writes

    users {
        bigint id PK
        string name
        string email UK
        string password
        timestamp email_verified_at
        timestamp created_at
        timestamp updated_at
    }

    addresses {
        bigint id PK
        bigint user_id FK
        string street
        string city
        string postal_code
        timestamp created_at
    }

    orders {
        bigint id PK
        bigint user_id FK
        decimal total
        string status
        timestamp created_at
        timestamp updated_at
    }

    order_items {
        bigint id PK
        bigint order_id FK
        bigint product_id FK
        int quantity
        decimal price
    }

    products {
        bigint id PK
        string name
        string description
        decimal price
        int stock
        timestamp created_at
    }

    reviews {
        bigint id PK
        bigint user_id FK
        bigint product_id FK
        int rating
        text content
        timestamp created_at
    }
```

## Rendering Notes

- Mermaid renders ERDs in GitHub, GitLab, Notion, and modern editors
- Cardinalities are directional — the relationship flows from left to right
- Use quotes for multi-word relationship labels: `"places orders"`
- Column order matters for readability — put keys first

## Laravel Relationship Mapping

| Laravel Relationship | Cardinality | Syntax |
|----------------------|------------|--------|
| `hasMany()` | One-to-many | `users \|\|--o{ orders` |
| `belongsTo()` | Many-to-one | `orders }o--\|\| users` |
| `hasOne()` | One-to-one | `users \|\|--\|\| profile` |
| `belongsToMany()` | Many-to-many | `users }o--o{ roles` (via pivot) |

## Column Type Examples

```
string — VARCHAR
text — TEXT (long text)
bigint — BIGINT (unsigned for ID)
int — INTEGER
decimal(8,2) — DECIMAL with precision
boolean — BOOLEAN
timestamp — TIMESTAMP
date — DATE
json — JSON
enum — ENUM (for fixed values)
```
