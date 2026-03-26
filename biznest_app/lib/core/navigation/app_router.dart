import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:biznest_core/biznest_core.dart';
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
import '../../features/business/screens/profile_hub_screen.dart';

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
    '/profile',
    '/settings',
    '/support',
    '/onboarding',
  ];

  return businessPaths.any(
    (path) => location == path || location.startsWith('$path/'),
  );
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
        if (auth.isCustomer) return isLoginRoute ? null : '/login';
        return '/dashboard';
      }
      if (isAuth) {
        final auth = authState;
        final isBusinessRoute = _isBusinessRoute(location);

        if (auth.isCustomer && isBusinessRoute) {
          return '/login';
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
            path: '/profile',
            builder: (context, state) => const ProfileHubScreen(),
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
