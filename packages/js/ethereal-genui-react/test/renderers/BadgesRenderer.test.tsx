import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { BadgesRenderer } from '../../src/components/renderers/BadgesRenderer.js'

describe('BadgesRenderer', () => {
  it('renders all badge labels', () => {
    render(<BadgesRenderer spec={{ type: 'badges', items: ['new', 'beta', 'v2'] }} />)
    expect(screen.getByText('new')).toBeDefined()
    expect(screen.getByText('beta')).toBeDefined()
    expect(screen.getByText('v2')).toBeDefined()
  })

  it('renders empty state without crashing', () => {
    render(<BadgesRenderer spec={{ type: 'badges', items: [] }} />)
    expect(screen.getByRole('status', { name: 'No badges' })).toBeDefined()
  })

  it('forwards className to root element', () => {
    const { container } = render(
      <BadgesRenderer spec={{ type: 'badges', items: [] }} className="badges-cls" />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('badges-cls')
  })
})
