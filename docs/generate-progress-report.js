#!/usr/bin/env node
// Regenerates progress-report.html's embedded FALLBACK_DATA snapshot from the
// real ticket/**/*.md files, so the report shows current status even when
// opened directly as a file:// document (where the page's own live fetch()
// is blocked by the browser). Run this after editing any ticket's
// **Status:** field. Parsing rules mirror the in-page parseTicket() exactly.
//
// Usage: node docs/generate-progress-report.js

const fs = require('fs');
const path = require('path');

const DOCS_DIR = __dirname;
const REPORT_PATH = path.join(DOCS_DIR, 'progress-report.html');
const NOTE_MAX = 260;

const BEGIN_MARKER = '// AUTO-GENERATED:BEGIN';
const END_MARKER = '// AUTO-GENERATED:END';

function normalizeStatus(raw) {
  const s = (raw || '').toLowerCase();
  if (s.includes('done')) return 'done';
  if (s.includes('progress')) return 'progress';
  return 'todo';
}

function extractNote(body) {
  const idx = body.search(/^##\s+Problem\s*\/\s*Value/m);
  if (idx === -1) return '';
  const after = body.slice(idx).replace(/^##[^\n]*\n/, '');
  const nextHeading = after.search(/\n##\s+/);
  const section = (nextHeading === -1 ? after : after.slice(0, nextHeading)).trim();
  const firstPara = section.split(/\n\s*\n/)[0].replace(/\s+/g, ' ').trim();
  return firstPara.length > NOTE_MAX ? firstPara.slice(0, NOTE_MAX).trim() + '…' : firstPara;
}

function parseTicket(relPath, text) {
  const titleMatch = text.match(/^#\s+(.+)$/m);
  const phaseMatch = text.match(/^\*\*Phase:\*\*\s*(.+)$/m);
  const ticketMatch = text.match(/^\*\*Ticket:\*\*\s*(\S+)/m);
  const dependsMatch = text.match(/^\*\*Depends on:\*\*\s*(.+)$/m);
  const statusMatch = text.match(/^\*\*Status:\*\*\s*(.+)$/m);

  if (!titleMatch || !phaseMatch || !ticketMatch) {
    throw new Error(`${relPath}: missing required header field(s)`);
  }

  const phaseNumMatch = phaseMatch[1].match(/^(\d+)\s*[—-]\s*(.+)$/);
  const phaseNum = phaseNumMatch ? phaseNumMatch[1] : phaseMatch[1].trim();
  const phaseName = phaseNumMatch ? phaseNumMatch[2].trim() : phaseMatch[1].trim();
  const idMatch = ticketMatch[1].match(/^(phase\d+\/\d+)/);
  const id = idMatch ? idMatch[1] : ticketMatch[1];
  const deps = dependsMatch ? [...new Set(dependsMatch[1].match(/phase\d+\/\d+/g) || [])] : [];

  if (!statusMatch) {
    throw new Error(`${relPath}: no **Status:** field found`);
  }

  return {
    phaseKey: `phase${phaseNum}`,
    phaseTitle: `Phase ${phaseNum} — ${phaseName}`,
    ticket: {
      id,
      path: relPath,
      title: titleMatch[1].trim(),
      status: normalizeStatus(statusMatch[1]),
      note: extractNote(text),
      deps
    }
  };
}

function extractTicketPaths(reportHtml) {
  const match = reportHtml.match(/const TICKET_PATHS = \[([\s\S]*?)\];/);
  if (!match) throw new Error('Could not find TICKET_PATHS array in progress-report.html');
  return [...match[1].matchAll(/'([^']+)'/g)].map(m => m[1]);
}

function main() {
  const reportHtml = fs.readFileSync(REPORT_PATH, 'utf8');
  const ticketPaths = extractTicketPaths(reportHtml);

  const parsed = ticketPaths.map(relPath => {
    const absPath = path.join(DOCS_DIR, relPath);
    const text = fs.readFileSync(absPath, 'utf8');
    return parseTicket(relPath, text);
  });

  const byPhase = new Map();
  parsed.forEach(({ phaseKey, phaseTitle, ticket }) => {
    if (!byPhase.has(phaseKey)) byPhase.set(phaseKey, { phase: phaseKey, title: phaseTitle, tickets: [] });
    byPhase.get(phaseKey).tickets.push(ticket);
  });

  const data = Array.from(byPhase.values())
    .sort((a, b) => parseInt(a.phase.replace('phase', '')) - parseInt(b.phase.replace('phase', '')))
    .map(p => ({ ...p, tickets: p.tickets.sort((a, b) => a.id.localeCompare(b.id, undefined, { numeric: true })) }));

  const generatedBlock = [
    `${BEGIN_MARKER} — do not hand-edit; run \`node docs/generate-progress-report.js\``,
    `  const FALLBACK_DATA = ${JSON.stringify(data, null, 2).replace(/\n/g, '\n  ')};`,
    `  ${END_MARKER}`
  ].join('\n  ').replace(/^  /, '');

  const blockRegex = new RegExp(`${BEGIN_MARKER}[\\s\\S]*?${END_MARKER}`);
  if (!blockRegex.test(reportHtml)) {
    throw new Error('Could not find AUTO-GENERATED markers in progress-report.html');
  }

  const updatedHtml = reportHtml.replace(blockRegex, generatedBlock);
  fs.writeFileSync(REPORT_PATH, updatedHtml, 'utf8');

  const counts = data.reduce((acc, p) => {
    p.tickets.forEach(t => { acc[t.status] = (acc[t.status] || 0) + 1; });
    return acc;
  }, {});
  console.log(`Regenerated FALLBACK_DATA: ${data.reduce((n, p) => n + p.tickets.length, 0)} tickets ` +
    `(done=${counts.done || 0}, progress=${counts.progress || 0}, todo=${counts.todo || 0}) across ${data.length} phases.`);
}

main();
