import { describe, it, expect, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import { GenUiBlock } from '../src/components/GenUiBlock.js'
import { GenUiProvider } from '../src/provider.js'

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

  it('synchronously rejects duplicate sends from sibling options', () => {
    const onSend = vi.fn()
    render(<GenUiBlock spec={{ type: 'choices', options: ['Yes', 'No'] }} onSend={onSend} />)
    fireEvent.click(screen.getByRole('button', { name: 'Yes' }))
    fireEvent.click(screen.getByRole('button', { name: 'No' }))
    expect(onSend).toHaveBeenCalledTimes(1)
    expect(onSend).toHaveBeenCalledWith('Yes')
  })

  it('shares one dispatch lock across nested blocks', () => {
    const onSend = vi.fn()
    render(
      <GenUiBlock
        spec={{
          type: 'column',
          children: [
            { type: 'choices', options: ['First'] },
            { type: 'choices', options: ['Second'] },
          ],
        }}
        onSend={onSend}
      />
    )
    fireEvent.click(screen.getByRole('button', { name: 'First' }))
    fireEvent.click(screen.getByRole('button', { name: 'Second' }))
    expect(onSend).toHaveBeenCalledTimes(1)
  })

  it('resets only after enabled completes a false-to-true lifecycle', () => {
    const onSend = vi.fn()
    const spec = { type: 'choices', options: ['Again'] }
    const { rerender } = render(<GenUiBlock spec={spec} onSend={onSend} enabled />)
    fireEvent.click(screen.getByRole('button', { name: 'Again' }))
    rerender(<GenUiBlock spec={spec} onSend={onSend} enabled={false} />)
    rerender(<GenUiBlock spec={spec} onSend={onSend} enabled />)
    fireEvent.click(screen.getByRole('button', { name: 'Again' }))
    expect(onSend).toHaveBeenCalledTimes(2)
  })

  it('combines provider and prop enabled state for message inputs', () => {
    const onSend = vi.fn()
    render(
      <GenUiProvider actions={{ sendMessage: onSend, enabled: false }}>
        <GenUiBlock
          spec={{ type: 'input', label: 'Message', submitLabel: 'Send' }}
          onSend={onSend}
        />
      </GenUiProvider>
    )
    expect((screen.getByRole('textbox', { name: 'Message' }) as HTMLTextAreaElement).disabled).toBe(true)
    expect((screen.getByRole('button', { name: 'Send' }) as HTMLButtonElement).disabled).toBe(true)
  })
})
