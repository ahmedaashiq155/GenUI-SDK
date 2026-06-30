import React from 'react'
import { ChoicesRenderer } from './renderers/ChoicesRenderer.js'
import { ActionsRenderer } from './renderers/ActionsRenderer.js'
import { ConfirmRenderer } from './renderers/ConfirmRenderer.js'
import { SuggestionsRenderer } from './renderers/SuggestionsRenderer.js'
import { InputRenderer } from './renderers/InputRenderer.js'
import { MultiSelectRenderer } from './renderers/MultiSelectRenderer.js'
import { SliderRenderer } from './renderers/SliderRenderer.js'
import { FormRenderer } from './renderers/FormRenderer.js'
import { RatingRenderer } from './renderers/RatingRenderer.js'
import { SegmentedRenderer } from './renderers/SegmentedRenderer.js'
import { StepperRenderer } from './renderers/StepperRenderer.js'
import { ChecklistRenderer } from './renderers/ChecklistRenderer.js'
import { PollRenderer } from './renderers/PollRenderer.js'
import { QuizRenderer } from './renderers/QuizRenderer.js'

export interface GenUiBlockProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function GenUiBlock({ spec, onSend, className, style }: GenUiBlockProps) {
  const type = spec.type as string
  switch (type) {
    case 'choices':    return <ChoicesRenderer    spec={spec} onSend={onSend} className={className} style={style} />
    case 'actions':    return <ActionsRenderer    spec={spec} onSend={onSend} className={className} style={style} />
    case 'confirm':    return <ConfirmRenderer    spec={spec} onSend={onSend} className={className} style={style} />
    case 'suggestions': return <SuggestionsRenderer spec={spec} onSend={onSend} className={className} style={style} />
    case 'input':      return <InputRenderer      spec={spec} onSend={onSend} className={className} style={style} />
    case 'multiselect': return <MultiSelectRenderer spec={spec} onSend={onSend} className={className} style={style} />
    case 'slider':     return <SliderRenderer     spec={spec} onSend={onSend} className={className} style={style} />
    case 'form':       return <FormRenderer       spec={spec} onSend={onSend} className={className} style={style} />
    case 'rating':     return <RatingRenderer     spec={spec} onSend={onSend} className={className} style={style} />
    case 'segmented':  return <SegmentedRenderer  spec={spec} onSend={onSend} className={className} style={style} />
    case 'stepper':    return <StepperRenderer    spec={spec} onSend={onSend} className={className} style={style} />
    case 'checklist':  return <ChecklistRenderer  spec={spec} onSend={onSend} className={className} style={style} />
    case 'poll':       return <PollRenderer       spec={spec} onSend={onSend} className={className} style={style} />
    case 'quiz':       return <QuizRenderer       spec={spec} onSend={onSend} className={className} style={style} />
    default:           return null
  }
}
