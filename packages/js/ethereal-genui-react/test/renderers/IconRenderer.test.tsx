import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { IconRenderer } from '../../src/components/renderers/IconRenderer.js'

describe('IconRenderer', () => {
  it('renders known icon name as mapped character', () => {
    const { container } = render(<IconRenderer spec={{ type: 'icon', icon: 'star' }} />)
    expect(container.textContent).toBe('★')
  })

  it('renders heart icon', () => {
    const { container } = render(<IconRenderer spec={{ type: 'icon', icon: 'heart' }} />)
    expect(container.textContent).toBe('♥')
  })

  it('renders unknown icon name as bullet dot', () => {
    const { container } = render(<IconRenderer spec={{ type: 'icon', icon: 'unknownxyz' }} />)
    expect(container.textContent).toBe('•')
  })

  it('applies font size from spec', () => {
    const { container } = render(<IconRenderer spec={{ type: 'icon', icon: 'star', size: 30 }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.fontSize).toBe('30px')
  })

  it('applies hex color from spec', () => {
    const { container } = render(<IconRenderer spec={{ type: 'icon', icon: 'star', color: '#FF0000' }} />)
    const el = container.firstElementChild as HTMLElement
    // jsdom normalizes hex to rgb; verify it's not the fallback CSS var
    expect(el.style.color).not.toBe('')
    expect(el.style.color).not.toContain('var(')
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <IconRenderer spec={{ type: 'icon', icon: 'star' }} className="icon-cls" style={{ margin: '2px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('icon-cls')
    expect(el.style.margin).toBe('2px')
  })
})
