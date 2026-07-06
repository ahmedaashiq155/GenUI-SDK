import { describe, it, expect, vi } from 'vitest'
import { render } from '@testing-library/react'
import { GalleryRenderer } from '../../src/components/renderers/GalleryRenderer.js'

describe('GalleryRenderer', () => {
  it('returns null for empty images', () => {
    const { container } = render(<GalleryRenderer spec={{ type: 'gallery', images: [] }} />)
    expect(container.firstChild).toBeNull()
  })

  it('filters non-http(s) URLs', () => {
    const { container } = render(
      <GalleryRenderer spec={{ type: 'gallery', images: ['ftp://bad.com/img.jpg', 'data:image/png;base64,...'] }} />
    )
    // none are https so returns null
    expect(container.firstChild).toBeNull()
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

  it('returns null when images key is absent', () => {
    const { container } = render(<GalleryRenderer spec={{ type: 'gallery' }} />)
    expect(container.firstChild).toBeNull()
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
