import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';
import '../cubit/cart_cubit.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _api = ApiService();
  List<dynamic> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.getFavorites();
      setState(() {
        _favorites = res.data is List
            ? res.data
            : (res.data?['favorites'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _remove(String productId) async {
    try {
      await _api.removeFavorite(productId);
      _fetch();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Favorites',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          Text(
            '${_favorites.length} items',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),

          if (_favorites.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 56,
                      color: AppColors.gray300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No favorites yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Products you love will appear here',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (ctx, constraints) {
                final cols = constraints.maxWidth > 700 ? 3 : 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _favorites.map((f) {
                    final product = f['product'] is Map
                        ? Map<String, dynamic>.from(f['product'] as Map)
                        : <String, dynamic>{'_id': f['product'] ?? f['_id']};
                    return SizedBox(
                      width: (constraints.maxWidth - 12 * (cols - 1)) / cols,
                      child: _card(product),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> p) {
    final imageUrl = resolveProductImageUrl(p);
    final imageProvider = resolveImageProvider(imageUrl);
    final cart = context.read<CartCubit>();
    final inCart = cart.state.isInCart(p['_id'] ?? '');

    return GestureDetector(
      onTap: () => context.go('/store/product/${p['_id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: imageProvider != null
                    ? Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.gray100,
                          child: Center(
                            child: Icon(
                              Icons.image,
                              size: 40,
                              color: AppColors.gray300,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.gray100,
                        child: Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: AppColors.gray300,
                          ),
                        ),
                      ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Transform.translate(
                offset: const Offset(-8, -18),
                child: GestureDetector(
                  onTap: () => _remove(p['_id'] ?? ''),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(p['sellingPrice'] ?? p['price'] ?? 0),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: inCart
                          ? null
                          : () {
                              final businessId = p['businessId'] is Map
                                  ? p['businessId']['_id']
                                  : p['businessId'];
                              cart.addToCart(p, businessId: businessId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${p['name']} added to cart'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: inCart
                            ? AppColors.gray200
                            : AppColors.primary600,
                        foregroundColor: inCart
                            ? AppColors.gray600
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(inCart ? 'In Cart' : 'Add to Cart'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
