import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { RowRenderer } from '../../src/components/renderers/RowRenderer.js'

describe('RowRenderer', () => {
  it('renders all children', () => {
    render(
      <RowRenderer
        spec={{
          type: 'row',
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
      <RowRenderer
        spec={{ type: 'row', children: [], gap: 16 }}
        onSend={vi.fn()}
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.style.gap).toBe('16px')
  })

  it('has flex-direction row', () => {
    const { container } = render(
      <RowRenderer spec={{ type: 'row', children: [] }} onSend={vi.fn()} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.style.flexDirection).toBe('row')
  })

  it('omits gap for space-between alignment', () => {
    const { container } = render(
      <RowRenderer
        spec={{ type: 'row', children: [], align: 'between', gap: 8 }}
        onSend={vi.fn()}
      />
    )
    const el = container.firstElementChild as HTMLElement
    // gap should not be applied when spaced
    expect(el.style.gap).toBe('')
  })

  it('wraps children in flex:1 divs when expand is true', () => {
    const { container } = render(
      <RowRenderer
        spec={{
          type: 'row',
          expand: true,
          children: [{ type: 'badges', items: ['X'] }],
        }}
        onSend={vi.fn()}
      />
    )
    const wrapper = container.firstElementChild!.firstElementChild as HTMLElement
    // jsdom normalizes flex:1 to '1 1 0%'
    expect(wrapper.style.flex).toContain('1')
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <RowRenderer spec={{ type: 'row', children: [] }} className="row-cls" style={{ padding: '4px' }} onSend={vi.fn()} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('row-cls')
    expect(el.style.padding).toBe('4px')
  })
})
