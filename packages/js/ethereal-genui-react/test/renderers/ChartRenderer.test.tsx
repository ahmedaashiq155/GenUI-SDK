import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { ChartRenderer } from '../../src/components/renderers/ChartRenderer.js'

describe('ChartRenderer', () => {
  it('renders a consistent empty state for empty data', () => {
    render(
      <ChartRenderer spec={{ type: 'chart', chart: 'bar', data: [] }} onSend={vi.fn()} />
    )
    expect(screen.getByRole('status', { name: 'No chart data' })).toBeDefined()
  })

  it('renders an empty state when data is missing', () => {
    render(
      <ChartRenderer spec={{ type: 'chart', chart: 'bar' }} onSend={vi.fn()} />
    )
    expect(screen.getByText('No chart data')).toBeDefined()
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
    expect(container.querySelector('polygon')).toBeNull()
  })

  it('renders a filled area chart with area semantics', () => {
    const { container } = render(
      <ChartRenderer
        spec={{
          type: 'chart',
          chart: 'area',
          title: 'Traffic',
          data: [{ label: 'Mon', value: 3 }, { label: 'Tue', value: 7 }],
        }}
        onSend={vi.fn()}
      />
    )
    expect(container.querySelector('polyline')).not.toBeNull()
    expect(container.querySelector('polygon')).not.toBeNull()
    expect(container.querySelector('[role="img"]')?.getAttribute('aria-label'))
      .toBe('Traffic. Area chart: Mon 3, Tue 7')
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
