import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/business/widgets/business_shell.dart';
import '../../features/business/screens/dashboard_screen.dart';
import '../../features/business/screens/products_screen.dart';
import '../../features/business/screens/orders_screen.dart';
import '../../features/business/screens/customers_screen.dart';
import '../../features/business/screens/expenses_screen.dart';
import '../../features/business/screens/add_expense_screen.dart';
import '../../features/business/screens/analytics_screen.dart';
import '../../features/business/screens/pricing_screen.dart';
import '../../features/business/screens/invoices_screen.dart';
import '../../features/business/screens/invoice_detail_screen.dart';
import '../../features/business/screens/learn_screen.dart';
import '../../features/business/screens/settings_screen.dart';
import '../../features/business/screens/support_screen.dart';
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

bool _isBusinessRoute(String location) {
  const businessPaths = [
    '/dashboard',
    '/products',
    '/orders',
    '/customers',
    '/expenses',
    '/analytics',
    '/pricing',
    '/invoices',
    '/learn',
    '/settings',
    '/support',
    '/onboarding',
  ];

  return businessPaths.any(
    (path) => location == path || location.startsWith('$path/'),
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
      final isLoginRoute = state.matchedLocation == '/login';
      final isSignupRoute = state.matchedLocation == '/signup';
      final isAuthRoute = isLoginRoute || isSignupRoute;

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) {
        final auth = authState;
        if (auth.isBusinessOwner && !auth.hasOnboarded) return '/onboarding';
        if (auth.isCustomer) return '/store';
        return '/dashboard';
      }
      if (isAuth) {
        final auth = authState;
        final isBusinessRoute = _isBusinessRoute(location);
        final isCustomerRoute = _isCustomerRoute(location);

        if (auth.isCustomer && isBusinessRoute) {
          return '/store';
        }

        if (auth.isBusinessOwner && isCustomerRoute) {
          return '/dashboard';
        }

        if (auth.isBusinessOwner &&
            !auth.hasOnboarded &&
            location != '/onboarding') {
          return '/onboarding';
        }
      }
      if (isAuth && location == '/onboarding') {
        final auth = authState;
        if (auth.hasOnboarded) return '/dashboard';
      }
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Business Owner Shell
      ShellRoute(
        builder: (context, state, child) => BusinessShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpensesScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddExpenseScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/pricing',
            builder: (context, state) => const PricingScreen(),
          ),
          GoRoute(
            path: '/invoices',
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: '/invoices/:id',
            builder: (context, state) =>
                InvoiceDetailScreen(orderId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/learn',
            builder: (context, state) => const LearnScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) => const SupportScreen(),
          ),
        ],
      ),

      // Customer Portal Shell
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: '/store',
            builder: (context, state) => const CustomerHomeScreen(),
          ),
          GoRoute(
            path: '/store/businesses',
            builder: (context, state) => const AllBusinessesScreen(),
          ),
          GoRoute(
            path: '/store/business/:id',
            builder: (context, state) =>
                BusinessStoreScreen(businessId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/store/product/:id',
            builder: (context, state) =>
                ProductDetailScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/store/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/store/checkout',
            builder: (context, state) => const CheckoutScreen(),
          ),
          GoRoute(
            path: '/store/orders',
            builder: (context, state) => const CustomerOrdersScreen(),
          ),
          GoRoute(
            path: '/store/orders/:id',
            builder: (context, state) =>
                OrderDetailScreen(orderId: state.pathParameters['id']!),
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

/// Converts a Stream to a Listenable for GoRouter's refreshListenable
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
