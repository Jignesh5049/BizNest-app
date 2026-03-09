import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _api = ApiService();
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final response = await _api.getOrders();
      setState(() {
        _orders = response.data is List ? response.data as List : [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invoices',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select an order to open its invoice',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order List',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 12),
              if (_orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No orders yet',
                      style: GoogleFonts.inter(color: AppColors.gray500),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _orders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final o = Map<String, dynamic>.from(_orders[i] as Map);
                    final customer = (o['customerId'] is Map)
                        ? Map<String, dynamic>.from(o['customerId'] as Map)
                        : <String, dynamic>{};
                    final status = (o['paymentStatus'] ?? 'unpaid')
                        .toString()
                        .toUpperCase();
                    final statusColor = status == 'PAID'
                        ? AppColors.success
                        : AppColors.warning;

                    return InkWell(
                      onTap: () => context.go('/invoices/${o['_id']}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gray100),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (o['orderNumber'] ?? '').toString(),
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.gray900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (customer['name'] ??
                                            o['customerName'] ??
                                            'Walk-in Customer')
                                        .toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                  Text(
                                    formatDate(o['createdAt'] ?? ''),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.gray400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatCurrency(o['total'] ?? 0),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.gray600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
