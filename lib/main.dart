import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thriveapp/config/router.dart';
import 'package:thriveapp/config/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thriveapp/features/auth/blocs/auth_bloc.dart';
import 'package:thriveapp/features/auth/services/auth_service.dart';
import 'package:thriveapp/features/home/services/home_service.dart';
import 'package:thriveapp/features/activities/services/activity_service.dart';
import 'package:thriveapp/features/activities/activity_bloc.dart';
import 'package:thriveapp/features/health/services/health_content_service.dart';
import 'package:thriveapp/features/health/services/health_monitoring_service.dart';
import 'package:thriveapp/features/health/services/medication_service.dart';
import 'package:thriveapp/features/health/blocs/medication_bloc.dart';
import 'package:thriveapp/features/emergency/bloc/emergency_bloc.dart';
import 'package:thriveapp/features/emergency/services/emergency_service.dart';
import 'package:thriveapp/features/ai/services/ai_service.dart';
import 'package:thriveapp/features/ai/bloc/ai_chat_bloc.dart';
import 'package:thriveapp/config/ai_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ThriveApp());
}

class ThriveApp extends StatelessWidget {
  const ThriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => AuthService(),
        ),
        RepositoryProvider(
          create: (context) => HomeService(),
        ),
        RepositoryProvider(
          create: (context) => ActivityService(),
        ),
        RepositoryProvider(
          create: (context) => HealthContentService(),
        ),
        RepositoryProvider(
          create: (context) => HealthMonitoringService(),
        ),
        RepositoryProvider(
          create: (context) => MedicationService(),
        ),
        RepositoryProvider(
          create: (context) => EmergencyService(),
        ),
        RepositoryProvider(
          create: (context) => AIService(
            apiKey: AIConfig.apiKey,
            apiUrl: AIConfig.apiUrl,
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc()..add(AuthCheckRequested()),
            lazy: false,
          ),
          BlocProvider(
            create: (context) => ActivityBloc(
              context.read<ActivityService>(),
            )..add(LoadActivities()),
          ),
          BlocProvider(
            create: (context) => MedicationBloc(
              medicationService: context.read<MedicationService>(),
            )..add(LoadMedications()),
          ),
          BlocProvider(
            create: (context) => EmergencyBloc(
              emergencyService: context.read<EmergencyService>(),
            )..add(LoadEmergencyContacts()),
          ),
          BlocProvider(
            create: (context) => AIChatBloc(
              aiService: context.read<AIService>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'Thrive',
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
