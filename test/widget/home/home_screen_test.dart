import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thriveapp/features/home/screens/home_screen.dart';
import 'package:thriveapp/features/home/home_bloc.dart';
import 'package:thriveapp/features/home/services/home_service.dart';

@GenerateMocks([HomeService])
import 'home_screen_test.mocks.dart';

void main() {
  late MockHomeService mockHomeService;
  late HomeBloc homeBloc;

  setUp(() {
    mockHomeService = MockHomeService();
    homeBloc = HomeBloc(mockHomeService);
  });

  tearDown(() {
    homeBloc.close();
  });

  Widget createHomeScreen() {
    return MaterialApp(
      home: BlocProvider.value(
        value: homeBloc,
        child: const HomeScreen(),
      ),
    );
  }

  testWidgets('shows loading indicator when state is HomeLoading',
      (WidgetTester tester) async {
    homeBloc.emit(HomeLoading());

    await tester.pumpWidget(createHomeScreen());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message and retry button when state is HomeError',
      (WidgetTester tester) async {
    homeBloc.emit(HomeError('Test error'));

    await tester.pumpWidget(createHomeScreen());

    expect(find.text('Test error'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows home content when state is HomeLoaded',
      (WidgetTester tester) async {
    final testState = HomeLoaded(
      userName: 'Test User',
      steps: 5000,
      heartRate: 75,
      sleepHours: 7.5,
      recommendations: [
        Recommendation(
          title: 'Test Recommendation',
          description: 'Test Description',
          icon: Icons.favorite,
        ),
      ],
    );

    homeBloc.emit(testState);

    await tester.pumpWidget(createHomeScreen());

    // Verify welcome section
    expect(find.text('Welcome, Test User!'), findsOneWidget);
    expect(find.text('Here\'s your wellness summary for today'), findsOneWidget);

    // Verify activity summary
    expect(find.text('Daily Activity'), findsOneWidget);
    expect(find.text('5000'), findsOneWidget);
    expect(find.text('75'), findsOneWidget);
    expect(find.text('7.5h'), findsOneWidget);

    // Verify quick access section
    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.text('Activities'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Emergency'), findsOneWidget);

    // Verify recommendations section
    expect(find.text('Recommended for You'), findsOneWidget);
    expect(find.text('Test Recommendation'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
  });

  testWidgets('retry button triggers LoadHomeData event',
      (WidgetTester tester) async {
    homeBloc.emit(HomeError('Test error'));

    await tester.pumpWidget(createHomeScreen());

    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(mockHomeService.getHomeData()).called(1);
  });
} 