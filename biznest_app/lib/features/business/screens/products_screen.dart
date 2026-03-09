import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
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
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await _api.getProducts();
      if (mounted) {
        setState(() {
          _products = response.data is List ? response.data : [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final category = (p['category'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          category.contains(_searchQuery.toLowerCase());
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

  void _showProductDialog([Map<String, dynamic>? product]) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final categoryCtrl = TextEditingController(
      text: product?['category'] ?? '',
    );
    final descCtrl = TextEditingController(text: product?['description'] ?? '');
    final costCtrl = TextEditingController(
      text: '${product?['costPrice'] ?? ''}',
    );
    final sellCtrl = TextEditingController(
      text: '${product?['sellingPrice'] ?? ''}',
    );
    final stockCtrl = TextEditingController(text: '${product?['stock'] ?? ''}');
    final imageCtrl = TextEditingController(text: product?['image'] ?? '');
    String unitValue = product?['unit'] ?? 'piece';
    // Ensure unitValue is valid, default to 'piece' if not in list
    const validUnits = ['piece', 'kg', 'g', 'l', 'ml', 'dozen', 'box', 'pack'];
    if (!validUnits.contains(unitValue)) unitValue = 'piece';

    final formKey = GlobalKey<FormState>();
    bool isUploading = false;
    bool isSaving = false;
    final picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickImage() async {
            try {
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image == null) return;

              setState(() => isUploading = true);
              final res = await _api.uploadProductImage(image);
              setState(() {
                imageCtrl.text = res.data['url'];
                isUploading = false;
              });
            } catch (e) {
              setState(() => isUploading = false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upload failed: $e'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 600,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isEdit ? Icons.edit : Icons.add,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isEdit ? 'Edit Product' : 'Add Product',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image Upload Section
                            Center(
                              child: GestureDetector(
                                onTap: pickImage,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: AppColors.gray50,
                                      border: Border.all(
                                        color: AppColors.gray200,
                                      ),
                                    ),
                                    child: isUploading
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : imageCtrl.text.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: imageCtrl.text,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                            errorWidget:
                                                (context, url, error) => Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      size: 28,
                                                      color: AppColors.gray400,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Image Error',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color:
                                                            AppColors.gray500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                size: 32,
                                                color: AppColors.gray400,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Add Image',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: AppColors.gray500,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton.icon(
                                onPressed: pickImage,
                                icon: const Icon(Icons.upload_file, size: 16),
                                label: const Text('Upload Image'),
                              ),
                            ),
                            const SizedBox(height: 20),

                            _formLabel('Product Name *'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Wireless Earbuds',
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),

                            _formLabel('Category'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: categoryCtrl,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Electronics',
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _formLabel('Cost Price (₹) *'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: costCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          hintText: '0',
                                        ),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _formLabel('Selling Price (₹) *'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: sellCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          hintText: '0',
                                        ),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _formLabel('Stock *'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: stockCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          hintText: '0',
                                        ),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _formLabel('Unit'),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        initialValue: unitValue,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                        ),
                                        items: validUnits.map((u) {
                                          return DropdownMenuItem(
                                            value: u,
                                            child: Text(
                                              u.substring(0, 1).toUpperCase() +
                                                  u.substring(1),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (v) =>
                                            setState(() => unitValue = v!),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _formLabel('Description'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: descCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Product description...',
                              ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isSaving
                                        ? null
                                        : () async {
                                            if (!formKey.currentState!
                                                .validate()) {
                                              return;
                                            }

                                            setState(() => isSaving = true);

                                            final data = {
                                              'name': nameCtrl.text.trim(),
                                              'category': categoryCtrl.text
                                                  .trim(),
                                              'description': descCtrl.text
                                                  .trim(),
                                              'costPrice':
                                                  num.tryParse(costCtrl.text) ??
                                                  0,
                                              'sellingPrice':
                                                  num.tryParse(sellCtrl.text) ??
                                                  0,
                                              'stock':
                                                  int.tryParse(
                                                    stockCtrl.text,
                                                  ) ??
                                                  0,
                                              'unit': unitValue,
                                              'image': imageCtrl.text.trim(),
                                            };

                                            try {
                                              if (isEdit) {
                                                await _api.updateProduct(
                                                  product['_id'],
                                                  data,
                                                );
                                              } else {
                                                await _api.createProduct(data);
                                              }

                                              if (ctx.mounted &&
                                                  Navigator.canPop(ctx)) {
                                                Navigator.pop(ctx);
                                              }

                                              if (mounted) _fetchProducts();
                                            } catch (e) {
                                              if (ctx.mounted) {
                                                setState(
                                                  () => isSaving = false,
                                                );
                                                ScaffoldMessenger.of(
                                                  ctx,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                    backgroundColor:
                                                        AppColors.danger,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            isEdit
                                                ? 'Update Product'
                                                : 'Create Product',
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
    if (confirm == true) {
      try {
        await _api.deleteProduct(id);
        _fetchProducts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary500),
      );
    }

    final products = _filteredProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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

            final actionButton = ElevatedButton.icon(
              onPressed: _openAddProductScreen,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Product'),
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
        const SizedBox(height: 20),

        // Search Bar
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
        const SizedBox(height: 20),

        // Products Grid
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
              final isCompact = constraints.maxWidth < 520;
              final maxTileWidth = constraints.maxWidth > 1200
                  ? 360.0
                  : (constraints.maxWidth > 700 ? 320.0 : 420.0);
              final tileHeight = isCompact ? 232.0 : 244.0;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxTileWidth,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: tileHeight,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) =>
                    _buildProductCard(products[index]),
              );
            },
          ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final stockStatus = getStockStatus(product['stock']);
    final margin = calculateMargin(
      product['costPrice'],
      product['sellingPrice'],
    );
    final imageUrl = resolveProductImageUrl(product);
    final imageProvider = resolveImageProvider(imageUrl);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageProvider != null
                      ? Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          width: 48,
                          height: 48,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primary600,
                            size: 24,
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary600,
                          size: 24,
                        ),
                ),
              ),
              Expanded(
                child: Text(
                  product['name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _openEditProductScreen(product);
                  if (v == 'delete') _deleteProduct(product['_id']);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                icon: Icon(Icons.more_vert, size: 18, color: AppColors.gray400),
              ),
            ],
          ),
          if (product['category'] != null &&
              product['category'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                product['category'],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.gray600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatCurrency(product['sellingPrice']),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Margin: $margin%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stockStatus.bg,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '${stockStatus.label} (${product['stock']})',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: stockStatus.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.gray700,
      ),
    );
  }
}
