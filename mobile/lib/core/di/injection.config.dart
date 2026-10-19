// Hand-maintained equivalent of injectable's generated configuration.
// Regenerate with `dart run build_runner build` after adding injectable types.
// ignore_for_file: unnecessary_lambdas

import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/order_session/data/repositories/session_repository_impl.dart';
import '../../features/order_session/domain/repositories/session_repository.dart';
import '../../features/order_session/presentation/cubit/session_cubit.dart';

extension GetItInjectableX on GetIt {
  Future<GetIt> init() async {
    registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
    registerLazySingleton<SessionRepository>(
      () => SessionRepositoryImpl(get<SupabaseClient>()),
    );
    registerFactory<SessionCubit>(() => SessionCubit(get<SessionRepository>()));
    return this;
  }
}
