import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { GenUiBlockError } from '../src/components/GenUiBlockError.js'

describe('GenUiBlockError', () => {
  it('renders the "Couldn\'t render this" label', () => {
    render(<GenUiBlockError />)
    expect(screen.getByText("Couldn't render this")).toBeDefined()
  })

  it('forwards className and style', () => {
    const { container } = render(<GenUiBlockError className="err-class" style={{ color: 'blue' }} />)
    const el = container.firstChild as HTMLElement
    expect(el.className).toBe('err-class')
    expect(el.style.color).toBe('blue')
  })
})
