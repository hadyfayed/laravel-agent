---
name: db-diagram
description: Generate a database ER diagram or schema visualization from migrations and models in Mermaid or DBML format; when documenting the database schema.
disable-model-invocation: true
allowed-tools: Bash(php artisan *) Read Grep Glob Write
argument-hint: "[format] [tables]"
---

## Task

Analyze Laravel migrations and Eloquent models to generate a visual database schema diagram.

## Input

- **format** (optional): Output format — `mermaid` (default), `dbml`, `plantuml`
- **tables** (optional): Comma-separated table names to include; all by default

## Steps

1. **Read Migrations**
   ```bash
   find database/migrations -name "*.php" -type f
   ```
   - Parse table definitions, columns, indexes, foreign keys
   - Identify relationships (foreign key constraints)

2. **Analyze Models**
   - Extract model relationships (hasMany, belongsTo, belongsToMany, hasOne)
   - Map relationship directions and cardinalities
   - Detect pivot tables and through relationships

3. **Detect Schema Properties**
   - Column types and constraints (nullable, unsigned, default)
   - Primary and unique keys
   - Indexes and composite keys
   - Foreign key relationships and cascade options

4. **Generate Diagram**
   - Render in chosen format (Mermaid ERD, DBML, PlantUML)
   - Show all tables and relationships
   - Include column details (types, keys)
   - Render cardinalities (one-to-many, many-to-many, etc.)

## Output Format

### Mermaid (default)
Renders natively in GitHub, GitLab, Notion, and VS Code.

```mermaid
erDiagram
    users ||--o{ orders : places
    orders ||--|{ order_items : contains
    products ||--o{ order_items : "ordered in"

    users {
        bigint id PK
        string name
        string email UK
        timestamp created_at
    }

    orders {
        bigint id PK
        bigint user_id FK
        decimal total
        timestamp created_at
    }

    order_items {
        bigint id PK
        bigint order_id FK
        bigint product_id FK
        int quantity
    }

    products {
        bigint id PK
        string name
        decimal price
    }
```

### DBML
Export to dbdiagram.io for interactive editing and collaboration.

```dbml
Table users as U {
  id bigint [primary key]
  name varchar
  email varchar [unique]
  created_at timestamp
}

Table orders as O {
  id bigint [primary key]
  user_id bigint [ref: > U.id]
  total decimal
  created_at timestamp
}

Table order_items as OI {
  id bigint [primary key]
  order_id bigint [ref: > O.id]
  product_id bigint [ref: > P.id]
  quantity int
}

Table products as P {
  id bigint [primary key]
  name varchar
  price decimal
}
```

### PlantUML
For documentation systems and static generation.

```plantuml
@startuml schema
entity users {
  * id : bigint
  ---
  name : varchar
  email : varchar
  created_at : timestamp
}

entity orders {
  * id : bigint
  ---
  user_id : bigint [FK]
  total : decimal
  created_at : timestamp
}

users ||--o{ orders : places
@enduml
```

## Reference

See `${CLAUDE_SKILL_DIR}/references/` for:
- `mermaid-erd.md` — Mermaid ERD syntax and relationship cardinalities
- `dbml-syntax.md` — DBML format for dbdiagram.io

## Options

```bash
# Generate full schema in Mermaid
/db:diagram

# Generate specific tables
/db:diagram mermaid users,orders,products

# Generate in DBML format
/db:diagram dbml

# Generate in PlantUML
/db:diagram plantuml
```
