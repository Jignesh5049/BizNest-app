import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';
import '../cubit/cart_cubit.dart';

class BusinessStoreScreen extends StatefulWidget {
  final String businessId;
  const BusinessStoreScreen({super.key, required this.businessId});

  @override
  State<BusinessStoreScreen> createState() => _BusinessStoreScreenState();
}

class _BusinessStoreScreenState extends State<BusinessStoreScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _business;
  List<dynamic> _products = [];
  List<String> _favoriteIds = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchFavorites();
  }

  Future<void> _fetchData() async {
    try {
      final bizRes = await _api.getStoreBusiness(widget.businessId);
      final data = bizRes.data is Map
          ? Map<String, dynamic>.from(bizRes.data as Map)
          : null;
      setState(() {
        _business = data?['business'] ?? data;
        _products = data?['products'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchFavorites() async {
    try {
      final res = await _api.getFavorites();
      final favs = res.data is List ? res.data : (res.data?['favorites'] ?? []);
      setState(() {
        _favoriteIds = (favs as List).map((f) {
          final prod = f['product'];
          return (prod is Map ? prod['_id'] : prod ?? f['_id'] ?? f).toString();
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String productId) async {
    try {
      if (_favoriteIds.contains(productId)) {
        await _api.removeFavorite(productId);
        setState(() => _favoriteIds.remove(productId));
      } else {
        await _api.addFavorite(productId);
        setState(() => _favoriteIds.add(productId));
      }
    } catch (_) {}
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _products;
    final q = _search.toLowerCase();
    return _products
        .where((p) => (p['name'] ?? '').toString().toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_business == null) {
      return Center(
        child: Text(
          'Business not found',
          style: GoogleFonts.inter(color: AppColors.gray500),
        ),
      );
    }

    final biz = _business!;
    final filtered = _filtered;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          IconButton(
            onPressed: () => context.go('/store'),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
          const SizedBox(height: 12),

          // Business Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary600, AppColors.primary800],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    (biz['name'] ?? '?')[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  biz['name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if ((biz['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    biz['description'],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if ((biz['contact']?['phone'] ?? '').toString().isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (biz['contact']?['phone'] ?? '').toString(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    if ((biz['address']?['city'] ?? '').toString().isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (biz['address']?['city'] ?? '').toString(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search products in this store...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            '${filtered.length} Products',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),

          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: AppColors.gray300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No products found',
                      style: GoogleFonts.inter(
                        fontSize: 15,
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
                  children: filtered
                      .map(
                        (p) => SizedBox(
                          width:
                              (constraints.maxWidth - 12 * (cols - 1)) / cols,
                          child: _productCard(
                            Map<String, dynamic>.from(p as Map),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    // Handle both single image (image field) and array format
    final imageUrl =
        p['image'] as String? ??
        (p['images'] is List && (p['images'] as List).isNotEmpty
            ? (p['images'] as List).first.toString()
            : null);
    final images = imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : [];
    final isFav = _favoriteIds.contains(p['_id']);
    final cart = context.read<CartCubit>();
    final inCart = cart.state.isInCart(p['_id']);

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
                child: images.isNotEmpty
                    ? Image.network(
                        images.first.toString(),
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
                  onTap: () => _toggleFavorite(p['_id']),
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
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFav ? Colors.red : AppColors.gray400,
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
                              cart.addToCart(
                                p,
                                businessId: widget.businessId,
                                businessName: _business?['name'],
                              );
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
