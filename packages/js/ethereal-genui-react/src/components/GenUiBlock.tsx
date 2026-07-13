import React, { createContext, useContext, useEffect } from 'react'
import { useOptionalGenUiDebug } from '../devtools.js'
import { useOptionalGenUiActions } from '../provider.js'
import { GenUiPlaceholder } from './GenUiPlaceholder.js'
import { GenUiErrorBoundary } from './GenUiErrorBoundary.js'
import {
  GenUiInteractionBoundary,
  useOptionalGenUiInteraction,
} from './GenUiInteraction.js'
import { TextRenderer } from './renderers/TextRenderer.js'
import { IconRenderer } from './renderers/IconRenderer.js'
import { SpacerRenderer } from './renderers/SpacerRenderer.js'
import { ButtonRenderer } from './renderers/ButtonRenderer.js'
import { BoxRenderer } from './renderers/BoxRenderer.js'
import { RowRenderer } from './renderers/RowRenderer.js'
import { ColumnRenderer } from './renderers/ColumnRenderer.js'
import { StackRenderer } from './renderers/StackRenderer.js'
import { ChartRenderer } from './renderers/ChartRenderer.js'
import { ArtifactRenderer } from './renderers/ArtifactRenderer.js'
import { ThemeDirectiveRenderer } from './renderers/ThemeDirectiveRenderer.js'
import { ShortcutsDirectiveRenderer } from './renderers/ShortcutsDirectiveRenderer.js'
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
import { SectionRenderer } from './renderers/SectionRenderer.js'
import { GridRenderer } from './renderers/GridRenderer.js'
import { ColumnsRenderer } from './renderers/ColumnsRenderer.js'
import { AccordionRenderer } from './renderers/AccordionRenderer.js'
import { TabsRenderer } from './renderers/TabsRenderer.js'
import { WhenRenderer } from './renderers/WhenRenderer.js'
import { AnimationRenderer } from './renderers/AnimationRenderer.js'

export interface GenUiBlockProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  /** External turn availability. Also combines with GenUiProvider.actions.enabled. */
  enabled?: boolean
  className?: string
  style?: React.CSSProperties
}

/**
 * Maximum nesting depth for one spec tree. A hostile/buggy model can nest a
 * spec thousands deep; without a cap that blows the render stack (RangeError)
 * and, absent a boundary, unmounts the host app. 24 is far deeper than any
 * real layout. Mirrors Dart's kGenUiMaxDepth.
 */
const MAX_DEPTH = 24
const DepthContext = createContext(0)

export function GenUiBlock({ spec, onSend, enabled = true, className, style }: GenUiBlockProps) {
  const depth = useContext(DepthContext)
  const existingInteraction = useOptionalGenUiInteraction()
  const providerActions = useOptionalGenUiActions()
  const debug = useOptionalGenUiDebug()
  useEffect(() => {
    debug?.record({ type: 'render', blockType: String(spec.type ?? '') })
  }, [debug, spec])
  if (depth >= MAX_DEPTH) {
    return <GenUiPlaceholder type="too-deep" className={className} style={style} />
  }

  const content = (
    <GenUiErrorBoundary resetKey={spec} className={className} style={style}>
      <DepthContext.Provider value={depth + 1}>
        <GenUiBlockContent spec={spec} className={className} style={style} />
      </DepthContext.Provider>
    </GenUiErrorBoundary>
  )

  if (existingInteraction) return content

  const externallyEnabled = enabled && (providerActions?.enabled ?? true)
  return (
    <GenUiInteractionBoundary enabled={externallyEnabled} onSend={onSend}>
      {content}
    </GenUiInteractionBoundary>
  )
}

function GenUiBlockContent({ spec, className, style }: Omit<GenUiBlockProps, 'onSend'>) {
  const interaction = useOptionalGenUiInteraction()
  // GenUiBlock always establishes or inherits this context.
  return <GenUiBlockInner spec={spec} onSend={interaction!.dispatch} className={className} style={style} />
}

function GenUiBlockInner({ spec, onSend, className, style }: GenUiBlockProps) {
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
    case 'stat':
    case 'kpi':        return <StatRenderer       spec={spec} onSend={onSend} className={className} style={style} />
    case 'table':      return <TableRenderer      spec={spec} onSend={onSend} className={className} style={style} />
    case 'timeline':
    case 'steps':      return <TimelineRenderer   spec={spec} onSend={onSend} className={className} style={style} />
    case 'progress':   return <ProgressRenderer   spec={spec} onSend={onSend} className={className} style={style} />
    case 'badges':
    case 'chips':      return <BadgesRenderer     spec={spec} onSend={onSend} className={className} style={style} />
    case 'gallery':    return <GalleryRenderer    spec={spec} onSend={onSend} className={className} style={style} />
    case 'divider':    return <DividerRenderer    className={className} style={style} />
    case 'calculator': return <CalculatorRenderer spec={spec} onSend={onSend} className={className} style={style} />
    case 'converter':  return <ConverterRenderer  spec={spec} onSend={onSend} className={className} style={style} />
    case 'timer':      return <TimerRenderer      spec={spec} onSend={onSend} className={className} style={style} />
    case 'section':    return <SectionRenderer    spec={spec} onSend={onSend} className={className} style={style} />
    case 'grid':       return <GridRenderer       spec={spec} onSend={onSend} className={className} style={style} />
    case 'columns':    return <ColumnsRenderer    spec={spec} onSend={onSend} className={className} style={style} />
    case 'accordion':  return <AccordionRenderer  spec={spec} onSend={onSend} className={className} style={style} />
    case 'tabs':       return <TabsRenderer       spec={spec} onSend={onSend} className={className} style={style} />
    case 'when':       return <WhenRenderer       spec={spec} onSend={onSend} className={className} style={style} />
    case 'animate':    return <AnimationRenderer  spec={spec} onSend={onSend} className={className} style={style} />
    case 'text':       return <TextRenderer        spec={spec} onSend={onSend} className={className} style={style} />
    case 'icon':       return <IconRenderer        spec={spec} onSend={onSend} className={className} style={style} />
    case 'spacer':     return <SpacerRenderer      spec={spec}                 className={className} style={style} />
    case 'button':     return <ButtonRenderer      spec={spec} onSend={onSend} className={className} style={style} />
    case 'box':
    case 'container':  return <BoxRenderer         spec={spec} onSend={onSend} className={className} style={style} />
    case 'row':        return <RowRenderer         spec={spec} onSend={onSend} className={className} style={style} />
    case 'column':     return <ColumnRenderer      spec={spec} onSend={onSend} className={className} style={style} />
    case 'stack':      return <StackRenderer       spec={spec} onSend={onSend} className={className} style={style} />
    case 'chart':      return <ChartRenderer       spec={spec} onSend={onSend} className={className} style={style} />
    case 'artifact':   return <ArtifactRenderer    spec={spec} onSend={onSend} className={className} style={style} />
    case 'theme':      return <ThemeDirectiveRenderer spec={spec} onSend={onSend} className={className} style={style} />
    case 'shortcuts':  return <ShortcutsDirectiveRenderer spec={spec} onSend={onSend} className={className} style={style} />
    default:           return <GenUiPlaceholder type={type} className={className} style={style} />
  }
}
