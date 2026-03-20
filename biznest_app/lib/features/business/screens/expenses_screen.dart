// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';

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
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final params = _filterCategory.isNotEmpty
          ? {'category': _filterCategory}
          : null;
      final results = await Future.wait([
        _api.getExpenses(
          params: params != null ? Map<String, dynamic>.from(params) : null,
        ),
        _api.getExpensesSummary(),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

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
                ElevatedButton.icon(
                  onPressed: _openAddExpenseScreen,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      _totalCard(totalExpenses),
                      const SizedBox(width: 16),
                      Expanded(child: _chartCard(summaryList)),
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
      constraints: const BoxConstraints(maxWidth: 280),
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
          Column(
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
                'This Month',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
              ),
            ],
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
                  'No expense data for this month',
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
          ElevatedButton(
            onPressed: _openAddExpenseScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
