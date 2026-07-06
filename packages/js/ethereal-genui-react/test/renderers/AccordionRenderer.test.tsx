import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { AccordionRenderer } from '../../src/components/renderers/AccordionRenderer.js'

describe('AccordionRenderer', () => {
  it('renders item titles', () => {
    render(
      <AccordionRenderer
        spec={{ type: 'accordion', items: [{ title: 'Item 1' }, { title: 'Item 2' }] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('Item 1')).toBeDefined()
    expect(screen.getByText('Item 2')).toBeDefined()
  })

  it('body is hidden by default', () => {
    render(
      <AccordionRenderer
        spec={{ type: 'accordion', items: [{ title: 'Q', text: 'Answer here' }] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.queryByText('Answer here')).toBeNull()
  })

  it('clicking header reveals body text', () => {
    render(
      <AccordionRenderer
        spec={{ type: 'accordion', items: [{ title: 'Q', text: 'Answer here' }] }}
        onSend={vi.fn()}
      />
    )
    fireEvent.click(screen.getByText('Q'))
    expect(screen.queryByText('Answer here')).not.toBeNull()
  })

  it('clicking open header closes it', () => {
    render(
      <AccordionRenderer
        spec={{ type: 'accordion', items: [{ title: 'Q', text: 'Answer here' }] }}
        onSend={vi.fn()}
      />
    )
    fireEvent.click(screen.getByText('Q'))
    expect(screen.queryByText('Answer here')).not.toBeNull()
    fireEvent.click(screen.getByText('Q'))
    expect(screen.queryByText('Answer here')).toBeNull()
  })

  it('renders child spec via GenUiBlock when content is object', () => {
    render(
      <AccordionRenderer
        spec={{ type: 'accordion', items: [{ title: 'Q', content: { type: 'badges', items: ['badge-child'] } }] }}
        onSend={vi.fn()}
      />
    )
    fireEvent.click(screen.getByText('Q'))
    expect(screen.queryByText('badge-child')).not.toBeNull()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <AccordionRenderer spec={{ type: 'accordion', items: [] }} onSend={vi.fn()} className="accordion-cls" style={{ margin: '4px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('accordion-cls')
    expect(el.style.margin).toBe('4px')
  })

  it('header is a real button with aria-expanded reflecting open state', () => {
    render(
      <AccordionRenderer
        spec={{ type: 'accordion', items: [{ title: 'Q', text: 'Answer here' }] }}
        onSend={vi.fn()}
      />
    )
    const header = screen.getByRole('button', { name: /Q/ })
    expect(header.tagName).toBe('BUTTON')
    expect(header.getAttribute('aria-expanded')).toBe('false')
    fireEvent.click(header)
    expect(header.getAttribute('aria-expanded')).toBe('true')
    expect(header.getAttribute('aria-controls')).toBeTruthy()
  })
})
