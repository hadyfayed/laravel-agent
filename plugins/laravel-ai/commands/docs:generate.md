---
description: "AI-powered documentation generation"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit
---

# /docs:generate - Generate Documentation

Generate documentation from your Laravel codebase.

## Input
$ARGUMENTS = `[type] [target]`

Examples:
- `/docs:generate` - Generate README and basic docs
- `/docs:generate api` - API documentation
- `/docs:generate architecture` - Architecture overview
- `/docs:generate app/Services` - Document specific directory

## Documentation Types

### README (default)
Project overview with:
- Features
- Installation
- Configuration
- Usage examples

### API
Endpoint documentation:
- Routes
- Request/response formats
- Authentication
- Examples

### Architecture
System design docs:
- Directory structure
- Design patterns used
- Data flow diagrams
- Component interactions

### Models
Database documentation:
- Entity relationships
- Attributes
- Methods
- Scopes

## Process

1. **Analyze Codebase**
   - Scan directory structure
   - Read key files
   - Identify patterns
   - Extract PHPDoc

2. **Generate Documentation**
   ```markdown
   ## Project Documentation

   ### Overview
   <Generated description based on code analysis>

   ### Features
   - Feature 1: <description>
   - Feature 2: <description>

   ### Installation
   ```bash
   composer install
   php artisan migrate
   ```

   ### Architecture
   ```
   app/
   ├── Features/     # Self-contained business features
   ├── Modules/      # Reusable domain logic
   ├── Services/     # Business logic services
   └── Actions/      # Single-purpose actions
   ```

   ### Models
   | Model | Table | Relationships |
   |-------|-------|---------------|
   | User | users | hasMany(Order) |
   | Order | orders | belongsTo(User), hasMany(OrderItem) |
   ```

3. **Output Options**
   - Markdown files
   - README.md
   - docs/ directory
   - Docusaurus/VitePress compatible

## Generated Files

```
docs/
├── README.md           # Project overview
├── ARCHITECTURE.md     # System design
├── API.md              # API reference
├── MODELS.md           # Database models
└── DEPLOYMENT.md       # Deployment guide
```
