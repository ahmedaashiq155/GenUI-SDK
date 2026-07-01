import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent, act } from '@testing-library/react'
import { ButtonRenderer } from '../../src/components/renderers/ButtonRenderer.js'
import { GenUiProvider, useOptionalGenUiStore } from '../../src/provider.js'
import { GenUiStore } from '../../src/store.js'

describe('ButtonRenderer', () => {
  it('renders the label', () => {
    render(<ButtonRenderer spec={{ type: 'button', label: 'Click me' }} onSend={vi.fn()} />)
    expect(screen.getByText('Click me')).toBeDefined()
  })

  it('calls onSend with label when no explicit send is set', () => {
    const onSend = vi.fn()
    render(<ButtonRenderer spec={{ type: 'button', label: 'Go' }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Go'))
    expect(onSend).toHaveBeenCalledWith('Go')
  })

  it('calls onSend with explicit send message', () => {
    const onSend = vi.fn()
    render(<ButtonRenderer spec={{ type: 'button', label: 'Go', send: 'do it' }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Go'))
    expect(onSend).toHaveBeenCalledWith('do it')
  })

  it('calls store.setValue for spec.set entries', () => {
    let storeRef: GenUiStore | null = null
    function Capture() {
      storeRef = useOptionalGenUiStore()
      return null
    }
    render(
      <GenUiProvider actions={{ sendMessage: vi.fn(), enabled: true }}>
        <Capture />
        <ButtonRenderer
          spec={{ type: 'button', label: 'Switch', set: { view: 'detail' } }}
          onSend={vi.fn()}
        />
      </GenUiProvider>
    )
    act(() => {
      fireEvent.click(screen.getByText('Switch'))
    })
    expect(storeRef!.getValue('view')).toBe('detail')
  })

  it('does not call onSend when set is provided and send is absent', () => {
    const onSend = vi.fn()
    render(
      <GenUiProvider actions={{ sendMessage: vi.fn(), enabled: true }}>
        <ButtonRenderer
          spec={{ type: 'button', label: 'Switch', set: { view: 'detail' } }}
          onSend={onSend}
        />
      </GenUiProvider>
    )
    fireEvent.click(screen.getByText('Switch'))
    expect(onSend).not.toHaveBeenCalled()
  })

  it('shows opacity 0.5 and cursor default when no action', () => {
    // No send, no label, no set — hasAction = false
    const { container } = render(
      <ButtonRenderer spec={{ type: 'button', label: '', send: '' }} />
    )
    // The button is inside a wrapper div
    const btn = container.querySelector('button') as HTMLButtonElement
    expect(btn.style.opacity).toBe('0.5')
    expect(btn.style.cursor).toBe('default')
  })

  it('renders leading icon at label-matched size and text color', () => {
    const { container } = render(
      <ButtonRenderer spec={{ type: 'button', label: 'Go', send: 'x', icon: 'rocket', style: 'primary' }} onSend={vi.fn()} />
    )
    const iconSpan = container.querySelector('span') as HTMLSpanElement
    expect(iconSpan.style.fontSize).toBe('18px')
    expect(iconSpan.style.color).toBe('var(--ethereal-on-accent)')
  })

  it('forwards className and style to button', () => {
    const { container } = render(
      <ButtonRenderer
        spec={{ type: 'button', label: 'X', send: 'x' }}
        className="btn-cls"
        style={{ margin: '3px' }}
      />
    )
    const btn = container.querySelector('button') as HTMLButtonElement
    expect(btn.className).toContain('btn-cls')
    expect(btn.style.margin).toBe('3px')
  })
})
