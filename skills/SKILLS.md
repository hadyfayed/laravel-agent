# Laravel Agent Skills System

Progressive disclosure architecture for efficient context loading.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PROGRESSIVE DISCLOSURE                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Tier 1: Metadata (Always Loaded)                                   │
│  ├── Skill name, description, triggers                              │
│  └── ~100 tokens per skill                                          │
│                                                                      │
│  Tier 2: Core Instructions (On Demand)                              │
│  ├── Main workflow, key patterns                                    │
│  └── ~500-1000 tokens per skill                                     │
│                                                                      │
│  Tier 3: References (Deep Dive)                                     │
│  ├── Examples, edge cases, advanced patterns                        │
│  └── ~2000+ tokens per skill                                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Skill Registry

```yaml
# skills/registry.yaml
version: "1.0"
skills:
  # Core Laravel Skills
  - id: feature-build
    name: Feature Builder
    trigger: "build feature|create feature|implement feature"
    tier1: skills/feature-build/meta.md
    tier2: skills/feature-build/SKILL.md
    tier3: skills/feature-build/references/
    agent: laravel-feature-builder

  - id: api-build
    name: API Builder
    trigger: "build api|create endpoint|api resource"
    tier1: skills/api-build/meta.md
    tier2: skills/api-build/SKILL.md
    tier3: skills/api-build/references/
    agent: laravel-api-builder

  - id: database
    name: Database Expert
    trigger: "migration|database|schema|eloquent|query"
    tier1: skills/database/meta.md
    tier2: skills/database/SKILL.md
    tier3: skills/database/references/
    agent: laravel-database

  - id: testing
    name: Testing Expert
    trigger: "test|pest|phpunit|coverage"
    tier1: skills/testing/meta.md
    tier2: skills/testing/SKILL.md
    tier3: skills/testing/references/
    agent: laravel-testing

  - id: auth
    name: Auth Expert
    trigger: "auth|permission|role|guard|policy"
    tier1: skills/auth/meta.md
    tier2: skills/auth/SKILL.md
    tier3: skills/auth/references/
    agent: laravel-auth

  - id: review
    name: Code Review
    trigger: "review|audit|security check|pr review"
    tier1: skills/review/meta.md
    tier2: skills/review/SKILL.md
    tier3: skills/review/references/
    agent: laravel-review

  # Package-Specific Skills
  - id: livewire
    name: Livewire Expert
    trigger: "livewire|reactive|component"
    tier1: skills/livewire/meta.md
    tier2: skills/livewire/SKILL.md
    agent: laravel-livewire

  - id: filament
    name: Filament Expert
    trigger: "filament|admin panel|resource"
    tier1: skills/filament/meta.md
    tier2: skills/filament/SKILL.md
    agent: laravel-filament

  - id: reverb
    name: WebSocket Expert
    trigger: "websocket|reverb|broadcast|real-time"
    tier1: skills/reverb/meta.md
    tier2: skills/reverb/SKILL.md
    agent: laravel-reverb

  - id: tenancy
    name: Multi-Tenancy Expert
    trigger: "tenant|multi-tenant|saas|stancl"
    tier1: skills/tenancy/meta.md
    tier2: skills/tenancy/SKILL.md
    agent: laravel-architect
```

## Tier 1: Metadata Files

```markdown
<!-- skills/feature-build/meta.md -->
---
id: feature-build
name: Feature Builder
version: 1.0.0
description: Build complete Laravel features with CRUD, views, API, and tests
triggers:
  - "build feature"
  - "create feature"
  - "implement feature"
  - "new feature"
packages:
  - none required (uses core Laravel)
complexity: medium
tokens: ~800
---

Build self-contained business features in app/Features/<Name>/ with:
- Models, migrations, factories
- Controllers, form requests, resources
- Views (Blade or Livewire)
- API endpoints (optional)
- Policies and tests

Use: `/feature:make <Name>` or ask architect for feature recommendation.
```

```markdown
<!-- skills/api-build/meta.md -->
---
id: api-build
name: API Builder
version: 1.0.0
description: Build production-ready APIs with versioning, docs, and rate limiting
triggers:
  - "build api"
  - "create endpoint"
  - "api resource"
  - "rest api"
packages:
  - spatie/laravel-query-builder (optional)
  - knuckleswtf/scribe (optional)
complexity: medium
tokens: ~600
---

Build RESTful APIs with:
- Versioned routes (v1, v2)
- JSON:API or REST conventions
- OpenAPI/Swagger documentation
- Rate limiting and throttling
- Resource transformations

Use: `/api:make <Resource>` or architect for recommendations.
```

## Tier 2: Core Skill Files

```markdown
<!-- skills/feature-build/SKILL.md -->
# Feature Builder Skill

## Quick Start
```bash
/feature:make Invoice
```

## Structure Generated
```
app/Features/Invoice/
├── InvoiceServiceProvider.php
├── Domain/
│   ├── Models/Invoice.php
│   ├── Events/InvoiceCreated.php
│   └── Enums/InvoiceStatus.php
├── Http/
│   ├── Controllers/InvoiceController.php
│   ├── Requests/StoreInvoiceRequest.php
│   └── Resources/InvoiceResource.php
├── Database/
│   └── Migrations/create_invoices_table.php
└── Tests/
    └── InvoiceFeatureTest.php
```

## Key Patterns
1. **Service Provider** - Registers routes, views, migrations
2. **Form Requests** - Validation encapsulation
3. **Resources** - API transformation
4. **Policies** - Authorization logic
5. **Events** - Side effect handling

## Tenancy Support
Add `--tenant` flag for multi-tenant features with automatic scoping.
```

## Tier 3: Reference Files

```
skills/feature-build/references/
├── patterns/
│   ├── repository.md
│   ├── action.md
│   └── dto.md
├── examples/
│   ├── invoice-feature.md
│   ├── order-feature.md
│   └── product-feature.md
├── testing/
│   ├── feature-tests.md
│   └── api-tests.md
└── edge-cases/
    ├── soft-deletes.md
    ├── multi-tenant.md
    └── versioning.md
```

## Loading Strategy

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SKILL LOADING FLOW                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. User Request                                                    │
│     └── "Build an invoice feature"                                  │
│                                                                      │
│  2. Trigger Matching (Tier 1)                                       │
│     └── Match: "feature-build" skill                                │
│     └── Load: meta.md (~100 tokens)                                 │
│                                                                      │
│  3. Skill Activation (Tier 2)                                       │
│     └── Load: SKILL.md (~800 tokens)                                │
│     └── Ready to execute                                            │
│                                                                      │
│  4. Reference Loading (Tier 3 - On Demand)                          │
│     └── If complex: Load relevant references                        │
│     └── If multi-tenant: Load tenancy patterns                      │
│     └── If testing focus: Load test examples                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Skill Invocation

### Automatic (Trigger-Based)
```
User: "I need to build an invoice management feature"
       ↓
System: Detects "build feature" trigger
       ↓
System: Loads feature-build Tier 1 (meta.md)
       ↓
System: Confirms skill match, loads Tier 2 (SKILL.md)
       ↓
Agent: Executes feature-build with context
```

### Explicit (Command-Based)
```
User: /skill:load feature-build
       ↓
System: Loads Tier 1 + Tier 2 immediately
       ↓
User: /skill:deep feature-build/patterns/repository
       ↓
System: Loads specific Tier 3 reference
```

### Agent-Directed
```
Agent: Analyzing request... needs feature + API + testing skills
       ↓
Agent: Loads multiple skills in parallel:
       - feature-build (Tier 2)
       - api-build (Tier 2)
       - testing (Tier 2)
```

## Token Budget Management

```yaml
# Context budget allocation
budget:
  total: 8000  # tokens reserved for skills
  tier1_all: 2000  # All metadata always available
  tier2_active: 3000  # Currently active skills
  tier3_deep: 3000  # Deep reference for complex tasks

# Auto-unload strategy
unload:
  after_idle: 3  # messages without skill use
  on_switch: true  # unload when switching skills
  preserve: ["architect"]  # never unload these
```

## Creating New Skills

### 1. Create Skill Directory
```bash
mkdir -p skills/<skill-name>/{references/{patterns,examples,edge-cases}}
```

### 2. Create Metadata (Tier 1)
```markdown
<!-- skills/<skill-name>/meta.md -->
---
id: <skill-name>
name: <Display Name>
version: 1.0.0
description: <One-line description>
triggers:
  - "<trigger phrase 1>"
  - "<trigger phrase 2>"
packages: []
complexity: low|medium|high
tokens: ~<estimated>
---

<Brief summary of what this skill does and when to use it>
```

### 3. Create Core Instructions (Tier 2)
```markdown
<!-- skills/<skill-name>/SKILL.md -->
# <Skill Name>

## Quick Start
<Fastest way to use this skill>

## Key Patterns
<Essential patterns and workflows>

## Common Options
<Configuration and customization>
```

### 4. Add References (Tier 3)
```markdown
<!-- skills/<skill-name>/references/patterns/<pattern>.md -->
# <Pattern Name>

## When to Use
## Implementation
## Examples
## Edge Cases
```

### 5. Register in Registry
```yaml
# Add to skills/registry.yaml
- id: <skill-name>
  name: <Display Name>
  trigger: "<trigger phrases>"
  tier1: skills/<skill-name>/meta.md
  tier2: skills/<skill-name>/SKILL.md
  tier3: skills/<skill-name>/references/
  agent: <associated-agent>
```
