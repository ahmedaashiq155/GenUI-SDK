import 'dart:async';
import 'package:flutter/foundation.dart';

enum GenUiAttachmentKind { image, audio, video, file }

/// Host-owned attachment metadata. The engine never fetches [uri] or uploads
/// [bytes]; the host decides how media is stored, scanned and transmitted.
@immutable
class GenUiAttachment {
  const GenUiAttachment({
    required this.id,
    required this.kind,
    required this.name,
    required this.mimeType,
    this.sizeBytes,
    this.uri,
    this.bytes,
    this.altText,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final GenUiAttachmentKind kind;
  final String name;
  final String mimeType;
  final int? sizeBytes;
  final Uri? uri;
  final Uint8List? bytes;
  final String? altText;
  final Map<String, Object?> metadata;
}

/// One typed user turn containing text, media, or both.
@immutable
class GenUiMessageInput {
  const GenUiMessageInput({
    this.text = '',
    this.attachments = const <GenUiAttachment>[],
    this.metadata = const <String, Object?>{},
  });

  final String text;
  final List<GenUiAttachment> attachments;
  final Map<String, Object?> metadata;

  bool get isEmpty => text.trim().isEmpty && attachments.isEmpty;
}

typedef GenUiInputSender = FutureOr<void> Function(GenUiMessageInput input);
typedef GenUiAttachmentPicker = FutureOr<List<GenUiAttachment>> Function();
