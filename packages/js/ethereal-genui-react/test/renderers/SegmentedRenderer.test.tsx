import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { SegmentedRenderer } from '../../src/components/renderers/SegmentedRenderer.js'

describe('SegmentedRenderer', () => {
  it('renders all segments', () => {
    render(<SegmentedRenderer spec={{ type: 'segmented', options: ['Daily', 'Weekly', 'Monthly'] }} onSend={vi.fn()} />)
    expect(screen.getByText('Daily')).toBeDefined()
    expect(screen.getByText('Weekly')).toBeDefined()
    expect(screen.getByText('Monthly')).toBeDefined()
  })

  it('calls onSend with option value on click', () => {
    const onSend = vi.fn()
    render(<SegmentedRenderer spec={{ type: 'segmented', options: ['Daily', 'Weekly'] }} onSend={onSend} />)
    fireEvent.click(screen.getByText('Weekly'))
    expect(onSend).toHaveBeenCalledWith('Weekly')
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <SegmentedRenderer spec={{ type: 'segmented', options: [] }} onSend={vi.fn()} className="seg-cls" style={{ margin: '4px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('seg-cls')
    expect(el.style.margin).toBe('4px')
  })
})
