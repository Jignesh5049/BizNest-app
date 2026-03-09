import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../cubit/cart_cubit.dart';

class CustomerShell extends StatelessWidget {
  final Widget child;
  const CustomerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/images/favicon.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'BizNest',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
        actions: [
          // Cart icon with badge
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => context.go('/store/cart'),
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      color: location == '/store/cart'
                          ? AppColors.primary600
                          : AppColors.gray600,
                    ),
                  ),
                  if (cartState.itemCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cartState.itemCount}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  context,
                  Icons.home_outlined,
                  Icons.home,
                  'Home',
                  '/store',
                  location,
                ),
                _navItem(
                  context,
                  Icons.shopping_bag_outlined,
                  Icons.shopping_bag,
                  'Orders',
                  '/store/orders',
                  location,
                ),
                _navItem(
                  context,
                  Icons.favorite_outline,
                  Icons.favorite,
                  'Favorites',
                  '/store/favorites',
                  location,
                ),
                _navItem(
                  context,
                  Icons.person_outline,
                  Icons.person,
                  'Profile',
                  '/store/profile',
                  location,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    IconData activeIcon,
    String label,
    String path,
    String current,
  ) {
    final isActive =
        current == path || (path != '/store' && current.startsWith(path));
    final isHome = path == '/store' && current == '/store';
    final active = isActive || isHome;

    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 24,
              color: active ? AppColors.primary600 : AppColors.gray400,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AppColors.primary600 : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
