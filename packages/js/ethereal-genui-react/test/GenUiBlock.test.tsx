import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { GenUiBlock } from '../src/components/GenUiBlock.js'

describe('GenUiBlock', () => {
  it('renders a canonical type', () => {
    render(<GenUiBlock spec={{ type: 'divider' }} onSend={vi.fn()} />)
    expect(document.querySelector('hr, div')).not.toBeNull()
  })

  it('renders an "Unsupported block" placeholder for an unknown type', () => {
    render(<GenUiBlock spec={{ type: 'nonexistent' }} onSend={vi.fn()} />)
    expect(screen.getByText('Unsupported block: nonexistent')).toBeDefined()
  })

  // Schema-sanctioned aliases (@ethereal/genui-core genui_schema.ts) must route
  // to their canonical renderer instead of falling through to null.
  it('routes alias "kpi" to StatRenderer', () => {
    render(<GenUiBlock spec={{ type: 'kpi', stats: [{ label: 'Users', value: '1.2k' }] }} onSend={vi.fn()} />)
    expect(screen.getByText('1.2k')).toBeDefined()
  })

  it('routes alias "steps" to TimelineRenderer', () => {
    render(<GenUiBlock spec={{ type: 'steps', items: [{ title: 'Order placed' }] }} onSend={vi.fn()} />)
    expect(screen.getByText('Order placed')).toBeDefined()
  })

  it('routes alias "chips" to BadgesRenderer', () => {
    render(<GenUiBlock spec={{ type: 'chips', items: ['new'] }} onSend={vi.fn()} />)
    expect(screen.getByText('new')).toBeDefined()
  })

  it('routes alias "container" to BoxRenderer', () => {
    render(<GenUiBlock spec={{ type: 'container', child: { type: 'badges', items: ['inside'] } }} onSend={vi.fn()} />)
    expect(screen.getByText('inside')).toBeDefined()
  })
})
