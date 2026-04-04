import 'package:get_it/get_it.dart';
import 'package:medi_chain_mobile/core/network/api_client.dart';
import 'package:medi_chain_mobile/core/utils/secure_storage_service.dart';
import 'package:medi_chain_mobile/data/repositories/auth_repository.dart';
import 'package:medi_chain_mobile/data/repositories/user_repository.dart';
import 'package:medi_chain_mobile/data/repositories/medical_repository.dart';
import 'package:medi_chain_mobile/data/repositories/ai_repository.dart';
import 'package:medi_chain_mobile/data/repositories/sharing_repository.dart';
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
}
