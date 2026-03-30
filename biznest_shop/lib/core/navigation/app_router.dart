import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:biznest_core/biznest_core.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/customer/widgets/customer_shell.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import '../../features/customer/screens/all_businesses_screen.dart';
import '../../features/customer/screens/business_store_screen.dart';
import '../../features/customer/screens/product_detail_screen.dart';
import '../../features/customer/screens/cart_screen.dart';
import '../../features/customer/screens/checkout_screen.dart';
import '../../features/customer/screens/customer_orders_screen.dart';
import '../../features/customer/screens/order_detail_screen.dart';
import '../../features/customer/screens/favorites_screen.dart';
import '../../features/customer/screens/customer_profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _buildTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 0.92, end: 1).animate(curve),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

bool _isCustomerRoute(String location) {
  return location == '/store' || location.startsWith('/store/');
}

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuth = authState is AuthAuthenticated;
      final location = state.matchedLocation;
      final isLoginRoute = location == '/login';
      final isSignupRoute = location == '/signup';
      final isAuthRoute = isLoginRoute || isSignupRoute;

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) {
        final auth = authState;
        if (auth.isCustomer) return '/store';
        return isLoginRoute ? null : '/login';
      }

      if (isAuth) {
        final auth = authState;
        final isStoreRoute = _isCustomerRoute(location);
        if (!auth.isCustomer && isStoreRoute) {
          return '/login';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _buildTransitionPage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) =>
            _buildTransitionPage(state: state, child: const SignupScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: '/store',
            builder: (context, state) => const CustomerHomeScreen(),
          ),
          GoRoute(
            path: '/store/businesses',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const AllBusinessesScreen(),
            ),
          ),
          GoRoute(
            path: '/store/business/:id',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: BusinessStoreScreen(
                businessId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/store/product/:id',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: ProductDetailScreen(
                productId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/store/cart',
            pageBuilder: (context, state) =>
                _buildTransitionPage(state: state, child: const CartScreen()),
          ),
          GoRoute(
            path: '/store/checkout',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const CheckoutScreen(),
            ),
          ),
          GoRoute(
            path: '/store/orders',
            builder: (context, state) => const CustomerOrdersScreen(),
          ),
          GoRoute(
            path: '/store/orders/:id',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: OrderDetailScreen(orderId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/store/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/store/profile',
            builder: (context, state) => const CustomerProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
