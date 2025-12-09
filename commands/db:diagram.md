---
description: "Generate database schema diagram"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit
---

# /db:diagram - Database Schema Diagram

Generate a visual diagram of your database schema.

## Input
$ARGUMENTS = `[format] [tables]`

Examples:
- `/db:diagram` - Generate full schema diagram
- `/db:diagram mermaid` - Mermaid.js format
- `/db:diagram dbml` - DBML format
- `/db:diagram users,orders,products` - Specific tables only

## Process

1. **Analyze Schema**
   - Read all migrations
   - Extract table definitions
   - Map relationships

2. **Generate Diagram**
   - Mermaid.js ERD format (default)
   - DBML for dbdiagram.io
   - PlantUML format

3. **Output**
   ```markdown
   ## Database Schema

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
   ```
   ```

## Output Formats

### Mermaid (default)
Renders in GitHub, GitLab, VS Code

### DBML
Export to dbdiagram.io for interactive editing

### PlantUML
For documentation systems
