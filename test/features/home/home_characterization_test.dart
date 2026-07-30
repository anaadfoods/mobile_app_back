import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/home/domain/entities/banner_entity.dart';
import 'package:grocery_app/features/home/domain/entities/community_entity.dart';
import 'package:grocery_app/features/home/domain/usecases/get_banners_use_case.dart';
import 'package:grocery_app/features/home/domain/usecases/get_communities_use_case.dart';
import 'package:grocery_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:grocery_app/features/home/presentation/cubit/home_state.dart';

class MockGetBannersUseCase extends Mock implements GetBannersUseCase {}
class MockGetCommunitiesUseCase extends Mock implements GetCommunitiesUseCase {}

void main() {
  late MockGetBannersUseCase mockGetBanners;
  late MockGetCommunitiesUseCase mockGetCommunities;

  const testBanner = BannerEntity(
    id: 1,
    title: 'Test Banner',
    subtitle: 'Subtitle',
    image: 'banner.png',
    link: null,
    isActive: true,
    startDate: '2026-01-01',
    endDate: '2026-12-31',
    priority: 1,
  );

  const testCommunity = CommunityEntity(
    id: 1,
    name: 'Test Community',
    description: 'Description',
    image: 'comm.png',
    benefits: 'Benefits',
    comingSoon: false,
    launchDate: '2026-01-01',
    fullImageUrl: 'https://bck-dev.anaadfoods.com/comm.png',
  );

  setUp(() {
    mockGetBanners = MockGetBannersUseCase();
    mockGetCommunities = MockGetCommunitiesUseCase();

    when(() => mockGetBanners()).thenAnswer((_) async => [testBanner]);
    when(() => mockGetCommunities()).thenAnswer((_) async => [testCommunity]);
  });

  HomeCubit buildCubit() {
    return HomeCubit(
      getBannersUseCase: mockGetBanners,
      getCommunitiesUseCase: mockGetCommunities,
    );
  }

  test('loadHomeData emits HomeLoading then HomeSuccess with banners and communities', () async {
    final cubit = buildCubit();
    await cubit.loadHomeData();

    expect(cubit.state, isA<HomeSuccess>());
    final success = cubit.state as HomeSuccess;
    expect(success.banners.length, 1);
    expect(success.communities.length, 1);
  });

  test('loadHomeData handles banner failure gracefully and loads communities', () async {
    when(() => mockGetBanners()).thenThrow(Exception('Banner error'));
    final cubit = buildCubit();
    await cubit.loadHomeData();

    expect(cubit.state, isA<HomeSuccess>());
    final success = cubit.state as HomeSuccess;
    expect(success.banners.isEmpty, true);
    expect(success.communities.length, 1);
  });
}
