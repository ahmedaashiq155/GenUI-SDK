import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { StepperRenderer } from '../../src/components/renderers/StepperRenderer.js'

describe('StepperRenderer', () => {
  it('renders label and initial value', () => {
    render(<StepperRenderer spec={{ type: 'stepper', label: 'Guests', min: 1, max: 9, value: 2 }} onSend={vi.fn()} />)
    expect(screen.getByText('Guests')).toBeDefined()
    expect(screen.getByText('2')).toBeDefined()
  })

  it('increments value on + click', () => {
    render(<StepperRenderer spec={{ type: 'stepper', label: 'Guests', min: 1, max: 9, value: 2 }} onSend={vi.fn()} />)
    fireEvent.click(screen.getByText('+'))
    expect(screen.getByText('3')).toBeDefined()
  })

  it('decrements value on − click', () => {
    render(<StepperRenderer spec={{ type: 'stepper', label: 'Guests', min: 1, max: 9, value: 3 }} onSend={vi.fn()} />)
    fireEvent.click(screen.getByText('−'))
    expect(screen.getByText('2')).toBeDefined()
  })

  it('− button disabled at min', () => {
    render(<StepperRenderer spec={{ type: 'stepper', label: 'Guests', min: 1, max: 9, value: 1 }} onSend={vi.fn()} />)
    const minusBtn = screen.getByText('−').closest('button') as HTMLButtonElement
    expect(minusBtn.disabled).toBe(true)
  })

  it('calls onSend on send click', () => {
    const onSend = vi.fn()
    render(<StepperRenderer spec={{ type: 'stepper', label: 'Guests', min: 1, max: 9, value: 2 }} onSend={onSend} />)
    fireEvent.click(screen.getByText('→'))
    expect(onSend).toHaveBeenCalledWith('Guests: 2')
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <StepperRenderer spec={{ type: 'stepper', min: 0, max: 10, value: 5 }} onSend={vi.fn()} className="step-cls" style={{ padding: '6px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('step-cls')
    expect(el.style.padding).toBe('6px')
  })

  it('resyncs when a patch changes the configured value', () => {
    const { rerender } = render(<StepperRenderer spec={{ type: 'stepper', min: 1, max: 9, value: 2 }} onSend={vi.fn()} />)
    fireEvent.click(screen.getByText('+'))
    expect(screen.getByText('3')).toBeDefined()
    rerender(<StepperRenderer spec={{ type: 'stepper', min: 1, max: 9, value: 7 }} onSend={vi.fn()} />)
    expect(screen.getByText('7')).toBeDefined()
  })
})
