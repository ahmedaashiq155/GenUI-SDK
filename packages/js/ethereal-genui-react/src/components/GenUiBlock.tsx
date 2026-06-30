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
import { CardRenderer } from './renderers/CardRenderer.js'
import { CalloutRenderer } from './renderers/CalloutRenderer.js'
import { StatRenderer } from './renderers/StatRenderer.js'
import { TableRenderer } from './renderers/TableRenderer.js'
import { TimelineRenderer } from './renderers/TimelineRenderer.js'
import { ProgressRenderer } from './renderers/ProgressRenderer.js'
import { BadgesRenderer } from './renderers/BadgesRenderer.js'
import { GalleryRenderer } from './renderers/GalleryRenderer.js'
import { DividerRenderer } from './renderers/DividerRenderer.js'
import { CalculatorRenderer } from './renderers/CalculatorRenderer.js'
import { ConverterRenderer } from './renderers/ConverterRenderer.js'
import { TimerRenderer } from './renderers/TimerRenderer.js'

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
    case 'card':       return <CardRenderer       spec={spec} onSend={onSend} className={className} style={style} />
    case 'callout':    return <CalloutRenderer    spec={spec} onSend={onSend} className={className} style={style} />
    case 'stat':       return <StatRenderer       spec={spec} onSend={onSend} className={className} style={style} />
    case 'table':      return <TableRenderer      spec={spec} onSend={onSend} className={className} style={style} />
    case 'timeline':   return <TimelineRenderer   spec={spec} onSend={onSend} className={className} style={style} />
    case 'progress':   return <ProgressRenderer   spec={spec} onSend={onSend} className={className} style={style} />
    case 'badges':     return <BadgesRenderer     spec={spec} onSend={onSend} className={className} style={style} />
    case 'gallery':    return <GalleryRenderer    spec={spec} onSend={onSend} className={className} style={style} />
    case 'divider':    return <DividerRenderer    className={className} style={style} />
    case 'calculator': return <CalculatorRenderer spec={spec} onSend={onSend} className={className} style={style} />
    case 'converter':  return <ConverterRenderer  spec={spec} onSend={onSend} className={className} style={style} />
    case 'timer':      return <TimerRenderer      spec={spec} onSend={onSend} className={className} style={style} />
    default:           return null
  }
}
