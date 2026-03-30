// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:biznest_core/biznest_core.dart';
import '../widgets/business_refresh_registry.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _api = ApiService();
  List<dynamic> _expenses = [];
  Map<String, dynamic> _summary = {'summary': [], 'totalExpenses': 0};
  bool _loading = true;
  String _filterCategory = '';
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTimeRange? _customRange;
  DateTime? _minSelectableDate;

  static const _chartColors = [
    Color(0xFF0ea5e9),
    Color(0xFF22c55e),
    Color(0xFFf59e0b),
    Color(0xFFef4444),
    Color(0xFF8b5cf6),
    Color(0xFFec4899),
    Color(0xFF14b8a6),
    Color(0xFFf97316),
    Color(0xFF6366f1),
  ];

  @override
  void initState() {
    super.initState();
    BusinessRefreshRegistry.register('/expenses', _fetch);
    _initialize();
  }

  @override
  void dispose() {
    BusinessRefreshRegistry.unregister('/expenses', _fetch);
    super.dispose();
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
      final baseParams = <String, dynamic>{...dateParams};
      if (_filterCategory.isNotEmpty) {
        baseParams['category'] = _filterCategory;
      }

      final results = await Future.wait([
        _api.getExpenses(params: baseParams),
        _api.getExpensesSummary(params: dateParams),
      ]);
      setState(() {
        _expenses = results[0].data is List ? results[0].data : [];
        _summary = results[1].data is Map
            ? Map<String, dynamic>.from(results[1].data as Map)
            : {'summary': [], 'totalExpenses': 0};
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteExpense(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Delete this expense?'),
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
      await _api.deleteExpense(id);
      _fetch();
    }
  }

  Future<void> _openAddExpenseScreen() async {
    final created = await context.push<bool>('/expenses/add');
    if (created == true && mounted) {
      _fetch();
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

  String _dateOnly(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, dynamic> _currentDateWindowParams() {
    final monthRange = _monthRange(_selectedMonth);
    final start = _customRange?.start ?? monthRange.start;
    final end = _customRange?.end ?? monthRange.end;
    return {
      'startDate': _dateOnly(_normalizeStart(start)),
      'endDate': _dateOnly(_normalizeEnd(end)),
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
    if (_loading) return const AppPageSkeleton();

    final summaryList = (_summary['summary'] is List)
        ? _summary['summary'] as List
        : [];
    final totalExpenses = (_summary['totalExpenses'] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expenses',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your business expenses',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _filterCategory.isEmpty ? '' : _filterCategory,
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('All Categories'),
                        ),
                        ...expenseCategories.entries.map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value.label),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _filterCategory = v ?? '';
                          _loading = true;
                        });
                        _fetch();
                      },
                    ),
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
                const SizedBox(height: 12),
                AppGradientButton(
                  onPressed: _openAddExpenseScreen,
                  minimumSize: const Size(double.infinity, 48),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Add Expense'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Summary Row
        LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _totalCard(totalExpenses)),
                      const SizedBox(width: 16),
                      Expanded(flex: 7, child: _chartCard(summaryList)),
                    ],
                  )
                : Column(
                    children: [
                      _totalCard(totalExpenses),
                      const SizedBox(height: 16),
                      _chartCard(summaryList),
                    ],
                  );
          },
        ),
        const SizedBox(height: 20),

        // Expenses List
        if (_expenses.isEmpty) _emptyState() else _expensesList(),
      ],
    );
  }

  Widget _totalCard(dynamic total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.currency_rupee,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Expenses',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  formatCurrency(total),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _selectedDateLabel(),
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(List summaryList) {
    final chartData = summaryList.asMap().entries.map((e) {
      final item = e.value;
      final label =
          expenseCategories[item['_id']]?.label ?? item['_id'].toString();
      return _ChartItem(
        label,
        (item['total'] ?? 0).toDouble(),
        _chartColors[e.key % _chartColors.length],
      );
    }).toList();

    return Container(
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
            'Expense Breakdown',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          if (chartData.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _customRange == null
                      ? 'No expense data for selected month'
                      : 'No expense data for selected duration',
                  style: GoogleFonts.inter(color: AppColors.gray500),
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: chartData
                            .map(
                              (d) => PieChartSectionData(
                                value: d.value,
                                color: d.color,
                                radius: 35,
                                title: '',
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: chartData
                        .map(
                          (d) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: d.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  d.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _expensesList() {
    return Container(
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
            'Recent Expenses',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_expenses.length, (i) {
            final e = _expenses[i];
            final cat = expenseCategories[e['category']];
            return Container(
              margin: EdgeInsets.only(top: i > 0 ? 8 : 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      cat?.icon ?? Icons.list_alt_outlined,
                      size: 20,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat?.label ?? e['category'].toString(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray900,
                          ),
                        ),
                        if ((e['description'] ?? '').toString().isNotEmpty)
                          Text(
                            e['description'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.gray500,
                            ),
                          ),
                        Text(
                          formatDate(e['date'] ?? ''),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '-${formatCurrency(e['amount'] ?? 0)}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _deleteExpense(e['_id']),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.delete_outlined,
                        size: 18,
                        color: AppColors.gray400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
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
          Icon(
            Icons.currency_rupee_outlined,
            size: 64,
            color: AppColors.gray300,
          ),
          const SizedBox(height: 12),
          Text(
            'No expenses recorded',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start tracking your business expenses',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),
          AppGradientButton(
            onPressed: _openAddExpenseScreen,
            minimumSize: const Size(160, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }
}

class _ChartItem {
  final String label;
  final double value;
  final Color color;
  _ChartItem(this.label, this.value, this.color);
}
