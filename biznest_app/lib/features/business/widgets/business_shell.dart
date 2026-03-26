import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_core/biznest_core.dart';
import 'sidebar.dart';

class BusinessShell extends StatefulWidget {
  final Widget child;

  const BusinessShell({super.key, required this.child});

  @override
  State<BusinessShell> createState() => _BusinessShellState();
}

class _BusinessShellState extends State<BusinessShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const List<String> _coreRoutes = [
    '/dashboard',
    '/products',
    '/orders',
    '/customers',
  ];
  static const List<String> _drawerOnlyRoutes = [
    '/expenses',
    '/analytics',
    '/pricing',
    '/invoices',
    '/learn',
    '/profile',
    '/settings',
    '/support',
  ];

  EdgeInsets _contentPadding(double width, bool isDesktop) {
    if (isDesktop) return const EdgeInsets.all(20);
    if (width < 360)
      return const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
    return const EdgeInsets.symmetric(horizontal: 10, vertical: 8);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final routerState = GoRouterState.of(context);
    final location = routerState.matchedLocation;
    final fromRoute = routerState.uri.queryParameters['from'];
    final isDrawerScreen = _matchesAnyRoute(location, _drawerOnlyRoutes);
    final showBottomNav = !isDesktop && _matchesAnyRoute(location, _coreRoutes);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.gray50,
      drawer: isDesktop
          ? null
          : Drawer(
              width: 260,
              child: AppSidebar(
                showPrimaryItems: false,
                onClose: () => _scaffoldKey.currentState?.closeDrawer(),
              ),
            ),
      bottomNavigationBar: !showBottomNav
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _bottomNavItem(
                        context: context,
                        path: '/dashboard',
                        label: 'Dashboard',
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        currentLocation: location,
                      ),
                      _bottomNavItem(
                        context: context,
                        path: '/products',
                        label: 'Products',
                        icon: Icons.inventory_2_outlined,
                        activeIcon: Icons.inventory_2,
                        currentLocation: location,
                      ),
                      _bottomNavItem(
                        context: context,
                        path: '/orders',
                        label: 'Orders',
                        icon: Icons.shopping_cart_outlined,
                        activeIcon: Icons.shopping_cart,
                        currentLocation: location,
                      ),
                      _bottomNavItem(
                        context: context,
                        path: '/customers',
                        label: 'Customers',
                        icon: Icons.people_outlined,
                        activeIcon: Icons.people,
                        currentLocation: location,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: AppColors.gray200)),
              ),
              child: const AppSidebar(),
            ),
          Expanded(
            child: Column(
              children: [
                if (!isDesktop)
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.gray200),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: IconButton(
                              onPressed: () {
                                if (isDrawerScreen) {
                                  if (fromRoute != null &&
                                      _matchesAnyRoute(
                                        fromRoute,
                                        _coreRoutes,
                                      )) {
                                    context.go(fromRoute);
                                    return;
                                  }
                                  if (context.canPop()) {
                                    context.pop();
                                    return;
                                  }
                                  context.go('/dashboard');
                                  return;
                                }
                                _scaffoldKey.currentState?.openDrawer();
                              },
                              icon: Icon(
                                isDrawerScreen ? Icons.arrow_back : Icons.menu,
                                size: 24,
                              ),
                              color: AppColors.gray600,
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/images/logo.svg',
                                height: 30,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: location.startsWith('/profile')
                                ? const SizedBox.shrink()
                                : IconButton(
                                    onPressed: () =>
                                        context.go('/profile?from=$location'),
                                    icon: const Icon(
                                      Icons.person_outline,
                                      size: 24,
                                    ),
                                    color: AppColors.gray600,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: _contentPadding(width, isDesktop),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNavItem({
    required BuildContext context,
    required String path,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required String currentLocation,
  }) {
    final isActive = _isTabActive(path, currentLocation);

    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? AppColors.primary600 : AppColors.gray500,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary600 : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isTabActive(String tabPath, String currentLocation) {
    return currentLocation == tabPath ||
        currentLocation.startsWith('$tabPath/');
  }

  bool _matchesAnyRoute(String location, List<String> routes) {
    return routes.any(
      (path) => location == path || location.startsWith('$path/'),
    );
  }
}
