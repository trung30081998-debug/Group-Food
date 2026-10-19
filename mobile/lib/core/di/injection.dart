import 'package:get_it/get_it.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

/// Call after Supabase.initialize and before runApp.
Future<void> configureDependencies() => getIt.init();
