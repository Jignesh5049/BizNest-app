import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:biznest_core/biznest_core.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _stats;
  List<dynamic> _revenueData = [];
  List<dynamic> _topProducts = [];
  Map<String, dynamic>? _healthScore;
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
      final params = _buildDateParams();
      final results = await Future.wait([
        _api.getDashboardStats(params: params),
        _api.getRevenueChart(params: params),
        _api.getTopProducts(params: params),
        _api.getHealthScore(params: params),
      ]);
      setState(() {
        _stats = results[0].data is Map
            ? Map<String, dynamic>.from(results[0].data as Map)
            : null;
        _revenueData = results[1].data is List ? results[1].data as List : [];
        _topProducts = results[2].data is List ? results[2].data as List : [];
        _healthScore = results[3].data is Map
            ? Map<String, dynamic>.from(results[3].data as Map)
            : null;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _buildDateParams() {
    final monthRange = _monthRange(_selectedMonth);
    final start = _customRange?.start ?? monthRange.start;
    final end = _customRange?.end ?? monthRange.end;
    return {
      'startDate': _normalizeStart(start).toUtc().toIso8601String(),
      'endDate': _normalizeEnd(end).toUtc().toIso8601String(),
    };
  }

  DateTimeRange _monthRange(DateTime monthDate) {
    final start = DateTime(monthDate.year, monthDate.month, 1);
    final end = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
    return DateTimeRange(start: start, end: end);
  }

  DateTime get _effectiveMinSelectableDate =>
      _minSelectableDate ?? DateTime(2020, 1, 1);

  DateTime _normalizeStart(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _normalizeEnd(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
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
    if (_loading) return const Center(child: CircularProgressIndicator());

    final width = MediaQuery.of(context).size.width;
    final sectionGap = width < 360 ? 16.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Business Analytics',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Deep insights into your business performance',
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
        SizedBox(height: sectionGap),

        // KPI Cards
        _kpiCards(),
        SizedBox(height: sectionGap),

        // Revenue vs Expenses Chart
        _revenueChart(),
        SizedBox(height: sectionGap),

        // Bottom Row
        LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _topProductsCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _healthScoreCard()),
                    ],
                  )
                : Column(
                    children: [
                      _topProductsCard(),
                      const SizedBox(height: 12),
                      _healthScoreCard(),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _kpiCards() {
    final revenue = _stats?['revenue'];
    final profit = _stats?['profit'];
    final expenses = _stats?['expenses'];
    final customers = _stats?['customers'];

    // Safely convert growth to double
    final growthValue = revenue?['growth'];
    final growth = growthValue == null
        ? 0.0
        : growthValue is String
        ? (double.tryParse(growthValue) ?? 0.0)
        : (growthValue is num ? growthValue.toDouble() : 0.0);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth > 700;
        final cards = [
          _kpiCard(
            'Monthly Revenue',
            formatCurrency(revenue?['monthly'] ?? 0),
            AppColors.gray900,
            trailing: Wrap(
              spacing: 4,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  growth > 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: growth > 0
                      ? const Color(0xFF22C55E)
                      : AppColors.danger,
                ),
                Text(
                  '${growth.abs().toStringAsFixed(0)}% vs last month',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: growth > 0
                        ? const Color(0xFF22C55E)
                        : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          _kpiCard(
            'Monthly Profit',
            formatCurrency(profit?['net'] ?? 0),
            const Color(0xFF22C55E),
            subtitle: 'After expenses',
          ),
          _kpiCard(
            'Monthly Expenses',
            formatCurrency(expenses?['monthly'] ?? 0),
            AppColors.danger,
            subtitle: 'This month',
          ),
          _kpiCard(
            'Repeat Customer Rate',
            '${customers?['repeatRate'] ?? 0}%',
            const Color(0xFF9333EA),
            subtitle: '${customers?['repeat'] ?? 0} repeat customers',
          ),
        ];

        if (isWide) {
          return Row(
            children: cards
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: c,
                    ),
                  ),
                )
                .toList(),
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (c) => SizedBox(
                  width: constraints.maxWidth < 520
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2,
                  child: c,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _kpiCard(
    String label,
    String value,
    Color valueColor, {
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.gray500),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.gray500),
            ),
          ],
          if (trailing != null) ...[const SizedBox(height: 6), trailing],
        ],
      ),
    );
  }

  Widget _revenueChart() {
    if (_revenueData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Center(
          child: Text(
            'No chart data available',
            style: GoogleFonts.inter(color: AppColors.gray500),
          ),
        ),
      );
    }

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
            'Revenue vs Expenses',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            children: [
              _legendItem('Revenue', const Color(0xFF22C55E)),
              const SizedBox(width: 16),
              _legendItem('Expenses', const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              _legendItem('Profit', const Color(0xFF0EA5E9)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: 0,
                maxY:
                    _revenueData.fold<double>(0, (max, d) {
                      final revValue = d['revenue'];
                      final revenue = revValue == null
                          ? 0.0
                          : revValue is String
                          ? (double.tryParse(revValue) ?? 0.0)
                          : (revValue is num ? revValue.toDouble() : 0.0);
                      final expValue = d['expenses'];
                      final expenses = expValue == null
                          ? 0.0
                          : expValue is String
                          ? (double.tryParse(expValue) ?? 0.0)
                          : (expValue is num ? expValue.toDouble() : 0.0);
                      final profValue = d['profit'];
                      final profit =
                          (profValue == null
                                  ? 0.0
                                  : profValue is String
                                  ? (double.tryParse(profValue) ?? 0.0)
                                  : (profValue is num
                                        ? profValue.toDouble()
                                        : 0.0))
                              .abs();
                      final maxValue = [
                        revenue,
                        expenses,
                        profit,
                      ].reduce((a, b) => a > b ? a : b);
                      return maxValue > max ? maxValue : max;
                    }) *
                    1.15,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final labels = ['Revenue', 'Expenses', 'Profit'];
                      return BarTooltipItem(
                        '${labels[rodIndex]}\n${formatCurrency(rod.toY)}',
                        GoogleFonts.inter(fontSize: 12, color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _revenueData.length) {
                          return const SizedBox();
                        }
                        final monthValue = _revenueData[idx]['month'];
                        final monthStr = monthValue == null
                            ? ''
                            : monthValue is String
                            ? monthValue
                            : monthValue.toString();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            monthStr,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.gray500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(0)}k',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.gray500,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppColors.gray100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_revenueData.length, (i) {
                  final d = _revenueData[i];
                  final revValue = d['revenue'];
                  final revenue = revValue == null
                      ? 0.0
                      : revValue is String
                      ? (double.tryParse(revValue) ?? 0.0)
                      : (revValue is num ? revValue.toDouble() : 0.0);
                  final expValue = d['expenses'];
                  final expenses = expValue == null
                      ? 0.0
                      : expValue is String
                      ? (double.tryParse(expValue) ?? 0.0)
                      : (expValue is num ? expValue.toDouble() : 0.0);
                  final profValue = d['profit'];
                  final profit =
                      (profValue == null
                              ? 0.0
                              : profValue is String
                              ? (double.tryParse(profValue) ?? 0.0)
                              : (profValue is num ? profValue.toDouble() : 0.0))
                          .abs();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: revenue,
                        color: const Color(0xFF22C55E),
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: expenses,
                        color: const Color(0xFFEF4444),
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: profit,
                        color: const Color(0xFF0EA5E9),
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.gray600),
        ),
      ],
    );
  }

  Widget _topProductsCard() {
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
            'Top Selling Products',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          if (_topProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: AppColors.gray300),
                    const SizedBox(height: 8),
                    Text(
                      'No sales data yet',
                      style: GoogleFonts.inter(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_topProducts.length, (i) {
              final p = _topProducts[i];
              final maxQtyVal = _topProducts[0]['totalQuantity'];
              final maxQty = (maxQtyVal == null
                  ? 1
                  : (maxQtyVal is int
                        ? maxQtyVal.toDouble()
                        : (double.tryParse(maxQtyVal.toString()) ?? 1)));
              final qtyVal = p['totalQuantity'];
              final qty = (qtyVal == null
                  ? 0
                  : (qtyVal is int
                        ? qtyVal.toDouble()
                        : (double.tryParse(qtyVal.toString()) ?? 0)));
              final productName = (p['name'] ?? '').toString();
              final totalRevenue = p['totalRevenue'];
              final totalQty = qtyVal ?? 0;
              return Padding(
                padding: EdgeInsets.only(top: i > 0 ? 12 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: maxQty > 0 ? qty / maxQty : 0,
                              backgroundColor: AppColors.gray100,
                              color: AppColors.primary500,
                              minHeight: 6,
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
                          '$totalQty sold',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          formatCurrency(totalRevenue ?? 0),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _healthScoreCard() {
    if (_healthScore == null) return const SizedBox();
    final scoreValue = _healthScore!['score'];
    final score = scoreValue == null
        ? 0.0
        : scoreValue is String
        ? (double.tryParse(scoreValue) ?? 0.0)
        : (scoreValue is num ? scoreValue.toDouble() : 0.0);
    final status = _healthScore!['status'] ?? '';
    final tips = _healthScore!['tips'] is List
        ? _healthScore!['tips'] as List
        : [];
    final breakdown = _healthScore!['breakdown'] is Map
        ? Map<String, dynamic>.from(_healthScore!['breakdown'] as Map)
        : <String, dynamic>{};

    Color scoreColor;
    if (score >= 70) {
      scoreColor = const Color(0xFF22C55E);
    } else if (score >= 40) {
      scoreColor = const Color(0xFFEAB308);
    } else {
      scoreColor = AppColors.danger;
    }

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
            'Business Health Score',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          // Score circle
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 10,
                      backgroundColor: AppColors.gray100,
                      color: scoreColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${score.toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Breakdown
          if (breakdown.isNotEmpty) ...[
            ...breakdown.entries.map((e) {
              final valRaw = e.value;
              final val = valRaw == null
                  ? 0.0
                  : valRaw is String
                  ? (double.tryParse(valRaw) ?? 0.0)
                  : (valRaw is num ? valRaw.toDouble() : 0.0);
              final keyStr = (e.key ?? '').toString();
              final displayLabel = keyStr
                  .replaceAll('_', ' ')
                  .replaceAllMapped(
                    RegExp(r'^\w'),
                    (m) => (m[0] ?? '').toUpperCase(),
                  );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          displayLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.gray600,
                          ),
                        ),
                        Text(
                          '${val.toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: val / 100,
                        backgroundColor: AppColors.gray100,
                        color: scoreColor,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          // Tips
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Tips',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            ...tips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: const Color(0xFFEAB308),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.gray600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
