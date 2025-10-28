import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'auth_notifier.dart';
// Auth
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
// Splash & Consent
import '../features/splash/screens/splash_screen.dart';
import '../features/consent/screens/consent_screen.dart';
// Profile
import '../features/profile/screens/profile_creation_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/progress_screen.dart';
// Home & Dashboard
import '../features/home/screens/home_screen.dart';
// Activities
import '../features/activities/screens/activities_screen.dart';
import '../features/activities/screens/achievements_screen.dart';
import '../features/activities/screens/memory_game_screen.dart';
import '../features/activities/screens/word_puzzle_screen.dart';
import '../features/activities/blocs/memory_game_bloc.dart';
import '../features/activities/services/activity_service.dart';
// Emergency
import '../features/emergency/bloc/emergency_bloc.dart';
import '../features/emergency/screens/emergency_screen.dart';
// AI
import '../features/ai/screens/ai_chat_screen.dart';
import '../features/ai/bloc/ai_chat_bloc.dart';
// Health
import '../features/health/screens/medications_screen.dart';
import '../features/health/blocs/medication_bloc.dart';
import '../features/health/screens/health_education_screen.dart';
import '../features/health/screens/health_content_screen.dart';
import '../features/health/screens/learning_progress_screen.dart';
import '../features/health/screens/health_monitoring_screen.dart';
import '../features/health/screens/health_report_screen.dart';
import '../features/health/screens/self_reported_metrics_screen.dart';
import '../features/health/screens/ai_recommendations_screen.dart';
// Admin
import '../features/admin/screens/admin_login_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/user_detail_screen.dart';
import '../features/admin/services/admin_service.dart';

class AppRouter {
  static GoRouter router(AuthNotifier authNotifier) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authNotifier,
      redirect: (context, state) async {
        final isAuthenticated = authNotifier.isAuthenticated;
        final isAuthRoute = ['/login', '/signup', '/forgot-password'].contains(state.matchedLocation);
        final isSplashRoute = state.matchedLocation == '/splash';
        final isAdminRoute = state.matchedLocation.startsWith('/admin');
        
        // Check if user is admin (from SharedPreferences)
        final isAdmin = await AdminService.isAdminSession();

        // Handle splash screen
        if (isSplashRoute) {
          if (!isAuthenticated) {
            return '/login';
          }
          // Authenticated user on splash - redirect based on role
          return isAdmin ? '/admin/dashboard' : '/home';
        }

        // Handle regular auth routes (not admin login)
        if (isAuthRoute) {
          if (isAuthenticated) {
            // Already authenticated, redirect to appropriate dashboard
            return isAdmin ? '/admin/dashboard' : '/home';
          }
          return null; // Stay on auth page
        }

        // Handle admin routes
        if (isAdminRoute) {
          // Admin routes handle their own authentication
          // Let them through without redirect
          return null;
        }

        // Handle regular protected routes
        if (!isAuthenticated) {
          return '/login';
        }

        // If admin user tries to access regular user routes, redirect to admin dashboard
        if (isAdmin && !isAdminRoute) {
          return '/admin/dashboard';
        }

        return null;
      },
      routes: [
        // Splash
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        // Auth
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        // Consent
        GoRoute(
          path: '/consent',
          builder: (context, state) => const ConsentScreen(),
        ),
        // Profile Creation
        GoRoute(
          path: '/profile/create',
          builder: (context, state) => const ProfileCreationScreen(),
        ),
        // Profile
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const ProgressScreen(),
        ),
        // Home
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        // Activities
        GoRoute(
          path: '/activities',
          builder: (context, state) => const ActivitiesScreen(),
        ),
        GoRoute(
          path: '/achievements',
          builder: (context, state) => const AchievementsScreen(),
        ),
        GoRoute(
          path: '/activities/:id/memory-game',
          builder: (context, state) => BlocProvider(
            create: (context) => MemoryGameBloc(
              context.read<ActivityService>(),
            ),
            child: MemoryGameScreen(
              activityId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/activities/:id/word-puzzle',
          builder: (context, state) => WordPuzzleScreen(
            activityId: state.pathParameters['id']!,
          ),
        ),
        // Emergency
        GoRoute(
          path: '/emergency',
          builder: (context, state) => BlocProvider.value(
            value: context.read<EmergencyBloc>(),
            child: const EmergencyScreen(),
          ),
        ),
        // AI Chat
        GoRoute(
          path: '/ai/chat',
          builder: (context, state) => BlocProvider.value(
            value: context.read<AIChatBloc>(),
            child: const AIChatScreen(),
          ),
        ),
        // Health
        GoRoute(
          path: '/health/medications',
          builder: (context, state) => BlocProvider.value(
            value: context.read<MedicationBloc>(),
            child: const MedicationsScreen(),
          ),
        ),
        GoRoute(
          path: '/health',
          builder: (context, state) => const HealthEducationScreen(),
        ),
        GoRoute(
          path: '/health/:id',
          builder: (context, state) => HealthContentScreen(
            contentId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/health/progress',
          builder: (context, state) => const LearningProgressScreen(),
        ),
        GoRoute(
          path: '/health/monitoring',
          builder: (context, state) => const HealthMonitoringScreen(),
        ),
        GoRoute(
          path: '/health/reports',
          builder: (context, state) => const HealthReportScreen(),
        ),
        GoRoute(
          path: '/health/recommendations',
          builder: (context, state) => const AIRecommendationsScreen(),
        ),
        GoRoute(
          path: '/health/metrics',
          builder: (context, state) => const SelfReportedMetricsScreen(),
        ),
        // Admin Routes
        GoRoute(
          path: '/admin/login',
          builder: (context, state) => const AdminLoginScreen(),
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/user/:userId',
          builder: (context, state) => UserDetailScreen(
            userId: state.pathParameters['userId']!,
          ),
        ),
        GoRoute(
          path: '/admin/user/:userId/health',
          builder: (context, state) => UserDetailScreen(
            userId: state.pathParameters['userId']!,
          ),
        ),
        GoRoute(
          path: '/admin/user/:userId/medications',
          builder: (context, state) => UserDetailScreen(
            userId: state.pathParameters['userId']!,
          ),
        ),
      ],
    );
  }
}