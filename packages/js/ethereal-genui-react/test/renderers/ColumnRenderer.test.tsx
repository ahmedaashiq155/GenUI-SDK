import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { ColumnRenderer } from '../../src/components/renderers/ColumnRenderer.js'

describe('ColumnRenderer', () => {
  it('renders all children', () => {
    render(
      <ColumnRenderer
        spec={{
          type: 'column',
          children: [
            { type: 'badges', items: ['A'] },
            { type: 'badges', items: ['B'] },
          ],
        }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('A')).toBeDefined()
    expect(screen.getByText('B')).toBeDefined()
  })

  it('applies gap from spec', () => {
    const { container } = render(
      <ColumnRenderer
        spec={{ type: 'column', children: [], gap: 12 }}
        onSend={vi.fn()}
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.style.gap).toBe('12px')
  })

  it('has flex-direction column', () => {
    const { container } = render(
      <ColumnRenderer spec={{ type: 'column', children: [] }} onSend={vi.fn()} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.style.flexDirection).toBe('column')
  })

  it('has minHeight 0', () => {
    const { container } = render(
      <ColumnRenderer spec={{ type: 'column', children: [] }} onSend={vi.fn()} />
    )
    const el = container.firstElementChild as HTMLElement
    // jsdom stores '0' not '0px'
    expect(['0', '0px']).toContain(el.style.minHeight)
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <ColumnRenderer spec={{ type: 'column', children: [] }} className="col-cls" style={{ padding: '4px' }} onSend={vi.fn()} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('col-cls')
    expect(el.style.padding).toBe('4px')
  })
})
