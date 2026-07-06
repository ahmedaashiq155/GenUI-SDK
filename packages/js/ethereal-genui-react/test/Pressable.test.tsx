import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { Pressable } from '../src/components/Pressable.js'

describe('Pressable', () => {
  it('renders a real button element (type=button)', () => {
    render(<Pressable onPress={vi.fn()}>Tap me</Pressable>)
    const btn = screen.getByRole('button', { name: 'Tap me' })
    expect(btn.tagName).toBe('BUTTON')
    expect(btn.getAttribute('type')).toBe('button')
  })

  it('fires onPress on click', () => {
    const onPress = vi.fn()
    render(<Pressable onPress={onPress}>Go</Pressable>)
    fireEvent.click(screen.getByText('Go'))
    expect(onPress).toHaveBeenCalledTimes(1)
  })

  it('does not fire onPress when disabled', () => {
    const onPress = vi.fn()
    render(<Pressable onPress={onPress} disabled>Go</Pressable>)
    fireEvent.click(screen.getByText('Go'))
    expect(onPress).not.toHaveBeenCalled()
  })

  it('passes through ARIA role and state attributes', () => {
    render(
      <Pressable onPress={vi.fn()} role="checkbox" aria-checked={true}>
        Opt
      </Pressable>
    )
    const el = screen.getByRole('checkbox', { name: 'Opt' })
    expect(el.getAttribute('aria-checked')).toBe('true')
  })

  it('always carries the ethereal-pressable class and merges custom className', () => {
    render(<Pressable onPress={vi.fn()} className="extra">X</Pressable>)
    const btn = screen.getByText('X')
    expect(btn.className).toContain('ethereal-pressable')
    expect(btn.className).toContain('extra')
  })

  it('merges caller style over the reset', () => {
    render(<Pressable onPress={vi.fn()} style={{ padding: '9px' }}>X</Pressable>)
    const btn = screen.getByText('X') as HTMLElement
    expect(btn.style.padding).toBe('9px')
    expect(btn.style.textAlign).toBe('left')
  })
})
