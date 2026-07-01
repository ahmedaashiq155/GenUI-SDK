import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { GenUiPlaceholder } from '../src/components/GenUiPlaceholder.js'

describe('GenUiPlaceholder', () => {
  it('renders "Preparing…" when no type is given', () => {
    render(<GenUiPlaceholder />)
    expect(screen.getByText('Preparing…')).toBeDefined()
  })

  it('renders "Unsupported block: {type}" when a type is given', () => {
    render(<GenUiPlaceholder type="mystery" />)
    expect(screen.getByText('Unsupported block: mystery')).toBeDefined()
  })

  it('forwards className and style', () => {
    const { container } = render(
      <GenUiPlaceholder type="foo" className="my-class" style={{ color: 'red' }} />
    )
    const el = container.firstChild as HTMLElement
    expect(el.className).toBe('my-class')
    expect(el.style.color).toBe('red')
  })
})
