import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { TextRenderer } from '../../src/components/renderers/TextRenderer.js'

describe('TextRenderer', () => {
  it('renders the text content', () => {
    const { container } = render(<TextRenderer spec={{ type: 'text', text: 'Hello world' }} />)
    expect(container.textContent).toBe('Hello world')
  })

  it('applies font size from spec', () => {
    const { container } = render(<TextRenderer spec={{ type: 'text', text: 'hi', size: 24 }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.fontSize).toBe('24px')
  })

  it('maps weight bold to 700', () => {
    const { container } = render(<TextRenderer spec={{ type: 'text', text: 'x', weight: 'bold' }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.fontWeight).toBe('700')
  })

  it('maps weight semibold to 600', () => {
    const { container } = render(<TextRenderer spec={{ type: 'text', text: 'x', weight: 'semibold' }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.fontWeight).toBe('600')
  })

  it('maps weight medium to 500', () => {
    const { container } = render(<TextRenderer spec={{ type: 'text', text: 'x', weight: 'medium' }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.fontWeight).toBe('500')
  })

  it('maps weight light to 300', () => {
    const { container } = render(<TextRenderer spec={{ type: 'text', text: 'x', weight: 'light' }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.fontWeight).toBe('300')
  })

  it('defaults unknown weight to 400', () => {
    const { container } = render(<TextRenderer spec={{ type: 'text', text: 'x', weight: 'thin' }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.fontWeight).toBe('400')
  })

  it('passes through hex color from spec', () => {
    const { container } = render(<TextRenderer spec={{ type: 'text', text: 'x', color: '#8B93FF' }} />)
    const el = container.firstElementChild as HTMLElement
    // jsdom normalizes hex to rgb; check it's not the fallback CSS var
    expect(el.style.color).not.toBe('')
    expect(el.style.color).not.toContain('var(')
  })

  it('maps align center', () => {
    const { container } = render(<TextRenderer spec={{ type: 'text', text: 'x', align: 'center' }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.textAlign).toBe('center')
  })

  it('maps align end to right', () => {
    const { container } = render(<TextRenderer spec={{ type: 'text', text: 'x', align: 'end' }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.textAlign).toBe('right')
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <TextRenderer spec={{ type: 'text', text: 'x' }} className="text-cls" style={{ margin: '4px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('text-cls')
    expect(el.style.margin).toBe('4px')
  })
})
