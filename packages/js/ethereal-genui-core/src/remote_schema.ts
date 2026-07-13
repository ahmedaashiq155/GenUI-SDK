import {
  GENUI_SCHEMA_VERSION,
  buildGenUiPromptCatalogue,
  genUiCatalog,
  validateGenUiSpec,
  type GenUiBlockSchema,
  type GenUiCategory,
  type GenUiField,
  type GenUiValidation,
} from './genui_schema.js'

export interface GenUiRemoteSchemaResponse {
  statusCode: number
  body: string
  etag?: string
  signature?: string
}

export type GenUiRemoteSchemaFetcher = (
  endpoint: URL,
  options: { etag?: string },
) => Promise<GenUiRemoteSchemaResponse>

export type GenUiRemoteSchemaVerifier = (
  body: Uint8Array,
  signature?: string,
) => boolean | Promise<boolean>

export interface GenUiRemoteSchemaPolicy {
  allowedHosts: ReadonlySet<string>
  maxBytes?: number
  maxBlocks?: number
  maxFieldsPerBlock?: number
  allowUnknownTypes?: boolean
  minimumVersion?: number
  maximumVersion?: number
}

export interface GenUiRemoteSchemaSnapshot {
  version: number
  revision: string
  catalog: readonly GenUiBlockSchema[]
  loadedAt: Date
  etag?: string
  validate(spec: unknown): GenUiValidation
  buildPromptCatalogue(): string
}

const categories = new Set<GenUiCategory>([
  'interactive', 'display', 'moreInteractive', 'charts', 'moreDisplay',
  'miniTools', 'layout', 'primitives', 'artifact', 'directive',
])
const fieldTypes = new Set([
  'string', 'int', 'double', 'bool', 'num', 'list', 'map', 'color', 'enum',
])

function snapshot(
  version: number,
  revision: string,
  catalog: readonly GenUiBlockSchema[],
  etag?: string,
): GenUiRemoteSchemaSnapshot {
  return {
    version,
    revision,
    catalog,
    loadedAt: new Date(),
    ...(etag ? { etag } : {}),
    validate: (spec) => validateGenUiSpec(spec, '$', catalog),
    buildPromptCatalogue: () => buildGenUiPromptCatalogue(catalog),
  }
}

/** Secure data-only hot reload. Renderer code can never arrive remotely. */
export class GenUiRemoteSchemaController {
  readonly endpoint: URL
  readonly fetcher: GenUiRemoteSchemaFetcher
  readonly policy: Required<Omit<GenUiRemoteSchemaPolicy, 'allowedHosts'>> & Pick<GenUiRemoteSchemaPolicy, 'allowedHosts'>
  readonly verifier?: GenUiRemoteSchemaVerifier
  current = snapshot(GENUI_SCHEMA_VERSION, 'built-in', genUiCatalog)
  lastError: unknown = null
  private listeners = new Set<() => void>()
  private inFlight?: Promise<GenUiRemoteSchemaSnapshot>
  private timer?: ReturnType<typeof setInterval>

  constructor(options: {
    endpoint: string | URL
    fetcher: GenUiRemoteSchemaFetcher
    policy: GenUiRemoteSchemaPolicy
    verifier?: GenUiRemoteSchemaVerifier
  }) {
    this.endpoint = new URL(options.endpoint)
    this.fetcher = options.fetcher
    this.verifier = options.verifier
    this.policy = {
      allowedHosts: options.policy.allowedHosts,
      maxBytes: options.policy.maxBytes ?? 512 * 1024,
      maxBlocks: options.policy.maxBlocks ?? 200,
      maxFieldsPerBlock: options.policy.maxFieldsPerBlock ?? 100,
      allowUnknownTypes: options.policy.allowUnknownTypes ?? false,
      minimumVersion: options.policy.minimumVersion ?? GENUI_SCHEMA_VERSION,
      maximumVersion: options.policy.maximumVersion ?? GENUI_SCHEMA_VERSION,
    }
    if (this.endpoint.protocol !== 'https:') throw new Error('remote schema endpoint must use https')
    if (!this.policy.allowedHosts.has(this.endpoint.hostname)) {
      throw new Error(`remote schema host is not allowlisted: ${this.endpoint.hostname}`)
    }
  }

  subscribe = (listener: () => void) => {
    this.listeners.add(listener)
    return () => this.listeners.delete(listener)
  }

  reload(): Promise<GenUiRemoteSchemaSnapshot> {
    if (this.inFlight) return this.inFlight
    this.inFlight = this.reloadOnce().finally(() => { this.inFlight = undefined })
    return this.inFlight
  }

  private async reloadOnce(): Promise<GenUiRemoteSchemaSnapshot> {
    try {
      const response = await this.fetcher(this.endpoint, { etag: this.current.etag })
      if (response.statusCode === 304) return this.current
      if (response.statusCode !== 200) throw new Error(`remote schema returned HTTP ${response.statusCode}`)
      const bytes = new TextEncoder().encode(response.body)
      if (bytes.byteLength > this.policy.maxBytes) throw new Error('remote schema exceeds size limit')
      if (this.verifier && !await this.verifier(bytes, response.signature)) {
        throw new Error('remote schema signature rejected')
      }
      const next = this.parseSnapshot(JSON.parse(response.body) as unknown, response.etag)
      this.current = next
      this.lastError = null
      this.listeners.forEach((listener) => listener())
      return next
    } catch (error) {
      this.lastError = error
      throw error
    }
  }

  private parseSnapshot(raw: unknown, etag?: string): GenUiRemoteSchemaSnapshot {
    if (!isRecord(raw) || raw.format !== 'ethereal-genui-catalog') throw new Error('invalid remote schema format')
    const version = raw.version
    if (typeof version !== 'number' || !Number.isInteger(version) ||
        version < this.policy.minimumVersion || version > this.policy.maximumVersion) {
      throw new Error('unsupported remote schema version')
    }
    if (!Array.isArray(raw.blocks) || raw.blocks.length > this.policy.maxBlocks) {
      throw new Error('invalid remote schema blocks')
    }
    const remote = raw.blocks.map((block) => this.parseBlock(block))
    const builtInTypes = new Set(genUiCatalog.map((block) => block.type))
    if (!this.policy.allowUnknownTypes && remote.some((block) => !builtInTypes.has(block.type))) {
      throw new Error('remote schema contains a type without a built-in renderer')
    }
    const replacements = new Map(remote.map((block) => [block.type, block]))
    const catalog = genUiCatalog.map((block) => {
      const replacement = replacements.get(block.type)
      replacements.delete(block.type)
      return replacement ?? block
    })
    if (this.policy.allowUnknownTypes) catalog.push(...replacements.values())
    const types = new Set<string>()
    for (const block of catalog) {
      for (const type of block.allTypes) {
        if (types.has(type)) throw new Error(`duplicate remote schema type or alias: ${type}`)
        types.add(type)
      }
    }
    const revision = safeString(raw.revision ?? etag ?? 'remote', 'revision', 128)
    return snapshot(version, revision, Object.freeze(catalog), etag)
  }

  private parseBlock(raw: unknown): GenUiBlockSchema {
    if (!isRecord(raw)) throw new Error('invalid remote block')
    const type = safeString(raw.type, 'block type', 64)
    const category = safeString(raw.category, 'block category', 32) as GenUiCategory
    if (!categories.has(category)) throw new Error('invalid block category')
    if (raw.fields !== undefined && (!Array.isArray(raw.fields) || raw.fields.length > this.policy.maxFieldsPerBlock)) {
      throw new Error('invalid remote block fields')
    }
    const fields = (raw.fields ?? []).map((field: unknown) => this.parseField(field))
    const aliases = Array.isArray(raw.aliases)
      ? raw.aliases.map((alias) => safeString(alias, 'block alias', 64))
      : []
    return Object.freeze({
      type,
      category,
      example: safeString(raw.example, 'block example', 8192),
      fields: Object.freeze(fields),
      aliases: Object.freeze(aliases),
      childrenAllowed: raw.childrenAllowed === true,
      ...(raw.note === undefined ? {} : { note: safeString(raw.note, 'block note', 2048) }),
      allTypes: Object.freeze([type, ...aliases]),
    })
  }

  private parseField(raw: unknown): GenUiField {
    if (!isRecord(raw)) throw new Error('invalid remote field')
    const type = safeString(raw.type, 'field type', 16)
    if (!fieldTypes.has(type)) throw new Error('invalid field type')
    return Object.freeze({
      name: safeString(raw.name, 'field name', 64),
      type: type as GenUiField['type'],
      required: raw.required === true,
      ...(Array.isArray(raw.enumValues)
        ? { enumValues: Object.freeze(raw.enumValues.map((value) => safeString(value, 'enum value', 128))) }
        : {}),
    })
  }

  startPolling(intervalMs: number) {
    if (!Number.isFinite(intervalMs) || intervalMs < 5000) throw new Error('remote schema polling must be at least 5s')
    this.stopPolling()
    this.timer = setInterval(() => { void this.reload().catch(() => undefined) }, intervalMs)
  }

  stopPolling() {
    if (this.timer !== undefined) clearInterval(this.timer)
    this.timer = undefined
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}

function safeString(value: unknown, label: string, maxLength: number): string {
  if (typeof value !== 'string' || value.length === 0 || value.length > maxLength) {
    throw new Error(`invalid ${label}`)
  }
  return value
}
