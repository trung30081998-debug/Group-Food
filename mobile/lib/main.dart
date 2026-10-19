import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/injection.dart';
import 'features/order_session/presentation/pages/create_session_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  await configureDependencies();
  runApp(const GroupFoodApp());
}

class GroupFoodApp extends StatelessWidget {
  const GroupFoodApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GroupFood',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      useMaterial3: true,
    ),
    home: const CreateSessionPage(),
  );
}
