import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { ShortcutsDirectiveRenderer } from '../../src/components/renderers/ShortcutsDirectiveRenderer.js'
import { GenUiProvider } from '../../src/provider.js'

describe('ShortcutsDirectiveRenderer', () => {
  it('renders shortcut pills', () => {
    render(
      <ShortcutsDirectiveRenderer
        spec={{ type: 'shortcuts', items: ['Plan my week', 'Summarize a doc'] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('Plan my week')).toBeDefined()
    expect(screen.getByText('Summarize a doc')).toBeDefined()
  })

  it('clicking a pill calls onSend with the item text', () => {
    const onSend = vi.fn()
    render(
      <ShortcutsDirectiveRenderer
        spec={{ type: 'shortcuts', items: ['Do something'] }}
        onSend={onSend}
      />
    )
    fireEvent.click(screen.getByText('Do something'))
    expect(onSend).toHaveBeenCalledWith('Do something')
  })

  it('returns null for empty items array', () => {
    const { container } = render(
      <ShortcutsDirectiveRenderer
        spec={{ type: 'shortcuts', items: [] }}
        onSend={vi.fn()}
      />
    )
    expect(container.firstChild).toBeNull()
  })

  it('returns null when items are all empty strings', () => {
    const { container } = render(
      <ShortcutsDirectiveRenderer
        spec={{ type: 'shortcuts', items: ['', '   '] }}
        onSend={vi.fn()}
      />
    )
    expect(container.firstChild).toBeNull()
  })

  it('calls setShortcuts on mount with filtered items', () => {
    const setShortcuts = vi.fn()
    const actions = { sendMessage: vi.fn(), setShortcuts, enabled: true }
    render(
      <GenUiProvider actions={actions}>
        <ShortcutsDirectiveRenderer
          spec={{ type: 'shortcuts', items: ['Item A', 'Item B'] }}
          onSend={vi.fn()}
        />
      </GenUiProvider>
    )
    expect(setShortcuts).toHaveBeenCalledWith(['Item A', 'Item B'])
  })

  it('renders header text "Saved to your shortcuts"', () => {
    render(
      <ShortcutsDirectiveRenderer
        spec={{ type: 'shortcuts', items: ['x'] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('Saved to your shortcuts')).toBeDefined()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <ShortcutsDirectiveRenderer
        spec={{ type: 'shortcuts', items: ['x'] }}
        className="shortcuts-cls"
        style={{ margin: '4px' }}
        onSend={vi.fn()}
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('shortcuts-cls')
    expect(el.style.margin).toBe('4px')
  })
})
