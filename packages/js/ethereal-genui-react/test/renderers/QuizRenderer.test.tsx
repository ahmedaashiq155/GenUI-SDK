import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { QuizRenderer } from '../../src/components/renderers/QuizRenderer.js'

describe('QuizRenderer', () => {
  it('renders question and options', () => {
    render(<QuizRenderer spec={{ type: 'quiz', question: 'What is 2+2?', options: ['3', '4', '5'], answer: 1 }} onSend={vi.fn()} />)
    expect(screen.getByText('What is 2+2?')).toBeDefined()
    expect(screen.getByText('3')).toBeDefined()
    expect(screen.getByText('4')).toBeDefined()
    expect(screen.getByText('5')).toBeDefined()
  })

  it('does NOT call onSend when option clicked', () => {
    const onSend = vi.fn()
    render(<QuizRenderer spec={{ type: 'quiz', question: 'Q?', options: ['A', 'B'], answer: 1 }} onSend={onSend} />)
    fireEvent.click(screen.getByText('A'))
    expect(onSend).not.toHaveBeenCalled()
  })

  it('shows correct/wrong feedback after picking wrong answer', () => {
    const { container } = render(
      <QuizRenderer spec={{ type: 'quiz', question: 'Q?', options: ['A', 'B'], answer: 1 }} onSend={vi.fn()} />
    )
    fireEvent.click(screen.getByText('A')) // wrong
    expect(container.querySelector('[data-wrong]')).toBeTruthy()
    expect(container.querySelector('[data-correct]')).toBeTruthy()
  })

  it('shows explanation after answering', () => {
    render(<QuizRenderer spec={{ type: 'quiz', question: 'Q?', options: ['A', 'B'], answer: 0, explanation: 'Because A' }} onSend={vi.fn()} />)
    fireEvent.click(screen.getByText('A'))
    expect(screen.getByText('Because A')).toBeDefined()
  })

  it('cannot re-answer once picked', () => {
    const { container } = render(
      <QuizRenderer spec={{ type: 'quiz', question: 'Q?', options: ['A', 'B'], answer: 1 }} onSend={vi.fn()} />
    )
    fireEvent.click(screen.getByText('A')) // wrong pick
    // Clicking B after should not change feedback since already answered
    fireEvent.click(screen.getByText('B'))
    const wrongEls = container.querySelectorAll('[data-wrong]')
    expect(wrongEls.length).toBe(1) // still A, not B
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <QuizRenderer spec={{ type: 'quiz', question: 'Q?', options: [] }} onSend={vi.fn()} className="quiz-cls" style={{ padding: '5px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('quiz-cls')
    expect(el.style.padding).toBe('5px')
  })

  it('options are buttons, disabled after answering, with outcome in the accessible name', () => {
    render(<QuizRenderer spec={{ type: 'quiz', question: 'Q?', options: ['A', 'B'], answer: 1 }} onSend={vi.fn()} />)
    const a = screen.getByRole('button', { name: 'A' })
    expect(a.tagName).toBe('BUTTON')
    fireEvent.click(a) // wrong pick
    expect(screen.getByRole('button', { name: 'A — incorrect' }).hasAttribute('disabled')).toBe(true)
    expect(screen.getByRole('button', { name: 'B — correct answer' }).hasAttribute('disabled')).toBe(true)
  })
})
