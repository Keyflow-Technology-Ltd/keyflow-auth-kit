#!/usr/bin/env node
// Regenerate Events.swift and (optionally) a TS twin from events.json.
// Usage:
//   node scripts/generate-events.mjs                  # writes Swift in-repo
//   node scripts/generate-events.mjs --ts <path.ts>   # also writes TS to path

import { readFileSync, writeFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const repoRoot = resolve(here, '..')
const eventsJsonPath = resolve(repoRoot, 'events.json')
const swiftPath = resolve(repoRoot, 'Sources/KeyflowEventsKit/Events.swift')

const spec = JSON.parse(readFileSync(eventsJsonPath, 'utf8'))

const toCamel = (snake) =>
  snake.replace(/_([a-z])/g, (_, c) => c.toUpperCase())

const toPascal = (snake) => {
  const camel = toCamel(snake)
  return camel[0].toUpperCase() + camel.slice(1)
}

function renderSwift() {
  const lines = [
    '//',
    '//  Events.swift',
    '//  KeyflowEventsKit',
    '//',
    '//  Canonical event taxonomy for the Keyflow ecosystem.',
    '//  DO NOT edit by hand — generated from ../events.json.',
    '//  Keep in lockstep with keyflow-auth/src/lib/events.ts.',
    '//',
    '',
    'import Foundation',
    '',
    'public enum KeyflowEvent: String, CaseIterable, Sendable {',
  ]
  for (const cat of spec.categories) {
    lines.push(`    // MARK: ${cat.name}`)
    for (const ev of cat.events) {
      lines.push(`    case ${toCamel(ev.key)} = "${ev.key}"`)
    }
    lines.push('')
  }
  // trim trailing blank line
  while (lines[lines.length - 1] === '') lines.pop()
  lines.push('}')
  lines.push('')
  lines.push('public enum KeyflowProductId: String, Sendable {')
  lines.push('    case leadsflow')
  lines.push('    case dealsflow')
  lines.push('    case leaseflow')
  lines.push('    case auth')
  lines.push('    case connect')
  lines.push('}')
  lines.push('')
  return lines.join('\n')
}

function renderTs() {
  const lines = [
    '// Canonical event taxonomy for the Keyflow ecosystem.',
    '// DO NOT edit by hand — generated from keyflow-auth-kit/events.json.',
    '// Keep in lockstep with keyflow-auth-kit/Sources/KeyflowEventsKit/Events.swift.',
    '',
    'export const KeyflowEvent = {',
  ]
  for (const cat of spec.categories) {
    lines.push(`  // ${cat.name}`)
    for (const ev of cat.events) {
      lines.push(`  ${toPascal(ev.key)}: '${ev.key}',`)
    }
    lines.push('')
  }
  while (lines[lines.length - 1] === '') lines.pop()
  lines.push('} as const')
  lines.push('')
  lines.push('export type KeyflowEventKey = typeof KeyflowEvent[keyof typeof KeyflowEvent]')
  lines.push('')
  lines.push('export const KeyflowProductId = {')
  lines.push("  Leadsflow: 'leadsflow',")
  lines.push("  Dealsflow: 'dealsflow',")
  lines.push("  Leaseflow: 'leaseflow',")
  lines.push("  Auth: 'auth',")
  lines.push("  Connect: 'connect',")
  lines.push('} as const')
  lines.push('')
  lines.push('export type KeyflowProductIdValue = typeof KeyflowProductId[keyof typeof KeyflowProductId]')
  lines.push('')
  return lines.join('\n')
}

writeFileSync(swiftPath, renderSwift())
console.log(`wrote ${swiftPath}`)

const tsFlag = process.argv.indexOf('--ts')
if (tsFlag !== -1 && process.argv[tsFlag + 1]) {
  const tsPath = resolve(process.cwd(), process.argv[tsFlag + 1])
  writeFileSync(tsPath, renderTs())
  console.log(`wrote ${tsPath}`)
}
