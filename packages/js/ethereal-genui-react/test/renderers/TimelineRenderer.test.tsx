import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { TimelineRenderer } from '../../src/components/renderers/TimelineRenderer.js'

describe('TimelineRenderer', () => {
  it('renders timeline items with titles', () => {
    render(
      <TimelineRenderer
        spec={{
          type: 'timeline',
          items: [
            { title: 'Order placed', done: true },
            { title: 'Shipped', done: false },
          ],
        }}
      />
    )
    expect(screen.getByText('Order placed')).toBeDefined()
    expect(screen.getByText('Shipped')).toBeDefined()
  })

  it('renders subtitle when present', () => {
    render(
      <TimelineRenderer
        spec={{
          type: 'timeline',
          items: [{ title: 'Order placed', subtitle: '2h ago', done: true }],
        }}
      />
    )
    expect(screen.getByText('2h ago')).toBeDefined()
  })

  it('falls back to steps key', () => {
    render(
      <TimelineRenderer
        spec={{ type: 'timeline', steps: [{ title: 'Step One', done: false }] }}
      />
    )
    expect(screen.getByText('Step One')).toBeDefined()
  })

  it('renders optional title', () => {
    render(
      <TimelineRenderer
        spec={{ type: 'timeline', title: 'Progress', items: [] }}
      />
    )
    expect(screen.getByText('Progress')).toBeDefined()
  })

  it('forwards className to root element', () => {
    const { container } = render(
      <TimelineRenderer spec={{ type: 'timeline', items: [] }} className="tl-cls" />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('tl-cls')
  })
})
