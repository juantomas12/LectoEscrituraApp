import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'application/providers/app_providers.dart';
import 'core/utils/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/viewmodels/settings_view_model.dart';
import 'presentation/widgets/upper_text.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: LectoescrituraApp()));
}

class LectoescrituraApp extends ConsumerWidget {
  const LectoescrituraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);

    return startup.when(
      data: (_) {
        final settings = ref.watch(settingsViewModelProvider);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'APP DE LECTOESCRITURA',
          theme: buildAppTheme(settings),
          home: const HomeScreen(),
        );
      },
      error: (error, stack) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: UpperText('ERROR DE INICIO: $error'),
              ),
            ),
          ),
        );
      },
      loading: () {
        return const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  UpperText('CARGANDO CONTENIDO OFFLINE...'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
