import 'package:get_it/get_it.dart';
import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/core/utils/secure_storage_service.dart';
import 'package:medi_chain_mobile/data/repositories/auth_repository.dart';
import 'package:medi_chain_mobile/data/repositories/user_repository.dart';
import 'package:medi_chain_mobile/data/repositories/medical_repository.dart';
import 'package:medi_chain_mobile/data/repositories/ai_repository.dart';
import 'package:medi_chain_mobile/data/repositories/sharing_repository.dart';
import 'package:medi_chain_mobile/data/repositories/admin_repository.dart';
import 'package:medi_chain_mobile/logic/auth/auth_bloc.dart';
import 'package:medi_chain_mobile/logic/dashboard/dashboard_bloc.dart';
import 'package:medi_chain_mobile/logic/medical/medical_bloc.dart';
import 'package:medi_chain_mobile/logic/medicine/medicine_bloc.dart';
import 'package:medi_chain_mobile/logic/ai/ai_bloc.dart';
import 'package:medi_chain_mobile/logic/chat/chat_bloc.dart';
import 'package:medi_chain_mobile/logic/profile/profile_bloc.dart';
import 'package:medi_chain_mobile/logic/appointment/appointment_bloc.dart';
import 'package:medi_chain_mobile/logic/metric/metric_bloc.dart';
import 'package:medi_chain_mobile/logic/sharing/sharing_bloc.dart';
import 'package:medi_chain_mobile/logic/admin/admin_bloc.dart';
import 'package:medi_chain_mobile/data/repositories/payment_repository.dart';
import 'package:medi_chain_mobile/logic/payment/payment_bloc.dart';
import 'package:medi_chain_mobile/data/repositories/clinic_repository.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_appointment_bloc.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_patient_bloc.dart';
import 'package:medi_chain_mobile/logic/clinic/clinic_payment_bloc.dart';
import 'package:medi_chain_mobile/logic/clinic/notification_bloc.dart';
import 'package:medi_chain_mobile/data/repositories/health_twin_repository.dart';
import 'package:medi_chain_mobile/logic/health_twin/health_twin_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupInjection() async {
  // Services
  getIt.registerLazySingleton(() => SecureStorageService());
  getIt.registerLazySingleton(() => ApiClient(getIt<SecureStorageService>()));

  // Repositories
  getIt.registerLazySingleton(() => AuthRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => UserRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => MedicalRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => AIRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => SharingRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => AdminRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => PaymentRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => ClinicRepository(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => HealthTwinRepository(getIt<ApiClient>()));

  // Blocs
  getIt.registerLazySingleton(
    () => AuthBloc(getIt<AuthRepository>(), getIt<SecureStorageService>()),
  );
  getIt.registerFactory(() => DashboardBloc(getIt<UserRepository>()));
  getIt.registerFactory(() => MedicalBloc(getIt<MedicalRepository>()));
  getIt.registerFactory(() => MedicineBloc(getIt<MedicalRepository>()));
  getIt.registerFactory(() => AIBloc(getIt<AIRepository>()));
  getIt.registerFactory(() => ChatBloc(getIt<AIRepository>()));
  getIt.registerFactory(() => ProfileBloc(getIt<MedicalRepository>()));
  getIt.registerFactory(() => AppointmentBloc(getIt<MedicalRepository>()));
  getIt.registerFactory(() => MetricBloc(getIt<MedicalRepository>()));
  getIt.registerFactory(() => SharingBloc(getIt<SharingRepository>()));
  getIt.registerFactory(() => AdminBloc(getIt<AdminRepository>()));
  getIt.registerFactory(() => PaymentBloc(getIt<PaymentRepository>()));
  getIt.registerFactory(() => ClinicAppointmentBloc(getIt<ClinicRepository>()));
  getIt.registerFactory(() => ClinicPatientBloc(getIt<ClinicRepository>()));
  getIt.registerFactory(() => ClinicPaymentBloc(getIt<ClinicRepository>()));
  getIt.registerFactory(() => NotificationBloc(getIt<ClinicRepository>()));
  getIt.registerFactory(() => HealthTwinBloc(getIt<HealthTwinRepository>()));
}
