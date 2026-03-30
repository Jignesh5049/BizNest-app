import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_core/biznest_core.dart';
import '../widgets/business_refresh_registry.dart';

import 'add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _api = ApiService();
  List<dynamic> _products = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    BusinessRefreshRegistry.register('/products', _fetchProducts);
    _fetchProducts();
  }

  @override
  void dispose() {
    BusinessRefreshRegistry.unregister('/products', _fetchProducts);
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    if (mounted) setState(() => _loading = true);
    try {
      final response = await _api.getProducts();
      if (!mounted) return;
      setState(() {
        _products = response.data is List ? response.data : [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _products;

    return _products.where((item) {
      final product = item is Map
          ? Map<String, dynamic>.from(item)
          : <String, dynamic>{};
      final name = (product['name'] ?? '').toString().toLowerCase();
      final category = (product['category'] ?? '').toString().toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();
  }

  Future<void> _openAddProductScreen() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (created == true && mounted) {
      _fetchProducts();
    }
  }

  Future<void> _openEditProductScreen(Map<String, dynamic> product) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen(product: product)),
    );
    if (updated == true && mounted) {
      _fetchProducts();
    }
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.deleteProduct(id);
      _fetchProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final stockStatus = getStockStatus(product['stock']);
    final rating = _asDouble(product['ratingAverage']);
    final ratingCount = _asInt(product['ratingCount']);
    final stockCount = _asInt(product['stock']);
    final sellingPrice = _asDouble(product['sellingPrice']);
    final costPrice = _asDouble(product['costPrice']);
    final marginPercent = costPrice > 0
        ? ((sellingPrice - costPrice) / costPrice) * 100
        : 0.0;
    final unitText = (product['unit']?.toString().trim().isNotEmpty ?? false)
        ? product['unit'].toString().trim()
        : 'piece';
    final imageUrl = resolveProductImageUrl(product);
    final imageProvider = resolveImageProvider(imageUrl);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageProvider != null
                      ? Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          width: 64,
                          height: 64,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primary600,
                            size: 30,
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary600,
                          size: 30,
                        ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (product['name'] ?? '').toString(),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (product['category']?.toString().isNotEmpty ?? false)
                          ? product['category'].toString()
                          : 'Uncategorized',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.gray500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: stockStatus.bg,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  stockStatus.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: stockStatus.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELLING PRICE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(product['sellingPrice']),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STOCK',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$stockCount $unitText',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cost: ${formatCurrency(product['costPrice'])}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${marginPercent >= 0 ? '+' : ''}${marginPercent.toStringAsFixed(1)}% margin',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: marginPercent >= 0
                      ? const Color(0xFF16A34A)
                      : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                size: 18,
                color: ratingCount > 0
                    ? const Color(0xFFFACC15)
                    : AppColors.gray300,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ratingCount > 0
                      ? '${rating.toStringAsFixed(1)} ($ratingCount)'
                      : 'No ratings yet',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.gray100, height: 1),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEditProductScreen(product),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: AppColors.gray200),
                    foregroundColor: AppColors.gray800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () =>
                      _deleteProduct((product['_id'] ?? '').toString()),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                  tooltip: 'Delete',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppPageSkeleton();
    }

    final products = _filteredProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 520;

            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Products',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  '${_products.length} products total',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            );

            final actionButton = AppGradientButton(
              onPressed: _openAddProductScreen,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Add Product'),
                ],
              ),
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleBlock,
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: actionButton),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: titleBlock),
                actionButton,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        const SizedBox(height: 4),
        if (products.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 60,
                    color: AppColors.gray300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No products match your search'
                        : 'No products yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 0) {
                return const SizedBox.shrink();
              }

              final isCompact = constraints.maxWidth < 520;
              final targetTileWidth = constraints.maxWidth > 1200
                  ? 360.0
                  : (constraints.maxWidth > 700 ? 320.0 : 420.0);
              final crossAxisCount = (constraints.maxWidth / targetTileWidth)
                  .floor()
                  .clamp(1, 6);
              final tileHeight = isCompact ? 280.0 : 268.0;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: tileHeight,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index] is Map
                      ? Map<String, dynamic>.from(products[index] as Map)
                      : <String, dynamic>{};
                  return _buildProductCard(product);
                },
              );
            },
          ),
      ],
    );
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
