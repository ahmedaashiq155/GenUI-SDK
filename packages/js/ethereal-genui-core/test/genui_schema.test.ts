import { describe, it, expect } from 'vitest'
import { readFileSync } from 'fs'
import { resolve } from 'path'
import { fileURLToPath } from 'url'
import { buildGenUiPromptCatalogue, validateGenUiSpec, genUiCatalog } from '../src/genui_schema.js'

const root = resolve(fileURLToPath(import.meta.url), '../../../../..')

describe('buildGenUiPromptCatalogue parity', () => {
  it('matches Dart fixture exactly', () => {
    const fixture = readFileSync(resolve(root, 'schema/genui_prompt_fixture.txt'), 'utf8')
    expect(buildGenUiPromptCatalogue()).toBe(fixture)
  })
})

describe('genUiCatalog', () => {
  it('contains exactly 44 block types from fixture', () => {
    const fixture = JSON.parse(readFileSync(resolve(root, 'schema/genui_block_types_fixture.json'), 'utf8'))
    const types = genUiCatalog.map(s => s.type).sort()
    expect(types).toEqual(fixture)
  })
})

describe('validateGenUiSpec', () => {
  it('valid spec returns isValid=true', () => {
    const result = validateGenUiSpec({ type: 'choices', options: ['A', 'B'] })
    expect(result.isValid).toBe(true)
    expect(result.issues).toHaveLength(0)
  })
  it('unknown type returns hasUnknownType=true', () => {
    const result = validateGenUiSpec({ type: 'unknown_block_type' })
    expect(result.isValid).toBe(false)
    expect(result.hasUnknownType).toBe(true)
    expect(result.issues[0].message).toContain('unknown type')
  })
  it('missing type field returns issue', () => {
    const result = validateGenUiSpec({ title: 'No type' })
    expect(result.isValid).toBe(false)
    expect(result.issues[0].message).toContain('missing "type"')
  })
  it('validates a nested block in when.child', () => {
    const result = validateGenUiSpec({
      type: 'when',
      key: 'view',
      child: { type: 'totally-bogus' },
    })
    expect(result.hasUnknownType).toBe(true)
    expect(result.issues[0].path).toBe('$.child')
  })
  it('non-object is valid (not a block)', () => {
    expect(validateGenUiSpec('hello').isValid).toBe(true)
    expect(validateGenUiSpec(null).isValid).toBe(true)
  })
})
