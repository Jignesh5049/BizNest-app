import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:biznest_core/biznest_core.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  static final _articles = [
    (
      icon: Icons.trending_up,
      color: const Color(0xFF22C55E),
      title: '5 Growth Tips for Small Businesses',
      tips: [
        'Focus on your top 20% customers who bring 80% revenue',
        'Reinvest profits into marketing during slow seasons',
        'Track your expenses daily to avoid financial surprises',
        'Build an online presence with social media',
        'Offer loyalty programs to retain customers',
      ],
    ),
    (
      icon: Icons.campaign,
      color: const Color(0xFF3B82F6),
      title: 'Marketing on a Budget',
      tips: [
        'Use WhatsApp Business for free customer communication',
        'Create Instagram Reels showcasing your products',
        'Ask satisfied customers for Google reviews',
        'Start a referral program with discounts for referrers',
        'Participate in local community events',
      ],
    ),
    (
      icon: Icons.inventory_2,
      color: const Color(0xFF9333EA),
      title: 'Smart Inventory Management',
      tips: [
        'Track fast-moving vs slow-moving products',
        'Set reorder points to never run out of stock',
        'Negotiate bulk discounts with suppliers',
        'Do monthly inventory audits to avoid losses',
        'Use FIFO (First In, First Out) for perishables',
      ],
    ),
    (
      icon: Icons.currency_rupee,
      color: const Color(0xFFEAB308),
      title: 'Pricing Strategies That Work',
      tips: [
        'Research competitor pricing before setting yours',
        "Use bundle pricing to increase average order value",
        'Offer early-bird or festive discounts strategically',
        'Test different price points on similar products',
        'Ensure your margins cover ALL costs, not just purchase price',
      ],
    ),
    (
      icon: Icons.people,
      color: const Color(0xFFEC4899),
      title: 'Customer Service Excellence',
      tips: [
        'Respond to customer queries within 2 hours',
        'Handle complaints with empathy and quick resolution',
        'Follow up after purchase to build relationships',
        'Train staff on product knowledge and soft skills',
        'Create a FAQ document for common questions',
      ],
    ),
    (
      icon: Icons.analytics,
      color: const Color(0xFF14B8A6),
      title: 'Understanding Your Business Data',
      tips: [
        'Review your daily sales and expenses every morning',
        'Calculate your break-even point and monitor it',
        'Track customer acquisition cost (CAC)',
        'Measure customer lifetime value (CLV)',
        'Use data to make decisions, not just gut feeling',
      ],
    ),
  ];

  static final _resources = [
    (title: 'YouTube: Business Mastery', url: 'https://youtube.com/', icon: Icons.play_circle, color: const Color(0xFFEF4444)),
    (title: 'Canva: Free Design Tool', url: 'https://canva.com/', icon: Icons.palette, color: const Color(0xFF3B82F6)),
    (title: 'Google My Business', url: 'https://business.google.com/', icon: Icons.store, color: const Color(0xFF22C55E)),
    (title: 'WhatsApp Business', url: 'https://business.whatsapp.com/', icon: Icons.chat, color: const Color(0xFF25D366)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text('Learn & Grow', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.gray900)),
        const SizedBox(height: 4),
        Text('Tips, guides, and resources to grow your business', style: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500)),
        const SizedBox(height: 20),

        // Pro Tip Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFFBBF24)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, size: 28, color: Color(0xFF92400E)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡 Pro Tip of the Day',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF78350F))),
                    const SizedBox(height: 6),
                    Text(
                      'Track your expenses daily, even small ones. At the end of the month, you\'ll know exactly where your money went!',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Articles grid
        LayoutBuilder(builder: (ctx, constraints) {
          final cols = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 550 ? 2 : 1);
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _articles
                .map((a) => SizedBox(
                      width: (constraints.maxWidth - 16 * (cols - 1)) / cols,
                      child: _articleCard(a),
                    ))
                .toList(),
          );
        }),
        const SizedBox(height: 24),

        // Resources
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary50, const Color(0xFFEFF6FF)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Helpful Resources', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray900)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _resources
                    .map((r) => InkWell(
                          onTap: () => launchUrl(Uri.parse(r.url), mode: LaunchMode.externalApplication),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 190,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                            ),
                            child: Row(
                              children: [
                                Icon(r.icon, size: 22, color: r.color),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(r.title,
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _articleCard(dynamic a) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (a.color as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(a.icon as IconData, size: 22, color: a.color as Color),
          ),
          const SizedBox(height: 14),
          Text(a.title as String,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900)),
          const SizedBox(height: 12),
          ...(a.tips as List<String>).map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: a.color as Color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(tip, style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray600))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}


