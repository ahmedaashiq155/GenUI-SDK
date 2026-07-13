import React, { useState } from 'react'
import { GenUiEmptyState } from '../GenUiEmptyState.js'

export interface GalleryRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function GalleryRenderer({ spec, className, style }: GalleryRendererProps) {
  // Require https:// — plaintext http is a downgrade/MITM vector and, like
  // any spec-supplied URL, an auto-loaded remote image doubles as a tracking
  // pixel. `spec.images` may not be an array on hostile input.
  const alt = Array.isArray(spec.alt) ? spec.alt.map(String) : []
  const images = (Array.isArray(spec.images) ? spec.images : [])
    .map((raw, index) => {
      if (raw !== null && typeof raw === 'object' && !Array.isArray(raw)) {
        const image = raw as Record<string, unknown>
        return {
          url: String(image.url ?? image.src ?? ''),
          alt: String(image.alt ?? image.altText ?? ''),
        }
      }
      return { url: String(raw), alt: alt[index] ?? '' }
    })
    .filter((image) => image.url.startsWith('https://'))

  if (images.length === 0) {
    return <GenUiEmptyState label="No images" icon="▧" className={className} style={style} />
  }

  return (
    <div
      className={className}
      style={{
        width: '100%',
        height: 160,
        display: 'flex',
        gap: 'var(--ethereal-space-sm)',
        overflowX: 'auto',
        overflowY: 'hidden',
        padding: 'var(--ethereal-space-sm) 0',
        ...style,
      }}
    >
      {images.map((image, i) => (
        <GalleryImage key={i} {...image} />
      ))}
    </div>
  )
}

function GalleryImage({ url, alt }: { url: string; alt: string }) {
  const [errored, setErrored] = useState(false)

  if (errored) {
    return (
      <div style={{
        width: 200,
        height: '100%',
        flexShrink: 0,
        borderRadius: 'var(--ethereal-radius-md)',
        backgroundColor: 'var(--ethereal-surface)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: 'var(--ethereal-text-tertiary)',
        fontSize: '1.5rem',
      }}>
        🖼
      </div>
    )
  }

  return (
    <img
      src={url}
      alt={alt}
      loading="lazy"
      referrerPolicy="no-referrer"
      onError={() => setErrored(true)}
      style={{
        width: 200,
        height: '100%',
        flexShrink: 0,
        borderRadius: 'var(--ethereal-radius-md)',
        objectFit: 'cover',
      }}
    />
  )
}
