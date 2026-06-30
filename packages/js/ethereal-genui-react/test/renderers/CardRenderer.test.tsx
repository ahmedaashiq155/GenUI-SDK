import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { CardRenderer } from '../../src/components/renderers/CardRenderer.js'

describe('CardRenderer', () => {
  it('renders title and subtitle', () => {
    render(<CardRenderer spec={{ type: 'card', title: 'User', subtitle: 'Active' }} />)
    expect(screen.getByText('User')).toBeDefined()
    expect(screen.getByText('Active')).toBeDefined()
  })

  it('renders items as label/value rows', () => {
    render(
      <CardRenderer
        spec={{ type: 'card', title: 'User', items: [{ label: 'Email', value: 'foo@bar.com' }] }}
      />
    )
    expect(screen.getByText('Email')).toBeDefined()
    expect(screen.getByText('foo@bar.com')).toBeDefined()
  })

  it('renders without subtitle or items', () => {
    render(<CardRenderer spec={{ type: 'card', title: 'Simple' }} />)
    expect(screen.getByText('Simple')).toBeDefined()
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <CardRenderer spec={{ type: 'card' }} className="card-cls" style={{ margin: '10px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('card-cls')
    expect(el.style.margin).toBe('10px')
  })
})
