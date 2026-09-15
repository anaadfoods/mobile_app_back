import '../entities/community_entity.dart';
import '../repositories/home_repository.dart';

class GetCommunitiesUseCase {
  final HomeRepository _repository;

  const GetCommunitiesUseCase(this._repository);

  Future<List<CommunityEntity>> call() async {
    return await _repository.getCommunities();
  }
}
