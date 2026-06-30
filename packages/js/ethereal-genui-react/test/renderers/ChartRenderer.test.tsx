import { describe, it, expect, vi } from 'vitest'
import { render } from '@testing-library/react'
import { ChartRenderer } from '../../src/components/renderers/ChartRenderer.js'

describe('ChartRenderer', () => {
  it('returns null for empty data', () => {
    const { container } = render(
      <ChartRenderer spec={{ type: 'chart', chart: 'bar', data: [] }} onSend={vi.fn()} />
    )
    expect(container.firstChild).toBeNull()
  })

  it('returns null when data is missing', () => {
    const { container } = render(
      <ChartRenderer spec={{ type: 'chart', chart: 'bar' }} onSend={vi.fn()} />
    )
    expect(container.firstChild).toBeNull()
  })

  it('renders SVG for bar chart', () => {
    const { container } = render(
      <ChartRenderer
        spec={{
          type: 'chart',
          chart: 'bar',
          data: [{ label: 'Mon', value: 3 }, { label: 'Tue', value: 7 }],
        }}
        onSend={vi.fn()}
      />
    )
    expect(container.querySelector('svg')).not.toBeNull()
    expect(container.querySelector('rect')).not.toBeNull()
  })

  it('renders SVG for pie chart', () => {
    const { container } = render(
      <ChartRenderer
        spec={{
          type: 'chart',
          chart: 'pie',
          data: [{ label: 'A', value: 50 }, { label: 'B', value: 50 }],
        }}
        onSend={vi.fn()}
      />
    )
    expect(container.querySelector('svg')).not.toBeNull()
    expect(container.querySelector('path')).not.toBeNull()
  })

  it('renders SVG for line chart', () => {
    const { container } = render(
      <ChartRenderer
        spec={{
          type: 'chart',
          chart: 'line',
          data: [{ label: 'Mon', value: 3 }, { label: 'Tue', value: 7 }],
        }}
        onSend={vi.fn()}
      />
    )
    expect(container.querySelector('svg')).not.toBeNull()
    expect(container.querySelector('polyline')).not.toBeNull()
  })

  it('renders title when provided', () => {
    const { container } = render(
      <ChartRenderer
        spec={{
          type: 'chart',
          chart: 'bar',
          title: 'Weekly Stats',
          data: [{ label: 'Mon', value: 5 }],
        }}
        onSend={vi.fn()}
      />
    )
    expect(container.textContent).toContain('Weekly Stats')
  })

  it('line chart handles n=1 without NaN', () => {
    const { container } = render(
      <ChartRenderer
        spec={{
          type: 'chart',
          chart: 'line',
          data: [{ label: 'Only', value: 5 }],
        }}
        onSend={vi.fn()}
      />
    )
    const polyline = container.querySelector('polyline')
    expect(polyline).not.toBeNull()
    // points attribute should not contain NaN
    const points = polyline!.getAttribute('points') ?? ''
    expect(points).not.toContain('NaN')
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <ChartRenderer
        spec={{ type: 'chart', data: [{ label: 'A', value: 1 }] }}
        className="chart-cls"
        style={{ margin: '4px' }}
        onSend={vi.fn()}
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('chart-cls')
    expect(el.style.margin).toBe('4px')
  })
})
