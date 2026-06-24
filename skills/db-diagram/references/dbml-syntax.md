# DBML Syntax Reference

## What is DBML?

Database Markup Language (DBML) is a simple, readable syntax for defining database schemas. It's rendered by dbdiagram.io for interactive visualization and sharing.

## Basic Syntax

```dbml
Table table_name {
  id int [primary key]
  name varchar
  email varchar [unique]
  created_at timestamp
}
```

## Column Constraints

| Constraint | Syntax | Meaning |
|-----------|--------|---------|
| Primary key | `[primary key]` | Unique identifier |
| Foreign key | `[ref: > other_table.id]` | Reference to other table |
| Unique | `[unique]` | Must be unique |
| Not null | `[not null]` | Cannot be empty |
| Default | `[default: value]` | Default value |

## Relationship Syntax

```dbml
Ref: users.id < orders.user_id
Ref: orders.id < order_items.order_id
Ref: products.id < order_items.product_id
```

### Relationship Cardinalities

| Syntax | Meaning |
|--------|---------|
| `<` | Many-to-one (foreign key on left) |
| `>` | One-to-many (foreign key on right) |
| `-` | One-to-one |

## Full Example

```dbml
Table users {
  id bigint [primary key]
  name varchar [not null]
  email varchar [unique, not null]
  password varchar [not null]
  email_verified_at timestamp
  created_at timestamp
  updated_at timestamp

  Note: 'User accounts and authentication'
}

Table orders {
  id bigint [primary key]
  user_id bigint [not null, ref: > users.id]
  total decimal [not null]
  status varchar [default: 'pending']
  created_at timestamp
  updated_at timestamp
}

Table order_items {
  id bigint [primary key]
  order_id bigint [not null, ref: > orders.id]
  product_id bigint [not null, ref: > products.id]
  quantity int [not null]
  price decimal [not null]
}

Table products {
  id bigint [primary key]
  name varchar [not null]
  description text
  price decimal [not null]
  stock int [not null, default: 0]
  created_at timestamp
}

Table reviews {
  id bigint [primary key]
  user_id bigint [not null, ref: > users.id]
  product_id bigint [not null, ref: > products.id]
  rating int [not null]
  content text
  created_at timestamp

  Note: 'User reviews on products'
}

Ref: users.id < reviews.user_id
```

## Table Aliases

Use `as` to shorten table names in references:

```dbml
Table users as U {
  id bigint [primary key]
}

Table orders as O {
  user_id bigint [ref: > U.id]
}
```

## Indexes

Define indexes for performance:

```dbml
Table orders {
  id bigint [primary key]
  user_id bigint [not null]
  status varchar
  created_at timestamp

  indexes {
    (user_id, status)
    (created_at)
  }
}
```

## Comments (Notes)

Add documentation notes to tables and columns:

```dbml
Table users {
  id bigint [primary key]
  email varchar [unique, note: 'Must be verified']
  role varchar [default: 'user', note: 'admin, user, moderator']

  Note: 'Core user table with authentication'
}
```

## Enums

Define enumerated types:

```dbml
enum order_status {
  pending
  completed
  cancelled
  refunded
}

Table orders {
  id bigint [primary key]
  status order_status [default: 'pending']
}
```

## Export to Code

DBML can be exported to SQL, Laravel migrations, and other formats via dbdiagram.io UI.

## Sharing and Collaboration

1. Create diagram on dbdiagram.io
2. Paste DBML code
3. Share URL with team members
4. Collaborate on schema design in real-time
