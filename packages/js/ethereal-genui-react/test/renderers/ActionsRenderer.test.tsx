import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { ActionsRenderer } from '../../src/components/renderers/ActionsRenderer.js'

describe('ActionsRenderer', () => {
  it('renders action buttons', () => {
    render(<ActionsRenderer spec={{ type: 'actions', actions: [{ label: 'Yes', send: 'yes_value' }] }} onSend={vi.fn()} />)
    expect(screen.getByText('Yes')).toBeDefined()
  })

  it('calls onSend with send value on click', () => {
    const onSend = vi.fn()
    render(<ActionsRenderer spec={{ type: 'actions', actions: [{ label: 'Yes', send: 'yes_value' }] }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Yes'))
    expect(onSend).toHaveBeenCalledWith('yes_value')
  })

  it('falls back to label when send is not set', () => {
    const onSend = vi.fn()
    render(<ActionsRenderer spec={{ type: 'actions', actions: [{ label: 'Cancel' }] }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Cancel'))
    expect(onSend).toHaveBeenCalledWith('Cancel')
  })

  it('renders title when provided', () => {
    render(<ActionsRenderer spec={{ type: 'actions', title: 'Choose action', actions: [{ label: 'OK' }] }} onSend={vi.fn()} />)
    expect(screen.getByText('Choose action')).toBeDefined()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <ActionsRenderer spec={{ type: 'actions', actions: [] }} onSend={vi.fn()} className="my-cls" style={{ marginTop: '8px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('my-cls')
    expect(el.style.marginTop).toBe('8px')
  })
})
