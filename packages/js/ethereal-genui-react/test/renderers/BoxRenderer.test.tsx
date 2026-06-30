import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { BoxRenderer } from '../../src/components/renderers/BoxRenderer.js'

describe('BoxRenderer', () => {
  it('renders a child spec via GenUiBlock', () => {
    render(
      <BoxRenderer
        spec={{ type: 'box', child: { type: 'badges', items: ['child-badge'] } }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('child-badge')).toBeDefined()
  })

  it('renders multiple children from children array', () => {
    render(
      <BoxRenderer
        spec={{
          type: 'box',
          children: [
            { type: 'badges', items: ['kid1'] },
            { type: 'badges', items: ['kid2'] },
          ],
        }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('kid1')).toBeDefined()
    expect(screen.getByText('kid2')).toBeDefined()
  })

  it('applies gradient background when gradient has 2+ colors', () => {
    const { container } = render(
      <BoxRenderer
        spec={{ type: 'box', gradient: ['#aaa', '#bbb'] }}
        onSend={vi.fn()}
      />
    )
    // The inner div (child of wrapper) has the background
    const inner = container.firstElementChild!.firstElementChild as HTMLElement
    expect(inner.style.background).toContain('linear-gradient')
  })

  it('calls onSend when send is set and box is clicked', () => {
    const onSend = vi.fn()
    const { container } = render(
      <BoxRenderer
        spec={{ type: 'box', send: 'open-box' }}
        onSend={onSend}
      />
    )
    const inner = container.firstElementChild!.firstElementChild as HTMLElement
    fireEvent.click(inner)
    expect(onSend).toHaveBeenCalledWith('open-box')
  })

  it('forwards className and style to inner div', () => {
    const { container } = render(
      <BoxRenderer
        spec={{ type: 'box' }}
        className="box-cls"
        style={{ border: '2px solid red' }}
        onSend={vi.fn()}
      />
    )
    const inner = container.firstElementChild!.firstElementChild as HTMLElement
    expect(inner.className).toBe('box-cls')
    expect(inner.style.border).toBe('2px solid red')
  })
})
