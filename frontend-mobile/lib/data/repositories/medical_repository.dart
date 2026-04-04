import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/data/models/medical_models.dart';

class MedicalRepository {
  final ApiClient _apiClient;

  MedicalRepository(this._apiClient);

  // Records
  Future<MedicalRecordsResponse> getRecords() async {
    try {
      final response = await _apiClient.get('/user/records');
      return MedicalRecordsResponse.fromJson(response.data);
    } catch (e) {
      return MedicalRecordsResponse(success: false, message: 'Lỗi tải hồ sơ');
    }
  }

  Future<bool> createRecord(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/user/records', data: data);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateRecord(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/user/records/$id', data: data);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteRecord(String id) async {
    try {
      final response = await _apiClient.delete('/user/records/$id');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Medicines
  Future<MedicinesResponse> getMedicines() async {
    try {
      final response = await _apiClient.get('/user/medicines');
      return MedicinesResponse.fromJson(response.data);
    } catch (e) {
      return MedicinesResponse(
        success: false,
        message: 'Lỗi tải danh sách thuốc',
      );
    }
  }

  Future<bool> createMedicine(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/user/medicines', data: data);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMedicine(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/user/medicines/$id', data: data);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMedicine(String id) async {
    try {
      final response = await _apiClient.delete('/user/medicines/$id');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Appointments
  Future<AppointmentsResponse> getAppointments() async {
    try {
      final response = await _apiClient.get('/user/appointments');
      return AppointmentsResponse.fromJson(response.data);
    } catch (e) {
      return AppointmentsResponse(success: false, message: 'Lỗi tải lịch hẹn');
    }
  }

  Future<bool> createAppointment(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/user/appointments', data: data);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAppointment(String id) async {
    try {
      final response = await _apiClient.delete('/user/appointments/$id');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Metrics
  Future<MetricsResponse> getMetrics({int? limit}) async {
    try {
      final response = await _apiClient.get(
        '/user/metrics',
        queryParameters: limit != null ? {'limit': limit} : null,
      );
      return MetricsResponse.fromJson(response.data);
    } catch (e) {
      return MetricsResponse(
        success: false,
        message: 'Lỗi tải chỉ số sức khỏe',
      );
    }
  }

  Future<bool> createMetric(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/user/metrics', data: data);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Profile
  Future<ProfileResponse> getProfile() async {
    try {
      final response = await _apiClient.get('/user/profile');
      return ProfileResponse.fromJson(response.data);
    } catch (e) {
      return ProfileResponse(success: false, message: 'Lỗi tải hồ sơ cá nhân');
    }
  }

  Future<bool> updateProfile(ProfileModel profile) async {
    try {
      final response = await _apiClient.put(
        '/user/profile',
        data: profile.toJson(),
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
