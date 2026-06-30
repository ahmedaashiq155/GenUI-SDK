import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { InputRenderer } from '../../src/components/renderers/InputRenderer.js'

describe('InputRenderer', () => {
  it('renders textarea and submit button', () => {
    render(<InputRenderer spec={{ type: 'input', label: 'Your name?' }} onSend={vi.fn()} />)
    expect(screen.getByText('Your name?')).toBeDefined()
    expect(screen.getByRole('button', { name: 'Send' })).toBeDefined()
  })

  it('submit button disabled when empty', () => {
    render(<InputRenderer spec={{ type: 'input' }} onSend={vi.fn()} />)
    const btn = screen.getByRole('button', { name: 'Send' })
    expect(btn.hasAttribute('disabled')).toBe(true)
  })

  it('calls onSend with trimmed text on submit', () => {
    const onSend = vi.fn()
    render(<InputRenderer spec={{ type: 'input' }} onSend={onSend} />)
    const textarea = screen.getByRole('textbox')
    fireEvent.change(textarea, { target: { value: '  Hello  ' } })
    fireEvent.click(screen.getByRole('button', { name: 'Send' }))
    expect(onSend).toHaveBeenCalledWith('Hello')
  })

  it('renders custom submitLabel', () => {
    render(<InputRenderer spec={{ type: 'input', submitLabel: 'Go' }} onSend={vi.fn()} />)
    expect(screen.getByRole('button', { name: 'Go' })).toBeDefined()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <InputRenderer spec={{ type: 'input' }} onSend={vi.fn()} className="inp-cls" style={{ border: '1px solid red' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('inp-cls')
    expect(el.style.border).toBe('1px solid red')
  })
})
