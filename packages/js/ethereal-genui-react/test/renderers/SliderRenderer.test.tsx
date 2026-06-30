import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { SliderRenderer } from '../../src/components/renderers/SliderRenderer.js'

describe('SliderRenderer', () => {
  it('renders a range input', () => {
    render(<SliderRenderer spec={{ type: 'slider', label: 'Spiciness', min: 0, max: 5 }} onSend={vi.fn()} />)
    expect(screen.getByRole('slider')).toBeDefined()
  })

  it('renders label', () => {
    render(<SliderRenderer spec={{ type: 'slider', label: 'Spiciness', min: 0, max: 5 }} onSend={vi.fn()} />)
    expect(screen.getByText('Spiciness')).toBeDefined()
  })

  it('calls onSend with value+unit on submit', () => {
    const onSend = vi.fn()
    render(<SliderRenderer spec={{ type: 'slider', min: 0, max: 5, value: 3, unit: '/5', submitLabel: 'Set' }} onSend={onSend} />)
    fireEvent.click(screen.getByRole('button', { name: 'Set' }))
    expect(onSend).toHaveBeenCalledWith('3/5')
  })

  it('displays initial value', () => {
    const { container } = render(
      <SliderRenderer spec={{ type: 'slider', min: 0, max: 10, value: 7, unit: '%' }} onSend={vi.fn()} />
    )
    expect(container.textContent).toContain('7%')
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <SliderRenderer spec={{ type: 'slider' }} onSend={vi.fn()} className="sl-cls" style={{ border: '1px solid blue' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('sl-cls')
    expect(el.style.border).toBe('1px solid blue')
  })
})
