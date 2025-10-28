import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_service.dart';

// Events
abstract class EmergencyEvent extends Equatable {
  const EmergencyEvent();

  @override
  List<Object?> get props => [];
}

class LoadEmergencyContacts extends EmergencyEvent {}

class AddEmergencyContact extends EmergencyEvent {
  final EmergencyContact contact;

  const AddEmergencyContact(this.contact);

  @override
  List<Object?> get props => [contact];
}

class UpdateEmergencyContact extends EmergencyEvent {
  final EmergencyContact contact;

  const UpdateEmergencyContact(this.contact);

  @override
  List<Object?> get props => [contact];
}

class DeleteEmergencyContact extends EmergencyEvent {
  final String id;

  const DeleteEmergencyContact(this.id);

  @override
  List<Object?> get props => [id];
}

class TriggerSOS extends EmergencyEvent {
  final String description;

  const TriggerSOS(this.description);

  @override
  List<Object?> get props => [description];
}

class CancelSOS extends EmergencyEvent {}

// States
abstract class EmergencyState extends Equatable {
  const EmergencyState();

  @override
  List<Object?> get props => [];
}

class EmergencyInitial extends EmergencyState {}

class EmergencyLoading extends EmergencyState {}

class EmergencyLoaded extends EmergencyState {
  final List<EmergencyContact> contacts;
  final bool isSOSActive;
  final int? remainingSeconds;

  const EmergencyLoaded({
    required this.contacts,
    this.isSOSActive = false,
    this.remainingSeconds,
  });

  @override
  List<Object?> get props => [contacts, isSOSActive, remainingSeconds];
}

class EmergencyError extends EmergencyState {
  final String message;

  const EmergencyError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class EmergencyBloc extends Bloc<EmergencyEvent, EmergencyState> {
  final EmergencyService _emergencyService;

  EmergencyBloc({
    required EmergencyService emergencyService,
  })  : _emergencyService = emergencyService,
        super(EmergencyInitial()) {
    on<LoadEmergencyContacts>(_onLoadEmergencyContacts);
    on<AddEmergencyContact>(_onAddEmergencyContact);
    on<UpdateEmergencyContact>(_onUpdateEmergencyContact);
    on<DeleteEmergencyContact>(_onDeleteEmergencyContact);
    on<TriggerSOS>(_onTriggerSOS);
    on<CancelSOS>(_onCancelSOS);
  }

  Future<void> _onLoadEmergencyContacts(
    LoadEmergencyContacts event,
    Emitter<EmergencyState> emit,
  ) async {
    emit(EmergencyLoading());
    try {
      final contacts = await _emergencyService.getEmergencyContacts().first;
      emit(EmergencyLoaded(contacts: contacts));
    } catch (e) {
      emit(EmergencyError(e.toString()));
    }
  }

  Future<void> _onAddEmergencyContact(
    AddEmergencyContact event,
    Emitter<EmergencyState> emit,
  ) async {
    try {
      await _emergencyService.addEmergencyContact(event.contact);
      // Reload contacts after adding
      final contacts = await _emergencyService.getEmergencyContacts().first;
      emit(EmergencyLoaded(contacts: contacts));
    } catch (e) {
      emit(EmergencyError(e.toString()));
    }
  }

  Future<void> _onUpdateEmergencyContact(
    UpdateEmergencyContact event,
    Emitter<EmergencyState> emit,
  ) async {
    try {
      await _emergencyService.updateEmergencyContact(event.contact);
      // Reload contacts after updating
      final contacts = await _emergencyService.getEmergencyContacts().first;
      emit(EmergencyLoaded(contacts: contacts));
    } catch (e) {
      emit(EmergencyError(e.toString()));
    }
  }

  Future<void> _onDeleteEmergencyContact(
    DeleteEmergencyContact event,
    Emitter<EmergencyState> emit,
  ) async {
    try {
      await _emergencyService.deleteEmergencyContact(event.id);
      // Reload contacts after deleting
      final contacts = await _emergencyService.getEmergencyContacts().first;
      emit(EmergencyLoaded(contacts: contacts));
    } catch (e) {
      emit(EmergencyError(e.toString()));
    }
  }

  Future<void> _onTriggerSOS(
    TriggerSOS event,
    Emitter<EmergencyState> emit,
  ) async {
    try {
      final state = this.state;
      if (state is EmergencyLoaded) {
        // Get location first
        final location = await _emergencyService.getCurrentLocation();

        // Countdown from 5 to 1
        for (int i = 5; i > 0; i--) {
          // Check if cancelled
          if (this.state is! EmergencyLoaded || !(this.state as EmergencyLoaded).isSOSActive) {
            return; // SOS was cancelled
          }
          
          emit(EmergencyLoaded(
            contacts: state.contacts,
            isSOSActive: true,
            remainingSeconds: i,
          ));
          
          // Wait 1 second before next tick
          await Future.delayed(const Duration(seconds: 1));
        }

        // Check one more time if we're still in the same state
        if (this.state is! EmergencyLoaded || !(this.state as EmergencyLoaded).isSOSActive) {
          return; // SOS was cancelled
        }

        try {
          // Notify contacts
          await _emergencyService.notifyEmergencyContacts(
            state.contacts,
            location,
          );

          // Log the event
          await _emergencyService.logEmergencyEvent(
            type: 'SOS',
            description: event.description,
            location: location,
            notifiedContacts: state.contacts.map((c) => c.id).toList(),
          );

          // Update state
          emit(EmergencyLoaded(
            contacts: state.contacts,
            isSOSActive: false,
          ));
        } catch (e) {
          emit(EmergencyError('Failed to send emergency notifications: $e'));
        }
      }
    } catch (e) {
      emit(EmergencyError('Failed to trigger SOS: $e'));
    }
  }

  Future<void> _onCancelSOS(
    CancelSOS event,
    Emitter<EmergencyState> emit,
  ) async {
    final state = this.state;
    if (state is EmergencyLoaded) {
      emit(EmergencyLoaded(
        contacts: state.contacts,
        isSOSActive: false,
      ));
    }
  }
} 