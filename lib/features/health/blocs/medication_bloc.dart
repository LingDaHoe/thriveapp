import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';

// Events
abstract class MedicationEvent extends Equatable {
  const MedicationEvent();

  @override
  List<Object?> get props => [];
}

class LoadMedications extends MedicationEvent {}

class AddMedication extends MedicationEvent {
  final Medication medication;

  const AddMedication(this.medication);

  @override
  List<Object?> get props => [medication];
}

class UpdateMedication extends MedicationEvent {
  final Medication medication;

  const UpdateMedication(this.medication);

  @override
  List<Object?> get props => [medication];
}

class DeleteMedication extends MedicationEvent {
  final String id;

  const DeleteMedication(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkMedicationAsTaken extends MedicationEvent {
  final String medicationId;
  final DateTime takenAt;

  const MarkMedicationAsTaken(this.medicationId, this.takenAt);

  @override
  List<Object?> get props => [medicationId, takenAt];
}

// States
abstract class MedicationState extends Equatable {
  const MedicationState();

  @override
  List<Object?> get props => [];
}

class MedicationInitial extends MedicationState {}

class MedicationLoading extends MedicationState {}

class MedicationLoaded extends MedicationState {
  final List<Medication> medications;

  const MedicationLoaded(this.medications);

  @override
  List<Object?> get props => [medications];
}

class MedicationError extends MedicationState {
  final String message;

  const MedicationError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final MedicationService _medicationService;

  MedicationBloc({
    required MedicationService medicationService,
  })  : _medicationService = medicationService,
        super(MedicationInitial()) {
    on<LoadMedications>(_onLoadMedications);
    on<AddMedication>(_onAddMedication);
    on<UpdateMedication>(_onUpdateMedication);
    on<DeleteMedication>(_onDeleteMedication);
    on<MarkMedicationAsTaken>(_onMarkMedicationAsTaken);
  }

  void _onLoadMedications(LoadMedications event, Emitter<MedicationState> emit) async {
    emit(MedicationLoading());
    try {
      await emit.forEach<List<Medication>>(
        _medicationService.getMedications(),
        onData: (medications) => MedicationLoaded(medications),
        onError: (error, stackTrace) => MedicationError(error.toString()),
      );
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onAddMedication(
    AddMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationService.addMedication(event.medication);
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onUpdateMedication(
    UpdateMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationService.updateMedication(event.medication);
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onDeleteMedication(
    DeleteMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationService.deleteMedication(event.id);
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onMarkMedicationAsTaken(
    MarkMedicationAsTaken event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationService.markMedicationAsTaken(
        event.medicationId,
        event.takenAt,
      );
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }
} 