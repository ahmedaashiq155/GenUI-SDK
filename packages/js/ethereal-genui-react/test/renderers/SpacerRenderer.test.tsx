import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { SpacerRenderer } from '../../src/components/renderers/SpacerRenderer.js'

describe('SpacerRenderer', () => {
  it('renders a div with the given size', () => {
    const { container } = render(<SpacerRenderer spec={{ type: 'spacer', size: 12 }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.tagName.toLowerCase()).toBe('div')
    expect(el.style.width).toBe('12px')
    expect(el.style.height).toBe('12px')
  })

  it('uses default size 16 when not specified', () => {
    const { container } = render(<SpacerRenderer spec={{ type: 'spacer' }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.width).toBe('16px')
    expect(el.style.height).toBe('16px')
  })

  it('has flexShrink 0', () => {
    const { container } = render(<SpacerRenderer spec={{ type: 'spacer', size: 8 }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.flexShrink).toBe('0')
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <SpacerRenderer spec={{ type: 'spacer', size: 8 }} className="spacer-cls" style={{ display: 'block' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('spacer-cls')
    expect(el.style.display).toBe('block')
  })
})
