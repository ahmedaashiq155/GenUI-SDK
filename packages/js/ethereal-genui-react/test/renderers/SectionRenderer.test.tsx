import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { SectionRenderer } from '../../src/components/renderers/SectionRenderer.js'

describe('SectionRenderer', () => {
  it('renders title when provided', () => {
    render(<SectionRenderer spec={{ type: 'section', title: 'My Section', children: [] }} onSend={vi.fn()} />)
    expect(screen.getByText('My Section')).toBeDefined()
  })

  it('renders children via GenUiBlock', () => {
    render(<SectionRenderer spec={{ type: 'section', children: [{ type: 'badges', items: ['hello'] }] }} onSend={vi.fn()} />)
    expect(screen.getByText('hello')).toBeDefined()
  })

  it('renders without title when not provided', () => {
    const { container } = render(<SectionRenderer spec={{ type: 'section', children: [] }} onSend={vi.fn()} />)
    expect(container.firstChild).toBeDefined()
  })

  it('renders multiple children', () => {
    render(
      <SectionRenderer
        spec={{ type: 'section', children: [{ type: 'badges', items: ['A'] }, { type: 'badges', items: ['B'] }] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('A')).toBeDefined()
    expect(screen.getByText('B')).toBeDefined()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <SectionRenderer spec={{ type: 'section', children: [] }} onSend={vi.fn()} className="section-cls" style={{ padding: '8px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('section-cls')
    expect(el.style.padding).toBe('8px')
  })
})
