// tool/check_architecture.dart
//
// Enforces the layer boundaries and file-size budget defined in
// FLUTTER_MIGRATION.md. Run before considering any feature migration done:
//
//   dart run tool/check_architecture.dart
//
// Exits with code 1 (and prints every violation) if anything fails.
// No external dependencies — plain dart:io + dart:convert.

import 'dart:io';

/// Max lines allowed in any file under lib/features/. Tune this once and
/// keep it consistent — the point is to catch the *next* 2,373-line
/// checkout-screen-style monolith before it happens, not to be precise.
const int maxLinesPerFile = 400;

const String featuresRoot = 'lib/features';

class Violation {
  final String file;
  final String rule;
  final String detail;
  Violation(this.file, this.rule, this.detail);

  @override
  String toString() => '  [$rule] $file\n    -> $detail';
}

/// Returns the layer ("data" | "domain" | "presentation" | null) for a
/// given file path based on its position under lib/features/<feature>/<layer>/...
String? layerOf(String path) {
  final parts = path.split(Platform.pathSeparator);
  final idx = parts.indexOf('features');
  if (idx == -1 || idx + 2 >= parts.length) return null;
  final layer = parts[idx + 2];
  if (layer == 'data' || layer == 'domain' || layer == 'presentation') {
    return layer;
  }
  return null;
}

List<String> extractImports(String content) {
  final importRegex = RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''', multiLine: true);
  return importRegex.allMatches(content).map((m) => m.group(1)!).toList();
}

void main() {
  final featuresDir = Directory(featuresRoot);
  if (!featuresDir.existsSync()) {
    stderr.writeln(
      'No $featuresRoot directory found. Run this from the Flutter project root, '
      'after at least one feature has been scaffolded.',
    );
    exit(1);
  }

  final violations = <Violation>[];
  final dartFiles = featuresDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in dartFiles) {
    final relPath = file.path.replaceFirst('${Directory.current.path}${Platform.pathSeparator}', '');
    final content = file.readAsStringSync();
    final layer = layerOf(relPath);
    final lineCount = '\n'.allMatches(content).length + 1;

    // --- File size budget ---
    if (lineCount > maxLinesPerFile) {
      violations.add(Violation(
        relPath,
        'FILE_SIZE',
        '$lineCount lines exceeds the $maxLinesPerFile line budget. '
            'Split into smaller widgets/use cases.',
      ));
    }

    if (layer == null) continue;

    final imports = extractImports(content);

    if (layer == 'domain') {
      for (final imp in imports) {
        if (imp.startsWith('package:flutter/')) {
          violations.add(Violation(
            relPath,
            'DOMAIN_FLUTTER_IMPORT',
            'domain/ imports "$imp" — domain must be pure Dart.',
          ));
        }
        if (imp.contains('/data/') || imp.contains('/presentation/')) {
          violations.add(Violation(
            relPath,
            'DOMAIN_LAYER_LEAK',
            'domain/ imports "$imp" — domain must not depend on data/ or presentation/.',
          ));
        }
      }
    }

    if (layer == 'presentation') {
      for (final imp in imports) {
        if (imp.contains('/data/')) {
          violations.add(Violation(
            relPath,
            'PRESENTATION_SKIPS_DOMAIN',
            'presentation/ imports "$imp" directly — must go through domain/ (use cases), not data/.',
          ));
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('✅ Architecture check passed — no boundary or size violations.');
    exit(0);
  }

  stderr.writeln('❌ Architecture check failed with ${violations.length} violation(s):\n');
  for (final v in violations) {
    stderr.writeln(v);
  }
  exit(1);
}
