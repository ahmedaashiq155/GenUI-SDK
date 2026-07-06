import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { SliderRenderer } from '../src/components/renderers/SliderRenderer.js'
import { RatingRenderer } from '../src/components/renderers/RatingRenderer.js'
import { TabsRenderer } from '../src/components/renderers/TabsRenderer.js'
import { SegmentedRenderer } from '../src/components/renderers/SegmentedRenderer.js'
import { ProgressRenderer } from '../src/components/renderers/ProgressRenderer.js'
import { ChartRenderer, chartSemanticLabel } from '../src/components/renderers/ChartRenderer.js'
import { FormRenderer } from '../src/components/renderers/FormRenderer.js'
import { ConverterRenderer } from '../src/components/renderers/ConverterRenderer.js'
import { InputRenderer } from '../src/components/renderers/InputRenderer.js'

// Task 6e — accessibility contract for the remaining renderers.
describe('a11y: SliderRenderer', () => {
  it('range input is labelled by the spec label', () => {
    render(<SliderRenderer spec={{ type: 'slider', label: 'Temperature' }} onSend={vi.fn()} />)
    expect(screen.getByRole('slider', { name: 'Temperature' })).toBeDefined()
  })

  it('range input gets a fallback aria-label without a spec label', () => {
    render(<SliderRenderer spec={{ type: 'slider' }} onSend={vi.fn()} />)
    expect(screen.getByRole('slider', { name: 'Slider' })).toBeDefined()
  })
})

describe('a11y: RatingRenderer', () => {
  it('stars are labelled buttons with pressed state', () => {
    render(<RatingRenderer spec={{ type: 'rating', label: 'Rate us', max: 3 }} onSend={vi.fn()} />)
    expect(screen.getByRole('group', { name: 'Rate us' })).toBeDefined()
    const star2 = screen.getByRole('button', { name: 'Rate 2 out of 3' })
    expect(star2.getAttribute('aria-pressed')).toBe('false')
  })
})

describe('a11y: TabsRenderer', () => {
  it('exposes tablist/tab/tabpanel with aria-selected', () => {
    render(
      <TabsRenderer
        spec={{ type: 'tabs', tabs: [{ label: 'One', text: 'first' }, { label: 'Two', text: 'second' }] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByRole('tablist')).toBeDefined()
    const one = screen.getByRole('tab', { name: 'One' })
    const two = screen.getByRole('tab', { name: 'Two' })
    expect(one.getAttribute('aria-selected')).toBe('true')
    expect(two.getAttribute('aria-selected')).toBe('false')
    const panel = screen.getByRole('tabpanel')
    expect(panel.getAttribute('aria-labelledby')).toBe(one.id)
  })
})

describe('a11y: SegmentedRenderer', () => {
  it('renders a radiogroup of radios with aria-checked', () => {
    render(
      <SegmentedRenderer spec={{ type: 'segmented', title: 'Size', options: ['S', 'M'] }} onSend={vi.fn()} />
    )
    expect(screen.getByRole('radiogroup', { name: 'Size' })).toBeDefined()
    const s = screen.getByRole('radio', { name: 'S' })
    expect(s.getAttribute('aria-checked')).toBe('false')
  })
})

describe('a11y: ProgressRenderer', () => {
  it('exposes progressbar with value now/min/max', () => {
    render(<ProgressRenderer spec={{ type: 'progress', label: 'Upload', percent: 40 }} onSend={vi.fn()} />)
    const bar = screen.getByRole('progressbar', { name: 'Upload' })
    expect(bar.getAttribute('aria-valuenow')).toBe('40')
    expect(bar.getAttribute('aria-valuemin')).toBe('0')
    expect(bar.getAttribute('aria-valuemax')).toBe('100')
  })
})

describe('a11y: ChartRenderer', () => {
  it('chart is an img with a generated data summary', () => {
    render(
      <ChartRenderer
        spec={{ type: 'chart', chart: 'bar', title: 'Sales', data: [{ label: 'Mon', value: 3 }, { label: 'Tue', value: 5.5 }] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByRole('img', { name: 'Sales. Bar chart: Mon 3, Tue 5.5' })).toBeDefined()
  })

  it('chartSemanticLabel matches the Dart format', () => {
    expect(chartSemanticLabel('pie', undefined, [{ label: 'A', value: 1 }])).toBe('Pie chart: A 1')
    expect(chartSemanticLabel('line', 'T', [{ label: 'X', value: 2.25 }])).toBe('T. Line chart: X 2.3')
  })
})

describe('a11y: FormRenderer', () => {
  it('text and toggle fields are label-associated; select pills expose pressed state', () => {
    render(
      <FormRenderer
        spec={{
          type: 'form',
          fields: [
            { key: 'name', label: 'Name', type: 'text' },
            { key: 'vip', label: 'VIP', type: 'toggle' },
            { key: 'size', label: 'Size', type: 'select', options: ['S', 'M'] },
          ],
        }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByRole('textbox', { name: 'Name' })).toBeDefined()
    expect(screen.getByRole('checkbox', { name: 'VIP' })).toBeDefined()
    expect(screen.getByRole('group', { name: 'Size' })).toBeDefined()
    expect(screen.getByRole('button', { name: 'S' }).getAttribute('aria-pressed')).toBe('false')
  })
})

describe('a11y: ConverterRenderer', () => {
  it('value input and unit selects have accessible names', () => {
    render(<ConverterRenderer spec={{ type: 'converter', title: 'Distance' }} onSend={vi.fn()} />)
    expect(screen.getByRole('textbox', { name: 'Distance' })).toBeDefined()
    expect(screen.getByRole('combobox', { name: 'From unit' })).toBeDefined()
    expect(screen.getByRole('combobox', { name: 'To unit' })).toBeDefined()
  })
})

describe('a11y: InputRenderer', () => {
  it('textarea is labelled by the spec label', () => {
    render(<InputRenderer spec={{ type: 'input', label: 'Your name' }} onSend={vi.fn()} />)
    expect(screen.getByRole('textbox', { name: 'Your name' })).toBeDefined()
  })

  it('textarea falls back to placeholder as accessible name', () => {
    render(<InputRenderer spec={{ type: 'input', placeholder: 'Say something' }} onSend={vi.fn()} />)
    expect(screen.getByRole('textbox', { name: 'Say something' })).toBeDefined()
  })
})
