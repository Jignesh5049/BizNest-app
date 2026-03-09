import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';
import '../cubit/cart_cubit.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final _api = ApiService();
  List<dynamic> _orders = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.getStoreOrders();
      setState(() {
        _orders = res.data is List ? res.data : (res.data?['orders'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'all') return _orders;
    return _orders
        .where((o) => (o['status'] ?? '').toString().toLowerCase() == _filter)
        .toList();
  }

  void _reorder(Map<String, dynamic> order) {
    final items = order['items'] ?? [];
    if (items is List && items.isNotEmpty) {
      context.read<CartCubit>().addItemsForReorder(items);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Items added to cart for reorder')),
      );
      context.go('/store/cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final filtered = _filtered;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Orders',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          Text(
            '${_orders.length} orders',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip('All', 'all'),
                _chip('Pending', 'pending'),
                _chip('Confirmed', 'confirmed'),
                _chip('Completed', 'completed'),
                _chip('Cancelled', 'cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (filtered.isEmpty)
            _emptyState()
          else
            ...filtered.map(
              (o) => _orderCard(Map<String, dynamic>.from(o as Map)),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final active = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
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

  Widget _orderCard(Map<String, dynamic> o) {
    final status = (o['status'] ?? 'pending').toString();
    final statusColors = getStatusColor(status);
    final items = o['items'] as List? ?? [];
    final total = (o['totalAmount'] ?? o['total'] ?? 0).toDouble();

    return GestureDetector(
      onTap: () => context.go('/store/orders/${o['_id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    size: 20,
                    color: AppColors.primary600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${(o['orderNumber'] ?? o['_id'] ?? '').toString().substring(0, 8)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        formatDate(o['createdAt'] ?? ''),
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
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColors.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.replaceFirstMapped(
                      RegExp(r'^\w'),
                      (m) => m[0]!.toUpperCase(),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColors.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Show item images and details
            if (items.isNotEmpty) ...[
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length > 4 ? 4 : items.length,
                  itemBuilder: (context, index) {
                    if (index == 3 && items.length > 4) {
                      return Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '+${items.length - 3}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                      );
                    }
                    final item = items[index];
                    final imageUrl = resolveOrderItemImageUrl(
                      Map<String, dynamic>.from(item as Map),
                    );
                    final imageProvider = resolveImageProvider(imageUrl);
                    return Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: imageProvider != null
                            ? Image(
                                image: imageProvider,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.inventory_2,
                                      color: AppColors.gray400,
                                      size: 24,
                                    ),
                              )
                            : Icon(
                                Icons.inventory_2,
                                color: AppColors.gray400,
                                size: 24,
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Text(
                  formatCurrency(total),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary600,
                  ),
                ),
                Text(
                  ' · ${items.length} items',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.gray500,
                  ),
                ),
                const Spacer(),
                if (status == 'completed')
                  TextButton.icon(
                    onPressed: () => _reorder(o),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reorder'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary600,
                      textStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 56,
              color: AppColors.gray300,
            ),
            const SizedBox(height: 12),
            Text(
              'No orders yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your order history will appear here',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}
