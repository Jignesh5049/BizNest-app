import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:biznest_core/biznest_core.dart';
import '../widgets/business_refresh_registry.dart';
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
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTimeRange? _customRange;
  DateTime? _minSelectableDate;

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
    BusinessRefreshRegistry.register('/orders', _fetchOrders);
    _initialize();
  }

  @override
  void dispose() {
    BusinessRefreshRegistry.unregister('/orders', _fetchOrders);
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadMinimumDate();
    if (!mounted) return;
    _fetchOrders();
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

  DateTime get _effectiveMinSelectableDate =>
      _minSelectableDate ?? DateTime(2020, 1, 1);

  DateTimeRange _monthRange(DateTime monthDate) {
    final start = DateTime(monthDate.year, monthDate.month, 1);
    final end = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
    return DateTimeRange(start: start, end: end);
  }

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
      });
      _fetchOrders();
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
    });
    _fetchOrders();
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
    });
    _fetchOrders();
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
    });
    _fetchOrders();
  }

  void _goToNextMonth() {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (nextMonth.isAfter(currentMonth)) return;

    setState(() {
      _selectedMonth = nextMonth;
      _customRange = null;
    });
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{..._currentDateWindowParams()};
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
                                  child: AppGradientButton(
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
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
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
            AppGradientButton(
              onPressed: _openAddOrderScreen,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text('New Order'),
                ],
              ),
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
          const AppPageSkeleton()
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
              //  m button (extracted separately for right-alignment)
              final invoiceButton = (order['paymentStatus'] ?? '') == 'paid'
                  ? TextButton.icon(
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
                    )
                  : null;

              // Other action buttons
              final otherActions = <Widget>[
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
              ];

              final totalText = Text(
                'Total: ${formatCurrency(total)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary600,
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (invoiceButton != null) invoiceButton,
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: totalText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (otherActions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 4, runSpacing: 4, children: otherActions),
                  ],
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
