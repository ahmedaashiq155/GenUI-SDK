import React from 'react'

export interface GenUiEmptyStateProps {
  label: string
  icon?: React.ReactNode
  className?: string
  style?: React.CSSProperties
}

/** Consistent, non-error state for an intentionally empty collection. */
export function GenUiEmptyState({
  label,
  icon = '◇',
  className,
  style,
}: GenUiEmptyStateProps) {
  return (
    <div
      className={className}
      role="status"
      aria-label={label}
      style={{
        width: '100%',
        boxSizing: 'border-box',
        padding: 'var(--ethereal-space-lg)',
        borderRadius: 'var(--ethereal-radius-lg)',
        border: '1px solid var(--ethereal-hairline)',
        backgroundColor: 'var(--ethereal-surface)',
        display: 'flex',
        alignItems: 'center',
        gap: 'var(--ethereal-space-sm)',
        color: 'var(--ethereal-text-secondary)',
        fontSize: '0.875rem',
        ...style,
      }}
    >
      <span aria-hidden="true" style={{ color: 'var(--ethereal-text-tertiary)' }}>{icon}</span>
      <span>{label}</span>
    </div>
  )
}
