import 'package:flutter/material.dart';
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
  Map<String, dynamic>? _selectedOrder;
  Map<String, dynamic>? _business;
  bool _loading = true;

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  String _readString(dynamic source, List<Object> path) {
    dynamic current = source;

    for (final segment in path) {
      if (current == null) return '';

      if (segment is String) {
        if (current is Map) {
          current = current[segment];
          continue;
        }

        if (current is List) {
          dynamic next;
          for (final entry in current) {
            if (entry is Map && entry.containsKey(segment)) {
              next = entry[segment];
              break;
            }
          }
          current = next;
          continue;
        }

        return '';
      }

      if (segment is int) {
        if (current is List && segment >= 0 && segment < current.length) {
          current = current[segment];
          continue;
        }
        return '';
      }

      return '';
    }

    return current?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final results = await Future.wait([
        _api.getOrders(params: {'paymentStatus': 'paid'}),
        _api.getBusiness(),
      ]);
      final orders = results[0].data is List ? results[0].data as List : [];
      final biz = results[1].data is Map
          ? Map<String, dynamic>.from(results[1].data as Map)
          : null;
      setState(() {
        _orders = orders;
        _business = biz;
        if (orders.isNotEmpty) {
          _selectedOrder = Map<String, dynamic>.from(orders[0] as Map);
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final content = LayoutBuilder(
          builder: (context, contentConstraints) {
            final isWide = contentConstraints.maxWidth > 700;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 280, child: _orderList(isWide: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _invoicePreview()),
                ],
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _orderList(isWide: false),
                    const SizedBox(height: 16),
                    _invoicePreview(),
                  ],
                ),
              );
            }
          },
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Header
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
              'Generate and view invoices for your orders',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
            ),
            const SizedBox(height: 20),

            // Content area
            if (hasBoundedHeight) Expanded(child: content) else content,
          ],
        );
      },
    );
  }

  Widget _orderList({bool isWide = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Paid Orders',
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
                  'No paid orders yet',
                  style: GoogleFonts.inter(color: AppColors.gray500),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: isWide ? 520 : 400,
              child: ListView.separated(
                itemCount: _orders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (_, i) => _buildOrderItem(i),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItem(int i) {
    final o = Map<String, dynamic>.from(_orders[i] as Map);
    final customer = _asMap(o['customerId']);
    final isSelected = _selectedOrder?['_id'] == o['_id'];
    return InkWell(
      onTap: () => setState(() => _selectedOrder = o),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.primary200) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    (o['orderNumber'] ?? '').toString(),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatCurrency(o['total'] ?? 0),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              (customer['name'] ?? '').toString(),
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.gray500),
            ),
            Text(
              formatDate(o['createdAt'] ?? ''),
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoicePreview() {
    if (_selectedOrder == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: AppColors.gray300,
              ),
              const SizedBox(height: 12),
              Text(
                'No invoice selected',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select an order from the list',
                style: GoogleFonts.inter(color: AppColors.gray500),
              ),
            ],
          ),
        ),
      );
    }

    final o = _selectedOrder!;
    final items = o['items'] is List ? o['items'] as List : <dynamic>[];
    final customer = _asMap(o['customerId']);
    final business = _asMap(_business);
    final bizName = (business['name'] ?? 'My Business').toString();
    final bizPhone = _readString(business, ['contact', 'phone']);
    final bizCity = _readString(business, ['address', 'city']);
    final bizState = _readString(business, ['address', 'state']);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business info
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'B',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bizName,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                          if (bizPhone.isNotEmpty)
                            Text(
                              bizPhone,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                            ),
                          if (bizCity.isNotEmpty)
                            Text(
                              '$bizCity, $bizState',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Invoice title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'INVOICE',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      o['orderNumber'] ?? '',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
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
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: AppColors.gray200),
            const SizedBox(height: 16),

            // Bill To
            Text(
              'BILL TO',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              customer['name'] ?? '',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            if ((customer['phone'] ?? '').toString().isNotEmpty)
              Text(
                customer['phone'],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.gray600,
                ),
              ),
            if ((customer['email'] ?? '').toString().isNotEmpty)
              Text(
                customer['email'],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.gray600,
                ),
              ),
            const SizedBox(height: 20),

            // Items table
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gray200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(7),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Item',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Qty',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Price',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Total',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rows
                  ...items.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.gray100),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['name'] ?? '',
                              style: GoogleFonts.inter(
                                color: AppColors.gray900,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${item['quantity'] ?? 0}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppColors.gray600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              formatCurrency(item['price'] ?? 0),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.inter(
                                color: AppColors.gray600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              formatCurrency(item['total'] ?? 0),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                color: AppColors.gray900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Totals
            Divider(color: AppColors.gray200),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      _totalRow('Subtotal', formatCurrency(o['subtotal'] ?? 0)),
                      if ((o['discount'] ?? 0) > 0)
                        _totalRow(
                          'Discount',
                          '-${formatCurrency(o['discount'])}',
                        ),
                      const SizedBox(height: 8),
                      Divider(color: AppColors.gray200),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                          Text(
                            formatCurrency(o['total'] ?? 0),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Footer
            Divider(color: AppColors.gray200),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Text(
                    'Thank you for your business!',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generated by BizNest',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray600),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}
