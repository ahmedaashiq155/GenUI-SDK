import { describe, it, expect, vi } from 'vitest'
import { render } from '@testing-library/react'
import { DividerRenderer } from '../../src/components/renderers/DividerRenderer.js'

describe('DividerRenderer', () => {
  it('renders a horizontal divider', () => {
    const { container } = render(<DividerRenderer />)
    expect(container.firstChild).toBeDefined()
  })

  it('forwards className', () => {
    const { container } = render(<DividerRenderer className="divider-cls" />)
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('divider-cls')
  })

  it('forwards style', () => {
    const { container } = render(<DividerRenderer style={{ marginTop: '20px' }} />)
    const el = container.firstElementChild as HTMLElement
    expect(el.style.marginTop).toBe('20px')
  })
})
