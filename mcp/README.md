# Laravel Agent MCP Extension

Complements [Laravel Boost](https://github.com/laravel/boost) with additional MCP tools for comprehensive Laravel development.

## Laravel Boost Coverage

Laravel Boost already provides excellent tools for:
- Application info (PHP/Laravel versions, packages, models)
- Database schema, connections, queries
- Routes inspection
- Artisan commands and Tinker
- Configuration values
- Log entries
- Documentation API (17,000+ pieces)
- Browser logs and last errors
- AI Guidelines

## Extension Tools (Proposed)

This extension adds tools that Laravel Boost doesn't cover:

### Testing Tools
| Tool | Description |
|------|-------------|
| `test:run` | Run Pest/PHPUnit tests with filters |
| `test:coverage` | Get test coverage report |
| `test:list` | List all test files and their status |

### Queue & Jobs Tools
| Tool | Description |
|------|-------------|
| `queue:status` | Get queue status (pending, failed, processed) |
| `queue:failed` | List failed jobs with details |
| `queue:jobs` | List pending jobs in queue |
| `horizon:status` | Get Horizon metrics (if installed) |

### Cache Tools
| Tool | Description |
|------|-------------|
| `cache:status` | Get cache driver status and stats |
| `cache:keys` | List cached keys (for supported drivers) |
| `cache:get` | Get specific cache value |

### Performance Tools
| Tool | Description |
|------|-------------|
| `perf:queries` | Get slow query analysis |
| `perf:memory` | Get memory usage stats |
| `perf:telescope` | Get Telescope metrics (if installed) |
| `perf:pulse` | Get Pulse metrics (if installed) |

### Migration Tools
| Tool | Description |
|------|-------------|
| `migrate:status` | Get migration status (ran, pending) |
| `migrate:diff` | Compare schema with migrations |

### Event Tools
| Tool | Description |
|------|-------------|
| `event:list` | List all events and listeners |
| `event:subscribers` | List event subscribers |

### Schedule Tools
| Tool | Description |
|------|-------------|
| `schedule:list` | List scheduled tasks |
| `schedule:next` | Get next run times |

### Mail & Notification Tools
| Tool | Description |
|------|-------------|
| `mail:list` | List all mailables |
| `notification:list` | List all notifications |
| `notification:channels` | List available channels |

### Security Tools
| Tool | Description |
|------|-------------|
| `security:scan` | Run basic security scan |
| `security:deps` | Check dependencies for vulnerabilities |

## Integration with Laravel Boost

This extension is designed to work alongside Laravel Boost, not replace it.

```bash
# Install Laravel Boost first
composer require laravel/boost

# Then add our extension (when available)
composer require laravel-agent/mcp-extension
```

## Implementation Status

This extension is in **proposal stage**. The tools above represent what we plan to implement.

### Phase 1 (Planned)
- Testing tools
- Queue & Jobs tools
- Cache tools

### Phase 2 (Planned)
- Performance tools
- Migration tools
- Event tools

### Phase 3 (Planned)
- Schedule tools
- Mail & Notification tools
- Security tools

## Contributing

We welcome contributions! If you'd like to help implement any of these tools, please open a PR.

## Why Not Add to Laravel Boost?

Laravel Boost is maintained by the Laravel team and focused on core functionality. This extension covers more specialized tools that:

1. May not fit Laravel Boost's scope
2. Require additional packages (Horizon, Telescope, Pulse)
3. Are more opinionated in implementation
4. Need more frequent updates

## License

MIT
