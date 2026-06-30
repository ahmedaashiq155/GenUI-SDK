import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { ChoicesRenderer } from '../src/components/renderers/ChoicesRenderer.js'

describe('ChoicesRenderer', () => {
  it('renders string options as buttons', () => {
    render(<ChoicesRenderer spec={{ type: 'choices', options: ['Yes', 'No'] }} onSend={vi.fn()} />)
    expect(screen.getByText('Yes')).toBeDefined()
    expect(screen.getByText('No')).toBeDefined()
  })
  it('renders object options using label', () => {
    render(
      <ChoicesRenderer
        spec={{ type: 'choices', options: [{ label: 'Accept', value: 'accept' }] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('Accept')).toBeDefined()
  })
  it('calls onSend with option value on click', () => {
    const onSend = vi.fn()
    render(<ChoicesRenderer spec={{ type: 'choices', options: ['Yes', 'No'] }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Yes'))
    expect(onSend).toHaveBeenCalledWith('Yes')
  })
  it('calls onSend with value (not label) for object options', () => {
    const onSend = vi.fn()
    render(
      <ChoicesRenderer
        spec={{ type: 'choices', options: [{ label: 'Accept', value: 'accept_action' }] }}
        onSend={onSend}
      />
    )
    fireEvent.click(screen.getByText('Accept'))
    expect(onSend).toHaveBeenCalledWith('accept_action')
  })
  it('renders title when provided', () => {
    render(<ChoicesRenderer spec={{ type: 'choices', title: 'What next?', options: ['A'] }} onSend={vi.fn()} />)
    expect(screen.getByText('What next?')).toBeDefined()
  })
  it('omits title when not provided', () => {
    const { container } = render(<ChoicesRenderer spec={{ type: 'choices', options: ['A'] }} onSend={vi.fn()} />)
    expect(container.querySelector('p')).toBeNull()
  })
  it('forwards className and style to container', () => {
    const { container } = render(
      <ChoicesRenderer
        spec={{ type: 'choices', options: ['A'] }}
        onSend={vi.fn()}
        className="my-choices"
        style={{ marginTop: '8px' }}
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('my-choices')
    expect(el.style.marginTop).toBe('8px')
  })
})
