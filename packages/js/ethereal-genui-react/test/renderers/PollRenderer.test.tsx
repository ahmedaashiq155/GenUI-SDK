import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { PollRenderer } from '../../src/components/renderers/PollRenderer.js'

describe('PollRenderer', () => {
  it('renders poll options', () => {
    render(<PollRenderer spec={{ type: 'poll', options: ['Cats', 'Dogs'] }} onSend={vi.fn()} />)
    expect(screen.getByText('Cats')).toBeDefined()
    expect(screen.getByText('Dogs')).toBeDefined()
  })

  it('calls onSend with voted label on vote', () => {
    const onSend = vi.fn()
    render(<PollRenderer spec={{ type: 'poll', options: ['Cats', 'Dogs'] }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Cats'))
    expect(onSend).toHaveBeenCalledWith('Cats')
  })

  it('cannot vote twice', () => {
    const onSend = vi.fn()
    render(<PollRenderer spec={{ type: 'poll', options: ['Cats', 'Dogs'] }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Cats'))
    fireEvent.click(screen.getByText('Dogs')) // should not work after first vote
    expect(onSend).toHaveBeenCalledTimes(1)
  })

  it('shows percentages after voting', () => {
    const { container } = render(<PollRenderer spec={{ type: 'poll', options: [{ label: 'Cats', votes: 9 }, { label: 'Dogs', votes: 1 }] }} onSend={vi.fn()} />)
    fireEvent.click(screen.getByText('Cats'))
    // After voting, percentage text should appear
    expect(container.textContent).toMatch(/\d+%/)
  })

  it('works with object options (label+votes)', () => {
    render(<PollRenderer spec={{ type: 'poll', options: [{ label: 'Cats', votes: 12 }, { label: 'Dogs', votes: 8 }] }} onSend={vi.fn()} />)
    expect(screen.getByText('Cats')).toBeDefined()
    expect(screen.getByText('Dogs')).toBeDefined()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <PollRenderer spec={{ type: 'poll', options: [] }} onSend={vi.fn()} className="poll-cls" style={{ padding: '5px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('poll-cls')
    expect(el.style.padding).toBe('5px')
  })

  it('options are buttons; disabled after voting with aria-pressed on the voted one', () => {
    render(<PollRenderer spec={{ type: 'poll', options: ['Cats', 'Dogs'] }} onSend={vi.fn()} />)
    const cats = screen.getByRole('button', { name: /Cats/ })
    expect(cats.tagName).toBe('BUTTON')
    expect(cats.hasAttribute('disabled')).toBe(false)
    fireEvent.click(cats)
    expect(cats.getAttribute('aria-pressed')).toBe('true')
    expect(cats.hasAttribute('disabled')).toBe(true)
    const dogs = screen.getByRole('button', { name: /Dogs/ })
    expect(dogs.hasAttribute('disabled')).toBe(true)
    expect(dogs.getAttribute('aria-pressed')).toBe('false')
  })
})
