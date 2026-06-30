import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { StackRenderer } from '../../src/components/renderers/StackRenderer.js'

describe('StackRenderer', () => {
  it('renders all children (even overlaid)', () => {
    render(
      <StackRenderer
        spec={{
          type: 'stack',
          children: [
            { type: 'badges', items: ['bottom'] },
            { type: 'badges', items: ['top'] },
          ],
        }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('bottom')).toBeDefined()
    expect(screen.getByText('top')).toBeDefined()
  })

  it('uses CSS grid for overlap layout', () => {
    const { container } = render(
      <StackRenderer
        spec={{ type: 'stack', children: [{ type: 'badges', items: ['x'] }] }}
        onSend={vi.fn()}
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.style.display).toBe('grid')
  })

  it('each child wrapper has correct gridArea', () => {
    const { container } = render(
      <StackRenderer
        spec={{
          type: 'stack',
          children: [
            { type: 'badges', items: ['a'] },
            { type: 'badges', items: ['b'] },
          ],
        }}
        onSend={vi.fn()}
      />
    )
    const root = container.firstElementChild as HTMLElement
    const wrappers = Array.from(root.children) as HTMLElement[]
    expect(wrappers.length).toBe(2)
    wrappers.forEach(w => {
      expect(w.style.gridArea).toBe('1 / 1 / 2 / 2')
    })
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <StackRenderer
        spec={{ type: 'stack', children: [] }}
        className="stack-cls"
        style={{ width: '100px' }}
        onSend={vi.fn()}
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('stack-cls')
    expect(el.style.width).toBe('100px')
  })
})
