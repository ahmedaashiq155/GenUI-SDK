import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { GenUiBlock } from '../src/components/GenUiBlock.js'
import { GenUiErrorBoundary } from '../src/components/GenUiErrorBoundary.js'
import { BoxRenderer } from '../src/components/renderers/BoxRenderer.js'
import { GalleryRenderer } from '../src/components/renderers/GalleryRenderer.js'

// Batch 1 hardening — the spec is untrusted model output.
describe('security: error boundary', () => {
  it('contains a renderer crash and shows the error chip instead of throwing', () => {
    // Force a renderer to throw: GalleryRenderer receiving a non-array where
    // it maps would be one path, but the most robust check is a child that
    // throws synchronously.
    const Boom = () => { throw new Error('boom') }
    render(
      <GenUiErrorBoundary>
        <Boom />
      </GenUiErrorBoundary>
    )
    expect(screen.getByText(/Couldn't render this/)).toBeDefined()
  })

  it('a malformed spec does not crash GenUiBlock', () => {
    expect(() => {
      render(<GenUiBlock spec={{ type: 'gallery', images: 'not-an-array' }} onSend={vi.fn()} />)
    }).not.toThrow()
  })
})

describe('security: recursion depth cap', () => {
  it('renders a placeholder instead of overflowing on a deeply nested spec', () => {
    // Build a spec nested well past MAX_DEPTH (24).
    let spec: Record<string, unknown> = { type: 'text', text: 'leaf' }
    for (let i = 0; i < 60; i++) spec = { type: 'box', child: spec }
    expect(() => {
      render(<GenUiBlock spec={spec} onSend={vi.fn()} />)
    }).not.toThrow()
    expect(screen.getByText(/Unsupported block: too-deep/)).toBeDefined()
  })
})

describe('security: gallery URL hardening', () => {
  it('drops non-https image URLs', () => {
    const { container } = render(
      <GalleryRenderer
        spec={{ type: 'gallery', images: ['http://insecure/x.png', 'javascript:alert(1)', 'https://ok/y.png'] }}
        onSend={vi.fn()}
      />
    )
    const imgs = container.querySelectorAll('img')
    expect(imgs.length).toBe(1)
    expect(imgs[0].getAttribute('src')).toBe('https://ok/y.png')
    expect(imgs[0].getAttribute('referrerPolicy') ?? imgs[0].getAttribute('referrerpolicy')).toBe('no-referrer')
  })

  it('renders nothing when images is not an array', () => {
    const { container } = render(
      <GalleryRenderer spec={{ type: 'gallery', images: 'nope' }} onSend={vi.fn()} />
    )
    expect(container.firstChild).toBeNull()
  })
})

describe('security: box CSS-value injection guard', () => {
  it('rejects a url() background — the injected value never reaches inline style', () => {
    const { container } = render(
      <BoxRenderer spec={{ type: 'box', bg: 'url(https://evil/pixel.png)', children: [] }} onSend={vi.fn()} />
    )
    // The inner styled div is the second div (outer wrapper has padding:3px 0).
    // Read the raw style attribute — jsdom's CSSOM doesn't round-trip the
    // `background` shorthand, but the attribute string holds exactly what React wrote.
    const inner = container.firstElementChild!.firstElementChild as HTMLElement
    const styleAttr = inner.getAttribute('style') ?? ''
    expect(styleAttr).not.toContain('url(')
    expect(styleAttr).not.toContain('evil')
    expect(styleAttr).toContain('--ethereal-surface')
  })

  it('accepts a plain hex background', () => {
    const { container } = render(
      <BoxRenderer spec={{ type: 'box', bg: '#123456', children: [] }} onSend={vi.fn()} />
    )
    const inner = container.firstElementChild!.firstElementChild as HTMLElement
    const styleAttr = inner.getAttribute('style') ?? ''
    // jsdom normalizes the accepted hex to rgb(); assert it made it through
    // (not the surface fallback).
    expect(styleAttr).toMatch(/#123456|rgb\(18, 52, 86\)/)
    expect(styleAttr).not.toContain('--ethereal-surface')
  })
})
