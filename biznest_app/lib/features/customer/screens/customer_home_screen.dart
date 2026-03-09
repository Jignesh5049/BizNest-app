import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';
import '../cubit/cart_cubit.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _api = ApiService();
  List<dynamic> _products = [];
  List<dynamic> _businesses = [];
  List<String> _favoriteIds = [];
  bool _loading = true;
  String _search = '';
  String _category = 'all';
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchFavorites();
  }

  Future<void> _fetchData() async {
    try {
      final params = <String, dynamic>{};
      if (_category != 'all') params['category'] = _category;
      if (_search.isNotEmpty) params['search'] = _search;
      params['sort'] = _sort;

      final prodRes = await _api.getAllStoreProducts(params: params);
      final bizRes = await _api.getStoreBusinesses();
      setState(() {
        _products = prodRes.data is List
            ? prodRes.data
            : (prodRes.data?['products'] ?? []);
        _businesses = bizRes.data is List
            ? bizRes.data
            : (bizRes.data?['businesses'] ?? []);
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
        _favoriteIds = (favs as List)
            .map(
              (f) =>
                  ((f['product'] ?? f['_id'] ?? f) is Map
                          ? f['product']['_id']
                          : f['product'] ?? f)
                      .toString(),
            )
            .toList();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary600, AppColors.primary800],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Local Businesses',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Shop from your favorite local stores',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search
          TextField(
            onChanged: (v) {
              _search = v;
              _fetchData();
            },
            decoration: InputDecoration(
              hintText: 'Search products...',
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

          // Category Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip('All', 'all'),
                ...businessCategories.map(
                  (c) => _categoryChip(c.label, c.value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Sort
          Row(
            children: [
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (v) {
                  _sort = v;
                  _fetchData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sort, size: 16, color: AppColors.gray600),
                      const SizedBox(width: 6),
                      Text(
                        'Sort',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'newest',
                    child: Text('Newest First'),
                  ),
                  const PopupMenuItem(
                    value: 'price_low',
                    child: Text('Price: Low to High'),
                  ),
                  const PopupMenuItem(
                    value: 'price_high',
                    child: Text('Price: High to Low'),
                  ),
                  const PopupMenuItem(
                    value: 'name_asc',
                    child: Text('Name: A to Z'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Featured Businesses
          if (_businesses.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Featured Businesses',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/store/businesses'),
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.primary600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _businesses.length > 6 ? 6 : _businesses.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _businessCard(_businesses[i]),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Products
          Text(
            'Products',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),

          if (_products.isEmpty)
            _emptyState(
              'No products found',
              'Try adjusting your search or filters',
            )
          else
            LayoutBuilder(
              builder: (ctx, constraints) {
                final cols = constraints.maxWidth > 700 ? 3 : 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _products
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

  Widget _categoryChip(String label, String value) {
    final active = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          _category = value;
          _fetchData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary600 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? AppColors.primary600 : AppColors.gray200,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _businessCard(dynamic biz) {
    final b = Map<String, dynamic>.from(biz as Map);
    return GestureDetector(
      onTap: () => context.go('/store/business/${b['_id']}'),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary100,
              child: Text(
                (b['name'] ?? '?')[0].toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              b['name'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              b['category'] ?? '',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    final imageUrl = resolveProductImageUrl(p);
    final imageProvider = resolveImageProvider(imageUrl);
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
            // Image
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
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
            ),
            // Favorite
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

  Widget _placeholderImage() {
    return Container(
      color: AppColors.gray100,
      child: Center(
        child: Icon(Icons.image, size: 40, color: AppColors.gray300),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 56, color: AppColors.gray300),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}
