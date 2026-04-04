import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';
import 'package:medi_chain_mobile/data/repositories/medical_repository.dart';

// Events
abstract class ProfileEvent {}

class ProfileFetchRequested extends ProfileEvent {}

class ProfileUpdateRequested extends ProfileEvent {
  final ProfileModel profile;
  ProfileUpdateRequested(this.profile);
}

// States
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileModel profile;
  ProfileLoaded(this.profile);
}

class ProfileUpdateSuccess extends ProfileState {
  final ProfileModel profile;
  ProfileUpdateSuccess(this.profile);
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final MedicalRepository _repository;

  ProfileBloc(this._repository) : super(ProfileInitial()) {
    on<ProfileFetchRequested>(_onFetchRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
  }

  Future<void> _onFetchRequested(
    ProfileFetchRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final response = await _repository.getProfile();

    if (response.success && response.data != null) {
      emit(ProfileLoaded(response.data!));
    } else {
      emit(ProfileError(response.message ?? 'Lỗi tải hồ sơ'));
    }
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final success = await _repository.updateProfile(event.profile);
    if (success) {
      emit(ProfileUpdateSuccess(event.profile));
      add(ProfileFetchRequested());
    } else {
      emit(ProfileError('Lỗi cập nhật hồ sơ'));
    }
  }
}
