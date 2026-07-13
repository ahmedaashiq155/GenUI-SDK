export type GenUiAttachmentKind = 'image' | 'audio' | 'video' | 'file'

/** Host-owned media metadata. GenUI never fetches or uploads attachment data. */
export interface GenUiAttachment {
  id: string
  kind: GenUiAttachmentKind
  name: string
  mimeType: string
  sizeBytes?: number
  uri?: string
  blob?: Blob
  altText?: string
  metadata?: Readonly<Record<string, unknown>>
}

export interface GenUiMessageInput {
  text: string
  attachments: readonly GenUiAttachment[]
  metadata?: Readonly<Record<string, unknown>>
}

export type GenUiAttachmentPicker = () =>
  | readonly GenUiAttachment[]
  | Promise<readonly GenUiAttachment[]>
