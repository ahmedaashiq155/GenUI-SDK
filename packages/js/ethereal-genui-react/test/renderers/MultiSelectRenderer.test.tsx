import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { MultiSelectRenderer } from '../../src/components/renderers/MultiSelectRenderer.js'

describe('MultiSelectRenderer', () => {
  it('renders options as toggleable pills', () => {
    render(<MultiSelectRenderer spec={{ type: 'multiselect', options: ['Cheese', 'Olives'] }} onSend={vi.fn()} />)
    expect(screen.getByText('Cheese')).toBeDefined()
    expect(screen.getByText('Olives')).toBeDefined()
  })

  it('submit button disabled when nothing selected', () => {
    render(<MultiSelectRenderer spec={{ type: 'multiselect', options: ['Cheese'], submitLabel: 'Order' }} onSend={vi.fn()} />)
    const btn = screen.getByRole('button', { name: 'Order' })
    expect(btn.hasAttribute('disabled')).toBe(true)
  })

  it('calls onSend with joined selection on submit', () => {
    const onSend = vi.fn()
    render(<MultiSelectRenderer spec={{ type: 'multiselect', options: ['Cheese', 'Olives'], submitLabel: 'Order' }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Cheese'))
    fireEvent.click(screen.getByText('Olives'))
    fireEvent.click(screen.getByRole('button', { name: 'Order' }))
    expect(onSend).toHaveBeenCalledWith('Cheese, Olives')
  })

  it('toggles option off when clicked again', () => {
    const onSend = vi.fn()
    render(<MultiSelectRenderer spec={{ type: 'multiselect', options: ['Cheese'], submitLabel: 'Order' }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Cheese'))
    fireEvent.click(screen.getByText('Cheese')) // toggle off
    const btn = screen.getByRole('button', { name: 'Order' })
    expect(btn.hasAttribute('disabled')).toBe(true)
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <MultiSelectRenderer spec={{ type: 'multiselect', options: [] }} onSend={vi.fn()} className="ms-cls" style={{ padding: '5px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('ms-cls')
    expect(el.style.padding).toBe('5px')
  })
})
