import 'dart:io';

void main() {
  final directory = Directory('lib');
  final files = directory.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  final states = [
    'AuthInitial',
    'AuthLoading',
    'Authenticated',
    'Unauthenticated',
    'AuthProfileUpdateSuccess',
    'AuthAddressUpdated',
    'AuthRegistrationSuccess',
    'AuthError',
    'AuthDeactivationOtpSent'
  ];

  for (final file in files) {
    if (file.path.contains('features/auth/')) continue; // Skip new auth feature files
    if (file.path.endsWith('global_import.dart')) continue;

    var content = file.readAsStringSync();
    if (!content.contains('global_import.dart')) continue;

    final importsToAdd = <String>[];

    if (content.contains('AuthCubit') && !content.contains('auth_cubit.dart')) {
      importsToAdd.add("import 'package:grocery_app/cubits/auth/auth_cubit.dart';");
    }
    
    final usesState = states.any((state) => content.contains(state));
    if (usesState && !content.contains('auth_state.dart')) {
      importsToAdd.add("import 'package:grocery_app/cubits/auth/auth_state.dart';");
    }

    if (content.contains('TokenService') && !content.contains('token_service.dart')) {
      importsToAdd.add("import 'package:grocery_app/services/token_service.dart';");
    }
    if (content.contains('OAuthService') && !content.contains('oauth_service.dart')) {
      importsToAdd.add("import 'package:grocery_app/services/oauth_service.dart';");
    }

    if (importsToAdd.isNotEmpty) {
      // Dedup
      final uniqueImports = importsToAdd.toSet().toList();
      final lines = content.split('\n');
      var insertIdx = -1;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim().startsWith('import ')) {
          insertIdx = i;
          break;
        }
      }
      if (insertIdx != -1) {
        // Filter out imports that are already explicitly there in any form
        uniqueImports.removeWhere((imp) => content.contains(imp));
        if (uniqueImports.isNotEmpty) {
          lines.insert(insertIdx, uniqueImports.join('\n'));
          file.writeAsStringSync(lines.join('\n'));
          print('Added imports to ${file.path}: ${uniqueImports.map((s) => s.split('/').last).join(', ')}');
        }
      }
    }
  }
}
