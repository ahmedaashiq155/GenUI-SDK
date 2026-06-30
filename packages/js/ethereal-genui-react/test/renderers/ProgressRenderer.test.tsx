import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { ProgressRenderer } from '../../src/components/renderers/ProgressRenderer.js'

describe('ProgressRenderer', () => {
  it('renders with value prop (0-1)', () => {
    render(<ProgressRenderer spec={{ type: 'progress', label: 'Loading', value: 0.6 }} />)
    expect(screen.getByText('Loading')).toBeDefined()
    expect(screen.getByText('60%')).toBeDefined()
  })

  it('accepts percent prop (0-100 range)', () => {
    render(<ProgressRenderer spec={{ type: 'progress', label: 'Done', percent: 75 }} />)
    expect(screen.getByText('Done')).toBeDefined()
    expect(screen.getByText('75%')).toBeDefined()
  })

  it('percent takes precedence over value', () => {
    render(<ProgressRenderer spec={{ type: 'progress', percent: 80, value: 0.2 }} />)
    expect(screen.getByText('80%')).toBeDefined()
  })

  it('clamps values outside 0-1', () => {
    render(<ProgressRenderer spec={{ type: 'progress', value: 1.5 }} />)
    expect(screen.getByText('100%')).toBeDefined()
  })

  it('defaults to 0 when no value or percent', () => {
    render(<ProgressRenderer spec={{ type: 'progress' }} />)
    expect(screen.getByText('0%')).toBeDefined()
  })

  it('forwards className to root element', () => {
    const { container } = render(
      <ProgressRenderer spec={{ type: 'progress', value: 0.5 }} className="prog-cls" />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('prog-cls')
  })
})
