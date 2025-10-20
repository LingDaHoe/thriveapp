import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:thriveapp/features/home/home_bloc.dart';
import 'package:thriveapp/features/home/services/home_service.dart';

@GenerateMocks([HomeService])
import 'home_bloc_test.mocks.dart';

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

  test('initial state is HomeInitial', () {
    expect(homeBloc.state, isA<HomeInitial>());
  });

  group('LoadHomeData', () {
    final testHomeData = HomeData(
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

    test('emits [HomeLoading, HomeLoaded] when data is loaded successfully', () async {
      when(mockHomeService.getHomeData()).thenAnswer((_) async => testHomeData);

      final expectedStates = [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having(
          (state) => state.userName,
          'userName',
          testHomeData.userName,
        ),
      ];

      expectLater(homeBloc.stream, emitsInOrder(expectedStates));

      homeBloc.add(LoadHomeData());
    });

    test('emits [HomeLoading, HomeError] when data loading fails', () async {
      when(mockHomeService.getHomeData()).thenThrow(Exception('Test error'));

      final expectedStates = [
        isA<HomeLoading>(),
        isA<HomeError>().having(
          (state) => state.message,
          'message',
          'Exception: Test error',
        ),
      ];

      expectLater(homeBloc.stream, emitsInOrder(expectedStates));

      homeBloc.add(LoadHomeData());
    });
  });
} 