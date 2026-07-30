import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart tool/scaffold_feature.dart <feature_name>');
    exit(1);
  }

  final featureName = args[0].toLowerCase();
  final snakeCase = featureName;
  
  // simple pascalCase conversion (e.g. auth -> Auth, refer_earn -> ReferEarn)
  final pascalCase = snakeCase.split('_').map((part) {
    if (part.isEmpty) return '';
    return part[0].toUpperCase() + part.substring(1);
  }).join('');

  print('Scaffolding feature: $featureName (PascalCase: $pascalCase)');

  final brickDir = Directory('bricks/feature_brick/__brick__');
  if (!brickDir.existsSync()) {
    print('Error: bricks/feature_brick/__brick__ does not exist.');
    exit(1);
  }

  final files = brickDir.listSync(recursive: true);
  for (final entity in files) {
    if (entity is File) {
      final relativePath = entity.path.substring(brickDir.path.length + 1);
      
      // Process path template variables
      var targetPath = relativePath
          .replaceAll('{{name.snakeCase()}}', snakeCase)
          .replaceAll('{{name.pascalCase()}}', pascalCase);

      final targetFile = File(targetPath);
      
      // Create directories
      targetFile.parent.createSync(recursive: true);

      // Process file content template variables
      var content = entity.readAsStringSync();
      content = content
          .replaceAll('{{name.snakeCase()}}', snakeCase)
          .replaceAll('{{name.pascalCase()}}', pascalCase);

      targetFile.writeAsStringSync(content);
      print('Created: $targetPath');
    }
  }

  print('Feature $featureName scaffolded successfully!');
}
