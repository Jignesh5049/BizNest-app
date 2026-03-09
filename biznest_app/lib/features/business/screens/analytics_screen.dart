import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/helpers.dart';

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

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final results = await Future.wait([
        _api.getDashboardStats(),
        _api.getRevenueChart(),
        _api.getTopProducts(),
        _api.getHealthScore(),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
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
          const SizedBox(height: 24),

          // KPI Cards
          _kpiCards(),
          const SizedBox(height: 24),

          // Revenue vs Expenses Chart
          _revenueChart(),
          const SizedBox(height: 24),

          // Bottom Row
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 700;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _topProductsCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _healthScoreCard()),
                      ],
                    )
                  : Column(
                      children: [
                        _topProductsCard(),
                        const SizedBox(height: 16),
                        _healthScoreCard(),
                      ],
                    );
            },
          ),
        ],
      ),
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
