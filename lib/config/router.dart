import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Auth
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/blocs/auth_bloc.dart';
// Splash & Consent
import '../features/splash/screens/splash_screen.dart';
import '../features/consent/screens/consent_screen.dart';
// Profile
import '../features/profile/screens/profile_creation_screen.dart';
import '../features/profile/screens/profile_screen.dart';
// Home & Dashboard
import '../features/home/screens/home_screen.dart';
// Activities
import '../features/activities/screens/activities_screen.dart';
import '../features/activities/screens/achievements_screen.dart';
import '../features/activities/screens/memory_game_screen.dart';
import '../features/activities/screens/word_puzzle_screen.dart';
import '../features/activities/activity_bloc.dart';
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

class AppRouter {
  static GoRouter get router {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        // Safely access AuthBloc state
        final authState = context.read<AuthBloc>().state;
        final isAuthRoute = ['/login', '/signup', '/forgot-password'].contains(state.matchedLocation);
        final isSplashRoute = state.matchedLocation == '/splash';

        // If on splash screen and authenticated, go to home
        if (isSplashRoute && authState is AuthAuthenticated) {
          return '/home';
        }
        // If on splash screen and not authenticated, go to login
        if (isSplashRoute && authState is! AuthAuthenticated) {
          return '/login';
        }
        // If not authenticated and not on auth page, redirect to login
        if (authState is! AuthAuthenticated && !isAuthRoute) {
          return '/login';
        }
        // If authenticated and on auth page, redirect to home
        if (authState is AuthAuthenticated && isAuthRoute) {
          return '/home';
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
      ],
    );
  }
}