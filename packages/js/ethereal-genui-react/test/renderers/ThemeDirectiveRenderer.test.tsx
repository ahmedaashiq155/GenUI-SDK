import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { ThemeDirectiveRenderer } from '../../src/components/renderers/ThemeDirectiveRenderer.js'
import { GenUiProvider } from '../../src/provider.js'

describe('ThemeDirectiveRenderer', () => {
  it('renders the accent swatch when valid hex provided', () => {
    const { container } = render(
      <ThemeDirectiveRenderer spec={{ type: 'theme', accent: '#8B93FF' }} />
    )
    // Check that a colored dot is rendered (div with background)
    const dots = Array.from(container.querySelectorAll('div')).filter(
      el => el.style.borderRadius === '50%'
    )
    expect(dots.length).toBeGreaterThan(0)
    // jsdom normalizes hex to rgb; just check it's not empty
    expect(dots[0].style.background).not.toBe('')
  })

  it('renders a suggestion prompt before applying', () => {
    const { container } = render(
      <ThemeDirectiveRenderer spec={{ type: 'theme', accent: '#8B93FF' }} />
    )
    expect(container.textContent).toContain('Suggested accent for this chat')
  })

  it('does NOT call setAccent on mount — waits for a user tap (consent gate)', () => {
    const setAccent = vi.fn()
    const actions = { sendMessage: vi.fn(), setAccent, enabled: true }
    render(
      <GenUiProvider actions={actions}>
        <ThemeDirectiveRenderer spec={{ type: 'theme', accent: '#FF0000' }} />
      </GenUiProvider>
    )
    expect(setAccent).not.toHaveBeenCalled()
  })

  it('applies the accent only after the user taps Apply', () => {
    const setAccent = vi.fn()
    const actions = { sendMessage: vi.fn(), setAccent, enabled: true }
    render(
      <GenUiProvider actions={actions}>
        <ThemeDirectiveRenderer spec={{ type: 'theme', accent: '#FF0000' }} />
      </GenUiProvider>
    )
    fireEvent.click(screen.getByRole('button', { name: 'Apply' }))
    expect(setAccent).toHaveBeenCalledWith('#FF0000')
    // Confirmed state, and no second application on repeat taps.
    expect(screen.queryByRole('button', { name: 'Apply' })).toBeNull()
  })

  it('does not offer Apply for invalid hex', () => {
    const setAccent = vi.fn()
    const actions = { sendMessage: vi.fn(), setAccent, enabled: true }
    render(
      <GenUiProvider actions={actions}>
        <ThemeDirectiveRenderer spec={{ type: 'theme', accent: 'notahex' }} />
      </GenUiProvider>
    )
    expect(screen.queryByRole('button', { name: 'Apply' })).toBeNull()
    expect(setAccent).not.toHaveBeenCalled()
  })

  it('does not crash without provider', () => {
    expect(() => {
      render(<ThemeDirectiveRenderer spec={{ type: 'theme', accent: '#aabbcc' }} />)
    }).not.toThrow()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <ThemeDirectiveRenderer
        spec={{ type: 'theme', accent: '#aabbcc' }}
        className="theme-cls"
        style={{ margin: '4px' }}
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('theme-cls')
    expect(el.style.margin).toBe('4px')
  })
})
