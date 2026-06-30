import React, { useState } from 'react'

export interface GalleryRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function GalleryRenderer({ spec, className, style }: GalleryRendererProps) {
  const urls = (spec.images as unknown[] | undefined ?? [])
    .map(String)
    .filter((u) => u.startsWith('http'))

  if (urls.length === 0) return null

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
      {urls.map((url, i) => (
        <GalleryImage key={i} url={url} />
      ))}
    </div>
  )
}

function GalleryImage({ url }: { url: string }) {
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
      alt=""
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
