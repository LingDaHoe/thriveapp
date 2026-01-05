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
import '../features/profile/screens/help_support_screens.dart';
// Home & Dashboard
import '../features/home/screens/home_screen.dart';
// Activities
import '../features/activities/screens/activities_screen.dart';
import '../features/activities/screens/achievements_screen.dart';
import '../features/activities/screens/memory_game_screen.dart';
import '../features/activities/screens/word_puzzle_screen.dart';
import '../features/activities/screens/create_social_activity_screen.dart';
import '../features/activities/screens/social_activities_screen.dart';
import '../features/activities/screens/group_chat_screen.dart';
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
import '../features/admin/screens/caregiver_registration_screen.dart';
import '../features/admin/screens/caregiver_dashboard_screen.dart';
import '../features/admin/services/admin_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Utils
import '../utils/create_admin.dart';
import '../utils/create_accounts_screen.dart';

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
        final isAdminLogin = state.matchedLocation == '/admin/login';
        
        // Check if user is admin/caregiver (from SharedPreferences and Firestore)
        final isAdminSession = await AdminService.isAdminSession();
        
        // CRITICAL: Check Firestore FIRST - it's the source of truth
        bool isAdmin = false;
        bool isCaregiver = false;
        if (isAuthenticated) {
          try {
            final adminService = AdminService();
            final adminUser = await adminService.getCurrentAdminUser();
            if (adminUser != null) {
              isAdmin = adminUser.isAdmin;
              isCaregiver = adminUser.isCaretaker;
              print('  → Firestore check: Admin=$isAdmin, Caregiver=$isCaregiver, Role=${adminUser.role}');
              
              // If Firestore says admin/caregiver but SharedPreferences doesn't, update it
              if ((isAdmin || isCaregiver) && !isAdminSession) {
                print('  → Updating SharedPreferences to match Firestore');
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isAdmin', true);
                await prefs.setString('userRole', adminUser.role);
              }
            } else {
              print('  → Firestore check: No admin user found for authenticated user');
              // If SharedPreferences says admin but Firestore doesn't, clear it
              if (isAdminSession) {
                print('  → Clearing stale SharedPreferences admin flag');
                await AdminService.clearAdminSession();
              }
            }
          } catch (e) {
            print('  → Firestore check error: $e');
            // If check fails due to parsing error, try to fix the Firestore document
            // But for now, use SharedPreferences as fallback
            isAdmin = isAdminSession;
            // Don't set isCaregiver from SharedPreferences fallback
          }
        } else {
          isAdmin = isAdminSession;
        }
        
        // Debug logging
        print('🔍 Router Redirect Debug:');
        print('  Location: ${state.matchedLocation}');
        print('  Authenticated: $isAuthenticated');
        print('  Is Admin Session: $isAdminSession');
        print('  Is Admin (Firestore): $isAdmin');
        print('  Is Caregiver: $isCaregiver');
        print('  Is Admin Route: $isAdminRoute');
        print('  Is Admin Login: $isAdminLogin');

        // Handle splash screen
        if (isSplashRoute) {
          if (!isAuthenticated) {
            print('  → Redirect: /login (not authenticated)');
            return '/login';
          }
          // Authenticated user on splash - redirect based on role
          if (isAdmin) {
            print('  → Redirect: /admin/dashboard (authenticated admin)');
            return '/admin/dashboard';
          } else if (isCaregiver) {
            print('  → Redirect: /caregiver/dashboard (authenticated caregiver)');
            return '/caregiver/dashboard';
          } else {
            print('  → Redirect: /home (authenticated user)');
            return '/home';
          }
        }

        // Handle admin login page
        if (isAdminLogin) {
          if (isAuthenticated) {
            if (isAdmin) {
              // Already authenticated as admin, go to admin dashboard
              print('  → Redirect: /admin/dashboard (already logged in as admin)');
              return '/admin/dashboard';
            } else if (isCaregiver) {
              // Already authenticated as caregiver, go to caregiver dashboard
              print('  → Redirect: /caregiver/dashboard (already logged in as caregiver)');
              return '/caregiver/dashboard';
            }
          }
          // Not authenticated or not admin/caregiver, allow access to login page
          print('  → Allow: admin login page');
          return null;
        }

        // Handle regular auth routes (not admin login)
        if (isAuthRoute) {
          if (isAuthenticated) {
            // Already authenticated, redirect to appropriate dashboard
            if (isAdmin) {
              print('  → Redirect: /admin/dashboard (authenticated admin on auth route)');
              return '/admin/dashboard';
            } else if (isCaregiver) {
              print('  → Redirect: /caregiver/dashboard (authenticated caregiver on auth route)');
              return '/caregiver/dashboard';
            } else {
              print('  → Redirect: /home (authenticated user on auth route)');
              return '/home';
            }
          }
          print('  → Allow: auth route');
          return null; // Stay on auth page
        }

        // Handle other admin routes (dashboard, user details, etc)
        if (isAdminRoute && !isAdminLogin) {
          // Admin routes require authentication and admin status
          if (!isAuthenticated) {
            print('  → Redirect: /admin/login (not authenticated)');
            return '/admin/login';
          }
          if (!isAdmin && !isCaregiver) {
            print('  → Redirect: /home (not an admin or caregiver)');
            return '/home'; // Not an admin/caregiver, redirect to regular dashboard
          }
          // Allow access if admin or caregiver
          print('  → Allow: admin route (authenticated ${isAdmin ? "admin" : "caregiver"})');
          return null;
        }
        
        // CRITICAL: Check caregiver registration FIRST before other caregiver routes
        // This allows public access to registration without authentication
        final isCaregiverRegister = state.matchedLocation == '/caregiver/register';
        if (isCaregiverRegister) {
          print('  → Allow: caregiver registration (public route)');
          return null; // Allow access to registration page without authentication
        }
        
        // Handle other caregiver routes (dashboard, etc) - requires authentication
        final isCaregiverRoute = state.matchedLocation.startsWith('/caregiver');
        if (isCaregiverRoute) {
          if (!isAuthenticated) {
            print('  → Redirect: /admin/login (not authenticated for caregiver route)');
            return '/admin/login';
          }
          if (!isCaregiver && !isAdmin) {
            print('  → Redirect: /home (not a caregiver)');
            return '/home';
          }
          print('  → Allow: caregiver route (authenticated ${isCaregiver ? "caregiver" : "admin"})');
          return null;
        }

        // Handle regular protected routes
        if (!isAuthenticated) {
          print('  → Redirect: /login (protected route, not authenticated)');
          return '/login';
        }

        // CRITICAL: If authenticated admin/caregiver tries to access regular user routes, redirect to appropriate dashboard
        // This catches cases where admin logs in but router hasn't redirected yet
        if (isAuthenticated && (isAdmin || isCaregiver) && !isAdminRoute && !isCaregiverRoute) {
          if (isAdmin) {
            print('  → Redirect: /admin/dashboard (admin accessing user route - FORCE REDIRECT)');
            return '/admin/dashboard';
          } else if (isCaregiver) {
            print('  → Redirect: /caregiver/dashboard (caregiver accessing user route - FORCE REDIRECT)');
            return '/caregiver/dashboard';
          }
        }

        // Regular authenticated user accessing regular routes
        print('  → Allow: regular route');
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
        GoRoute(
          path: '/help/faq',
          builder: (context, state) => const FAQScreen(),
        ),
        GoRoute(
          path: '/help/support',
          builder: (context, state) => const ContactSupportScreen(),
        ),
        GoRoute(
          path: '/help/privacy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        GoRoute(
          path: '/help/terms',
          builder: (context, state) => const TermsOfServiceScreen(),
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
          path: '/activities/chat/:chatId',
          builder: (context, state) {
            final chatId = state.pathParameters['chatId']!;
            final activityTitle = state.uri.queryParameters['title'] ?? 'Group Chat';
            final activityId = state.uri.queryParameters['activityId'];
            return GroupChatScreen(
              chatId: chatId,
              activityTitle: activityTitle,
              activityId: activityId,
            );
          },
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
        GoRoute(
          path: '/activities/create-social',
          builder: (context, state) => const CreateSocialActivityScreen(),
        ),
        GoRoute(
          path: '/activities/social',
          builder: (context, state) => const SocialActivitiesScreen(),
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
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            final tab = state.uri.queryParameters['tab'];
            return UserDetailScreen(
              userId: userId,
              initialTab: tab, // Pass tab parameter
            );
          },
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
        // Caregiver Routes
        GoRoute(
          path: '/caregiver/register',
          builder: (context, state) => const CaregiverRegistrationScreen(),
        ),
        GoRoute(
          path: '/caregiver/dashboard',
          builder: (context, state) => const CaregiverDashboardScreen(),
        ),
        GoRoute(
          path: '/caregiver/user/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            final tab = state.uri.queryParameters['tab'];
            return UserDetailScreen(
              userId: userId,
              initialTab: tab,
            );
          },
        ),
        // Utility Routes (for setup/debugging)
        GoRoute(
          path: '/setup/create-admin',
          builder: (context, state) => const CreateAdminUserScreen(),
        ),
        GoRoute(
          path: '/setup/create-accounts',
          builder: (context, state) => const CreateAccountsScreen(),
        ),
      ],
    );
  }
}