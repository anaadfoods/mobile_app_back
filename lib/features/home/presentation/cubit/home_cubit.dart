import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_banners_use_case.dart';
import '../../domain/usecases/get_communities_use_case.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetBannersUseCase _getBannersUseCase;
  final GetCommunitiesUseCase _getCommunitiesUseCase;

  HomeCubit({
    required GetBannersUseCase getBannersUseCase,
    required GetCommunitiesUseCase getCommunitiesUseCase,
  })  : _getBannersUseCase = getBannersUseCase,
        _getCommunitiesUseCase = getCommunitiesUseCase,
        super(HomeInitial());

  Future<void> loadHomeData() async {
    emit(HomeLoading());

    var currentState = const HomeSuccess();

    await Future.wait([
      Future.sync(() => _getBannersUseCase()).then((banners) {
        currentState = currentState.copyWith(banners: banners);
      }).catchError((_) {
        // Handle section failure to allow partial UI rendering
      }),
      Future.sync(() => _getCommunitiesUseCase()).then((communities) {
        currentState = currentState.copyWith(communities: communities);
      }).catchError((_) {
        // Handle section failure to allow partial UI rendering
      }),
    ]);

    emit(currentState);
  }
}
