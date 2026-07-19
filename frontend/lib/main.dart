import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import 'models/profile.dart';
import 'models/inventory_product.dart';
import 'providers/auth_provider.dart';
import 'providers/splash_finished_provider.dart';
import 'providers/router_notifier.dart';
import 'screens/product_form_screen.dart';
import 'screens/inventory_dashboard_screen.dart';
import 'screens/inventory_product_list_screen.dart';
import 'screens/inventory_product_detail_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/category_form_screen.dart';
import 'screens/inventory_transaction_list_screen.dart';
import 'screens/stock_in_form_screen.dart';
import 'screens/stock_out_form_screen.dart';
import 'screens/purchase_request_list_screen.dart';
import 'screens/purchase_request_form_screen.dart';
import 'screens/low_stock_product_list_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/role_screens.dart';
import 'screens/profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/personal_screens.dart';
import 'screens/work_schedule_screen.dart';
import 'screens/leave_request_form.dart';
import 'screens/schedule_request_form.dart';
import 'screens/notification_screen.dart';
import 'screens/manager_dashboard_screen.dart';
import 'screens/staff_list_screen.dart';
import 'screens/staff_detail_screen.dart';
import 'screens/promotion_list_screen.dart';
import 'screens/promotion_detail_screen.dart';
import 'screens/sales_dashboard_screen.dart';
import 'screens/sales_product_list_screen.dart';
import 'screens/sales_product_detail_screen.dart';
import 'screens/sales_problem_products_screen.dart';
import 'screens/sales_problem_product_details_screen.dart';
import 'screens/sales_report_status_screen.dart';
import 'screens/sales_suggestion_detail_screen.dart';
import 'screens/sales_inventory_issue_form.dart';
import 'screens/sales_product_update_form.dart';
import 'widgets/app_scaffold.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  var supabaseAnonKey = const String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  if (supabaseAnonKey.isEmpty) {
    supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
  }

  // Local filesystem fallback (useful for desktop runs like 'flutter run' on Windows)
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        final lines = envFile.readAsLinesSync();
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty || line.startsWith('#')) continue;
          final parts = line.split('=');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join('=').trim();
            if (key == 'SUPABASE_URL') {
              supabaseUrl = value;
            } else if (key == 'SUPABASE_PUBLISHABLE_KEY' ||
                key == 'SUPABASE_ANON_KEY') {
              if (supabaseAnonKey.isEmpty ||
                  key == 'SUPABASE_PUBLISHABLE_KEY') {
                supabaseAnonKey = value;
              }
            }
          }
        }
      }
    } catch (_) {
      // Safe to ignore in production environments where File access is restricted
    }
  }

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw AssertionError(
      'Missing Supabase configuration. Please run the app with '
      '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=... '
      'or ensure a valid .env file exists in the frontend directory.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  runApp(const ProviderScope(child: MyApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier();

  final authSub = ref.listen(authProvider, (previous, next) {
    final sessionChanged =
        previous?.session?.accessToken != next.session?.accessToken;
    final userChanged = previous?.user?.id != next.user?.id;
    final roleChanged =
        previous?.profile?.roleNumber != next.profile?.roleNumber;
    final initChanged = previous?.isInitialized != next.isInitialized;

    if (sessionChanged || userChanged || roleChanged || initChanged) {
      routerNotifier.notify();
    }
  });
  final splashSub = ref.listen(splashFinishedProvider, (previous, next) {
    routerNotifier.notify();
  });

  ref.onDispose(() {
    authSub.close();
    splashSub.close();
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final splashFinished = ref.read(splashFinishedProvider);

      final isSplashRoute = state.uri.path == '/splash';
      final isLoginRoute = state.uri.path == '/login';
      final isRegisterRoute = state.uri.path == '/register';

      // 1. If splash is not finished or auth is not initialized, stay on splash
      if (!splashFinished || !auth.isInitialized) {
        return isSplashRoute ? null : '/splash';
      }

      // 2. If initialized but not logged in:
      if (auth.session == null) {
        if (isLoginRoute || isRegisterRoute) {
          return null;
        }
        return '/login';
      }

      // 3. If logged in but profile is null:
      if (auth.profile?.roleNumber == null) {
        // Wait on splash while profile is loading
        return isSplashRoute ? null : '/splash';
      }

      // 4. If logged in and profile loaded:
      final role = auth.profile!.roleNumber;
      const landingPage = '/dashboard';

      // Redirect if on a public/splash route
      if (isSplashRoute || isLoginRoute || isRegisterRoute) {
        return landingPage;
      }

      // Root path redirect
      if (state.uri.path == '/') {
        return landingPage;
      }

      final path = state.uri.path;

      // Routes shared by all authenticated roles
      if (path == '/dashboard' ||
          path == '/profile' ||
          path == '/work-schedule' ||
          path == '/leave-request' ||
          path == '/schedule-change' ||
          path == '/manage-requests' ||
          path == '/notifications' ||
          path == '/change-password') {
        return null;
      }

      // Protect routes based on role:
      if (role == UserRoles.admin && !path.startsWith('/admin')) {
        return '/admin';
      }
      if (role == UserRoles.manager && !path.startsWith('/manager')) {
        return '/manager';
      }
      if (role == UserRoles.salesAssociate && !path.startsWith('/sales')) {
        return '/sales';
      }
      if (role == UserRoles.cashier && !path.startsWith('/cashier')) {
        return '/cashier';
      }
      if (role == UserRoles.stockController) {
        if (path.startsWith('/admin') ||
            path.startsWith('/manager') ||
            path.startsWith('/sales') ||
            path.startsWith('/cashier')) {
          return '/stock';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(body: child);
        },
        routes: [
          GoRoute(
            path: '/manager',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ManagerDashboardScreen()),
          ),
          GoRoute(
            path: '/manager/staff',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StaffListScreen()),
          ),
          GoRoute(
            path: '/manager/staff/:userId',
            pageBuilder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return NoTransitionPage(
                child: StaffDetailScreen(userId: userId),
              );
            },
          ),
          GoRoute(
            path: '/manager/promotion',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PromotionListScreen()),
          ),
          GoRoute(
            path: '/manager/promotion/:promotionNumber',
            pageBuilder: (context, state) {
              final promotionNumberStr = state.pathParameters['promotionNumber']!;
              final promotionNumber = int.tryParse(promotionNumberStr) ?? 0;
              return NoTransitionPage(
                child: PromotionDetailScreen(promotionNumber: promotionNumber),
              );
            },
          ),
        ],
      ),
      // Sales Associate workspace (inside AppScaffold shell)
      ShellRoute(
        builder: (context, state, child) => AppScaffold(body: child),
        routes: [
          GoRoute(
            path: '/sales',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SalesDashboardScreen()),
          ),
          GoRoute(
            path: '/sales/products',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SalesProductListScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: SalesProductDetailScreen(
                    productNumber:
                        int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/sales/problems',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SalesProblemProductsScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: SalesProblemProductDetailsScreen(
                    reportNumber:
                        int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/sales/reports',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SalesReportStatusScreen()),
            routes: [
              GoRoute(
                path: 'suggestions/:id',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: SalesSuggestionDetailScreen(
                    reportNumber:
                        int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/sales/report-issue',
            pageBuilder: (context, state) => NoTransitionPage(
              child: SalesInventoryIssueForm(
                prefilledProductNumber: int.tryParse(
                    state.uri.queryParameters['productNumber'] ?? ''),
              ),
            ),
          ),
          GoRoute(
            path: '/sales/suggest-update',
            pageBuilder: (context, state) => NoTransitionPage(
              child: SalesProductUpdateForm(
                prefilledProductNumber: int.tryParse(
                    state.uri.queryParameters['productNumber'] ?? ''),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/cashier',
        builder: (context, state) => const CashierScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(body: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
          GoRoute(
            path: '/work-schedule',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WorkScheduleScreen()),
          ),
          GoRoute(
            path: '/leave-request',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LeaveRequestForm()),
          ),
          GoRoute(
            path: '/schedule-change',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ScheduleRequestForm()),
          ),
          GoRoute(
            path: '/manage-requests',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ManageRequestStatusScreen()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotificationScreen()),
          ),
          GoRoute(
            path: '/stock',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: InventoryDashboardScreen()),
            routes: [
              GoRoute(
                path: 'profile',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
              GoRoute(
                path: 'categories',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CategoryListScreen()),
                routes: [
                  GoRoute(
                    path: 'add',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: CategoryFormScreen()),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    pageBuilder: (context, state) {
                      final idStr = state.pathParameters['id'] ?? '';
                      final id = int.tryParse(idStr);
                      return NoTransitionPage(
                        child: CategoryFormScreen(categoryNumber: id),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'products',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: InventoryProductListScreen()),
                routes: [
                  GoRoute(
                    path: 'add',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: ProductFormScreen()),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    pageBuilder: (context, state) {
                      final idStr = state.pathParameters['id'] ?? '';
                      final id = int.tryParse(idStr) ?? 0;
                      final product = state.extra as InventoryProduct?;
                      return NoTransitionPage(
                        child: ProductFormScreen(
                          productId: id,
                          product: product,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    pageBuilder: (context, state) {
                      final idStr = state.pathParameters['id'] ?? '';
                      final id = int.tryParse(idStr) ?? 0;
                      return NoTransitionPage(
                        child: InventoryProductDetailScreen(productNumber: id),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'transactions',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: InventoryTransactionListScreen()),
                routes: [
                  GoRoute(
                    path: 'record-stock-in/:prNumber',
                    pageBuilder: (context, state) {
                      final prNumberStr = state.pathParameters['prNumber'] ?? '';
                      final prNumber = int.tryParse(prNumberStr) ?? 0;
                      final supplierNumberStr = state.uri.queryParameters['supplierNumber'];
                      final supplierNumber = supplierNumberStr != null ? int.tryParse(supplierNumberStr) : null;
                      return NoTransitionPage(
                        child: StockInFormScreen(
                          purchaseRequestNumber: prNumber,
                          supplierNumber: supplierNumber,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'record-stock-out/:reportNumber',
                    pageBuilder: (context, state) {
                      final reportNumberStr = state.pathParameters['reportNumber'] ?? '';
                      final reportNumber = int.tryParse(reportNumberStr) ?? 0;
                      return NoTransitionPage(
                        child: StockOutFormScreen(reportNumber: reportNumber),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'purchase-requests',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: PurchaseRequestListScreen()),
                routes: [
                  GoRoute(
                    path: 'create',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: PurchaseRequestFormScreen()),
                  ),
                ],
              ),
              GoRoute(
                path: 'low-stock',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: LowStockProductListScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/test-cors',
        builder: (context, state) => const CorsTestHomePage(),
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Supermarket Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}



class CorsTestHomePage extends StatefulWidget {
  const CorsTestHomePage({super.key});

  @override
  State<CorsTestHomePage> createState() => _CorsTestHomePageState();
}

class _CorsTestHomePageState extends State<CorsTestHomePage> {
  String _status = 'Connection not tested yet';
  String _responseDetails = '';
  bool _isLoading = false;
  bool _isSuccess = false;

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  Future<void> _testBackendConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Calling backend API ($apiBaseUrl/test)...';
      _responseDetails = '';
    });

    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/test'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isSuccess = true;
          _status = 'Connection successful! (HTTP 200 OK)';
          _responseDetails = 'Response: ${data["message"]}';
        });
      } else {
        setState(() {
          _isSuccess = false;
          _status = 'Connection error! HTTP Status: ${response.statusCode}';
          _responseDetails = response.body;
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _status = 'API call failed!';
        _responseDetails = 'Error details (possibly CORS or backend not running): $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FE + BE Connection Check (CORS Test)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.swap_horizontal_circle_outlined,
                size: 80,
                color: Colors.teal,
              ),
              const SizedBox(height: 20),
              Text(
                'Supermarket System - CORS Connection Test',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Press the button below to send an HTTP GET request from the Frontend to the Backend at localhost:8080',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testBackendConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_sync),
                label: Text(
                  _isLoading ? 'Sending request...' : 'Test Backend Connection',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('not tested')
                      ? Colors.grey.shade100
                      : (_isSuccess
                            ? Colors.green.shade50
                            : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _status.contains('not tested')
                        ? Colors.grey.shade300
                        : (_isSuccess ? Colors.green : Colors.red),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _status.contains('not tested')
                            ? Colors.black87
                            : (_isSuccess
                                  ? Colors.green.shade800
                                  : Colors.red.shade800),
                      ),
                    ),
                    if (_responseDetails.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _responseDetails,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
