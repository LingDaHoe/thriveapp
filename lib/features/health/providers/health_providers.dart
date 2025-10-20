import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/health_initialization_service.dart';
import '../services/health_monitoring_service.dart';
import '../services/health_content_service.dart';
import '../services/medication_service.dart';
import '../services/health_report_service.dart';
import '../services/ai_recommendations_service.dart';
import '../services/chat_ai_service.dart';

class HealthProviders extends StatelessWidget {
  final Widget child;

  const HealthProviders({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HealthInitializationService>(
          create: (_) => HealthInitializationService(),
        ),
        Provider<HealthMonitoringService>(
          create: (_) => HealthMonitoringService(),
        ),
        Provider<HealthContentService>(
          create: (_) => HealthContentService(),
        ),
        Provider<MedicationService>(
          create: (_) => MedicationService(),
        ),
        Provider<HealthReportService>(
          create: (_) => HealthReportService(),
        ),
        Provider<AIRecommendationsService>(
          create: (_) => AIRecommendationsService(),
        ),
        Provider<ChatAIService>(
          create: (_) => ChatAIService(),
        ),
      ],
      child: child,
    );
  }
} 