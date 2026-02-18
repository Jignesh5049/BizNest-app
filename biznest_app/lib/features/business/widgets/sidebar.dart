import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';

class AppSidebar extends StatelessWidget {
  final VoidCallback? onClose;

  const AppSidebar({super.key, this.onClose});

  static final List<_NavItem> _navItems = [
    _NavItem(path: '/dashboard', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Dashboard'),
    _NavItem(path: '/products', icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Products'),
    _NavItem(path: '/orders', icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'Orders'),
    _NavItem(path: '/customers', icon: Icons.people_outlined, activeIcon: Icons.people, label: 'Customers'),
    _NavItem(path: '/expenses', icon: Icons.currency_rupee_outlined, activeIcon: Icons.currency_rupee, label: 'Expenses'),
    _NavItem(path: '/analytics', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Analytics'),
    _NavItem(path: '/pricing', icon: Icons.calculate_outlined, activeIcon: Icons.calculate, label: 'Pricing Tool'),
    _NavItem(path: '/invoices', icon: Icons.description_outlined, activeIcon: Icons.description, label: 'Invoices'),
    _NavItem(path: '/learn', icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Learn'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.gray100)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'BN',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'BizNest',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: [
                for (final item in _navItems) ...[
                  _buildNavLink(context, item, currentLocation),
                ],
              ],
            ),
          ),

          // Bottom Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.gray100)),
            ),
            child: Column(
              children: [
                _buildNavLink(
                  context,
                  _NavItem(path: '/support', icon: Icons.chat_outlined, activeIcon: Icons.chat, label: 'Support'),
                  currentLocation,
                ),
                _buildNavLink(
                  context,
                  _NavItem(path: '/settings', icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
                  currentLocation,
                ),
                const SizedBox(height: 4),
                // Logout Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: AppColors.danger),
                          const SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, _NavItem item, String currentLocation) {
    final isActive = currentLocation == item.path;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive ? AppColors.primary50 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            context.go(item.path);
            onClose?.call();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 20,
                  color: isActive ? AppColors.primary600 : AppColors.gray600,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? AppColors.primary600 : AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
