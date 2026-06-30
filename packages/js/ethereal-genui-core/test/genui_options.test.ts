import { describe, it, expect } from 'vitest'
import { readFileSync } from 'fs'
import { resolve } from 'path'
import { fileURLToPath } from 'url'
import { genUiOptions } from '../src/genui_options.js'

const root = resolve(fileURLToPath(import.meta.url), '../../../../..')

describe('genUiOptions parity', () => {
  it('matches Dart fixture exactly', () => {
    const fixture = JSON.parse(readFileSync(resolve(root, 'schema/genui_options_fixture.json'), 'utf8'))
    const input = [
      { label: 'Alpha', value: 'a' },
      { text: 'Beta', value: 'b' },
      { name: 'Gamma', value: 'c' },
      { value: 'd' },
    ]
    const result = genUiOptions(input).map(o => ({ label: o.label, value: o.value }))
    expect(result).toEqual(fixture)
  })
  it('handles plain strings', () => {
    const result = genUiOptions(['Yes', 'No'])
    expect(result).toEqual([
      { label: 'Yes', value: 'Yes', checked: false },
      { label: 'No', value: 'No', checked: false },
    ])
  })
  it('handles non-array input', () => {
    expect(genUiOptions(null)).toEqual([])
    expect(genUiOptions(undefined)).toEqual([])
    expect(genUiOptions('string')).toEqual([])
  })
})
