import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { ChecklistRenderer } from '../../src/components/renderers/ChecklistRenderer.js'

describe('ChecklistRenderer', () => {
  it('renders items', () => {
    render(<ChecklistRenderer spec={{ type: 'checklist', items: ['Buy milk', 'Call mom'] }} onSend={vi.fn()} />)
    expect(screen.getByText('Buy milk')).toBeDefined()
    expect(screen.getByText('Call mom')).toBeDefined()
  })

  it('submit button disabled when nothing checked', () => {
    render(<ChecklistRenderer spec={{ type: 'checklist', items: ['Buy milk'], submitLabel: 'Done' }} onSend={vi.fn()} />)
    const btn = screen.getByRole('button', { name: 'Done' })
    expect(btn.hasAttribute('disabled')).toBe(true)
  })

  it('calls onSend with checked labels on submit', () => {
    const onSend = vi.fn()
    render(<ChecklistRenderer spec={{ type: 'checklist', items: ['Buy milk', 'Call mom'], submitLabel: 'Done' }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Buy milk'))
    fireEvent.click(screen.getByRole('button', { name: 'Done' }))
    expect(onSend).toHaveBeenCalledWith('Buy milk')
  })

  it('respects initial checked state from spec', () => {
    const onSend = vi.fn()
    render(<ChecklistRenderer spec={{
      type: 'checklist',
      items: [{ label: 'Task 1', checked: true }, { label: 'Task 2', checked: false }],
      submitLabel: 'Done',
    }} onSend={onSend} />)
    fireEvent.click(screen.getByRole('button', { name: 'Done' }))
    expect(onSend).toHaveBeenCalledWith('Task 1')
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <ChecklistRenderer spec={{ type: 'checklist', items: [] }} onSend={vi.fn()} className="chk-cls" style={{ padding: '4px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('chk-cls')
    expect(el.style.padding).toBe('4px')
  })

  it('rows are checkboxes with aria-checked that toggles', () => {
    render(<ChecklistRenderer spec={{ type: 'checklist', items: ['Buy milk'] }} onSend={vi.fn()} />)
    const row = screen.getByRole('checkbox', { name: /Buy milk/ })
    expect(row.getAttribute('aria-checked')).toBe('false')
    fireEvent.click(row)
    expect(row.getAttribute('aria-checked')).toBe('true')
    fireEvent.click(row)
    expect(row.getAttribute('aria-checked')).toBe('false')
  })

  it('keeps checked state with the item value when items reorder', () => {
    const first = { type: 'checklist', items: [
      { label: 'First', value: 'first' },
      { label: 'Second', value: 'second' },
    ] }
    const { rerender } = render(<ChecklistRenderer spec={first} onSend={vi.fn()} />)
    fireEvent.click(screen.getByRole('checkbox', { name: /Second/ }))
    rerender(<ChecklistRenderer spec={{ ...first, items: [...first.items].reverse() }} onSend={vi.fn()} />)
    expect(screen.getByRole('checkbox', { name: /Second/ }).getAttribute('aria-checked')).toBe('true')
    expect(screen.getByRole('checkbox', { name: /First/ }).getAttribute('aria-checked')).toBe('false')
  })
})
