import React from 'react'

export interface TableRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function TableRenderer({ spec, className, style }: TableRendererProps) {
  const columns = (spec.columns as unknown[] | undefined ?? []).map(String)
  const rows = (spec.rows as unknown[][] | undefined ?? []).map(
    (r) => (Array.isArray(r) ? r : []).map(String)
  )

  if (columns.length === 0 && rows.length === 0) return null

  return (
    <div
      className={className}
      style={{
        width: '100%',
        padding: 'var(--ethereal-space-lg)',
        borderRadius: 'var(--ethereal-radius-lg)',
        border: '1px solid var(--ethereal-hairline)',
        backgroundColor: 'var(--ethereal-surface)',
        ...style,
      }}
    >
      <div style={{ overflowX: 'auto' }}>
        <table style={{
          width: '100%',
          borderCollapse: 'collapse',
          fontSize: '0.875rem',
        }}>
          {columns.length > 0 && (
            <thead>
              <tr>
                {columns.map((col, i) => (
                  <th
                    key={i}
                    style={{
                      padding: '6px var(--ethereal-space-sm)',
                      textAlign: 'left',
                      fontWeight: 700,
                      color: 'var(--ethereal-text-primary)',
                      borderBottom: '1px solid var(--ethereal-hairline)',
                      whiteSpace: 'nowrap',
                    }}
                  >
                    {col}
                  </th>
                ))}
              </tr>
            </thead>
          )}
          <tbody>
            {rows.map((row, ri) => (
              <tr key={ri}>
                {columns.length > 0
                  ? columns.map((_, ci) => (
                      <td
                        key={ci}
                        style={{
                          padding: '6px var(--ethereal-space-sm)',
                          color: 'var(--ethereal-text-secondary)',
                          borderBottom: '1px solid var(--ethereal-hairline)',
                          fontVariantNumeric: 'tabular-nums',
                          whiteSpace: 'nowrap',
                        }}
                      >
                        {ci < row.length ? row[ci] : ''}
                      </td>
                    ))
                  : row.map((cell, ci) => (
                      <td
                        key={ci}
                        style={{
                          padding: '6px var(--ethereal-space-sm)',
                          color: 'var(--ethereal-text-secondary)',
                          borderBottom: '1px solid var(--ethereal-hairline)',
                          fontVariantNumeric: 'tabular-nums',
                          whiteSpace: 'nowrap',
                        }}
                      >
                        {cell}
                      </td>
                    ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
