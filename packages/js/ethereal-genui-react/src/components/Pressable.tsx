import React from 'react'

/**
 * Shared pressable primitive — the single tap-target building block for every
 * interactive renderer (accordion headers, checklist rows, poll options, quiz
 * options, and future migrations).
 *
 * Always renders a real `<button>` so keyboard activation (Enter/Space),
 * focusability, and disabled semantics come from the platform instead of
 * being re-implemented per renderer. ARIA attributes (`role`, `aria-*`)
 * pass straight through, so a caller can present as checkbox/radio/tab while
 * keeping native button behavior.
 *
 * Styling: ships with the browser button chrome fully reset (transparent
 * background, no border, inherited font/color, left-aligned) so callers style
 * it exactly like the `<div>`s it replaces. A `:focus-visible` accent ring
 * comes from the `ethereal-pressable` class in theme.css.
 */
export interface PressableProps
  extends Omit<React.ButtonHTMLAttributes<HTMLButtonElement>, 'onClick'> {
  /** Activation handler — fires on click and keyboard (Enter/Space). */
  onPress?: (() => void) | undefined
}

const resetStyle: React.CSSProperties = {
  appearance: 'none',
  background: 'none',
  border: 'none',
  margin: 0,
  padding: 0,
  font: 'inherit',
  color: 'inherit',
  textAlign: 'left',
  cursor: 'pointer',
}

export function Pressable({
  onPress,
  disabled,
  type,
  className,
  style,
  children,
  ...rest
}: PressableProps) {
  return (
    <button
      type={type ?? 'button'}
      className={className ? `ethereal-pressable ${className}` : 'ethereal-pressable'}
      disabled={disabled}
      onClick={onPress}
      style={{
        ...resetStyle,
        cursor: disabled ? 'default' : 'pointer',
        ...style,
      }}
      {...rest}
    >
      {children}
    </button>
  )
}
