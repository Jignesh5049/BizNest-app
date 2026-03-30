import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import 'package:biznest_core/biznest_core.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _picker = ImagePicker();

  static const _validUnits = [
    'piece',
    'kg',
    'g',
    'l',
    'ml',
    'dozen',
    'box',
    'pack',
  ];

  String _unitValue = 'piece';
  bool _isUploading = false;
  bool _isSaving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p == null) return;

    _nameCtrl.text = (p['name'] ?? '').toString();
    _categoryCtrl.text = (p['category'] ?? '').toString();
    _descCtrl.text = (p['description'] ?? '').toString();
    _costCtrl.text = (p['costPrice'] ?? '').toString();
    _sellCtrl.text = (p['sellingPrice'] ?? '').toString();
    _stockCtrl.text = (p['stock'] ?? '').toString();
    _imageCtrl.text = (p['image'] ?? '').toString();

    final incomingUnit = (p['unit'] ?? 'piece').toString();
    if (_validUnits.contains(incomingUnit)) {
      _unitValue = incomingUnit;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    _sellCtrl.dispose();
    _stockCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploading = true);
      final res = await _api.uploadProductImage(image);
      if (!mounted) return;
      setState(() {
        _imageCtrl.text = (res.data['url'] ?? '').toString();
        _isUploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'category': _categoryCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'costPrice': num.tryParse(_costCtrl.text) ?? 0,
      'sellingPrice': num.tryParse(_sellCtrl.text) ?? 0,
      'stock': int.tryParse(_stockCtrl.text) ?? 0,
      'unit': _unitValue,
      'image': _imageCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await _api.updateProduct(widget.product!['_id'], data);
      } else {
        await _api.createProduct(data);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.gray700,
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isEdit ? 'Edit Product' : 'Add Product',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: _isUploading
                            ? const Center(child: CircularProgressIndicator())
                            : _imageCtrl.text.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _imageCtrl.text,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorWidget: (context, url, error) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_outlined,
                                      size: 28,
                                      color: AppColors.gray400,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Image Error',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.gray500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
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
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Upload Image'),
                  ),
                ),
                const SizedBox(height: 20),
                _formLabel('Product Name *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Wireless Earbuds',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _formLabel('Category'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Electronics',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _formLabel('Cost Price (Rs) *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '0'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _formLabel('Selling Price (Rs) *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _sellCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '0'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _formLabel('Stock *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '0'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _formLabel('Unit'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _unitValue,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            items: _validUnits.map((u) {
                              return DropdownMenuItem(
                                value: u,
                                child: Text(
                                  u.substring(0, 1).toUpperCase() +
                                      u.substring(1),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _unitValue = v);
                            },
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
                  controller: _descCtrl,
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
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppGradientButton(
                        onPressed: _isSaving ? null : _saveProduct,
                        minimumSize: const Size(double.infinity, 52),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isEdit ? 'Update Product' : 'Create Product',
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
    );
  }
}
