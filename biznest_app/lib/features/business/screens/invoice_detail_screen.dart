import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String orderId;

  const InvoiceDetailScreen({super.key, required this.orderId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _business;
  bool _loading = true;

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
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
        _api.getOrder(widget.orderId),
        _api.getBusiness(),
      ]);

      final order = results[0].data is Map
          ? Map<String, dynamic>.from(results[0].data as Map)
          : null;
      final business = results[1].data is Map
          ? Map<String, dynamic>.from(results[1].data as Map)
          : null;

      setState(() {
        _order = order;
        _business = business;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_order == null) {
      return Center(
        child: Text(
          'Invoice not found',
          style: GoogleFonts.inter(color: AppColors.gray600),
        ),
      );
    }

    final o = _order!;
    final items = o['items'] is List ? o['items'] as List : <dynamic>[];
    final customer = _asMap(o['customerId']);
    final business = _asMap(_business);
    final bizName = (business['name'] ?? 'My Business').toString();
    final bizPhone = _readString(business, ['contact', 'phone']);
    final bizCity = _readString(business, ['address', 'city']);
    final bizState = _readString(business, ['address', 'state']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/invoices'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.gray700,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
          const SizedBox(height: 8),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            'assets/images/logo.svg',
                            width: 36,
                            height: 36,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bizName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gray900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (bizPhone.isNotEmpty)
                                  Text(
                                    bizPhone,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                if (bizCity.isNotEmpty)
                                  Text(
                                    '$bizCity, $bizState',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.gray500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'INVOICE',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (o['orderNumber'] ?? '').toString(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray900,
                          ),
                        ),
                        Text(
                          formatDate(o['createdAt'] ?? ''),
                          style: GoogleFonts.inter(
                            fontSize: 10,
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
                  (customer['name'] ?? o['customerName'] ?? '').toString(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                if ((customer['phone'] ?? o['customerPhone'] ?? '')
                    .toString()
                    .isNotEmpty)
                  Text(
                    (customer['phone'] ?? o['customerPhone']).toString(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.gray600,
                    ),
                  ),
                if ((customer['email'] ?? '').toString().isNotEmpty)
                  Text(
                    customer['email'].toString(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.gray600,
                    ),
                  ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gray200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
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
                      ...items.map((item) {
                        final qty = item['quantity'] ?? 0;
                        final price = item['price'] ?? 0;
                        final lineTotal = (item['total'] ?? 0) == 0
                            ? ((qty is num ? qty : 0) *
                                  (price is num ? price : 0))
                            : item['total'];

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
                                  (item['name'] ?? '').toString(),
                                  style: GoogleFonts.inter(
                                    color: AppColors.gray900,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '$qty',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  formatCurrency(price),
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  formatCurrency(lineTotal),
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
                Divider(color: AppColors.gray200),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          _totalRow(
                            'Subtotal',
                            formatCurrency(o['subtotal'] ?? 0),
                          ),
                          if ((o['discount'] ?? 0) is num &&
                              (o['discount'] ?? 0) > 0)
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
                                formatCurrency(
                                  o['total'] ?? o['totalAmount'] ?? 0,
                                ),
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
        ],
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
