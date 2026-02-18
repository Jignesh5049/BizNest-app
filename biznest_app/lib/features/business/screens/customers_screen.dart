// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _api = ApiService();
  List<dynamic> _customers = [];
  bool _loading = true;
  bool _isGrid = true;
  String _search = '';

  // Form
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.getCustomers();
      setState(() {
        _customers = res.data is List ? res.data : [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _customers;
    final q = _search.toLowerCase();
    return _customers.where((c) {
      return (c['name'] ?? '').toString().toLowerCase().contains(q) ||
          (c['phone'] ?? '').toString().contains(q) ||
          (c['email'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  void _openForm([Map<String, dynamic>? customer]) {
    if (customer != null) {
      _editingId = customer['_id'];
      _nameCtrl.text = customer['name'] ?? '';
      _phoneCtrl.text = customer['phone'] ?? '';
      _emailCtrl.text = customer['email'] ?? '';
      _notesCtrl.text = customer['notes'] ?? '';
      _cityCtrl.text = customer['address']?['city'] ?? '';
      _stateCtrl.text = customer['address']?['state'] ?? '';
    } else {
      _editingId = null;
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _emailCtrl.clear();
      _notesCtrl.clear();
      _cityCtrl.clear();
      _stateCtrl.clear();
    }
    showDialog(context: context, builder: (_) => _buildFormDialog());
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.deleteCustomer(id);
        _fetch();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  Future<void> _viewOrders(Map<String, dynamic> customer) async {
    try {
      final res = await _api.getCustomer(customer['_id']);
      final data = res.data;
      final orders = data['orders'] is List ? data['orders'] as List : [];
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) =>
            _buildOrdersDialog(customer['name'] ?? 'Customer', orders),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filtered;
    final repeatCount = _customers
        .where((c) => c['isRepeatCustomer'] == true)
        .length;

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
                    'Customers',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_customers.length} customers • $repeatCount repeat',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            // View toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _toggleBtn(
                    Icons.grid_view_rounded,
                    _isGrid,
                    () => setState(() => _isGrid = true),
                  ),
                  _toggleBtn(
                    Icons.view_list_rounded,
                    !_isGrid,
                    () => setState(() => _isGrid = false),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search + Add
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Content
        if (filtered.isEmpty)
          _emptyState()
        else if (_isGrid)
          _gridView(filtered)
        else
          _listView(filtered),
      ],
    );
  }

  // ─── Grid View ───
  Widget _gridView(List<dynamic> items) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cols = constraints.maxWidth > 900
            ? 3
            : (constraints.maxWidth > 500 ? 2 : 1);
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items
              .map(
                (c) => SizedBox(
                  width: (constraints.maxWidth - 16 * (cols - 1)) / cols,
                  child: _customerCard(c),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _customerCard(Map<String, dynamic> c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Name
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF3E8FF),
                child: Text(
                  (c['name'] ?? '?')[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9333EA),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c['name'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (c['isRepeatCustomer'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Color(0xFFEAB308),
                          ),
                        ],
                      ],
                    ),
                    if ((c['address']?['city'] ?? '').toString().isNotEmpty)
                      Text(
                        c['address']['city'],
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
          const SizedBox(height: 12),

          // Contact
          if ((c['phone'] ?? '').toString().isNotEmpty)
            _infoRow(Icons.phone_outlined, c['phone']),
          if ((c['email'] ?? '').toString().isNotEmpty)
            _infoRow(Icons.email_outlined, c['email']),

          const SizedBox(height: 12),

          // Stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Orders',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.gray500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c['orderCount'] ?? 0}',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total Spent',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.gray500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatCurrency(c['totalSpent'] ?? 0),
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewOrders(c),
                  icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                  label: const Text('View Orders'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray700,
                    side: BorderSide(color: AppColors.gray200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _iconBtn(
                Icons.edit_outlined,
                const Color(0xFFEFF6FF),
                const Color(0xFF2563EB),
                () => _openForm(c),
              ),
              const SizedBox(width: 6),
              _iconBtn(
                Icons.delete_outlined,
                const Color(0xFFFEF2F2),
                AppColors.danger,
                () => _delete(c['_id']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── List View ───
  Widget _listView(List<dynamic> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.gray50),
          columns: const [
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Contact')),
            DataColumn(label: Text('Orders')),
            DataColumn(label: Text('Total Spent')),
            DataColumn(label: Text('Actions')),
          ],
          rows: items.map((c) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFF3E8FF),
                        child: Text(
                          (c['name'] ?? '?')[0].toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9333EA),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c['name'] ?? '',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray900,
                                ),
                              ),
                              if (c['isRepeatCustomer'] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Color(0xFFEAB308),
                                ),
                              ],
                            ],
                          ),
                          if ((c['address']?['city'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Text(
                              c['address']['city'],
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.gray500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((c['phone'] ?? '').toString().isNotEmpty)
                        Text(
                          c['phone'],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.gray700,
                          ),
                        ),
                      if ((c['email'] ?? '').toString().isNotEmpty)
                        Text(
                          c['email'],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.gray700,
                          ),
                        ),
                    ],
                  ),
                ),
                DataCell(Text('${c['orderCount'] ?? 0}')),
                DataCell(Text(formatCurrency(c['totalSpent'] ?? 0))),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          size: 18,
                        ),
                        onPressed: () => _viewOrders(c),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: const Color(0xFF2563EB),
                        ),
                        onPressed: () => _openForm(c),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outlined,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        onPressed: () => _delete(c['_id']),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Dialogs ───
  Widget _buildFormDialog() {
    return StatefulBuilder(
      builder: (ctx, setDialogState) {
        bool isSaving = false;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingId != null
                            ? 'Edit Customer'
                            : 'Add New Customer',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _field(
                        'Name *',
                        _nameCtrl,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              'Phone',
                              _phoneCtrl,
                              keyboard: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              'Email',
                              _emailCtrl,
                              keyboard: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field('City', _cityCtrl)),
                          const SizedBox(width: 12),
                          Expanded(child: _field('State', _stateCtrl)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field('Notes', _notesCtrl, maxLines: 3),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }

                                      setDialogState(() => isSaving = true);

                                      final data = {
                                        'name': _nameCtrl.text.trim(),
                                        'phone': _phoneCtrl.text.trim(),
                                        'email': _emailCtrl.text.trim(),
                                        'notes': _notesCtrl.text.trim(),
                                        'address': {
                                          'city': _cityCtrl.text.trim(),
                                          'state': _stateCtrl.text.trim(),
                                        },
                                      };

                                      try {
                                        if (_editingId != null) {
                                          await _api.updateCustomer(
                                            _editingId!,
                                            data,
                                          );
                                        } else {
                                          await _api.createCustomer(data);
                                        }

                                        if (ctx.mounted &&
                                            Navigator.canPop(ctx)) {
                                          Navigator.pop(ctx);
                                        }

                                        if (mounted) _fetch();
                                      } catch (e) {
                                        if (ctx.mounted) {
                                          setDialogState(
                                            () => isSaving = false,
                                          );
                                          ScaffoldMessenger.of(
                                            ctx,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to save customer: $e',
                                              ),
                                              backgroundColor: AppColors.danger,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                  : Text(
                                      _editingId != null
                                          ? 'Update Customer'
                                          : 'Add Customer',
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
          ),
        );
      },
    );
  }

  Widget _buildOrdersDialog(String name, List orders) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$name's Orders",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 16),
              if (orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: AppColors.gray300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No orders yet',
                          style: GoogleFonts.inter(color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: orders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final o = orders[i];
                      final statusColor = getStatusColor(o['paymentStatus']);
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  o['orderNumber'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.bg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    o['paymentStatus'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatDate(o['createdAt'] ?? ''),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.gray500,
                                  ),
                                ),
                                Text(
                                  formatCurrency(o['total'] ?? 0),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───
  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.gray200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.gray500),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: active ? AppColors.primary600 : AppColors.gray500,
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: fg),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outlined, size: 64, color: AppColors.gray300),
          const SizedBox(height: 12),
          Text(
            'No customers yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start by adding your first customer',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _openForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }
}
