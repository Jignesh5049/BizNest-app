import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/services/api_service.dart';
import 'add_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _api = ApiService();
  List<dynamic> _orders = [];
  bool _loading = true;
  String _statusFilter = 'all';
  String _searchQuery = '';

  static const _statusFilters = [
    'all',
    'pending',
    'confirmed',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{};
      if (_statusFilter != 'all') params['status'] = _statusFilter;
      final response = await _api.getOrders(params: params);
      if (mounted) {
        setState(() {
          _orders = response.data is List ? response.data : [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredOrders {
    if (_searchQuery.isEmpty) return _orders;
    return _orders.where((o) {
      final customerName = (o['customerName'] ?? '').toString().toLowerCase();
      final id = (o['_id'] ?? '').toString().toLowerCase();
      return customerName.contains(_searchQuery.toLowerCase()) ||
          id.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _openAddOrderScreen() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddOrderScreen()),
    );

    if (created == true && mounted) {
      _fetchOrders();
    }
  }

  void _showCreateOrderDialog() {
    final formKey = GlobalKey<FormState>();
    final customerNameCtrl = TextEditingController();
    final customerPhoneCtrl = TextEditingController();
    final itemNameCtrl = TextEditingController();
    final itemQtyCtrl = TextEditingController(text: '1');
    final itemPriceCtrl = TextEditingController();
    List<Map<String, dynamic>> items = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool isSaving = false;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 500,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'New Order',
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
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _formLabel('Customer Name *'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: customerNameCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Customer name',
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),
                            _formLabel('Customer Phone'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: customerPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Phone number',
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Items',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Item input
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: itemNameCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'Item name',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: itemQtyCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'Qty',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: itemPriceCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: '₹',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (itemNameCtrl.text.isNotEmpty &&
                                        itemPriceCtrl.text.isNotEmpty) {
                                      setDialogState(() {
                                        items.add({
                                          'name': itemNameCtrl.text.trim(),
                                          'quantity':
                                              int.tryParse(itemQtyCtrl.text) ??
                                              1,
                                          'price':
                                              num.tryParse(
                                                itemPriceCtrl.text,
                                              ) ??
                                              0,
                                        });
                                        itemNameCtrl.clear();
                                        itemQtyCtrl.text = '1';
                                        itemPriceCtrl.clear();
                                      });
                                    }
                                  },
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: AppColors.primary600,
                                  ),
                                ),
                              ],
                            ),
                            // Items list
                            if (items.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ...items.asMap().entries.map(
                                (e) => Container(
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
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                          ),
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
                                        formatCurrency(e.value['price']),
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
                                        onPressed: () => setDialogState(
                                          () => items.removeAt(e.key),
                                        ),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.only(left: 8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total: ${formatCurrency(items.fold<num>(0, (sum, i) => sum + (i['price'] as num) * (i['quantity'] as num)))}',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: (items.isEmpty || isSaving)
                                        ? null
                                        : () async {
                                            if (!formKey.currentState!
                                                .validate()) {
                                              return;
                                            }

                                            setDialogState(
                                              () => isSaving = true,
                                            );

                                            try {
                                              await _api.createOrder({
                                                'customerName': customerNameCtrl
                                                    .text
                                                    .trim(),
                                                'customerPhone':
                                                    customerPhoneCtrl.text
                                                        .trim(),
                                                'items': items,
                                              });
                                              if (ctx.mounted &&
                                                  Navigator.canPop(ctx)) {
                                                Navigator.pop(ctx);
                                              }
                                              if (mounted) _fetchOrders();
                                            } catch (e) {
                                              if (ctx.mounted) {
                                                setDialogState(
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
                                    child: isSaving
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

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await _api.updateOrderStatus(orderId, newStatus);
      _fetchOrders();
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

  Future<void> _markPaid(String orderId) async {
    try {
      await _api.updateOrderPayment(orderId, {'paymentStatus': 'paid'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as paid'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        _fetchOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking paid: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  Text(
                    '${_orders.length} orders total',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _openAddOrderScreen,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Order'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Status Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statusFilters.map((status) {
              final isActive = _statusFilter == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isActive,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  label: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.primary600
                          : AppColors.gray600,
                    ),
                  ),
                  selectedColor: AppColors.primary50,
                  checkmarkColor: AppColors.primary600,
                  onSelected: (_) {
                    setState(() => _statusFilter = status);
                    _fetchOrders();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Search
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Search orders...',
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

        // Orders List
        if (_loading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary500),
          )
        else if (orders.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 60,
                    color: AppColors.gray300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders found',
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
          ...orders.map((order) => _buildOrderCard(order)),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final statusColors = getStatusColor(order['status']);
    final items = order['items'] as List? ?? [];
    final total =
        order['totalAmount'] ??
        items.fold<num>(
          0,
          (sum, i) =>
              sum + ((i['price'] ?? 0) as num) * ((i['quantity'] ?? 1) as num),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['customerName'] ?? 'Walk-in Customer',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDateTime(order['createdAt']),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColors.bg,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  (order['status'] ?? 'pending').toString().toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColors.text,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Items preview
          ...items
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item['name']} x${item['quantity']}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.gray600,
                          ),
                        ),
                      ),
                      Text(
                        formatCurrency(
                          (item['price'] ?? 0) * (item['quantity'] ?? 1),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (items.length > 3)
            Text(
              '+${items.length - 3} more items',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.gray400),
            ),
          const Divider(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final actions = <Widget>[
                if (order['status'] == 'pending')
                  TextButton(
                    onPressed: () => _updateStatus(order['_id'], 'confirmed'),
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue600,
                      ),
                    ),
                  ),
                if (order['status'] == 'confirmed')
                  TextButton(
                    onPressed: () => _updateStatus(order['_id'], 'completed'),
                    child: Text(
                      'Complete',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                if ((order['paymentStatus'] ?? '') != 'paid')
                  TextButton(
                    onPressed: () => _markPaid(order['_id']),
                    child: Text(
                      'Mark Paid',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary600,
                      ),
                    ),
                  ),
                if ((order['paymentStatus'] ?? '') == 'paid')
                  TextButton.icon(
                    onPressed: () => context.go('/invoices/${order['_id']}'),
                    icon: Icon(
                      Icons.description,
                      size: 18,
                      color: AppColors.primary600,
                    ),
                    label: Text(
                      'Invoice',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary600,
                      ),
                    ),
                  ),
              ];

              final totalText = Text(
                'Total: ${formatCurrency(total)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary600,
                ),
              );

              if (constraints.maxWidth < 380) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    totalText,
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 4, runSpacing: 4, children: actions),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: totalText),
                  if (actions.isNotEmpty)
                    Flexible(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 4,
                        runSpacing: 4,
                        children: actions,
                      ),
                    ),
                ],
              );
            },
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
