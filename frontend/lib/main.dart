import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/manage_role_screen.dart';
import 'package:frontend/screens/schedule_shift_screen.dart';
import 'package:frontend/screens/promotion_list_screen.dart';
import 'package:frontend/screens/promotion_detail_screen.dart';
import 'package:frontend/screens/new_promotion_screen.dart';
import 'package:http/http.dart' as http;

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/profile/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id'];
        final id = int.tryParse(idStr ?? '') ?? 0;
        return ProfileScreen(employeeId: id);
      },
    ),
    GoRoute(
      path: '/role/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id'];
        final id = int.tryParse(idStr ?? '') ?? 0;
        return ManageRoleScreen(employeeId: id);
      },
    ),
    GoRoute(
      path: '/schedule/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id'];
        final id = int.tryParse(idStr ?? '') ?? 0;
        return ScheduleShiftScreen(employeeId: id);
      },
    ),
    GoRoute(
      path: '/cors-test',
      builder: (context, state) => const CorsTestHomePage(),
    ),
    GoRoute(
      path: '/promotions',
      builder: (context, state) => const PromotionListScreen(),
    ),
    GoRoute(
      path: '/promotions/new',
      builder: (context, state) => const NewPromotionScreen(promotionId: null),
    ),
    GoRoute(
      path: '/promotions/edit/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id'];
        final id = int.tryParse(idStr ?? '') ?? 0;
        return NewPromotionScreen(promotionId: id);
      },
    ),
    GoRoute(
      path: '/promotions/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id'];
        final id = int.tryParse(idStr ?? '') ?? 0;
        return PromotionDetailScreen(promotionId: id);
      },
    ),
  ],
);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Supermarket Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

//CorsTestHomePage
class CorsTestHomePage extends StatefulWidget {
  const CorsTestHomePage({super.key});

  @override
  State<CorsTestHomePage> createState() => _CorsTestHomePageState();
}

class _CorsTestHomePageState extends State<CorsTestHomePage> {
  String _status = 'Chưa kiểm tra kết nối';
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
      _status = 'Đang gọi API backend ($apiBaseUrl/test)...';
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
          _status = 'Kết nối thành công! (HTTP 200 OK)';
          _responseDetails = 'Response: ${data["message"]}';
        });
      } else {
        setState(() {
          _isSuccess = false;
          _status = 'Lỗi kết nối! HTTP Status: ${response.statusCode}';
          _responseDetails = response.body;
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _status = 'Thất bại khi gọi API!';
        _responseDetails = 'Chi tiết lỗi (có thể do CORS hoặc BE chưa bật): $e';
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
        title: const Text('Kiểm tra kết nối FE + BE (CORS Test)'),
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
                'Bấm nút bên dưới để thử gửi request HTTP GET từ Frontend đến Backend localhost:8080',
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
                  _isLoading ? 'Đang gửi request...' : 'Test Kết Nối Backend',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('Chưa')
                      ? Colors.grey.shade100
                      : (_isSuccess
                            ? Colors.green.shade50
                            : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _status.contains('Chưa')
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
                        color: _status.contains('Chưa')
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
