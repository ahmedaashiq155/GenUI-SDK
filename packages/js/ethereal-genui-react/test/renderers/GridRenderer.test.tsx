import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { GridRenderer } from '../../src/components/renderers/GridRenderer.js'

describe('GridRenderer', () => {
  it('renders children in a grid layout', () => {
    const { container } = render(
      <GridRenderer
        spec={{ type: 'grid', columns: 2, children: [{ type: 'badges', items: ['A'] }, { type: 'badges', items: ['B'] }] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('A')).toBeDefined()
    expect(screen.getByText('B')).toBeDefined()
  })

  it('defaults to 2 columns', () => {
    const { container } = render(<GridRenderer spec={{ type: 'grid', children: [] }} onSend={vi.fn()} />)
    expect(container.firstChild).toBeDefined()
    const el = container.firstElementChild as HTMLElement
    expect(el.style.gridTemplateColumns).toBe('repeat(2, 1fr)')
  })

  it('respects custom column count', () => {
    const { container } = render(<GridRenderer spec={{ type: 'grid', columns: 3, children: [] }} onSend={vi.fn()} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.gridTemplateColumns).toBe('repeat(3, 1fr)')
  })

  it('renders empty grid without crashing', () => {
    const { container } = render(<GridRenderer spec={{ type: 'grid', columns: 2, children: [] }} onSend={vi.fn()} />)
    expect(container.firstChild).toBeDefined()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <GridRenderer spec={{ type: 'grid', children: [] }} onSend={vi.fn()} className="grid-cls" style={{ gap: '4px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('grid-cls')
    expect(el.style.gap).toBe('4px')
  })
})
