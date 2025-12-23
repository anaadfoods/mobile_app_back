import 'package:grocery_app/common_widgets/global_import.dart';

class FavoriteStateService {
  static final FavoriteStateService _instance =
      FavoriteStateService._internal();
  factory FavoriteStateService() => _instance;
  FavoriteStateService._internal();

  final _favoriteStateController = StreamController<void>.broadcast();
  Stream<void> get onFavoriteChanged => _favoriteStateController.stream;

  void notifyFavoriteChanged() {
    _favoriteStateController.add(null);
  }

  void dispose() {
    _favoriteStateController.close();
  }
}
