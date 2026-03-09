import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  String _mode = 'margin'; // 'margin' or 'price'
  final _costCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  double _desiredMargin = 30;

  static const _marginTips = [
    (
      range: '0-20%',
      label: 'Low margin',
      color: Color(0xFFEF4444),
      tip: 'Consider if volume makes up for thin margins',
    ),
    (
      range: '20-40%',
      label: 'Standard margin',
      color: Color(0xFFEAB308),
      tip: 'Healthy for most retail businesses',
    ),
    (
      range: '40-60%',
      label: 'Good margin',
      color: Color(0xFF22C55E),
      tip: 'Great profitability, maintain quality',
    ),
    (
      range: '60%+',
      label: 'Premium margin',
      color: Color(0xFF3B82F6),
      tip: 'Ensure value justifies the premium',
    ),
  ];

  @override
  void dispose() {
    _costCtrl.dispose();
    _sellCtrl.dispose();
    super.dispose();
  }

  ({double recommendedPrice, double profit, double margin}) get _result {
    final cost = double.tryParse(_costCtrl.text) ?? 0;
    if (_mode == 'margin') {
      if (cost == 0) return (recommendedPrice: 0, profit: 0, margin: 0);
      final price = cost * (1 + _desiredMargin / 100);
      return (
        recommendedPrice: price,
        profit: price - cost,
        margin: _desiredMargin,
      );
    } else {
      final sell = double.tryParse(_sellCtrl.text) ?? 0;
      if (cost == 0) return (recommendedPrice: 0, profit: 0, margin: 0);
      final profit = sell - cost;
      final margin = ((sell - cost) / cost) * 100;
      return (recommendedPrice: sell, profit: profit, margin: margin);
    }
  }

  ({String range, String label, Color color, String tip}) get _marginLevel {
    final m = _result.margin;
    if (m < 20) return _marginTips[0];
    if (m < 40) return _marginTips[1];
    if (m < 60) return _marginTips[2];
    return _marginTips[3];
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calculate,
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
                          'Smart Pricing Calculator',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find the perfect price for your products',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mode toggle
            _buildModeToggle(),
            const SizedBox(height: 20),

            // Calculator
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray100),
              ),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  final input = _inputSection();
                  final result = _resultSection();
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: input),
                            const SizedBox(width: 32),
                            Expanded(child: result),
                          ],
                        )
                      : Column(
                          children: [input, const SizedBox(height: 20), result],
                        );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Tips
            _tipsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        height: 54,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMargin = _mode == 'margin';
            final segmentWidth = (constraints.maxWidth - 4) / 2;

            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: isMargin ? 0 : segmentWidth,
                  top: 0,
                  width: segmentWidth,
                  height: 54,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(11),
                        onTap: () {
                          if (_mode != 'margin') {
                            setState(() => _mode = 'margin');
                          }
                        },
                        child: _modeLabel(
                          icon: Icons.sell_outlined,
                          text: 'Price from Margin',
                          active: isMargin,
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(11),
                        onTap: () {
                          if (_mode != 'price') {
                            setState(() => _mode = 'price');
                          }
                        },
                        child: _modeLabel(
                          icon: Icons.percent,
                          text: 'Margin from Price',
                          active: !isMargin,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _modeLabel({
    required IconData icon,
    required String text,
    required bool active,
  }) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: active ? AppColors.primary600 : AppColors.gray600,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.primary600 : AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.currency_rupee, size: 18, color: AppColors.primary500),
            const SizedBox(width: 6),
            Text(
              'Enter Details',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Cost Price (Your Purchase Price) *',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _costCtrl,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixText: '₹ ',
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.gray200),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_mode == 'margin') ...[
          Text(
            'Desired Profit Margin: ${_desiredMargin.toInt()}%',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _desiredMargin,
            min: 5,
            max: 100,
            divisions: 19,
            activeColor: AppColors.primary500,
            onChanged: (v) => setState(() => _desiredMargin = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.gray500,
                ),
              ),
              Text(
                '50%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.gray500,
                ),
              ),
              Text(
                '100%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ] else ...[
          Text(
            'Selling Price *',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _sellCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: '0',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _resultSection() {
    final r = _result;
    final ml = _marginLevel;
    final hasCost =
        _costCtrl.text.isNotEmpty && (double.tryParse(_costCtrl.text) ?? 0) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up, size: 18, color: Color(0xFF22C55E)),
            const SizedBox(width: 6),
            Text(
              'Results',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_mode == 'margin')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Selling Price',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(r.recommendedPrice),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Profit per Unit',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(r.profit),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Profit Margin',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${r.margin.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (hasCost) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ml.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ml.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: ml.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ml.label} (${ml.range})',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ml.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ml.tip,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _tipsSection() {
    const tips = [
      "Consider your competition's pricing before setting yours",
      'Factor in all costs: packaging, delivery, returns',
      'Test different price points to find customer sweet spot',
      'Premium products can have higher margins with right positioning',
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary50, const Color(0xFFEFF6FF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: AppColors.primary500,
              ),
              const SizedBox(width: 6),
              Text(
                'Pricing Tips',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: tips
                .map(
                  (t) => SizedBox(
                    width: 300,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.primary500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.gray600,
                            ),
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
    );
  }
}
