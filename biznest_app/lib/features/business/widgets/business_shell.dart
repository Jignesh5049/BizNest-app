import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biznest_core/biznest_core.dart';
import '../screens/dashboard_screen.dart';
import '../screens/products_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/customers_screen.dart';
import 'business_refresh_registry.dart';
import 'sidebar.dart';

class BusinessShell extends StatefulWidget {
  final Widget child;

  const BusinessShell({super.key, required this.child});

  @override
  State<BusinessShell> createState() => _BusinessShellState();
}

class _BusinessShellState extends State<BusinessShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PageController _corePageController;
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
  static const List<String> _pullToRefreshDisabledRoutes = [
    '/profile',
    '/settings',
    '/learn',
    '/pricing',
    '/invoices',
  ];

  EdgeInsets _contentPadding(double width, bool isDesktop) {
    if (isDesktop) return const EdgeInsets.all(20);
    if (width < 360) {
      return const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
    }
    return const EdgeInsets.symmetric(horizontal: 10, vertical: 8);
  }

  @override
  void initState() {
    super.initState();
    _corePageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _corePageController.dispose();
    super.dispose();
  }

  int _coreIndexFromLocation(String location) {
    final index = _coreRoutes.indexWhere(
      (route) => location == route || location.startsWith('$route/'),
    );
    return index < 0 ? 0 : index;
  }

  void _syncCorePageIfNeeded(int coreIndex) {
    if (!_corePageController.hasClients) return;
    final currentPage = (_corePageController.page ?? coreIndex.toDouble())
        .round();
    if (currentPage == coreIndex) return;
    _corePageController.jumpToPage(coreIndex);
  }

  Widget _coreSwipePage(double width, bool isDesktop, String location) {
    final coreIndex = _coreIndexFromLocation(location);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCorePageIfNeeded(coreIndex);
    });

    final pages = <Widget>[
      const DashboardScreen(),
      const ProductsScreen(),
      const OrdersScreen(),
      const CustomersScreen(),
    ];

    return PageView.builder(
      controller: _corePageController,
      itemCount: pages.length,
      onPageChanged: (index) {
        final targetPath = _coreRoutes[index];
        if (targetPath != location) {
          context.go(targetPath);
        }
      },
      itemBuilder: (context, index) {
        final route = _coreRoutes[index];
        return RefreshIndicator(
          onRefresh: () => BusinessRefreshRegistry.refreshFor(route),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: _contentPadding(width, isDesktop),
            child: pages[index],
          ),
        );
      },
    );
  }

  Widget _regularPage(double width, bool isDesktop) {
    final location = GoRouterState.of(context).matchedLocation;
    if (_matchesAnyRoute(location, _pullToRefreshDisabledRoutes)) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _contentPadding(width, isDesktop),
        child: widget.child,
      );
    }

    return RefreshIndicator(
      onRefresh: () => BusinessRefreshRegistry.refreshFor(location),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _contentPadding(width, isDesktop),
        child: widget.child,
      ),
    );
  }

  Widget _bodyContent(
    double width,
    bool isDesktop,
    bool showBottomNav,
    String location,
  ) {
    if (showBottomNav) {
      return _coreSwipePage(width, isDesktop, location);
    }
    return _regularPage(width, isDesktop);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final routerState = GoRouterState.of(context);
    final location = routerState.matchedLocation;
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
                  child: _bodyContent(
                    width,
                    isDesktop,
                    showBottomNav,
                    location,
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
