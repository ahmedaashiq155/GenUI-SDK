import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { StatRenderer } from '../../src/components/renderers/StatRenderer.js'

describe('StatRenderer', () => {
  it('renders stat values', () => {
    render(
      <StatRenderer
        spec={{ type: 'stat', stats: [{ label: 'Users', value: '1.2k' }, { label: 'Revenue', value: '$42k' }] }}
      />
    )
    expect(screen.getByText('1.2k')).toBeDefined()
    expect(screen.getByText('$42k')).toBeDefined()
  })

  it('renders stat labels', () => {
    render(
      <StatRenderer
        spec={{ type: 'stat', stats: [{ label: 'Users', value: '100' }] }}
      />
    )
    // text-transform: uppercase is CSS — DOM content is the raw label
    expect(screen.getByText('Users')).toBeDefined()
  })

  it('renders multiple stats side by side', () => {
    const { container } = render(
      <StatRenderer
        spec={{ type: 'stat', stats: [{ label: 'A', value: '1' }, { label: 'B', value: '2' }] }}
      />
    )
    expect(container.textContent).toContain('1')
    expect(container.textContent).toContain('2')
  })

  it('falls back to items when stats is absent', () => {
    render(
      <StatRenderer
        spec={{ type: 'stat', items: [{ label: 'Count', value: '42' }] }}
      />
    )
    expect(screen.getByText('42')).toBeDefined()
  })

  it('renders optional title', () => {
    render(
      <StatRenderer spec={{ type: 'stat', title: 'Dashboard', stats: [] }} />
    )
    expect(screen.getByText('Dashboard')).toBeDefined()
  })

  it('forwards className to root element', () => {
    const { container } = render(
      <StatRenderer spec={{ type: 'stat', stats: [] }} className="stat-cls" />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('stat-cls')
  })
})
