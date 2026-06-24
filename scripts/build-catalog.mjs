#!/usr/bin/env node
import { readdirSync, readFileSync, existsSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

export function parseFrontmatter(text) {
  const m = text.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return {};
  const out = {};
  const lines = m[1].split('\n');
  let i = 0;
  while (i < lines.length) {
    const mm = lines[i].match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (mm) {
      const key = mm[1];
      const val = mm[2].trim();
      // Handle block scalars: >, |, >-, >+, |-, |+
      if (val === '>' || val === '|' || val === '>-' || val === '>+' || val === '|-' || val === '|+') {
        // Collect following indented lines as a block scalar
        const parts = [];
        i++;
        while (i < lines.length && /^\s+/.test(lines[i])) {
          parts.push(lines[i].trim());
          i++;
        }
        out[key] = parts.join(' ');
      } else {
        out[key] = val.replace(/^["']|["']$/g, '');
        i++;
      }
    } else {
      i++;
    }
  }
  return out;
}

export function classifySkill(fm) {
  if (String(fm.context || '').includes('fork')) return 'scaffolder';
  if (String(fm['disable-model-invocation'] || '') === 'true') return 'utility';
  return 'reference';
}

export function scan(root = ROOT) {
  const skills = [];
  const skillsDir = join(root, 'skills');
  if (existsSync(skillsDir)) {
    for (const name of readdirSync(skillsDir)) {
      const p = join(skillsDir, name, 'SKILL.md');
      if (existsSync(p)) {
        const fm = parseFrontmatter(readFileSync(p, 'utf8'));
        skills.push({ name, kind: classifySkill(fm), description: fm.description || '' });
      }
    }
  }
  const agents = [];
  const agentsDir = join(root, 'agents');
  if (existsSync(agentsDir)) {
    for (const f of readdirSync(agentsDir)) {
      if (f.endsWith('.md') && !f.startsWith('_')) agents.push(f.replace(/\.md$/, ''));
    }
  }
  skills.sort((a, b) => a.name.localeCompare(b.name));
  agents.sort();
  return { skills, agents };
}

export function counts({ skills, agents }) {
  return { skills: skills.length, agents: agents.length };
}

const BADGE = ({ skills, agents }) => `${skills.length} skills · ${agents.length} agents`;

export function applyCounts(text, data) {
  const re = /<!-- catalog:counts -->[\s\S]*?<!-- \/catalog:counts -->/;
  if (!re.test(text)) {
    throw new Error('Missing <!-- catalog:counts --> marker in text. The marker is required for applyCounts to work.');
  }
  const block = `<!-- catalog:counts -->${BADGE(data)}<!-- /catalog:counts -->`;
  return text.replace(re, block);
}

// Files whose embedded counts the generator owns. Each entry maps a path to a
// transform(text, data)->text. README uses the marker block; the others get a
// single normalized "N skills, M agents" token via regex.
export function targets(data) {
  const badge = `${data.skills.length} skills, ${data.agents.length} agents`;
  return [
    { path: 'README.md', fn: (t) => applyCounts(t, data) },
    { path: '.claude-plugin/marketplace.json',
      fn: (t) => t
        .replace(/\d+\s+agents,\s+\d+\s+commands/g, badge)
        .replace(/\d+\s+skills,\s+\d+\s+agents/g, badge)
        .replace(/\d+\s+specialized\s+agents/g, `${data.agents.length} specialized agents`) },
    { path: 'docs/_config.yml',
      fn: (t) => t.replace(/\d+\s+commands,\s+\d+\s+skills,\s+\d+\s+agents/g, badge).replace(/\d+\s+skills,\s+\d+\s+agents/g, badge) },
    { path: 'docs/index.html',
      fn: (t) => t
        .replace(/\d+\s+agents,\s+\d+\s+commands,\s+\d+\s+skills/g, badge)
        .replace(/\d+\s+skills,\s+\d+\s+agents/g, badge) },
    { path: 'docs/commands.html',
      fn: (t) => t
        .replace(/\d+\s+commands\b/g, badge)
        .replace(/\d+\s+skills,\s+\d+\s+agents/g, badge) },
  ];
}

export function run({ check } = {}) {
  const data = scan();
  const diffs = [];
  const catalog = renderCatalog(data);
  const catalogPath = join(ROOT, 'CATALOG.md');
  const curCatalog = existsSync(catalogPath) ? readFileSync(catalogPath, 'utf8') : '';
  if (curCatalog !== catalog) { diffs.push('CATALOG.md'); if (!check) writeFileSync(catalogPath, catalog); }

  // Write catalog.json data file for Jekyll
  const catalogJsonPath = join(ROOT, 'docs', '_data', 'catalog.json');
  const catalogJson = JSON.stringify({ skills: data.skills, agents: data.agents, counts: counts(data) }, null, 2);
  const curCatalogJson = existsSync(catalogJsonPath) ? readFileSync(catalogJsonPath, 'utf8') : '';
  if (curCatalogJson !== catalogJson) { diffs.push('docs/_data/catalog.json'); if (!check) writeFileSync(catalogJsonPath, catalogJson); }

  for (const { path, fn } of targets(data)) {
    const p = join(ROOT, path);
    if (!existsSync(p)) continue;
    const cur = readFileSync(p, 'utf8');
    const next = fn(cur);
    if (cur !== next) { diffs.push(path); if (!check) writeFileSync(p, next); }
  }
  return { ok: diffs.length === 0, diffs };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const check = process.argv.includes('--check');
  const { ok, diffs } = run({ check });
  if (check && !ok) {
    console.error('Catalog drift detected in:\n' + diffs.map((d) => '  - ' + d).join('\n') +
      '\nRun: node scripts/build-catalog.mjs --write');
    process.exit(1);
  }
  console.log(check ? 'Catalog up to date.' : (diffs.length ? 'Updated: ' + diffs.join(', ') : 'No changes.'));
}

export function renderCatalog({ skills, agents }) {
  const byKind = (k) => skills.filter((s) => s.kind === k);
  const sec = (title, list) =>
    `### ${title} (${list.length})\n\n` +
    (list.length ? list.map((s) => `- \`${s.name}\` — ${s.description}`).join('\n') : '_none_') + '\n';
  const c = counts({ skills, agents });
  return (
    `<!-- GENERATED by scripts/build-catalog.mjs — do not edit by hand -->\n` +
    `# laravel-agent catalog\n\n` +
    `**${c.skills} skills** (${byKind('reference').length} reference, ` +
    `${byKind('scaffolder').length} scaffolder, ${byKind('utility').length} utility) · ` +
    `**${c.agents} agents**\n\n` +
    sec('Reference skills', byKind('reference')) + '\n' +
    sec('Scaffolder skills', byKind('scaffolder')) + '\n' +
    sec('Utility skills', byKind('utility')) + '\n' +
    `### Agents (${agents.length})\n\n` +
    (agents.length ? agents.map((a) => `- \`${a}\``).join('\n') : '_none_') + '\n'
  );
}
