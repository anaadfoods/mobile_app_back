import '../../domain/repositories/{{name.snakeCase()}}_repository.dart';

/// Implementation of [{{name.pascalCase()}}Repository].
///
/// Delegates to data sources, maps DTOs to domain entities,
/// and translates exceptions to domain failures.
class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  // TODO: Inject data sources via constructor
  // TODO: Implement repository methods
}
