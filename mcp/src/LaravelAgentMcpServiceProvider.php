<?php

declare(strict_types=1);

namespace LaravelAgent\Mcp;

use Illuminate\Support\ServiceProvider;
use PhpMcp\Laravel\Facades\MCP;

/**
 * Laravel Agent MCP Extension Service Provider
 *
 * Extends Laravel Boost with additional MCP tools for:
 * - Testing (run tests, coverage, list tests)
 * - Queues (status, failed jobs, pending jobs)
 * - Cache (status, keys, values)
 * - Performance (queries, memory, monitoring)
 * - Migrations (status, diff)
 * - Events (list events, subscribers)
 * - Schedule (list tasks, next runs)
 * - Security (scan, dependency check)
 */
final class LaravelAgentMcpServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__ . '/../config/laravel-agent-mcp.php', 'laravel-agent-mcp');
    }

    public function boot(): void
    {
        if ($this->app->runningInConsole()) {
            $this->publishes([
                __DIR__ . '/../config/laravel-agent-mcp.php' => config_path('laravel-agent-mcp.php'),
            ], 'laravel-agent-mcp-config');
        }

        $this->registerMcpTools();
    }

    private function registerMcpTools(): void
    {
        // Only register if php-mcp/laravel is available
        if (! class_exists(MCP::class)) {
            return;
        }

        // Register Testing Tools
        MCP::tool('test:run', function (string $filter = '', string $suite = '') {
            return $this->runTests($filter, $suite);
        })->description('Run Pest/PHPUnit tests with optional filter');

        MCP::tool('test:coverage', function () {
            return $this->getTestCoverage();
        })->description('Get test coverage report summary');

        // Register Queue Tools
        MCP::tool('queue:status', function () {
            return $this->getQueueStatus();
        })->description('Get queue status including pending and failed counts');

        MCP::tool('queue:failed', function (int $limit = 10) {
            return $this->getFailedJobs($limit);
        })->description('List recent failed jobs with error details');

        // Register Cache Tools
        MCP::tool('cache:status', function () {
            return $this->getCacheStatus();
        })->description('Get cache driver status and statistics');

        // Register Performance Tools
        MCP::tool('perf:queries', function () {
            return $this->getSlowQueries();
        })->description('Get slow query analysis from query log');

        // Register Migration Tools
        MCP::tool('migrate:status', function () {
            return $this->getMigrationStatus();
        })->description('Get migration status (ran and pending)');

        // Register Event Tools
        MCP::tool('event:list', function () {
            return $this->getEventList();
        })->description('List all registered events and their listeners');

        // Register Schedule Tools
        MCP::tool('schedule:list', function () {
            return $this->getScheduleList();
        })->description('List scheduled tasks with next run times');

        // Register Security Tools
        MCP::tool('security:deps', function () {
            return $this->checkDependencies();
        })->description('Check Composer dependencies for known vulnerabilities');
    }

    private function runTests(string $filter, string $suite): array
    {
        $command = 'php artisan test';

        if ($filter) {
            $command .= ' --filter=' . escapeshellarg($filter);
        }

        if ($suite) {
            $command .= ' --testsuite=' . escapeshellarg($suite);
        }

        $output = [];
        $exitCode = 0;
        exec($command . ' 2>&1', $output, $exitCode);

        return [
            'success' => $exitCode === 0,
            'output' => implode("\n", $output),
            'exit_code' => $exitCode,
        ];
    }

    private function getTestCoverage(): array
    {
        $output = [];
        exec('php artisan test --coverage 2>&1', $output);

        return [
            'output' => implode("\n", $output),
        ];
    }

    private function getQueueStatus(): array
    {
        $status = [
            'driver' => config('queue.default'),
            'failed_count' => 0,
            'pending' => 'unknown',
        ];

        // Get failed job count
        try {
            $status['failed_count'] = \DB::table('failed_jobs')->count();
        } catch (\Exception $e) {
            $status['failed_count'] = 'N/A (table not found)';
        }

        // Check Horizon if available
        if (class_exists(\Laravel\Horizon\Horizon::class)) {
            $status['horizon_available'] = true;
        }

        return $status;
    }

    private function getFailedJobs(int $limit): array
    {
        try {
            $jobs = \DB::table('failed_jobs')
                ->orderBy('failed_at', 'desc')
                ->limit($limit)
                ->get(['id', 'queue', 'payload', 'exception', 'failed_at'])
                ->map(function ($job) {
                    $payload = json_decode($job->payload, true);
                    return [
                        'id' => $job->id,
                        'queue' => $job->queue,
                        'job' => $payload['displayName'] ?? 'Unknown',
                        'failed_at' => $job->failed_at,
                        'exception' => substr($job->exception, 0, 500),
                    ];
                })
                ->toArray();

            return ['jobs' => $jobs];
        } catch (\Exception $e) {
            return ['error' => 'Could not retrieve failed jobs: ' . $e->getMessage()];
        }
    }

    private function getCacheStatus(): array
    {
        return [
            'driver' => config('cache.default'),
            'prefix' => config('cache.prefix'),
            'stores' => array_keys(config('cache.stores', [])),
        ];
    }

    private function getSlowQueries(): array
    {
        // Check if query log is enabled
        if (! \DB::logging()) {
            return ['message' => 'Query logging is not enabled. Enable with DB::enableQueryLog()'];
        }

        $queries = collect(\DB::getQueryLog())
            ->sortByDesc('time')
            ->take(10)
            ->values()
            ->toArray();

        return ['slow_queries' => $queries];
    }

    private function getMigrationStatus(): array
    {
        $output = [];
        exec('php artisan migrate:status --no-ansi 2>&1', $output);

        return [
            'output' => implode("\n", $output),
        ];
    }

    private function getEventList(): array
    {
        $output = [];
        exec('php artisan event:list --no-ansi 2>&1', $output);

        return [
            'output' => implode("\n", $output),
        ];
    }

    private function getScheduleList(): array
    {
        $output = [];
        exec('php artisan schedule:list --no-ansi 2>&1', $output);

        return [
            'output' => implode("\n", $output),
        ];
    }

    private function checkDependencies(): array
    {
        $output = [];
        $exitCode = 0;
        exec('composer audit --format=json 2>&1', $output, $exitCode);

        $result = json_decode(implode('', $output), true);

        return [
            'vulnerable' => $exitCode !== 0,
            'advisories' => $result['advisories'] ?? [],
            'summary' => $result['summary'] ?? 'No vulnerabilities found',
        ];
    }
}
