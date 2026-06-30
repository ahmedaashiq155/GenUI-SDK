import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { FormRenderer } from '../../src/components/renderers/FormRenderer.js'

const basicSpec = {
  type: 'form',
  title: 'Booking',
  fields: [
    { key: 'name', label: 'Name', type: 'text' },
    { key: 'guests', label: 'Guests', type: 'number' },
  ],
  submitLabel: 'Submit',
}

describe('FormRenderer', () => {
  it('renders field labels', () => {
    render(<FormRenderer spec={basicSpec} onSend={vi.fn()} />)
    expect(screen.getByText('Name')).toBeDefined()
    expect(screen.getByText('Guests')).toBeDefined()
  })

  it('renders submit button', () => {
    render(<FormRenderer spec={basicSpec} onSend={vi.fn()} />)
    expect(screen.getByRole('button', { name: 'Submit' })).toBeDefined()
  })

  it('calls onSend with filled field values on submit', () => {
    const onSend = vi.fn()
    render(<FormRenderer spec={basicSpec} onSend={onSend} />)
    const inputs = screen.getAllByRole('textbox')
    fireEvent.change(inputs[0], { target: { value: 'Alice' } })
    fireEvent.click(screen.getByRole('button', { name: 'Submit' }))
    expect(onSend).toHaveBeenCalledWith(expect.stringContaining('Name: Alice'))
  })

  it('omits empty fields from message', () => {
    const onSend = vi.fn()
    render(<FormRenderer spec={basicSpec} onSend={onSend} />)
    fireEvent.click(screen.getByRole('button', { name: 'Submit' }))
    // empty submit should produce empty string or only non-empty fields
    const call = onSend.mock.calls[0]?.[0] as string
    expect(call).not.toContain('Name:')
  })

  it('renders select type fields', () => {
    render(<FormRenderer spec={{
      type: 'form',
      fields: [{ key: 'seat', label: 'Seating', type: 'select', options: ['Indoor', 'Outdoor'] }],
    }} onSend={vi.fn()} />)
    expect(screen.getByText('Indoor')).toBeDefined()
    expect(screen.getByText('Outdoor')).toBeDefined()
  })

  it('renders toggle type fields as checkbox', () => {
    render(<FormRenderer spec={{
      type: 'form',
      fields: [{ key: 'vip', label: 'VIP', type: 'toggle' }],
    }} onSend={vi.fn()} />)
    expect(screen.getByRole('checkbox')).toBeDefined()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <FormRenderer spec={{ type: 'form', fields: [] }} onSend={vi.fn()} className="form-cls" style={{ gap: '10px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('form-cls')
    expect(el.style.gap).toBe('10px')
  })
})
