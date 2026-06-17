#!/usr/bin/env tsx
// Installs Quartz v5 plugins from quartz.config.yaml without importing quartz.ts
// (which would trigger SCSS imports incompatible with tsx).
//
// Must be run from the quartz/ subdirectory with npx tsx:
//   npx tsx install-quartz-plugins.ts
//
// Expects quartz.config.yaml to be present in the current directory.

import { readFileSync } from "node:fs"
import { resolve } from "node:path"
import YAML from "yaml"
import { installPlugin, parsePluginSource, regeneratePluginIndex } from "./quartz/plugins/loader/gitLoader.js"

interface PluginEntry {
  source: string
  enabled: boolean
}

const configPath = resolve("quartz.config.yaml")
const config = YAML.parse(readFileSync(configPath, "utf-8")) as { plugins: PluginEntry[] }

const plugins: PluginEntry[] = config.plugins ?? []
let installed = 0
let failed = 0

for (const plugin of plugins) {
  if (!plugin.enabled) continue
  if (!plugin.source?.startsWith("github:")) continue

  try {
    const spec = parsePluginSource(plugin.source)
    await installPlugin(spec, { verbose: true })
    installed++
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err)
    console.error(`✗ Failed: ${plugin.source}: ${msg}`)
    failed++
  }
}

await regeneratePluginIndex({ verbose: true })
console.log(`\n✓ Done: ${installed} installed, ${failed} failed`)
