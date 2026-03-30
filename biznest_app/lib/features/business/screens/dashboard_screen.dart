import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:biznest_core/biznest_core.dart';
import '../widgets/business_refresh_registry.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _stats;
  List<dynamic> _revenueData = [];
  List<dynamic> _topProducts = [];
  Map<String, dynamic>? _healthScore;
  bool _loading = true;

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  bool get _hasAlerts {
    final pendingOrders = _toInt(_stats?['orders']?['pending']);
    final lowStock = _toInt(_stats?['products']?['lowStock']);
    return pendingOrders > 0 || lowStock > 0;
  }

  @override
  void initState() {
    super.initState();
    BusinessRefreshRegistry.register('/dashboard', _fetchDashboardData);
    _fetchDashboardData();
  }

  @override
  void dispose() {
    BusinessRefreshRegistry.unregister('/dashboard', _fetchDashboardData);
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final results = await Future.wait([
        _api.getDashboardStats(),
        _api.getRevenueChart(),
        _api.getTopProducts(),
        _api.getHealthScore(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0].data;
          _revenueData = results[1].data is List ? results[1].data : [];
          _topProducts = results[2].data is List ? results[2].data : [];
          _healthScore = results[3].data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final sectionGap = width < 360 ? 12.0 : 16.0;
    final authState = context.read<AuthBloc>().state;
    final userName = authState is AuthAuthenticated
        ? authState.userName.split(' ').first
        : '';
    final businessName = authState is AuthAuthenticated
        ? (authState.business?['name'] ?? '')
        : '';

    if (_loading) {
      return const AppPageSkeleton();
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Welcome back, $userName!',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.waving_hand, color: Colors.amber, size: 22),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$businessName Dashboard',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Stats Grid
        _buildStatsGrid(),
        SizedBox(height: sectionGap),

        // Alerts (Pending Orders & Low Stock)
        _buildAlerts(),
        SizedBox(height: sectionGap),

        // Revenue Chart + Health Score
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildRevenueChart()),
                  const SizedBox(width: 16),
                  if (_healthScore != null)
                    Expanded(child: _buildHealthScoreCard()),
                ],
              );
            }
            return Column(
              children: [
                _buildRevenueChart(),
                if (_healthScore != null) ...[
                  const SizedBox(height: 16),
                  _buildHealthScoreCard(),
                ],
              ],
            );
          },
        ),
        SizedBox(height: sectionGap),

        // Top Products & Quick Actions
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTopProducts()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildQuickActions()),
                ],
              );
            }
            return Column(
              children: [
                _buildTopProducts(),
                const SizedBox(height: 16),
                _buildQuickActions(),
              ],
            );
          },
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedHeight && constraints.maxHeight < 620) {
          return SingleChildScrollView(child: content);
        }
        return content;
      },
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 800 ? 4 : 2;
        final aspectRatio = constraints.maxWidth > 800 ? 1.8 : 1.2;
        return GridView.count(
          crossAxisCount: crossCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              title: 'Total Revenue',
              value: formatCurrency(_stats?['revenue']?['total'] ?? 0),
              icon: Icons.currency_rupee,
              color: AppColors.primary600,
              subtitle:
                  '${formatCurrency(_stats?['revenue']?['monthly'] ?? 0)} this month',
            ),
            _StatCard(
              title: 'Total Orders',
              value: '${_stats?['orders']?['total'] ?? 0}',
              icon: Icons.shopping_cart,
              color: AppColors.blue600,
              subtitle: '${_stats?['orders']?['monthly'] ?? 0} this month',
            ),
            _StatCard(
              title: 'Net Profit',
              value: formatCurrency(_stats?['profit']?['net'] ?? 0),
              icon: Icons.trending_up,
              color: AppColors.purple600,
              subtitle: 'This month',
            ),
            _StatCard(
              title: 'Total Customers',
              value: '${_stats?['customers']?['total'] ?? 0}',
              icon: Icons.people,
              color: AppColors.orange600,
              subtitle:
                  '${_stats?['customers']?['repeatRate'] ?? 0}% repeat rate',
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlerts() {
    final pendingOrders = _toInt(_stats?['orders']?['pending']);
    final lowStock = _toInt(_stats?['products']?['lowStock']);
    if (pendingOrders == 0 && lowStock == 0) return const SizedBox.shrink();

    return Column(
      children: [
        if (pendingOrders > 0)
          _buildAlertCard(
            icon: Icons.warning_amber_outlined,
            title: 'New Orders',
            subtitle: '$pendingOrders orders awaiting action',
            color: AppColors.warning,
            bgColor: AppColors.warningLight,
            onTap: () => context.go('/orders'),
          ),
        if (lowStock > 0) ...[
          const SizedBox(height: 12),
          _buildAlertCard(
            icon: Icons.inventory_2_outlined,
            title: 'Low Stock Alert',
            subtitle: '$lowStock products running low',
            color: AppColors.danger,
            bgColor: AppColors.dangerLight,
            onTap: () => context.go('/products'),
          ),
        ],
      ],
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final title = Text(
                'Revenue Overview',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              );

              final action = TextButton.icon(
                onPressed: () => context.go('/analytics'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.primary600,
                ),
                label: Text(
                  'View Details',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary600,
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 6), action],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [title, action],
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: _revenueData.isEmpty
                ? const Center(child: Text('No revenue data'))
                : Builder(
                    builder: (context) {
                      final maxValue = _revenueData.fold<double>(0, (max, d) {
                        final revenue = (d['revenue'] ?? 0).toDouble();
                        return revenue > max ? revenue : max;
                      });
                      final calculatedMaxY = maxValue > 0
                          ? maxValue * 1.15
                          : 1000.0;
                      final interval = calculatedMaxY > 0
                          ? calculatedMaxY / 5
                          : 200.0;

                      return LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: calculatedMaxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: interval,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: AppColors.gray100,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  if (value < 0) return const Text('');
                                  if (value >= 1000) {
                                    return Text(
                                      'Rs ${(value / 1000).toStringAsFixed(0)}k',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.gray400,
                                      ),
                                    );
                                  } else {
                                    return Text(
                                      'Rs ${value.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.gray400,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 &&
                                      index < _revenueData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _revenueData[index]['month']
                                                ?.toString()
                                                .substring(0, 3) ??
                                            '',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: AppColors.gray400,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          clipData: const FlClipData.all(),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _revenueData.asMap().entries.map((e) {
                                final revenue = (e.value['revenue'] ?? 0)
                                    .toDouble();
                                // Ensure value is never negative
                                final safeRevenue = revenue < 0 ? 0.0 : revenue;
                                return FlSpot(e.key.toDouble(), safeRevenue);
                              }).toList(),
                              isCurved: true,
                              preventCurveOverShooting: true,
                              preventCurveOvershootingThreshold: 0.0,
                              color: AppColors.primary600,
                              barWidth: 2.5,
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primary500.withValues(alpha: 0.3),
                                    AppColors.primary500.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    final scoreValue = _healthScore?['score'];
    final score = scoreValue == null
        ? 0.0
        : scoreValue is String
        ? (double.tryParse(scoreValue) ?? 0.0)
        : (scoreValue is num ? scoreValue.toDouble() : 0.0);
    final status = _healthScore?['status'] ?? 'Unknown';
    final tips = _healthScore?['tips'] as List? ?? [];

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
        boxShadow: AppColors.cardShadow,
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
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 140,
              width: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 10,
                      backgroundColor: AppColors.gray100,
                      color: scoreColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${score.toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.gray500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...tips
                .take(3)
                .map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip.toString(),
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

  Widget _buildTopProducts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final title = Text(
                'Top Selling Products',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              );

              final action = TextButton.icon(
                onPressed: () => context.go('/analytics'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.primary600,
                ),
                label: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary600,
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 6), action],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [title, action],
              );
            },
          ),
          const SizedBox(height: 16),
          if (_topProducts.isEmpty)
            const Center(child: Text('No product data'))
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _topProducts.length) {
                            final name =
                                _topProducts[index]['name']?.toString() ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                name.length > 8
                                    ? '${name.substring(0, 8)}...'
                                    : name,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.gray500,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: _topProducts.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: (e.value['totalQuantity'] ?? 0).toDouble(),
                          color: AppColors.primary500,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _QuickAction(
                icon: Icons.inventory_2_outlined,
                title: 'Add Product',
                subtitle: 'Create new product',
                color: AppColors.blue600,
                bgColor: const Color(0xFFEFF6FF),
                onTap: () => context.go('/products'),
              ),
              _QuickAction(
                icon: Icons.shopping_cart_outlined,
                title: 'New Order',
                subtitle: 'Create order',
                color: AppColors.primary600,
                bgColor: AppColors.successLight,
                onTap: () => context.go('/orders'),
              ),
              _QuickAction(
                icon: Icons.people_outlined,
                title: 'Add Customer',
                subtitle: 'New customer',
                color: AppColors.purple600,
                bgColor: const Color(0xFFF3E8FF),
                onTap: () => context.go('/customers'),
              ),
              _QuickAction(
                icon: Icons.description_outlined,
                title: 'View Invoices',
                subtitle: 'Generate invoices',
                color: AppColors.primary600,
                bgColor: const Color(0xFFFEF3C7),
                onTap: () => context.go('/invoices'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.75),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.gray900,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
