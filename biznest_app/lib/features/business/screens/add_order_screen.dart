import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _itemSearchCtrl = TextEditingController();
  final _itemQtyCtrl = TextEditingController(text: '1');
  final _customerFocusNode = FocusNode();
  final _productFocusNode = FocusNode();

  List<dynamic> _allCustomers = [];
  List<dynamic> _filteredCustomers = [];
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  Map<String, dynamic>? _selectedProduct;
  List<Map<String, dynamic>> _items = [];
  bool _isSaving = false;
  bool _isLoadingCustomers = false;
  bool _isLoadingProducts = false;
  bool _showCustomerSuggestions = false;
  bool _showProductSuggestions = false;

  num _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse((value ?? '').toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadProducts();
    _itemSearchCtrl.addListener(_filterProducts);

    _customerFocusNode.addListener(() {
      if (!_customerFocusNode.hasFocus && mounted) {
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted && !_customerFocusNode.hasFocus) {
            setState(() => _showCustomerSuggestions = false);
          }
        });
      }
    });

    _productFocusNode.addListener(() {
      if (!_productFocusNode.hasFocus && mounted) {
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted && !_productFocusNode.hasFocus) {
            setState(() => _showProductSuggestions = false);
          }
        });
      }
    });
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);
    try {
      final response = await _api.getCustomers();
      if (!mounted) return;
      setState(() {
        _allCustomers = response.data is List ? response.data : [];
        _isLoadingCustomers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCustomers = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final response = await _api.getProducts();
      if (mounted) {
        setState(() {
          _allProducts = response.data is List ? response.data : [];
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
      }
    }
  }

  void _filterProducts() {
    final query = _itemSearchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where(
              (p) =>
                  (p['name'] ?? '').toString().toLowerCase().contains(query) ||
                  (p['category'] ?? '').toString().toLowerCase().contains(
                    query,
                  ),
            )
            .toList();
      }
    });
  }

  void _filterCustomers() {
    final query = _customerNameCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _allCustomers;
      } else {
        _filteredCustomers = _allCustomers.where((c) {
          final name = (c['name'] ?? '').toString().toLowerCase();
          final phone = (c['phone'] ?? '').toString().toLowerCase();
          return name.contains(query) || phone.contains(query);
        }).toList();
      }
    });
  }

  void _selectCustomer(Map<String, dynamic> customer) {
    setState(() {
      _customerNameCtrl.text = (customer['name'] ?? '').toString();
      final phone = (customer['phone'] ?? '').toString();
      if (phone.isNotEmpty) {
        _customerPhoneCtrl.text = phone;
      }
      _showCustomerSuggestions = false;
    });
    _customerFocusNode.unfocus();
  }

  void _selectProduct(Map<String, dynamic> product) {
    setState(() {
      _selectedProduct = product;
      _itemSearchCtrl.text = product['name'] ?? '';
      _filteredProducts = [];
      _itemQtyCtrl.text = '1';
      _showProductSuggestions = false;
    });
    _productFocusNode.unfocus();
  }

  void _addItem() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final qty = int.tryParse(_itemQtyCtrl.text) ?? 1;
    final price = _asNum(_selectedProduct!['sellingPrice']);
    final amount = price * qty;

    setState(() {
      _items.add({
        'productId': _selectedProduct!['_id'],
        'name': _selectedProduct!['name'],
        'quantity': qty,
        'price': price,
        'amount': amount,
      });
      _selectedProduct = null;
      _itemSearchCtrl.clear();
      _itemQtyCtrl.text = '1';
      _filteredProducts = [];
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _api.createOrder({
        'customerName': _customerNameCtrl.text.trim(),
        'customerPhone': _customerPhoneCtrl.text.trim(),
        'items': _items,
      });

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
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _itemSearchCtrl.removeListener(_filterProducts);
    _itemSearchCtrl.dispose();
    _itemQtyCtrl.dispose();
    _customerFocusNode.dispose();
    _productFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsTotal = _items.fold<num>(
      0,
      (sum, i) =>
          sum + ((i['price'] ?? 0) as num) * ((i['quantity'] ?? 1) as num),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _showCustomerSuggestions = false;
          _showProductSuggestions = false;
        });
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
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
                  'New Order',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Customer Info Section
            _formLabel('Customer Name *'),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _customerNameCtrl,
                  focusNode: _customerFocusNode,
                  onTap: () {
                    setState(() {
                      _showCustomerSuggestions = true;
                      _filterCustomers();
                    });
                  },
                  onChanged: (_) {
                    setState(() => _showCustomerSuggestions = true);
                    _filterCustomers();
                  },
                  decoration: InputDecoration(
                    hintText: _isLoadingCustomers
                        ? 'Loading customers...'
                        : 'Customer name',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                if (_showCustomerSuggestions && _filteredCustomers.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = Map<String, dynamic>.from(
                          _filteredCustomers[index] as Map,
                        );
                        return ListTile(
                          dense: true,
                          title: Text((customer['name'] ?? '').toString()),
                          subtitle: Text(
                            (customer['phone'] ?? '').toString(),
                            style: TextStyle(
                              color: AppColors.gray600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () => _selectCustomer(customer),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _formLabel('Customer Phone'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _customerPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Phone number'),
            ),
            const SizedBox(height: 20),

            // Items Section
            Text(
              'Items',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 10),

            // Product Selection with Autocomplete
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _itemSearchCtrl,
                  focusNode: _productFocusNode,
                  onTap: () {
                    setState(() => _showProductSuggestions = true);
                    _filterProducts();
                  },
                  onChanged: (_) {
                    setState(() => _showProductSuggestions = true);
                    _filterProducts();
                  },
                  readOnly: _selectedProduct != null,
                  decoration: InputDecoration(
                    hintText: _isLoadingProducts
                        ? 'Loading products...'
                        : 'Select product',
                    suffixIcon: _selectedProduct != null
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedProduct = null;
                                _itemSearchCtrl.clear();
                                _filteredProducts = [];
                                _showProductSuggestions = false;
                              });
                            },
                            icon: const Icon(Icons.close, color: Colors.green),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_selectedProduct == null &&
                    _showProductSuggestions &&
                    _filteredProducts.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = Map<String, dynamic>.from(
                          _filteredProducts[index] as Map,
                        );
                        return ListTile(
                          dense: true,
                          title: Text((product['name'] ?? '').toString()),
                          subtitle: Text(
                            'Rs ${_asNum(product['sellingPrice'])}',
                            style: TextStyle(
                              color: AppColors.primary600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () => _selectProduct(product),
                        );
                      },
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Quantity and Add Button Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _itemQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed:
                      _selectedProduct != null && _itemQtyCtrl.text.isNotEmpty
                      ? _addItem
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Items List
            if (_items.isNotEmpty) ...[
              ..._items.asMap().entries.map((e) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.value['name'],
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                      Text(
                        'x${e.value['quantity']}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatCurrency(
                          e.value['amount'] ?? e.value['price'] ?? 0,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.danger,
                        ),
                        onPressed: () => _removeItem(e.key),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(left: 8),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                'Total: ${formatCurrency(itemsTotal)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary600,
                ),
                textAlign: TextAlign.right,
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
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
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Create Order'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
