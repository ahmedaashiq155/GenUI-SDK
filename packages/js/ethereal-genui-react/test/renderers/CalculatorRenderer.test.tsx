import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { CalculatorRenderer } from '../../src/components/renderers/CalculatorRenderer.js'

describe('CalculatorRenderer', () => {
  it('displays 0 initially', () => {
    const { container } = render(<CalculatorRenderer spec={{ type: 'calculator' }} />)
    const displayEl = container.querySelector('[style*="text-align: right"]') as HTMLElement
    expect(displayEl.textContent).toBe('0')
  })

  it('digit input updates display', () => {
    const { container } = render(<CalculatorRenderer spec={{ type: 'calculator' }} />)
    const displayEl = container.querySelector('[style*="text-align: right"]') as HTMLElement
    fireEvent.click(screen.getAllByText('5')[0])
    expect(displayEl.textContent).toBe('5')
  })

  it('computes 2+3=5', () => {
    const { container } = render(<CalculatorRenderer spec={{ type: 'calculator' }} />)
    const displayEl = container.querySelector('[style*="text-align: right"]') as HTMLElement
    fireEvent.click(screen.getByText('2'))
    fireEvent.click(screen.getByText('+'))
    fireEvent.click(screen.getAllByText('3')[0])
    fireEvent.click(screen.getByText('='))
    expect(displayEl.textContent).toBe('5')
  })

  it('computes 9÷3=3', () => {
    const { container } = render(<CalculatorRenderer spec={{ type: 'calculator' }} />)
    const displayEl = container.querySelector('[style*="text-align: right"]') as HTMLElement
    fireEvent.click(screen.getByText('9'))
    fireEvent.click(screen.getByText('÷'))
    fireEvent.click(screen.getAllByText('3')[0])
    fireEvent.click(screen.getByText('='))
    expect(displayEl.textContent).toBe('3')
  })

  it('C clears display to 0', () => {
    const { container } = render(<CalculatorRenderer spec={{ type: 'calculator' }} />)
    const displayEl = container.querySelector('[style*="text-align: right"]') as HTMLElement
    fireEvent.click(screen.getByText('7'))
    fireEvent.click(screen.getByText('C'))
    expect(displayEl.textContent).toBe('0')
  })

  it('forwards className to root element', () => {
    const { container } = render(
      <CalculatorRenderer spec={{ type: 'calculator' }} className="calc-cls" />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('calc-cls')
  })
})
