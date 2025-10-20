import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'services/home_service.dart';
import 'models/recommendation.dart';

// Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {}

// States
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String userName;
  final int steps;
  final int heartRate;
  final double sleepHours;
  final List<Recommendation> recommendations;

  const HomeLoaded({
    required this.userName,
    required this.steps,
    required this.heartRate,
    required this.sleepHours,
    required this.recommendations,
  });

  @override
  List<Object?> get props => [userName, steps, heartRate, sleepHours, recommendations];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// Recommendation Model
class Recommendation {
  final String title;
  final String description;
  final IconData icon;

  Recommendation({
    required this.title,
    required this.description,
    required this.icon,
  });
}

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeService _homeService;

  HomeBloc(this._homeService) : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final homeData = await _homeService.getHomeData();
      emit(HomeLoaded(
        userName: homeData.userName,
        steps: homeData.steps,
        heartRate: homeData.heartRate,
        sleepHours: homeData.sleepHours,
        recommendations: homeData.recommendations,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
} 