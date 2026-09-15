/// Remote data source for the {{name.snakeCase()}} feature.
///
/// This class owns the actual HTTP/Dio calls for this feature.
/// It does NOT wrap other services — it contains the real network logic.
abstract class {{name.pascalCase()}}RemoteDataSource {
  // TODO: Add remote data source methods
}

class {{name.pascalCase()}}RemoteDataSourceImpl
    implements {{name.pascalCase()}}RemoteDataSource {
  // TODO: Implement remote data source methods
}
