# Security model

Ethereal GenUI treats every model-authored spec as attacker-influenced input.
Validation and renderer hardening reduce crashes and unsafe interpretation, but
they do not turn model output into trusted application intent. Hosts remain the
security boundary for network access, persistence, navigation, privileged
actions, and artifact execution.

## User-visible labels and dispatched values

Interactive options deliberately separate the displayed `label` from the
dispatched `value` or `send` text. A spec can therefore display “Yes” while
sending different text as the next user message. Do not use a rendered label as
authorization for a sensitive operation. For consequential actions, show the
actual outgoing value, require a host-owned confirmation, and validate the
operation again outside the renderer.

## Local state and `set`

Primitive `button` and `box` blocks can update `GenUiStateScope`/`GenUiStore`
keys through an unscoped `set` map. Keep model-controlled state in an isolated
scope, do not share privileged application-state keys with that scope, and
whitelist or translate any state that crosses into host business logic.

## Directives

`theme` and `shortcuts` directives render a preview and require an explicit user
tap before invoking the corresponding host callback. Hosts should still validate
colors, shortcut counts, lengths, and persistence policy before applying them.

## Remote images

Gallery renderers only load `https://` URLs. Loading any remote image still
reveals network metadata such as the user's IP address and can act as a tracking
pixel. React images use lazy loading and `referrerPolicy="no-referrer"`; Flutter
network behavior is controlled by the host platform. Privacy-sensitive hosts
should proxy or cache images, enforce an allowlist and size limits, and apply
their own network security policy.

## HTML artifacts

The SDK does not execute `artifact.kind: "html"`; it passes the artifact to the
host's `openArtifact` callback. If a host chooses to render that content, treat
it as active hostile code and isolate it from the app:

- Use a separate-origin iframe or equivalently isolated WebView with the
  smallest possible sandbox. Never combine `allow-scripts` with
  `allow-same-origin` for untrusted same-origin content.
- Apply a restrictive Content Security Policy, preferably `default-src 'none'`,
  and opt into only the exact resources required.
- Block `file://`, custom schemes, popups, downloads, top-level navigation, and
  external navigation unless the host validates and handles them explicitly.
- Expose no privileged JavaScript/native bridge, cookies, credentials, local
  storage, filesystem access, clipboard access, or host DOM access.
- Destroy the sandbox when the artifact closes and do not reuse its storage or
  process as a trusted browsing context.

## Direct provider connections

API keys embedded in Flutter or web clients can be extracted. Direct LLM
connections are suitable for prototypes and controlled internal tools only.
Production hosts should proxy provider requests through a service that owns the
credential and enforces authentication, authorization, quotas, and logging.

## Reporting

Please report suspected vulnerabilities privately to the repository maintainers
and avoid including live credentials, private prompts, or user data in reports.
