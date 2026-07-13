import React, { useCallback, useEffect, useState } from 'react'
import { Pressable } from './components/Pressable.js'

export type GenUiVoiceState = 'idle' | 'listening' | 'speaking' | 'error'

export interface GenUiVoiceAdapter {
  startListening(handlers: {
    locale?: string
    onTranscript: (transcript: string) => void
    onError: (error: unknown) => void
    onEnd: () => void
  }): void | Promise<void>
  stopListening(): void | Promise<void>
  speak(text: string, options?: { locale?: string }): void | Promise<void>
  stopSpeaking(): void | Promise<void>
}

export function useGenUiVoice(adapter: GenUiVoiceAdapter, locale?: string) {
  const [state, setState] = useState<GenUiVoiceState>('idle')
  const [transcript, setTranscript] = useState('')
  const [error, setError] = useState<unknown>(null)

  const stop = useCallback(async () => {
    if (state === 'listening') await adapter.stopListening()
    if (state === 'speaking') await adapter.stopSpeaking()
    setState('idle')
  }, [adapter, state])

  const startListening = useCallback(async () => {
    await stop()
    setError(null)
    setState('listening')
    await adapter.startListening({
      locale,
      onTranscript: setTranscript,
      onError: (nextError) => {
        setError(nextError)
        setState('error')
      },
      onEnd: () => setState('idle'),
    })
  }, [adapter, locale, stop])

  const speak = useCallback(async (text: string) => {
    if (text.trim() === '') return
    await stop()
    setError(null)
    setState('speaking')
    try {
      await adapter.speak(text, { locale })
      setState('idle')
    } catch (nextError) {
      setError(nextError)
      setState('error')
    }
  }, [adapter, locale, stop])

  useEffect(() => () => {
    void adapter.stopListening()
    void adapter.stopSpeaking()
  }, [adapter])

  return { state, transcript, error, startListening, stop, speak, setTranscript }
}

export interface GenUiVoiceButtonProps {
  voice: ReturnType<typeof useGenUiVoice>
  onTranscript?: (transcript: string) => void
  className?: string
}

export function GenUiVoiceButton({ voice, onTranscript, className }: GenUiVoiceButtonProps) {
  useEffect(() => {
    if (voice.transcript) onTranscript?.(voice.transcript)
  }, [onTranscript, voice.transcript])
  const listening = voice.state === 'listening'
  return (
    <Pressable
      className={className}
      aria-label={listening ? 'Stop listening' : 'Start voice input'}
      aria-pressed={listening}
      onPress={() => void (listening ? voice.stop() : voice.startListening())}
    >
      <span aria-hidden="true">{listening ? '■' : '🎙'}</span>
    </Pressable>
  )
}
