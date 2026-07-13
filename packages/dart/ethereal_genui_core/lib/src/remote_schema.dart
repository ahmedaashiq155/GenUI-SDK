import 'dart:async';
import 'dart:convert';

import 'genui_schema.dart';

class GenUiRemoteSchemaResponse {
  const GenUiRemoteSchemaResponse({
    required this.statusCode,
    required this.body,
    this.etag,
    this.signature,
  });

  final int statusCode;
  final String body;
  final String? etag;
  final String? signature;
}

typedef GenUiRemoteSchemaFetcher =
    Future<GenUiRemoteSchemaResponse> Function(Uri uri, {String? etag});
typedef GenUiRemoteSchemaVerifier =
    FutureOr<bool> Function(List<int> bodyBytes, String? signature);

class GenUiRemoteSchemaPolicy {
  const GenUiRemoteSchemaPolicy({
    required this.allowedHosts,
    this.maxBytes = 512 * 1024,
    this.maxBlocks = 200,
    this.maxFieldsPerBlock = 100,
    this.allowUnknownTypes = false,
    this.minimumVersion = genUiSchemaVersion,
    this.maximumVersion = genUiSchemaVersion,
  });

  final Set<String> allowedHosts;
  final int maxBytes;
  final int maxBlocks;
  final int maxFieldsPerBlock;
  final bool allowUnknownTypes;
  final int minimumVersion;
  final int maximumVersion;

  void validateEndpoint(Uri uri) {
    if (uri.scheme != 'https') {
      throw const FormatException('remote schema endpoint must use https');
    }
    if (!allowedHosts.contains(uri.host)) {
      throw FormatException(
        'remote schema host is not allowlisted: ${uri.host}',
      );
    }
  }
}

class GenUiRemoteSchemaSnapshot {
  const GenUiRemoteSchemaSnapshot({
    required this.version,
    required this.revision,
    required this.catalog,
    required this.loadedAt,
    this.etag,
  });

  final int version;
  final String revision;
  final List<GenUiBlockSchema> catalog;
  final DateTime loadedAt;
  final String? etag;

  GenUiValidation validate(Object? spec) =>
      validateGenUiSpec(spec, catalog: catalog);

  String buildPromptCatalogue() => buildGenUiPromptCatalogue(catalog: catalog);
}

/// Secure, transport-injected remote catalog loader with atomic swaps, ETags
/// and optional signature verification. It loads data only—never renderer code.
class GenUiRemoteSchemaController {
  GenUiRemoteSchemaController({
    required this.endpoint,
    required this.fetcher,
    required this.policy,
    this.verifier,
  }) : current = GenUiRemoteSchemaSnapshot(
         version: genUiSchemaVersion,
         revision: 'built-in',
         catalog: genUiCatalog,
         loadedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
       ) {
    policy.validateEndpoint(endpoint);
  }

  final Uri endpoint;
  final GenUiRemoteSchemaFetcher fetcher;
  final GenUiRemoteSchemaPolicy policy;
  final GenUiRemoteSchemaVerifier? verifier;
  final StreamController<GenUiRemoteSchemaSnapshot> _changes =
      StreamController.broadcast(sync: true);
  Timer? _timer;
  Future<GenUiRemoteSchemaSnapshot>? _inFlight;

  GenUiRemoteSchemaSnapshot current;
  Object? lastError;
  Stream<GenUiRemoteSchemaSnapshot> get changes => _changes.stream;

  Future<GenUiRemoteSchemaSnapshot> reload() =>
      _inFlight ??= _reload().whenComplete(() => _inFlight = null);

  Future<GenUiRemoteSchemaSnapshot> _reload() async {
    try {
      final response = await fetcher(endpoint, etag: current.etag);
      if (response.statusCode == 304) return current;
      if (response.statusCode != 200) {
        throw FormatException(
          'remote schema returned HTTP ${response.statusCode}',
        );
      }
      final bytes = utf8.encode(response.body);
      if (bytes.length > policy.maxBytes) {
        throw const FormatException('remote schema exceeds size limit');
      }
      final verify = verifier;
      if (verify != null && !await verify(bytes, response.signature)) {
        throw const FormatException('remote schema signature rejected');
      }
      final decoded = jsonDecode(response.body);
      final next = _parseSnapshot(decoded, response.etag);
      current = next;
      lastError = null;
      _changes.add(next);
      return next;
    } catch (error) {
      lastError = error;
      rethrow;
    }
  }

  GenUiRemoteSchemaSnapshot _parseSnapshot(Object? decoded, String? etag) {
    if (decoded is! Map || decoded['format'] != 'ethereal-genui-catalog') {
      throw const FormatException('invalid remote schema format');
    }
    final version = decoded['version'];
    if (version is! num ||
        version.toInt() < policy.minimumVersion ||
        version.toInt() > policy.maximumVersion) {
      throw const FormatException('unsupported remote schema version');
    }
    final rawBlocks = decoded['blocks'];
    if (rawBlocks is! List || rawBlocks.length > policy.maxBlocks) {
      throw const FormatException('invalid remote schema blocks');
    }
    final remote = rawBlocks.map(_parseBlock).toList(growable: false);
    final builtInTypes = genUiCatalog.map((block) => block.type).toSet();
    if (!policy.allowUnknownTypes &&
        remote.any((block) => !builtInTypes.contains(block.type))) {
      throw const FormatException(
        'remote schema contains a type without a built-in renderer',
      );
    }
    final replacements = {for (final block in remote) block.type: block};
    final catalog = <GenUiBlockSchema>[
      for (final block in genUiCatalog)
        replacements.remove(block.type) ?? block,
      if (policy.allowUnknownTypes) ...replacements.values,
    ];
    final allTypes = <String>{};
    for (final block in catalog) {
      for (final type in block.allTypes) {
        if (!allTypes.add(type)) {
          throw FormatException('duplicate remote schema type or alias: $type');
        }
      }
    }
    final revision = (decoded['revision'] ?? etag ?? 'remote').toString();
    return GenUiRemoteSchemaSnapshot(
      version: version.toInt(),
      revision: revision.substring(0, revision.length.clamp(0, 128)),
      catalog: List.unmodifiable(catalog),
      loadedAt: DateTime.now().toUtc(),
      etag: etag,
    );
  }

  GenUiBlockSchema _parseBlock(Object? raw) {
    if (raw is! Map) throw const FormatException('invalid remote block');
    final type = _safeString(raw['type'], 'block type', 64);
    final categoryName = _safeString(raw['category'], 'block category', 32);
    final category = GenUiCategory.values
        .where((value) => value.name == categoryName)
        .firstOrNull;
    if (category == null) throw const FormatException('invalid block category');
    final example = _safeString(raw['example'], 'block example', 8192);
    final rawFields = raw['fields'] ?? const <Object?>[];
    if (rawFields is! List || rawFields.length > policy.maxFieldsPerBlock) {
      throw const FormatException('invalid remote block fields');
    }
    final fields = rawFields.map(_parseField).toList(growable: false);
    final aliases = raw['aliases'] is List
        ? (raw['aliases'] as List)
              .map((value) => _safeString(value, 'block alias', 64))
              .toList(growable: false)
        : const <String>[];
    return GenUiBlockSchema(
      type: type,
      category: category,
      example: example,
      fields: fields,
      aliases: aliases,
      childrenAllowed: raw['childrenAllowed'] == true,
      note: raw['note'] == null
          ? null
          : _safeString(raw['note'], 'block note', 2048),
    );
  }

  GenUiField _parseField(Object? raw) {
    if (raw is! Map) throw const FormatException('invalid remote field');
    const types = {
      'string',
      'int',
      'double',
      'bool',
      'num',
      'list',
      'map',
      'color',
      'enum',
    };
    final type = _safeString(raw['type'], 'field type', 16);
    if (!types.contains(type))
      throw const FormatException('invalid field type');
    final enumValues = raw['enumValues'] is List
        ? (raw['enumValues'] as List)
              .map((value) => _safeString(value, 'enum value', 128))
              .toList(growable: false)
        : null;
    return GenUiField(
      _safeString(raw['name'], 'field name', 64),
      type,
      required: raw['required'] == true,
      enumValues: enumValues,
    );
  }

  String _safeString(Object? value, String label, int maxLength) {
    if (value is! String || value.isEmpty || value.length > maxLength) {
      throw FormatException('invalid $label');
    }
    return value;
  }

  void startPolling(Duration interval) {
    if (interval < const Duration(seconds: 5)) {
      throw ArgumentError('remote schema polling must be at least 5s');
    }
    _timer?.cancel();
    _timer = Timer.periodic(
      interval,
      (_) => unawaited(reload().catchError((_) => current)),
    );
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    stopPolling();
    await _changes.close();
  }
}
