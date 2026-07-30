import 'package:equatable/equatable.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/community_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeSuccess extends HomeState {
  final List<BannerEntity> banners;
  final List<CommunityEntity> communities;

  const HomeSuccess({
    this.banners = const [],
    this.communities = const [],
  });

  HomeSuccess copyWith({
    List<BannerEntity>? banners,
    List<CommunityEntity>? communities,
  }) {
    return HomeSuccess(
      banners: banners ?? this.banners,
      communities: communities ?? this.communities,
    );
  }

  @override
  List<Object?> get props => [banners, communities];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
