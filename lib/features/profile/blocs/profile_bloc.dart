import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class LoadProfile extends ProfileEvent {}

class SaveProfile extends ProfileEvent {
  final Profile profile;

  const SaveProfile(this.profile);

  @override
  List<Object> get props => [profile];
}

class AddEmergencyContact extends ProfileEvent {
  final EmergencyContact contact;

  const AddEmergencyContact(this.contact);

  @override
  List<Object> get props => [contact];
}

class RemoveEmergencyContact extends ProfileEvent {
  final String phoneNumber;

  const RemoveEmergencyContact(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

class UpdateSettings extends ProfileEvent {
  final ProfileSettings settings;

  const UpdateSettings(this.settings);

  @override
  List<Object> get props => [settings];
}

// States
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Profile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService _profileService;

  ProfileBloc(this._profileService) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<SaveProfile>(_onSaveProfile);
    on<AddEmergencyContact>(_onAddEmergencyContact);
    on<RemoveEmergencyContact>(_onRemoveEmergencyContact);
    on<UpdateSettings>(_onUpdateSettings);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());
      final profile = await _profileService.getProfile();
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onSaveProfile(SaveProfile event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());
      await _profileService.updateProfile(event.profile);
      emit(ProfileLoaded(event.profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onAddEmergencyContact(AddEmergencyContact event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        final updatedContacts = List<EmergencyContact>.from(currentProfile.emergencyContacts)
          ..add(event.contact);
        final updatedProfile = currentProfile.copyWith(emergencyContacts: updatedContacts);
        await _profileService.updateProfile(updatedProfile);
        emit(ProfileLoaded(updatedProfile));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onRemoveEmergencyContact(RemoveEmergencyContact event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        final updatedContacts = currentProfile.emergencyContacts
            .where((contact) => contact.phoneNumber != event.phoneNumber)
            .toList();
        final updatedProfile = currentProfile.copyWith(emergencyContacts: updatedContacts);
        await _profileService.updateProfile(updatedProfile);
        emit(ProfileLoaded(updatedProfile));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateSettings(UpdateSettings event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        final updatedProfile = currentProfile.copyWith(settings: event.settings);
        await _profileService.updateProfile(updatedProfile);
        emit(ProfileLoaded(updatedProfile));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
} 