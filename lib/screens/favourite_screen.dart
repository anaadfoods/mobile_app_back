import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/models/favorite_model.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/common_widgets/shimmer_loading.dart';

class FavouriteScreen extends StatefulWidget {
  @override
  _FavouriteScreenState createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  final AuthService _authService = AuthService();
  List<FavoriteModel> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    // Listen to auth state changes
    AuthService.authStateChanges.listen((isLoggedIn) {
      if (isLoggedIn) {
        _loadFavorites();
      } else {
        setState(() {
          _favorites = [];
        });
      }
    });
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        setState(() {
          _isLoading = false;
          _error = 'Please login to view favorites';
        });

        // Navigate to login screen
        Future.microtask(() {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        });
        return;
      }

      final result = await _authService.getFavorites();
      print(result);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (result['success']) {
          _favorites = List<FavoriteModel>.from(result['data']);
        } else {
          _error = result['message'];
          if (result['code'] == 'unauthenticated' ||
              result['code'] == 'token_expired') {
            // Navigate to login screen
            Future.microtask(() {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            });
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'An error occurred while fetching favorites';
      });
      print('Error loading favorites: $e');
    }
  }

  Future<void> _removeFromFavorites(FavoriteModel favorite) async {
    try {
      // Get the product ID from the API response structure
      final result = await _authService.toggleFavorite(favorite.id);

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _favorites.removeWhere((item) => item.id == favorite.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Removed from favorites'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (result['code'] == 'unauthenticated' ||
            result['code'] == 'token_expired') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Failed to remove from favorites',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error removing from favorites: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove from favorites: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return ShimmerLoading(
          child: Container(
            height: 100,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            text: _error ?? 'An error occurred',
            fontWeight: FontWeight.w600,
            color: Color(0xFF7C7C7C),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFavorites,
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Color(0xFF7C7C7C)),
          SizedBox(height: 16),
          AppText(
            text: "No Favorite Items",
            fontWeight: FontWeight.w600,
            color: Color(0xFF7C7C7C),
          ),
          SizedBox(height: 8),
          AppText(
            text: "Start adding items to your favorites",
            fontSize: 14,
            color: Color(0xFF7C7C7C),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(FavoriteModel favorite) {
    return Dismissible(
      key: Key(favorite.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _removeFromFavorites(favorite),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.favorite, color: AppColors.primaryColor),
          ),
          title: AppText(text: favorite.name, fontWeight: FontWeight.w600),
          subtitle: AppText(
            text: favorite.weight,
            fontSize: 14,
            color: Color(0xFF7C7C7C),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () {
              print(favorite.id);
              _removeFromFavorites(favorite);
            },
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_favorites.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) => _buildFavoriteItem(_favorites[index]),
      ),
    );
  }
}
