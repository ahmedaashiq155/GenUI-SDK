import React from 'react'
import { GenUiEmptyState } from '../GenUiEmptyState.js'

export interface ChartRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

interface DataPoint {
  label: string
  value: number
}

/**
 * Screen-reader summary for a chart — cross-language parity with Dart's
 * `chartSemanticLabel` (same wording and number formatting), e.g.
 * "Weekly sales. Bar chart: Mon 3, Tue 5.5".
 */
export function chartSemanticLabel(
  variant: string,
  title: string | undefined,
  data: DataPoint[],
): string {
  const kind = variant === 'pie'
    ? 'Pie chart'
    : variant === 'line'
      ? 'Line chart'
      : variant === 'area'
        ? 'Area chart'
        : 'Bar chart'
  const fmt = (v: number) => (Number.isInteger(v) ? String(v) : v.toFixed(1))
  const points = data.map(d => `${d.label} ${fmt(d.value)}`).join(', ')
  const titlePart = title ? `${title}. ` : ''
  return `${titlePart}${kind}: ${points}`
}

const PIE_PALETTE = [
  'var(--ethereal-accent)',
  'var(--ethereal-celadon)',
  'var(--ethereal-danger)',
  'var(--ethereal-text-secondary)',
]

function polarToCartesian(cx: number, cy: number, r: number, angleDeg: number) {
  const rad = (angleDeg - 90) * Math.PI / 180
  return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) }
}

function slicePath(
  cx: number, cy: number,
  outerR: number, innerR: number,
  startAngle: number, endAngle: number,
): string {
  const o1 = polarToCartesian(cx, cy, outerR, startAngle)
  const o2 = polarToCartesian(cx, cy, outerR, endAngle)
  const i1 = polarToCartesian(cx, cy, innerR, endAngle)
  const i2 = polarToCartesian(cx, cy, innerR, startAngle)
  const large = endAngle - startAngle > 180 ? 1 : 0
  return `M ${o1.x} ${o1.y} A ${outerR} ${outerR} 0 ${large} 1 ${o2.x} ${o2.y} L ${i1.x} ${i1.y} A ${innerR} ${innerR} 0 ${large} 0 ${i2.x} ${i2.y} Z`
}

function BarChart({ data }: { data: DataPoint[] }) {
  const leftMargin = 20
  const rightMargin = 10
  const topMargin = 10
  const bottomMargin = 30
  const plotWidth  = 300 - leftMargin - rightMargin   // 270
  const plotHeight = 160 - topMargin - bottomMargin   // 120
  const maxValue   = Math.max(...data.map(d => d.value), 1)
  const slotWidth  = plotWidth / data.length
  const barWidth   = slotWidth * 0.6

  return (
    <svg viewBox="0 0 300 160" width="100%" height="200">
      {data.map((d, i) => {
        const barH  = (d.value / maxValue) * plotHeight
        const x     = leftMargin + i * slotWidth + (slotWidth - barWidth) / 2
        const y     = topMargin + plotHeight - barH
        const cx    = leftMargin + i * slotWidth + slotWidth / 2
        return (
          <g key={i}>
            <rect
              x={x}
              y={y}
              width={barWidth}
              height={barH}
              rx={4}
              style={{ fill: 'var(--ethereal-accent)' }}
            />
            <text
              x={cx}
              y={148}
              style={{ fontSize: 11, fill: 'var(--ethereal-text-tertiary)' }}
              textAnchor="middle"
            >
              {d.label}
            </text>
          </g>
        )
      })}
    </svg>
  )
}

function LineChart({ data, area }: { data: DataPoint[]; area: boolean }) {
  const leftMargin  = 20
  const rightMargin = 10
  const topMargin   = 10
  const bottomMargin = 30
  const plotWidth   = 300 - leftMargin - rightMargin   // 270
  const plotHeight  = 160 - topMargin - bottomMargin   // 120
  const maxValue    = Math.max(...data.map(d => d.value), 1)
  const n           = data.length

  const points: { x: number; y: number }[] = data.map((d, i) => {
    const x = n === 1
      ? leftMargin + plotWidth / 2
      : leftMargin + i * (plotWidth / (n - 1))
    const y = topMargin + (1 - d.value / maxValue) * plotHeight
    return { x, y }
  })

  const pointsStr  = points.map(p => `${p.x},${p.y}`).join(' ')
  const polygonPts = [
    ...points.map(p => `${p.x},${p.y}`),
    `${points[points.length - 1].x},${topMargin + plotHeight}`,
    `${points[0].x},${topMargin + plotHeight}`,
  ].join(' ')

  return (
    <svg viewBox="0 0 300 160" width="100%" height="200">
      {area ? (
        <polygon
          points={polygonPts}
          style={{ fill: 'var(--ethereal-accent)', opacity: 0.12 }}
        />
      ) : null}
      <polyline
        points={pointsStr}
        style={{ stroke: 'var(--ethereal-accent)', strokeWidth: 2.5, fill: 'none' }}
      />
      {data.map((d, i) => {
        const cx = n === 1
          ? leftMargin + plotWidth / 2
          : leftMargin + i * (plotWidth / (n - 1))
        return (
          <text
            key={i}
            x={cx}
            y={148}
            style={{ fontSize: 11, fill: 'var(--ethereal-text-tertiary)' }}
            textAnchor="middle"
          >
            {d.label}
          </text>
        )
      })}
    </svg>
  )
}

function PieChart({ data }: { data: DataPoint[] }) {
  const cx = 90
  const cy = 80
  const outerR = 65
  const innerR = 26
  const total = data.reduce((s, d) => s + d.value, 0) || 1

  let startAngle = 0
  const slices = data.map((d, i) => {
    const angle = (d.value / total) * 360
    // A sweep of exactly 360deg makes the arc's start/end points coincide,
    // which SVG treats as a degenerate no-op path (renders nothing).
    const sweep = Math.min(angle, 359.999)
    const path  = slicePath(cx, cy, outerR, innerR, startAngle, startAngle + sweep)
    const midAngle = startAngle + angle / 2
    const pct   = (d.value / total) * 100
    const labelPt = polarToCartesian(cx, cy, (outerR + innerR) / 2, midAngle)
    startAngle += angle
    return { path, color: PIE_PALETTE[i % PIE_PALETTE.length], label: d.label, pct, labelPt }
  })

  return (
    <svg viewBox="0 0 300 160" width="100%" height="200">
      {slices.map((s, i) => (
        <path key={i} d={s.path} style={{ fill: s.color }} />
      ))}
      {slices.map((s, i) =>
        s.pct >= 5 ? (
          <text
            key={i}
            x={s.labelPt.x}
            y={s.labelPt.y}
            textAnchor="middle"
            dominantBaseline="middle"
            style={{ fontSize: 10, fill: 'var(--ethereal-on-accent)', fontWeight: 600 }}
          >
            {Math.round(s.pct)}%
          </text>
        ) : null
      )}
      {/* Legend */}
      {slices.map((s, i) => (
        <g key={i} transform={`translate(175, ${20 + i * 22})`}>
          <circle r={5} cx={5} cy={0} style={{ fill: s.color }} />
          <text
            x={14}
            y={4}
            style={{ fontSize: 11, fill: 'var(--ethereal-text-secondary)' }}
          >
            {s.label}
          </text>
        </g>
      ))}
    </svg>
  )
}

export function ChartRenderer({ spec, className, style }: ChartRendererProps) {
  const rawData = Array.isArray(spec.data) ? spec.data as unknown[] : []
  const data: DataPoint[] = rawData
    .filter((d): d is Record<string, unknown> => typeof d === 'object' && d !== null)
    .map(d => {
      // A non-finite or negative value (NaN, Infinity, "-3") would poison the
      // SVG path math (a single NaN makes Math.max return NaN, blanking every
      // bar). Coerce to a safe non-negative finite number.
      const n = Number(d.value ?? 0)
      return { label: String(d.label ?? ''), value: Number.isFinite(n) && n > 0 ? n : 0 }
    })

  if (data.length === 0) {
    return <GenUiEmptyState label="No chart data" icon="▥" className={className} style={style} />
  }

  const chartType = (spec.chart ?? spec.variant ?? 'bar') as string
  const title = spec.title as string | undefined

  return (
    <div
      className={className}
      style={{
        width: '100%',
        padding: 'var(--ethereal-space-md)',
        borderRadius: 'var(--ethereal-radius-lg)',
        border: '1px solid var(--ethereal-hairline)',
        backgroundColor: 'var(--ethereal-surface)',
        display: 'flex',
        flexDirection: 'column',
        gap: 'var(--ethereal-space-sm)',
        ...style,
      }}
    >
      {title && (
        <p style={{
          margin: 0,
          fontWeight: 600,
          fontSize: '0.9375rem',
          color: 'var(--ethereal-text-primary)',
        }}>
          {title}
        </p>
      )}
      <div role="img" aria-label={chartSemanticLabel(chartType, title, data)}>
        <div aria-hidden="true">
          {chartType === 'line' || chartType === 'area' ? (
            <LineChart data={data} area={chartType === 'area'} />
          ) : chartType === 'pie' ? (
            <PieChart data={data} />
          ) : (
            <BarChart data={data} />
          )}
        </div>
      </div>
    </div>
  )
}
