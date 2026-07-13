import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { ArtifactRenderer } from '../../src/components/renderers/ArtifactRenderer.js'
import { GenUiProvider } from '../../src/provider.js'

describe('ArtifactRenderer', () => {
  it('renders the title', () => {
    render(
      <ArtifactRenderer
        spec={{ type: 'artifact', kind: 'code', title: 'my_script.py' }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('my_script.py')).toBeDefined()
  })

  it('does not advertise opening when no host handler exists', () => {
    render(
      <ArtifactRenderer
        spec={{ type: 'artifact', kind: 'markdown', title: 'doc.md' }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('markdown')).toBeDefined()
    expect(screen.queryByText(/tap to open/i)).toBeNull()
    expect(screen.queryByRole('button')).toBeNull()
  })

  it('defaults title to Artifact when not provided', () => {
    render(
      <ArtifactRenderer
        spec={{ type: 'artifact', kind: 'code' }}
        onSend={vi.fn()}
      />
    )
    expect(screen.getByText('Artifact')).toBeDefined()
  })

  it('calls openArtifact action on click when provided', () => {
    const openArtifact = vi.fn()
    const actions = { sendMessage: vi.fn(), openArtifact, enabled: true }
    const spec = { type: 'artifact', kind: 'code', title: 'test.py' }
    render(
      <GenUiProvider actions={actions}>
        <ArtifactRenderer spec={spec} onSend={vi.fn()} />
      </GenUiProvider>
    )
    expect(screen.getByText(/code.*tap to open/i)).toBeDefined()
    expect(screen.getByRole('button', { name: 'Open test.py' })).toBeDefined()
    fireEvent.click(screen.getByText('test.py'))
    expect(openArtifact).toHaveBeenCalledWith(spec)
  })

  it('renders correct icon for code kind', () => {
    const { container } = render(
      <ArtifactRenderer spec={{ type: 'artifact', kind: 'code', title: 'x' }} onSend={vi.fn()} />
    )
    expect(container.textContent).toContain('<>')
  })

  it('forwards className and style to root element', () => {
    const { container } = render(
      <ArtifactRenderer
        spec={{ type: 'artifact', kind: 'code', title: 'x' }}
        className="artifact-cls"
        style={{ padding: '4px' }}
        onSend={vi.fn()}
      />
    )
    const el = container.firstElementChild as HTMLElement
    expect(el.className).toBe('artifact-cls')
    expect(el.style.padding).toBe('4px')
  })
})
