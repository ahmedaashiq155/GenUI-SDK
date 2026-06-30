import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { ColumnsRenderer } from '../../src/components/renderers/ColumnsRenderer.js'

describe('ColumnsRenderer', () => {
  it('renders children side by side', () => {
    render(
      <ColumnsRenderer
        spec={{ type: 'columns', children: [{ type: 'badges', items: ['Col1'] }, { type: 'badges', items: ['Col2'] }] }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('Col1')).toBeDefined()
    expect(screen.getByText('Col2')).toBeDefined()
  })

  it('renders empty columns without crashing', () => {
    const { container } = render(<ColumnsRenderer spec={{ type: 'columns', children: [] }} onSend={vi.fn()} />)
    expect(container.firstChild).toBeDefined()
  })

  it('renders flex row layout', () => {
    const { container } = render(
      <ColumnsRenderer spec={{ type: 'columns', children: [] }} onSend={vi.fn()} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.style.display).toBe('flex')
    expect(el.style.flexDirection).toBe('row')
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <ColumnsRenderer spec={{ type: 'columns', children: [] }} onSend={vi.fn()} className="columns-cls" style={{ margin: '5px' }} />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('columns-cls')
    expect(el.style.margin).toBe('5px')
  })
})
