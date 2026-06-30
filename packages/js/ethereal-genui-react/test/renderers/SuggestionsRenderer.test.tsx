import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { SuggestionsRenderer } from '../../src/components/renderers/SuggestionsRenderer.js'

describe('SuggestionsRenderer', () => {
  it('renders suggestion chips', () => {
    render(<SuggestionsRenderer spec={{ type: 'suggestions', options: ['Tell me more', 'Give an example'] }} onSend={vi.fn()} />)
    expect(screen.getByText('Tell me more')).toBeDefined()
    expect(screen.getByText('Give an example')).toBeDefined()
  })

  it('calls onSend with option value on click', () => {
    const onSend = vi.fn()
    render(<SuggestionsRenderer spec={{ type: 'suggestions', options: ['Tell me more'] }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Tell me more'))
    expect(onSend).toHaveBeenCalledWith('Tell me more')
  })

  it('returns null when no options', () => {
    const { container } = render(<SuggestionsRenderer spec={{ type: 'suggestions', options: [] }} onSend={vi.fn()} />)
    expect(container.firstChild).toBeNull()
  })

  it('reads from suggestions alias', () => {
    render(<SuggestionsRenderer spec={{ type: 'suggestions', suggestions: ['Hello'] }} onSend={vi.fn()} />)
    expect(screen.getByText('Hello')).toBeDefined()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <SuggestionsRenderer spec={{ type: 'suggestions', options: ['Hi'] }} onSend={vi.fn()} className="sugg-cls" style={{ marginTop: '4px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('sugg-cls')
    expect(el.style.marginTop).toBe('4px')
  })
})
