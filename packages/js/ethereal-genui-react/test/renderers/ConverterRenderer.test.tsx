import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { ConverterRenderer } from '../../src/components/renderers/ConverterRenderer.js'

describe('ConverterRenderer', () => {
  it('renders unit selects', () => {
    const { container } = render(
      <ConverterRenderer
        spec={{
          type: 'converter',
          units: [{ label: 'm', factor: 1 }, { label: 'km', factor: 1000 }],
        }}
      />
    )
    const selects = container.querySelectorAll('select')
    expect(selects.length).toBe(2)
  })

  it('shows converted result', () => {
    render(
      <ConverterRenderer
        spec={{
          type: 'converter',
          units: [{ label: 'm', factor: 1 }, { label: 'km', factor: 1000 }],
        }}
      />
    )
    // 1 m = 0.001 km
    expect(screen.getByText('0.0010')).toBeDefined()
  })

  it('uses default units when fewer than 2 provided', () => {
    const { container } = render(
      <ConverterRenderer spec={{ type: 'converter', units: [{ label: 'x', factor: 1 }] }} />
    )
    const selects = container.querySelectorAll('select')
    // should use default 4 units
    expect(selects[0].options.length).toBe(4)
  })

  it('renders optional title', () => {
    render(
      <ConverterRenderer
        spec={{
          type: 'converter',
          title: 'Length',
          units: [{ label: 'm', factor: 1 }, { label: 'km', factor: 1000 }],
        }}
      />
    )
    expect(screen.getByText('Length')).toBeDefined()
  })

  it('forwards className to root element', () => {
    const { container } = render(
      <ConverterRenderer
        spec={{ type: 'converter', units: [{ label: 'a', factor: 1 }, { label: 'b', factor: 2 }] }}
        className="conv-cls"
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('conv-cls')
  })

  it('resyncs unit definitions after a patch', () => {
    const { container, rerender } = render(
      <ConverterRenderer spec={{ type: 'converter', units: [{ label: 'm', factor: 1 }, { label: 'km', factor: 1000 }] }} />
    )
    rerender(<ConverterRenderer spec={{ type: 'converter', units: [{ label: 'cm', factor: 0.01 }, { label: 'm', factor: 1 }] }} />)
    const selects = container.querySelectorAll('select')
    expect(Array.from(selects[0].options).map(option => option.text)).toEqual(['cm', 'm'])
  })
})
