import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { TimerRenderer } from '../../src/components/renderers/TimerRenderer.js'

describe('TimerRenderer', () => {
  it('renders formatted time', () => {
    render(<TimerRenderer spec={{ type: 'timer', seconds: 60 }} />)
    expect(screen.getByText('01:00')).toBeDefined()
  })

  it('Start button present', () => {
    render(<TimerRenderer spec={{ type: 'timer', seconds: 60 }} />)
    expect(screen.getByText('Start')).toBeDefined()
  })

  it('renders label when provided', () => {
    render(<TimerRenderer spec={{ type: 'timer', seconds: 30, label: 'Steep tea' }} />)
    expect(screen.getByText('Steep tea')).toBeDefined()
  })

  it('defaults to 60 seconds when seconds is absent', () => {
    render(<TimerRenderer spec={{ type: 'timer' }} />)
    expect(screen.getByText('01:00')).toBeDefined()
  })

  it('formats time correctly for non-round values', () => {
    render(<TimerRenderer spec={{ type: 'timer', seconds: 90 }} />)
    expect(screen.getByText('01:30')).toBeDefined()
  })

  it('shows Pause button when running', () => {
    render(<TimerRenderer spec={{ type: 'timer', seconds: 60 }} />)
    fireEvent.click(screen.getByText('Start'))
    expect(screen.getByText('Pause')).toBeDefined()
  })

  it('shows Start again after pausing (remaining unchanged in JSDOM)', () => {
    render(<TimerRenderer spec={{ type: 'timer', seconds: 60 }} />)
    fireEvent.click(screen.getByText('Start'))
    fireEvent.click(screen.getByText('Pause'))
    // In JSDOM setInterval doesn't tick, so remaining stays at total (60 === 60),
    // which means the "Resume" condition (remaining < total) is false → shows "Start"
    expect(screen.getByText('Start')).toBeDefined()
  })

  it('forwards className to root element', () => {
    const { container } = render(
      <TimerRenderer spec={{ type: 'timer', seconds: 60 }} className="timer-cls" />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('timer-cls')
  })

  it('resets when a patch changes the duration', () => {
    const { rerender } = render(<TimerRenderer spec={{ type: 'timer', seconds: 60 }} />)
    fireEvent.click(screen.getByText('Start'))
    rerender(<TimerRenderer spec={{ type: 'timer', seconds: 90 }} />)
    expect(screen.getByText('01:30')).toBeDefined()
    expect(screen.getByText('Start')).toBeDefined()
  })

  it('clamps negative durations to zero', () => {
    render(<TimerRenderer spec={{ type: 'timer', seconds: -5 }} />)
    expect(screen.getByText('00:00')).toBeDefined()
  })
})
