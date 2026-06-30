import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { CalloutRenderer } from '../../src/components/renderers/CalloutRenderer.js'

describe('CalloutRenderer', () => {
  it('renders info style with title and text', () => {
    render(
      <CalloutRenderer
        spec={{ type: 'callout', style: 'info', title: 'Note', text: 'This is important' }}
      />
    )
    expect(screen.getByText('Note')).toBeDefined()
    expect(screen.getByText('This is important')).toBeDefined()
  })

  it('renders warn style', () => {
    const { container } = render(
      <CalloutRenderer spec={{ type: 'callout', style: 'warn', title: 'Warning' }} />
    )
    expect(container.firstChild).toBeDefined()
    expect(screen.getByText('Warning')).toBeDefined()
  })

  it('renders success style', () => {
    const { container } = render(
      <CalloutRenderer spec={{ type: 'callout', style: 'success', text: 'Done!' }} />
    )
    expect(container.firstChild).toBeDefined()
    expect(screen.getByText('Done!')).toBeDefined()
  })

  it('defaults to info when no style provided', () => {
    const { container } = render(
      <CalloutRenderer spec={{ type: 'callout', text: 'Hello' }} />
    )
    expect(container.firstChild).toBeDefined()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <CalloutRenderer spec={{ type: 'callout' }} className="co-cls" style={{ opacity: '0.9' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('co-cls')
    expect(el.style.opacity).toBe('0.9')
  })
})
