import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { GalleryRenderer } from '../../src/components/renderers/GalleryRenderer.js'

describe('GalleryRenderer', () => {
  it('renders a consistent empty state for empty images', () => {
    render(<GalleryRenderer spec={{ type: 'gallery', images: [] }} />)
    expect(screen.getByRole('status', { name: 'No images' })).toBeDefined()
  })

  it('filters non-http(s) URLs', () => {
    const { container } = render(
      <GalleryRenderer spec={{ type: 'gallery', images: ['ftp://bad.com/img.jpg', 'data:image/png;base64,...'] }} />
    )
    // none are https, so the renderer explains the empty result.
    expect(container.textContent).toContain('No images')
  })

  it('renders only https URLs, dropping plaintext http', () => {
    const { container } = render(
      <GalleryRenderer spec={{ type: 'gallery', images: ['https://example.com/a.jpg', 'http://example.com/b.jpg'] }} />
    )
    expect(container.firstChild).toBeDefined()
    const imgs = container.querySelectorAll('img')
    // http:// is rejected as a downgrade/exfil vector; only the https image renders.
    expect(imgs.length).toBe(1)
    expect(imgs[0].getAttribute('src')).toBe('https://example.com/a.jpg')
  })

  it('uses schema alt text and supports self-describing image objects', () => {
    const { rerender } = render(
      <GalleryRenderer
        spec={{
          type: 'gallery',
          images: ['https://example.com/lake.jpg'],
          alt: ['A quiet lake at sunrise'],
        }}
      />
    )
    expect(screen.getByAltText('A quiet lake at sunrise')).toBeDefined()

    rerender(
      <GalleryRenderer
        spec={{
          type: 'gallery',
          images: [{ url: 'https://example.com/forest.jpg', alt: 'A green forest' }],
        }}
      />
    )
    expect(screen.getByAltText('A green forest')).toBeDefined()
  })

  it('renders an empty state when images key is absent', () => {
    render(<GalleryRenderer spec={{ type: 'gallery' }} />)
    expect(screen.getByText('No images')).toBeDefined()
  })

  it('forwards className to root element when images are present', () => {
    const { container } = render(
      <GalleryRenderer
        spec={{ type: 'gallery', images: ['https://example.com/img.jpg'] }}
        className="gallery-cls"
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('gallery-cls')
  })
})
