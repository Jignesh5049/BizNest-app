import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';
import '../cubit/cart_cubit.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _order;
  bool _loading = true;
  final _reviewCtrl = TextEditingController();
  int _reviewRating = 5;
  final _supportSubjectCtrl = TextEditingController();
  final _supportMessageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    _supportSubjectCtrl.dispose();
    _supportMessageCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.getStoreOrder(widget.orderId);
      setState(() {
        _order = res.data is Map
            ? Map<String, dynamic>.from(res.data as Map)
            : null;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    try {
      await _api.cancelStoreOrder(widget.orderId);
      _fetch();
    } catch (_) {}
  }

  void _reorder() {
    final items = _order?['items'] ?? [];
    if (items is List && items.isNotEmpty) {
      context.read<CartCubit>().addItemsForReorder(items);
      context.go('/store/cart');
    }
  }

  Future<void> _submitReview(String productId) async {
    if (_reviewCtrl.text.trim().isEmpty) return;
    try {
      await _api.createReview(productId, {
        'rating': _reviewRating,
        'comment': _reviewCtrl.text.trim(),
      });
      _reviewCtrl.clear();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review submitted!')));
      }
    } catch (_) {}
  }

  Future<void> _submitSupport() async {
    if (_supportSubjectCtrl.text.trim().isEmpty) return;
    try {
      await _api.createSupportTicket({
        'orderId': widget.orderId,
        'subject': _supportSubjectCtrl.text.trim(),
        'message': _supportMessageCtrl.text.trim(),
        'issueType': 'order_issue',
      });
      _supportSubjectCtrl.clear();
      _supportMessageCtrl.clear();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support ticket created!')),
        );
      }
    } catch (_) {}
  }

  void _showReviewDialog(String productId, String name) {
    _reviewCtrl.clear();
    _reviewRating = 5;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Review $name',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      onPressed: () => ss(() => _reviewRating = i + 1),
                      icon: Icon(
                        i < _reviewRating ? Icons.star : Icons.star_border,
                        size: 28,
                        color: const Color(0xFFFBBF24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reviewCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write your review...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                        onPressed: () => _submitReview(productId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary600,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Submit'),
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

  void _showSupportDialog() {
    _supportSubjectCtrl.clear();
    _supportMessageCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Report Issue',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _supportSubjectCtrl,
                decoration: InputDecoration(
                  hintText: 'Subject',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _supportMessageCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the issue...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                      onPressed: _submitSupport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_order == null) return Center(child: Text('Order not found'));

    final o = _order!;
    final status = (o['status'] ?? 'pending').toString();
    final sc = getStatusColor(status);
    final items = o['items'] as List? ?? [];
    final total = (o['totalAmount'] ?? 0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/store/orders'),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(backgroundColor: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order #${(o['orderNumber'] ?? o['_id'] ?? '').toString().substring(0, 8)}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: sc.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sc.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Placed on ${formatDateTime(o['createdAt'] ?? '')}',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray500),
          ),
          const SizedBox(height: 20),

          // Items
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((item) {
                  final i = Map<String, dynamic>.from(item as Map);
                  // Use sellingPrice from product or price from order item, with fallback
                  final itemPrice =
                      i['price'] ??
                      i['product']?['sellingPrice'] ??
                      i['product']?['price'] ??
                      0;
                  final imageUrl = resolveOrderItemImageUrl(i);
                  final imageProvider = resolveImageProvider(imageUrl);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Row(
                      children: [
                        // Product image
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: imageProvider != null
                                ? Image(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i['name'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray900,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Qty: ${i['quantity']} × ${formatCurrency(itemPrice)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.gray500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatCurrency(
                            (itemPrice ?? 0) * (i['quantity'] ?? 1),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatCurrency(total),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (status == 'pending')
                OutlinedButton.icon(
                  onPressed: _cancel,
                  icon: Icon(Icons.close, size: 16, color: AppColors.danger),
                  label: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (status == 'completed')
                ElevatedButton.icon(
                  onPressed: _reorder,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reorder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _showSupportDialog,
                icon: const Icon(Icons.chat_outlined, size: 16),
                label: const Text('Report Issue'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          if (status == 'completed' && items.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Leave a Review',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              final i = Map<String, dynamic>.from(item as Map);
              final pid =
                  (i['product'] is Map
                          ? i['product']['_id']
                          : i['productId'] ?? '')
                      .toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        i['name'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showReviewDialog(pid, i['name'] ?? ''),
                      icon: const Icon(
                        Icons.star,
                        size: 16,
                        color: Color(0xFFFBBF24),
                      ),
                      label: Text(
                        'Review',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
