import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { RatingRenderer } from '../../src/components/renderers/RatingRenderer.js'

describe('RatingRenderer', () => {
  it('renders max stars', () => {
    const { container } = render(<RatingRenderer spec={{ type: 'rating', max: 5 }} onSend={vi.fn()} />)
    const buttons = container.querySelectorAll('button')
    expect(buttons.length).toBe(5)
  })

  it('calls onSend with rating string on star click', () => {
    const onSend = vi.fn()
    const { container } = render(<RatingRenderer spec={{ type: 'rating', max: 5 }} onSend={onSend} />)
    const buttons = container.querySelectorAll('button')
    fireEvent.click(buttons[2]) // 3rd star = rating 3
    expect(onSend).toHaveBeenCalledWith('3 out of 5')
  })

  it('renders label', () => {
    render(<RatingRenderer spec={{ type: 'rating', max: 5, label: 'Rate this' }} onSend={vi.fn()} />)
    expect(screen.getByText('Rate this')).toBeDefined()
  })

  it('fills stars up to selected value', () => {
    const { container } = render(<RatingRenderer spec={{ type: 'rating', max: 3 }} onSend={vi.fn()} />)
    const buttons = container.querySelectorAll('button')
    fireEvent.click(buttons[1]) // star 2
    expect(buttons[0].textContent).toBe('★')
    expect(buttons[1].textContent).toBe('★')
    expect(buttons[2].textContent).toBe('☆')
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <RatingRenderer spec={{ type: 'rating', max: 3 }} onSend={vi.fn()} className="rat-cls" style={{ padding: '8px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('rat-cls')
    expect(el.style.padding).toBe('8px')
  })
})
