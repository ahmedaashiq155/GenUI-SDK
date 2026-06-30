import { describe, it, expect, vi } from 'vitest'
import { render, screen, act } from '@testing-library/react'
import { WhenRenderer } from '../../src/components/renderers/WhenRenderer.js'
import { GenUiProvider, useOptionalGenUiStore } from '../../src/provider.js'
import { GenUiStore } from '../../src/store.js'

describe('WhenRenderer', () => {
  it('renders nothing when no store is present (no provider)', () => {
    // No GenUiProvider wrapping — store is null
    const { container } = render(
      <WhenRenderer
        spec={{ type: 'when', key: 'view', equals: 'new', child: { type: 'badges', items: ['hello'] } }}
        onSend={vi.fn()}
      />
    )
    expect(container.firstChild).toBeNull()
  })

  it('renders nothing when store has no matching value', () => {
    render(
      <GenUiProvider actions={{ sendMessage: vi.fn(), enabled: true }}>
        <WhenRenderer
          spec={{ type: 'when', key: 'view', equals: 'new', child: { type: 'badges', items: ['hello'] } }}
          onSend={vi.fn()}
        />
      </GenUiProvider>
    )
    expect(screen.queryByText('hello')).toBeNull()
  })

  it('renders child when store value matches equals', () => {
    let storeRef: GenUiStore | null = null
    function Capture() {
      storeRef = useOptionalGenUiStore()
      return null
    }
    render(
      <GenUiProvider actions={{ sendMessage: vi.fn(), enabled: true }}>
        <Capture />
        <WhenRenderer
          spec={{ type: 'when', key: 'view', equals: 'new', child: { type: 'badges', items: ['hello'] } }}
          onSend={vi.fn()}
        />
      </GenUiProvider>
    )
    expect(screen.queryByText('hello')).toBeNull()
    act(() => storeRef!.setValue('view', 'new'))
    expect(screen.queryByText('hello')).not.toBeNull()
  })

  it('renders children array when child is absent but children is an array', () => {
    let storeRef: GenUiStore | null = null
    function Capture() {
      storeRef = useOptionalGenUiStore()
      return null
    }
    render(
      <GenUiProvider actions={{ sendMessage: vi.fn(), enabled: true }}>
        <Capture />
        <WhenRenderer
          spec={{
            type: 'when',
            key: 'flag',
            equals: 'on',
            children: [{ type: 'badges', items: ['kid1'] }, { type: 'badges', items: ['kid2'] }],
          }}
          onSend={vi.fn()}
        />
      </GenUiProvider>
    )
    act(() => storeRef!.setValue('flag', 'on'))
    expect(screen.queryByText('kid1')).not.toBeNull()
    expect(screen.queryByText('kid2')).not.toBeNull()
  })

  it('hides content again when value changes back', () => {
    let storeRef: GenUiStore | null = null
    function Capture() {
      storeRef = useOptionalGenUiStore()
      return null
    }
    render(
      <GenUiProvider actions={{ sendMessage: vi.fn(), enabled: true }}>
        <Capture />
        <WhenRenderer
          spec={{ type: 'when', key: 'view', equals: 'new', child: { type: 'badges', items: ['hello'] } }}
          onSend={vi.fn()}
        />
      </GenUiProvider>
    )
    act(() => storeRef!.setValue('view', 'new'))
    expect(screen.queryByText('hello')).not.toBeNull()
    act(() => storeRef!.setValue('view', 'old'))
    expect(screen.queryByText('hello')).toBeNull()
  })

  it('truthy match renders when equals is absent and value is truthy', () => {
    let storeRef: GenUiStore | null = null
    function Capture() {
      storeRef = useOptionalGenUiStore()
      return null
    }
    render(
      <GenUiProvider actions={{ sendMessage: vi.fn(), enabled: true }}>
        <Capture />
        <WhenRenderer
          spec={{ type: 'when', key: 'show', child: { type: 'badges', items: ['visible'] } }}
          onSend={vi.fn()}
        />
      </GenUiProvider>
    )
    act(() => storeRef!.setValue('show', 'yes'))
    expect(screen.queryByText('visible')).not.toBeNull()
  })
})
