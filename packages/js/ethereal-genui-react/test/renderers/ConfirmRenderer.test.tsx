import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { ConfirmRenderer } from '../../src/components/renderers/ConfirmRenderer.js'

describe('ConfirmRenderer', () => {
  it('renders prompt text', () => {
    render(<ConfirmRenderer spec={{ type: 'confirm', prompt: 'Are you sure?' }} onSend={vi.fn()} />)
    expect(screen.getByText('Are you sure?')).toBeDefined()
  })

  it('renders default labels when not provided', () => {
    render(<ConfirmRenderer spec={{ type: 'confirm' }} onSend={vi.fn()} />)
    expect(screen.getByText('Yes')).toBeDefined()
    expect(screen.getByText('No')).toBeDefined()
  })

  it('calls onSend with confirmLabel on confirm', () => {
    const onSend = vi.fn()
    render(<ConfirmRenderer spec={{ type: 'confirm', confirmLabel: 'Delete', cancelLabel: 'Keep' }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Delete'))
    expect(onSend).toHaveBeenCalledWith('Delete')
  })

  it('calls onSend with cancelLabel on cancel', () => {
    const onSend = vi.fn()
    render(<ConfirmRenderer spec={{ type: 'confirm', confirmLabel: 'Delete', cancelLabel: 'Keep' }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Keep'))
    expect(onSend).toHaveBeenCalledWith('Keep')
  })

  it('falls back to title for prompt text', () => {
    render(<ConfirmRenderer spec={{ type: 'confirm', title: 'Confirm this?' }} onSend={vi.fn()} />)
    expect(screen.getByText('Confirm this?')).toBeDefined()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <ConfirmRenderer spec={{ type: 'confirm' }} onSend={vi.fn()} className="confirm-cls" style={{ padding: '10px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('confirm-cls')
    expect(el.style.padding).toBe('10px')
  })
})
