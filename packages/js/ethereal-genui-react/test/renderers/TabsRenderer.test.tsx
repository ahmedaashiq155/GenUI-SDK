import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { TabsRenderer } from '../../src/components/renderers/TabsRenderer.js'

describe('TabsRenderer', () => {
  it('renders tab labels', () => {
    render(
      <TabsRenderer
        spec={{ type: 'tabs', tabs: [{ label: 'Tab A', text: 'Content A' }, { label: 'Tab B', text: 'Content B' }] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('Tab A')).toBeDefined()
    expect(screen.getByText('Tab B')).toBeDefined()
  })

  it('shows first tab content by default', () => {
    render(
      <TabsRenderer
        spec={{ type: 'tabs', tabs: [{ label: 'Tab A', text: 'Content A' }, { label: 'Tab B', text: 'Content B' }] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.queryByText('Content A')).not.toBeNull()
    expect(screen.queryByText('Content B')).toBeNull()
  })

  it('clicking second tab shows its content', () => {
    render(
      <TabsRenderer
        spec={{ type: 'tabs', tabs: [{ label: 'Tab A', text: 'Content A' }, { label: 'Tab B', text: 'Content B' }] }}
        onSend={vi.fn()}
      />
    )
    fireEvent.click(screen.getByText('Tab B'))
    expect(screen.queryByText('Content B')).not.toBeNull()
    expect(screen.queryByText('Content A')).toBeNull()
  })

  it('returns null for empty tabs', () => {
    const { container } = render(<TabsRenderer spec={{ type: 'tabs', tabs: [] }} onSend={vi.fn()} />)
    expect(container.firstChild).toBeNull()
  })

  it('renders tab content via GenUiBlock when content is object', () => {
    render(
      <TabsRenderer
        spec={{ type: 'tabs', tabs: [{ label: 'Tab A', content: { type: 'badges', items: ['tab-badge'] } }] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.queryByText('tab-badge')).not.toBeNull()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <TabsRenderer
        spec={{ type: 'tabs', tabs: [{ label: 'Tab A', text: 'Content' }] }}
        onSend={vi.fn()}
        className="tabs-cls"
        style={{ margin: '4px' }}
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('tabs-cls')
    expect(el.style.margin).toBe('4px')
  })
})
