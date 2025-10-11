import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/shimmer_loading.dart';
import 'package:grocery_app/models/favorite_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/services/favorite_state_service.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/services/cart_service.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  _FavouriteScreenState createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  final AuthService _authService = AuthService();
  final FavoriteStateService _favoriteStateService = FavoriteStateService();
  List<FavoriteModel> _favorites = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _authSubscription;
  StreamSubscription? _favoriteSubscription;

  @override
  void initState() {
    super.initState();
    _loadFavorites();

    _authSubscription = AuthService.authStateChanges.listen((isLoggedIn) {
      if (mounted) {
        if (isLoggedIn) {
          _loadFavorites();
        } else {
          setState(() {
            _favorites = [];
            _error = 'Please login to view favorites';
          });
        }
      }
    });

    _favoriteSubscription = _favoriteStateService.onFavoriteChanged.listen((_) {
      if (mounted) _loadFavorites();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _favoriteSubscription?.cancel();
    super.dispose();
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
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Please login to view favorites';
          });
        }
        return;
      }

      final result = await _authService.getFavorites();
      if (!mounted) return;

      if (result['success']) {

        // --- THE FIX IS HERE ---
        // The data from the service is already a List<FavoriteModel>.
        // We just need to cast it, not map it again.
        final favoriteList = result['data'] as List<FavoriteModel>;
        
        if(mounted) {
          setState(() {
            _favorites = favoriteList;
            _isLoading = false;
          });
        }
      } else {
        if(mounted) {
          setState(() {
            _error = result['message'];
            if (result['code'] == 'unauthenticated' ||
                result['code'] == 'token_expired') {
              _error = 'Your session has expired. Please login again.';
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // The error message from the screenshot is generated here
        _error = 'Error parsing favorites data: $e';
      });
    }
  }

  Future<void> _removeFromFavorites(FavoriteModel favorite, int index) async {
    setState(() {
      _favorites.removeAt(index);
    });

    try {
      final result = await _authService.toggleFavorite(favorite.productId);
      if (!mounted) return;

      if (result['success']) {
        _favoriteStateService.notifyFavoriteChanged();
        SnackBarHelper.showSuccess(context, result['message'] ?? 'Removed from favorites');
      } else {
        if (mounted) {
          setState(() {
            _favorites.insert(index, favorite);
          });
        }

        if (result['code'] == 'unauthenticated' ||
            result['code'] == 'token_expired') {
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
        } else {
          if (mounted) SnackBarHelper.showError(context, result['message'] ?? 'Failed to remove favorite');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _favorites.insert(index, favorite);
        });
        SnackBarHelper.showError(context, 'An error occurred. Please try again.');
      }
    }
  }

  void _addToCart(FavoriteModel favorite) {
    CartService().addToCart(favorite.productId, 1).then((_) {
      SnackBarHelper.showSuccess(context, '${favorite.name} added to cart');
    }).catchError((_) {
      SnackBarHelper.showError(context, 'Failed to add item to cart');
    });
  }

  Widget _buildBody() {
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final favorite = _favorites[index];
          return _buildFavoriteItem(favorite, index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text("My Wishlist"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildFavoriteItem(FavoriteModel favorite, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Dismissible(
        key: Key(favorite.id.toString()),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => _removeFromFavorites(favorite, index),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 28),
        ),
        child: GestureDetector(
          onTap: () async {
            try {
              final product = await CategoryService.fetchProductById(favorite.productId);
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(product: product),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                SnackBarHelper.showError(context, 'Failed to load product details');
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    favorite.image,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        favorite.weight,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${favorite.price}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _addToCart(favorite),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Omitted other build states for brevity, they remain the same.
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ShimmerLoading(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(width: 70, height: 70, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: double.infinity, height: 16, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 100, height: 14, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 50, height: 16, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(width: 60, height: 36, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null && _error!.toLowerCase().contains('login'))
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                child: const Text('Login'),
              )
            else
              ElevatedButton(
                onPressed: _loadFavorites,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            "Your Wishlist is Empty",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Tap the heart on any product to save it here.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}