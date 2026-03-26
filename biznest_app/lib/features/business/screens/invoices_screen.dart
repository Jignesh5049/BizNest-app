import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_core/biznest_core.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _api = ApiService();
  List<dynamic> _orders = [];
  bool _loading = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTimeRange? _customRange;
  DateTime? _minSelectableDate;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadMinimumDate();
    if (!mounted) return;
    _fetch();
  }

  Future<void> _loadMinimumDate() async {
    try {
      final response = await _api.getBusiness();
      final data = response.data;
      if (data is Map && data['createdAt'] != null) {
        final parsed = DateTime.tryParse(data['createdAt'].toString());
        if (parsed != null) {
          final minDate = DateTime(parsed.year, parsed.month, parsed.day);
          final selectedMonthStart = DateTime(
            _selectedMonth.year,
            _selectedMonth.month,
            1,
          );
          if (selectedMonthStart.isBefore(
            DateTime(minDate.year, minDate.month),
          )) {
            _selectedMonth = DateTime(minDate.year, minDate.month);
          }
          _minSelectableDate = minDate;
        }
      }
    } catch (_) {
      // Keep fallback minimum date when business metadata is unavailable.
    }
  }

  Future<void> _fetch() async {
    try {
      final dateParams = _currentDateWindowParams();
      final response = await _api.getOrders(params: dateParams);
      setState(() {
        _orders = response.data is List ? response.data as List : [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  DateTimeRange _monthRange(DateTime monthDate) {
    final start = DateTime(monthDate.year, monthDate.month, 1);
    final end = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
    return DateTimeRange(start: start, end: end);
  }

  String _monthLabel(DateTime monthDate) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[monthDate.month - 1]} ${monthDate.year}';
  }

  DateTime get _effectiveMinSelectableDate =>
      _minSelectableDate ?? DateTime(2020, 1, 1);

  DateTime _normalizeStart(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _normalizeEnd(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  Map<String, dynamic> _currentDateWindowParams() {
    final monthRange = _monthRange(_selectedMonth);
    final start = _customRange?.start ?? monthRange.start;
    final end = _customRange?.end ?? monthRange.end;
    return {
      'startDate': _normalizeStart(start).toUtc().toIso8601String(),
      'endDate': _normalizeEnd(end).toUtc().toIso8601String(),
    };
  }

  String _selectedDateLabel() {
    if (_customRange == null) {
      return _monthLabel(_selectedMonth);
    }
    return '${formatDate(_customRange!.start.toIso8601String())} - ${formatDate(_customRange!.end.toIso8601String())}';
  }

  Future<void> _openCalendarPicker() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Select month'),
              onTap: () => Navigator.pop(ctx, 'month'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range_outlined),
              title: const Text('Select date range'),
              onTap: () => Navigator.pop(ctx, 'range'),
            ),
            if (_customRange != null)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Clear custom range'),
                onTap: () => Navigator.pop(ctx, 'clear'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'month') {
      await _pickMonth();
      return;
    }
    if (action == 'range') {
      await _pickCustomRange();
      return;
    }
    if (action == 'clear' && _customRange != null) {
      setState(() {
        _customRange = null;
        _loading = true;
      });
      _fetch();
    }
  }

  Future<void> _pickMonth() async {
    final minDate = _effectiveMinSelectableDate;
    final now = DateTime.now();
    final initialDate = _selectedMonth.isBefore(minDate)
        ? minDate
        : (_selectedMonth.isAfter(now) ? now : _selectedMonth);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: now,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
      _customRange = null;
      _loading = true;
    });
    _fetch();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final minDate = _effectiveMinSelectableDate;
    final maxStart = now.isBefore(minDate) ? minDate : now;
    final initialRange =
        _customRange ??
        DateTimeRange(
          start: DateTime(maxStart.year, maxStart.month, 1),
          end: now,
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: minDate,
      lastDate: now,
      initialDateRange: initialRange,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _customRange = picked;
      _selectedMonth = DateTime(picked.start.year, picked.start.month);
      _loading = true;
    });
    _fetch();
  }

  void _goToPreviousMonth() {
    final minMonth = DateTime(
      _effectiveMinSelectableDate.year,
      _effectiveMinSelectableDate.month,
    );
    final previousMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
    );
    if (previousMonth.isBefore(minMonth)) return;

    setState(() {
      _selectedMonth = previousMonth;
      _customRange = null;
      _loading = true;
    });
    _fetch();
  }

  void _goToNextMonth() {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (nextMonth.isAfter(currentMonth)) return;

    setState(() {
      _selectedMonth = nextMonth;
      _customRange = null;
      _loading = true;
    });
    _fetch();
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
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              onPressed: _goToPreviousMonth,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
            ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openCalendarPicker,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(
                  _selectedDateLabel(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton(
              onPressed: _goToNextMonth,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
            ),
          ],
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
