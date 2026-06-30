import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { TableRenderer } from '../../src/components/renderers/TableRenderer.js'

describe('TableRenderer', () => {
  it('renders column headers and rows', () => {
    render(
      <TableRenderer
        spec={{ type: 'table', columns: ['Name', 'Score'], rows: [['Alice', '95'], ['Bob', '87']] }}
      />
    )
    expect(screen.getByText('Name')).toBeDefined()
    expect(screen.getByText('Score')).toBeDefined()
    expect(screen.getByText('Alice')).toBeDefined()
    expect(screen.getByText('95')).toBeDefined()
  })

  it('returns null for empty table', () => {
    const { container } = render(
      <TableRenderer spec={{ type: 'table', columns: [], rows: [] }} />
    )
    expect(container.firstChild).toBeNull()
  })

  it('returns null when columns and rows are both absent', () => {
    const { container } = render(
      <TableRenderer spec={{ type: 'table' }} />
    )
    expect(container.firstChild).toBeNull()
  })

  it('pads short rows with empty cells', () => {
    const { container } = render(
      <TableRenderer
        spec={{ type: 'table', columns: ['A', 'B'], rows: [['only-one']] }}
      />
    )
    // Should render without crashing and show the cell
    expect(container.textContent).toContain('only-one')
  })

  it('forwards className to root element', () => {
    const { container } = render(
      <TableRenderer
        spec={{ type: 'table', columns: ['X'], rows: [['y']] }}
        className="tbl-cls"
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('tbl-cls')
  })
})
