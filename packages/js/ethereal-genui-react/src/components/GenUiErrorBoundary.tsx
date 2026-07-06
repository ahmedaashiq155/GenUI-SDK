import React from 'react'
import { GenUiBlockError } from './GenUiBlockError.js'

export interface GenUiErrorBoundaryProps {
  children: React.ReactNode
  /** Changes to this value reset the boundary (e.g. the spec identity). */
  resetKey?: unknown
  className?: string
  style?: React.CSSProperties
}

interface GenUiErrorBoundaryState {
  hasError: boolean
}

/**
 * Contains a single block's render crash so one malformed spec can't unmount
 * the host app's entire React tree. The spec is untrusted model output — a
 * renderer that throws on a hostile shape (e.g. a string where an array was
 * expected) must degrade to the "Couldn't render this" chip, not take the
 * page down with it.
 */
export class GenUiErrorBoundary extends React.Component<
  GenUiErrorBoundaryProps,
  GenUiErrorBoundaryState
> {
  constructor(props: GenUiErrorBoundaryProps) {
    super(props)
    this.state = { hasError: false }
  }

  static getDerivedStateFromError(): GenUiErrorBoundaryState {
    return { hasError: true }
  }

  componentDidUpdate(prev: GenUiErrorBoundaryProps) {
    // A new spec is a fresh chance to render — clear the error so a valid
    // follow-up (e.g. a streamed patch) isn't stuck on the error chip.
    if (prev.resetKey !== this.props.resetKey && this.state.hasError) {
      this.setState({ hasError: false })
    }
  }

  render() {
    if (this.state.hasError) {
      return <GenUiBlockError className={this.props.className} style={this.props.style} />
    }
    return this.props.children
  }
}
